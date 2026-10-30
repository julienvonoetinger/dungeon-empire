# Sondes et simulations sans interface

Les sondes **observent** le jeu. Les scénarios **agissent** sur la même session
que le jeu : construction, transfert, lancement du raid et progression du temps.
Aucune scène graphique, aucun clic et aucun rendu GPU ne sont nécessaires.

## Lancer

Depuis la racine du dépôt, sous Windows :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-probes.ps1
```

Le lanceur recherche `GODOT`, `godot`/`godot4` dans le PATH, puis l'installation
Steam habituelle. On peut fournir `-Godot 'C:/chemin/godot.exe'`. Utiliser le même
Godot que le projet (validation actuelle : 4.7.2). Sur un nouveau checkout, ouvrir
une fois le projet dans l'éditeur ou faire un import headless pour enregistrer les
classes Godot, avant le premier lancement.

Le rapport est `artifacts/probes/report.json`. Codes de sortie : **0** réussite,
**1** assertion/invariant/délai non respecté, **2** entrée invalide ou erreur du
lanceur/moteur. Le wrapper vérifie aussi stderr : Godot peut sortir avec 0 après
une erreur GDScript. Il conserve les logs dans `artifacts/probes/logs` et impose un
watchdog de cinq minutes. Aucun réglage de sécurité permanent n'est modifié.

Exécuter 40 raids, avec les graines 1 à 40 :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-probes.ps1 `
  -Scenario tests/scenarios/raid-cycle.json -Seed 1 -Runs 40 `
  -Report artifacts/probes/raids-40.json
```

Un résultat se reproduit avec le même scénario, la même graine, le même code,
la même configuration et la même version de Godot. Le rapport contient le hash
du scénario, la graine, la version du moteur et l'option `testing/vulpin_only`.
Le temps simulé est `ticks × 0,05 s`, indépendamment du temps réel d'exécution.

Entrée Godot directe (tous systèmes ; surveiller également stderr) :

```text
godot --headless --path . --script res://tools/run_probes.gd -- --scenario res://tests/scenarios/raid-cycle.json --seed 42 --report res://artifacts/probes/raid.json
```

`--suite res://tests/scenarios` sélectionne un dossier de JSON. Sans sélection,
la suite fournie est lancée. `--runs N` incrémente la graine de chaque répétition.
Les rapports doivent rester hors du dossier des scénarios et hors de `user://`.

## Scénarios fournis

| Fichier | Vérification |
| --- | --- |
| `construction.json` | Ancrage, creusement, coûts, porte, refus d'emplacement/niveau, annulation et pointes |
| `raid-cycle.json` | Raid autonome complet, édition interdite, bilan et retour en préparation |
| `stair-traversal.json` | Graine 21 : descente avant exploration, pause, retour à l'escalier et remontée complète avant disparition |
| `trap-recoil.json` | Graine 21 : arrêt sur les pointes pendant les dégâts, pause, reprise après récupération et une seule activation |
| `timing.json` | Compte à rebours, pause et démarrage automatique |
| `treasury.json` | Transfert entre coffres, conservation de l'or et coût du verrou |
| `vulpin-lock-loot-repair.json` | Graine 21 : crochetage réel, déclenchement des pointes, vol sans attaque du cœur, réparation |

Les recettes de crochetage et d'escalier dépendent intentionnellement de leur
graine. Pour explorer d'autres graines/classes, utiliser `raid-cycle.json`, dont
les assertions sont générales. Le délai de 240 s est une borne de simulation ;
un Vulpin sans route accessible doit maintenant repartir directement.

Les comparaisons `eq` / `ne` acceptent les nombres JSON dans les tableaux et
objets : `[3.0,8.0]` correspond à la position entière `[3,8]`. Une chaîne ou un
booléen ne sont jamais convertis en nombre. Les champs `hero.entering`,
`hero.enter_t`, `hero.exit_arrival_t`, `hero.exiting` et `hero.exit_t` existent
seulement pendant leur phase ; utiliser `exists` pour attendre son apparition.

## Écrire un scénario

```json
{
  "version": 1,
  "name": "Inspecter une porte après le raid",
  "initial": "prepared",
  "seed": 21,
  "steps": [
    {"action":"start_raid"},
    {"action":"wait","probe":"door:5:8","field":"status","op":"eq","value":"open","timeout":20},
    {"action":"checkpoint","label":"Porte déverrouillée"},
    {"action":"wait","probe":"raid","field":"active","op":"eq","value":false,"timeout":240},
    {"action":"assert","probe":"core","field":"hp","op":"eq","value":100}
  ]
}
```

`initial` vaut `empty` (grille neuve) ou `prepared` (le vrai donjon d'essai).
La première commande `build` sur une grille vide place le cœur, comme en jeu.
Chaque commande est effectuée par les méthodes de session existantes, y compris
les contrôles de niveau, coût, phase et les confirmations de remplacement.
`build` annule ensuite la sélection : le compte à rebours peut donc reprendre.
Le donjon préparé garde sa sélection initiale, comme l'interface ; pour commencer
directement, utiliser `start_raid`.

| Action | Paramètres |
| --- | --- |
| `build` | `tool` (nom de `GameTypes.Tool`), `cell:[x,y]`, `expect` optionnel |
| `start_raid`, `undo` | `expect` optionnel |
| `pause` | `value:true/false` |
| `continue` | Fermer un bilan après raid ; rejet sans bilan ou en défaite |
| `advance` | `seconds` |
| `wait` | Condition de sonde et `timeout` |
| `assert` | `probe`, `field` optionnel, `op`, `value` |
| `checkpoint` | `label` ; copie de toutes les sondes |
| `transfer` | `cell`, `destination`, `amount`, `expect` optionnel |
| `collect`, `absorb` | `cell` ; collecte de butin/absorption de corps, sans effet sur une case vide comme en jeu |

`expect` vaut `accepted` par défaut ou `rejected` pour tester un refus.
Un refus inattendu échoue ; un refus attendu ne valide pas à lui seul l'absence
de débit : ajouter une assertion sur l'or pour vérifier cette règle.

Comparaisons : `eq`, `ne`, `lt`, `lte`, `gt`, `gte`, `exists`.
Les champs imbriqués utilisent un point (`result.raid_id`). Un champ absent fait
échouer les comparaisons ordinaires ; `exists` permet de tester sa présence avec
une valeur booléenne. `eq` compare les nombres exactement : pour les horloges
flottantes, préférer une borne `gte`/`lte`. Les chaînes et booléens ne sont pas
convertis en nombres.

Les coordonnées sont entières, de 0 à 15. Les durées sont des multiples positifs
de 0,05 s, au plus 3600 s chacune ; budget cumulé maximal de 100 000 ticks.
Maximum 512 étapes, 16 checkpoints, 1 Mio par fichier, 64 scénarios par suite et
100 répétitions par scénario. Les noms de champs/actions inconnus sont rejetés
avant toute exécution. Une attente trop longue échoue avec son état final.

## Sondes disponibles

| Identifiant | Champs principaux |
| --- | --- |
| `session` | phase, paused, editable, ready_for_raid, result_open, game_over, persistence_enabled |
| `economy` | gold, stored, unstored, capacity |
| `core` | hp, max_hp, cell |
| `raid` | active, index, elapsed, timer, stats, result |
| `hero` | present et état réel du héros : pos, hp, kind, lockpicking, collecting_gold, known, visited… |
| `progression` | xp, level, last_raid_id |
| `loot` | bags, corpses |
| `cell:x:y` | tile, walkable, cell |
| `door:x:y` | status (`locked`/`open`/`broken`), hp, max_hp, blocking |
| `trap:x:y` | charges, max_charges, spent, tile |
| `vault:x:y` | gold, capacity, lock_tier, opened, protected |

Une sonde d'objet existe uniquement tant que sa case contient cet objet. Les
coordonnées Godot sont exportées sous forme `[x,y]` ; les clés de dictionnaires
spatiaux deviennent `"x:y"`. `cell.walkable` décrit le terrain selon la simulation ;
une porte peut encore bloquer le héros, voir `door.blocking`.

Les invariants contrôlent chaque commande et chaque tick : dimensions/types de
grille, points de vie du cœur et portes, charges, protection et capacité des
coffres, trésorerie, références d'objets orphelines et occupation du héros
(roche/cœur solide/porte fermée). Les sondes sont passives : elles ne réparent ni
ne réconcilient les données. Une anomalie ne doit pas disparaître en la lisant.

Les rapports contiennent l'état initial/final, les checkpoints, les événements
de pièges et de fin de raid, les bornes temporelles de chaque étape et les
échecs (`step`, `tick`, `probe`, `expected`, `actual`, message).

## Réutilisation en GDScript

```gdscript
const Probes = preload("res://scripts/testing/game_probes.gd")
var state = Probes.snapshot(game_session)
var anomalies = Probes.violations(game_session)
```

Le runner `scripts/testing/scenario_runner.gd` expose `validate(data)` (dictionnaire
`ok`/`errors`) et `run(data, parent_node)` (rapport). Les runs sont synchrones et
séquentiels. Le RNG global du jeu est réinitialisé par run ; pour paralléliser,
utiliser plusieurs processus Godot. Ne pas exécuter ce runner dans une partie
active : ses commandes ciblent une session indépendante mais sa graine est globale.

Le runner crée seulement `game_session.gd`, désactive `persistence_enabled`
**avant** son entrée dans l'arbre et désactive son traitement automatique.
`advance_simulation` est le même point d'entrée que `_process` en jeu.
L'initialisation, les commandes et la fin de raid n'accèdent à aucune sauvegarde.
La réconciliation normale des coffres reste exécutée. La session est libérée à
la fin, y compris ses références croisées simulation/directeur.

## Vérifier l'outillage

```text
godot --headless --path . --script res://tools/verify_game_probes.gd
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify-probe-cli.ps1
```

Ces tests injectent des incohérences pour prouver leur détection, reproduisent
les scénarios, vérifient les codes de sortie et protègent les entrées contre
l'écrasement par un rapport. Les seuls fichiers de sauvegarde écrits par les tests
de persistance sont des fixtures dans `artifacts/probes`, jamais ceux du joueur.

Ces sondes valident la logique et l'état de grille. Elles ne prouvent pas la
qualité des textures, la bonne occultation des sprites, la lisibilité du HUD ou
les performances Android. Les captures natives existantes gardent ce rôle.
L'ancien panneau F3 de sondes visuelles n'est pas restauré par cet outil.
