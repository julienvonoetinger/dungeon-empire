# Première boucle jouable isométrique

État : base implémentée, deux corrections de revue intégrées ; validation
interactive partielle. [Relevé](../../gameplay/validation-2026-10-25.md).

## Décision utilisateur et objectif

Le 25 octobre, l'utilisateur choisit de reprendre préparation → raid autonome →
bilan du prototype précédent, et accepte des repères provisoires pour les héros,
coffres et pièges afin de rendre la boucle jouable avant leurs nouveaux sprites.
Ce document décrit la portée de cette première intégration, pas un état déjà livré.

Une nouvelle scène `scenes/game/DungeonGame.tscn` permet de créer un donjon,
creuser, construire, lancer un raid, observer un visiteur autonome, puis collecter,
réparer et recommencer. Un donjon d'essai facultatif donne accès immédiatement à
la boucle. Les 24 scènes visuelles existantes restent des références inchangées.

## Réemploi et adaptations

Source de règles : section 0 de `GAME_DESIGN.md` au tag `v1.0.0`, corroborée par
`scripts/game/{game_types,dungeon_sim,raid_director,hero_roster,core_progression}.gd`
et `scripts/mobile/mobile_save.gd`. Le vieux README ne reflète pas les dernières
règles (il cite notamment seulement trois classes et des coffres payants).

- Réutiliser la simulation indépendante du rendu : grille 16×16, quatre classes,
  exploration partielle, personnalités, retraite, charges, portes et protections,
  trésorerie par coffre, corps/butins, XP du cœur et visiteurs persistants.
- Valeurs initiales : 320 or, 100 PV du cœur ; creuser 5, coffre simple gratuit
  de capacité 150, pointes 35/3 charges, entrave 30/3, néant 45/1,
  porte 40/60 PV, porte magique 80, protections coffre 40/80.
  Réparations : porte/protection 15, piège 10 par charge.
- Déblocages normaux : entrave niveau 2, néant 3, magie 4 ; aucun ancien override
  Vulpin-only/unlock-defenses activé. Les quatre classes ont des repères distincts.
- **Choix d'adaptation** : cœur solide d'une case, centré à +(.5,.5), pour garder
  le sprite et l'échelle approuvés. Anneau d'accès gratuit autour de cette case,
  sans porte ni entrée ; aucune modification d'illustration. L'ancien 2×2 est
  explicitement abandonné pour cette scène, avec une sauvegarde distincte.
- Conserver les minuteries historiques d'interaction, sans réimporter les modèles
  ou animations 3D. Les repères montrent marche, action, vie et progression.

## Session, contrôles et persistance

États : ancrage, préparation, raid, bilan, défaite, pause. Le compte à rebours de
25 secondes commence lorsque cœur, entrée et capacité de stockage sont présents.
Il s'arrête pendant placement/inspection, bilan et pause. Un lancement manuel
emploie les mêmes conditions. Construction et économie sont verrouillées en raid.
Le bilan accorde les récompenses une seule fois. Le cœur à zéro arrête la partie.

Caméra fixe .75, libre au doigt/souris, sans zoom, rotation ni suivi automatique.
Un glissement déplace la vue, un tap sélectionne ; la construction se confirme
explicitement. Aucun glissement n'excave accidentellement. L'interface absorbe ses
événements. Second doigt/focus perdu annulent le geste ; le focus perdu met en pause.
Recentrer sur le cœur reste disponible. Cette interaction remplace le creusement
continu de l'ancien prototype, incompatible avec le pan tactile demandé.

Sauvegarde locale `user://isometric_run_v1.save`, jamais l'ancien mobile_run_v1.
Sauver les actions de préparation et le bilan, et un checkpoint avant le raid.
Quitter en raid restaure ce checkpoint, sans simulation hors ligne ; ne jamais
sauver un héros à mi-action. Échec d'écriture visible, original/backup conservés.
Recommencer demande confirmation, conserve l'XP du cœur et réinitialise le donjon
et ses visiteurs. Le donjon d'essai est une option explicite de démarrage/reset.

## Rendu et séparation des responsabilités

Le modèle reste en coordonnées logiques. Un adaptateur transmet cellules ouvertes,
portes, entrée et cœur au renderer commun. Texture/masques/atlas immuables.
Les repères provisoires sont des indicateurs vectoriels de jeu, pas des textures
architecturales ou de nouveaux assets approuvés. Porte ouverte/détruite : ouverture
lisible avec repère d'état tant qu'une illustration dédiée n'est pas disponible.
Les décors ne deviennent pas automatiquement des obstacles de gameplay.

Les repères mobiles utilisent les volumes/supports et l'ordre des éléments déjà
préparés, pas un simple calque toujours devant les murs. Ne pas reconstruire les
sprites architecturaux à chaque frame : seulement aux modifications de structure.
Séparer session, vue, entrée caméra et HUD ; pas de restauration du Main 3D.

## Validation et limites

Conformément à AGENTS.md, ne pas ajouter/lancer de tests automatisés sans demande.
Compiler/importer les scripts et ouvrir la scène pour un parcours manuel : ancrage,
creusement, coût/annulation, raid, résultat, réparation, pause et rechargement.
Capturer la nouvelle vue et vérifier les occlusions, la sélection et le pan.
Contrôler les dépendances et préserver `project.godot` déjà modifié par l'utilisateur.
Pas de commit/push, de nouveaux sprites, de performances mobile revendiquées ni de
nouveaux systèmes (monstres, groupes, recherche, carte du monde, simulation offline).
