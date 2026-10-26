# Validation de la première boucle jouable — 25 octobre 2026

## Portée et provenance

Scène `scenes/game/DungeonGame.tscn`, spécification
[`2026-10-25-isometric-gameplay-design.md`](../superpowers/specs/2026-10-25-isometric-gameplay-design.md).
Base de travail `862125f1`, branche `codex/2d-foundation` ; changements non commités.

`dungeon_sim.gd`, `hero_roster.gd` et `core_progression.gd` sont repris du tag
`v1.0.0`. `game_types.gd` retire les constantes d'ancien affichage et adopte le
cœur 1×1. `raid_director.gd` ajoute un instant de départ de pas pour la vue.
`gameplay_save.gd` reprend `scripts/mobile/mobile_save.gd` avec un nouveau nom de
classe ; la session emploie une sauvegarde indépendante. Le Main, le HUD et les
modèles 3D n'ont pas été réimportés.

## Vérifié

- Import Godot et lancement initial : un défaut d'inférence de type corrigé,
  puis lancement sans erreur. Les références circulaires sim/director sont
  libérées à la sortie.
- Essai interactif dans la fenêtre **Vérification**, sauvegarde distincte :
  ouverture de Pause, choix du donjon d'essai, confirmation, affichage du plan
  avec 245 or / capacité 450, porte, pointes, trois coffres et cœur ; lancement
  d'un raid avec un Ranger, disparition des outils de construction pendant le raid.
- La partie normale déjà utilisée par l'utilisateur est restée ouverte ; ses
  actions ne sont pas comptées comme notre validation.
- Revue indépendante en lecture seule des règles, session, vue, HUD, contrôles
  et sauvegarde. Deux anomalies concrètes corrigées, ci-dessous.
- Après corrections : démarrage `--headless`, 8 frames, sur la sauvegarde de
  vérification : code de sortie 0, stderr vide. Ce lancement charge les scripts
  et la scène ; il ne constitue pas un raid complet ni une preuve des gestes.

## Corrections issues de la revue

1. **Le héros rejouait un pas pendant une action stationnaire.** `move_cd` sert
   aussi aux décisions et aux immobilisations ; le réutiliser pour interpoler
   depuis `move_from` pouvait faire reculer le héros pendant crochetage/frappe.
   Le directeur enregistre désormais `step_started_at` uniquement lorsqu'il
   change effectivement de case. La vue calcule le progrès avec le temps de raid,
   qui s'arrête en pause. Les durées et effets de jeu restent identiques.
2. **Reprise possible derrière la confirmation de redémarrage.** La session
   possède désormais `confirmation_open` : simulation, édition et reprise sont
   bloquées. Le bouton Pause est désactivé et Échap ne peut lever ce verrou.
   Annuler libère la confirmation en restant en pause ; confirmer réinitialise
   les deux états. Vérification de ces chemins dans le code et compilation,
   sans nouvelle manipulation visuelle après la demande de l'utilisateur.

## Limites de la validation

L'utilisateur a interrompu le contrôle de l'écran avec Échap, puis demandé de
garder son ordinateur disponible. Aucun autre contrôle de fenêtre après cette
demande. La validation visuelle complète est **en attente**, notamment :

- fin d'un raid et bilan, réparation, transfert, collecte et absorption en UI ;
- rechargement visuellement identique et sortie pendant un raid ;
- gestes tactiles réels, glissement sans achat, second doigt et redimensionnement ;
- occlusions du héros dans toutes les orientations et pendant les interactions ;
- panne réelle d'écriture/disque et performances sur téléphone.

La revue n'a relevé aucun autre défaut concret dans les gardes de phase, achat,
récompense unique et sauvegarde. Cela ne remplace pas les vérifications ci-dessus.
Pas de suite de tests automatisés ajoutée/lancée : l'instruction du dépôt demande
une requête explicite. Pas d'APK, de benchmark téléphone, de commit ou de push.

## Reprendre les essais plus tard

Depuis la racine avec Godot disponible :

```powershell
godot --path . res://scenes/game/DungeonGame.tscn -- --review-session
```

Cet argument ne change que le nom de fenêtre et le fichier
`user://isometric_review_v1.save`, jamais les règles ni `isometric_run_v1.save`.
Les logs locaux sont dans `artifacts/gameplay-*.log` (ignorés par Git).
La scène de démarrage locale de `project.godot`, l'atlas et ses sources sont
préservés. Les processus déjà ouverts utilisent leur version chargée ; une
nouvelle ouverture de la scène sera nécessaire pour essayer les corrections.
