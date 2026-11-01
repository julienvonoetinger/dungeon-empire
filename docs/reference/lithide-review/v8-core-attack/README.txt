PALADIN — ATTAQUE DU CŒUR SOUS QUATRE DIRECTIONS
1 novembre2026

Demande : une scène où le paladin attaque le cœur dans les quatre directions.
Lancer scenes/PaladinCoreAttack.tscn avecF6. La répétition est active par défaut.
Contrôles partagés : Attack, pause, image suivante,0.5/1/1.5/2x, Repeat.
Ghost core permet de voir les contacts masqués en conservant le tri normal.

Réutilisation des SpriteFrames v7 sans nouveau rendu/image/sprite, échelle
.940425532,900ms/coup et impact450ms inchangés. Le cœur provient du catalogue
de production, avec son shader vortex, ses deux effets de sol et sa taille
native. Quatre petites plateformes utilisent le même rendu de sol du jeu.

La scène calibre en2D le point de frappe enregistré du marteau sur chacun des
quatre chapiteaux du socle : centres(±.295,±.295), hauteur.255, issus de la
géométrie figée migration-v1. L'origine du paladin est calculée une seule fois
et reste fixe. Le tri des objets réutilise les supports du rendu isométrique.
Ceci vérifie l'alignement visuel des sprites ; ce n'est pas une nouvelle
validation physique continue des modèles3D ni une application de dégâts réels.

paladin_action_preview expose désormais _populate_stage pour conserver la même
interface ; la petite borne de PaladinAttack reste dans sa propre spécialisation.
paladin_core_attack_stage utilise mobile_dungeon_renderer sans Game/Session.
Le temps du vortex suit pause et vitesse, sans redémarrer entre deux attaques.
L'impact donne un bref éclat au cœur. Ghost core agit uniquement sur son alpha.
Aucune sauvegarde joueur, règles de raid, héros autorisés, textures ou APK modifiés.

Vérifications natives :208contrôles de scène passent ;281contrôles de l'attaque
précédente et354des dégâts/mort passent après la refactorisation. Stderr vide.
Contrôle des quatre directions, ressources originales, échelles, contact2D,
positions stables, pieds hors du socle, tri avant/arrière, ombre/lueur, pause,
vitesses, transparence et3formats1280x720/844x390/720x960. Captures inspectées,
revue indépendante sans anomalie restante. Pas de profilage physique mobile.

Reproduction depuis la racine du dépôt, commandes successives :
  godot --headless --path . --editor --import
  godot --path . --script tools/verify_paladin_core_attack.gd
  godot --path . --script tools/verify_paladin_attack.gd
  godot --path . --script tools/verify_paladin_reactions.gd
  node docs/reference/lithide-review/v8-core-attack/prepare.cjs
Node requiert sharp via le NODE_PATH du runtime existant. Les captures/logs
sont dans artifacts/paladin-core-attack. Le WebP assemble10captures natives
avec les durées originales et une pause de revue1s ; la scène tourne en direct.
docs/.gdignore exclut cette revue des exports. Aucun commit/push.
