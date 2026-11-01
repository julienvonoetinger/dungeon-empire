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

Correction après retour utilisateur : le corps du paladin fait maintenant face
au centre du cœur, au milieu de chaque côté. L'ancien alignement du marteau sur
le chapiteau opposé décalait le corps latéralement. La portée projetée au sol
détermine la même distance d'approche (~.722case) dans les quatre directions ;
elle ne dépend pas de la hauteur apparente du marteau. L'origine reste fixe.
Le marteau droit vise le chapiteau du côté de la main : centres(±.295,±.295),
dessus carré.17 à hauteur.255, issus de la géométrie figée migration-v1. Le
contact peut toucher toute cette surface, sans exiger son centre exact. Le tri
des objets réutilise les supports du rendu isométrique.
Ceci vérifie l'alignement visuel des sprites ; ce n'est pas une nouvelle
validation physique continue des modèles3D ni une application de dégâts réels.

paladin_action_preview expose désormais _populate_stage pour conserver la même
interface ; la petite borne de PaladinAttack reste dans sa propre spécialisation.
paladin_core_attack_stage utilise mobile_dungeon_renderer sans Game/Session.
Le temps du vortex suit pause et vitesse, sans redémarrer entre deux attaques.
L'impact donne un bref éclat au cœur. Ghost core agit uniquement sur son alpha.
Aucune sauvegarde joueur, règles de raid, héros autorisés, textures ou APK modifiés.

Vérifications natives :224contrôles de scène passent après7échecs reproduisant
le décalage et les distances inégales. Nouveaux contrôles : corps sur l'axe du
cœur, bon côté d'approche, distance égale et impact dans le vrai chapiteau.
Les281contrôles de l'attaque précédente passent également. Stderr vide.
Contrôle des quatre directions, ressources originales, échelles, contact2D,
positions stables, pieds hors du socle, tri avant/arrière, ombre/lueur, pause,
vitesses, transparence et3formats1280x720/844x390/720x960. Captures inspectées,
revue indépendante sans anomalie actionnable.
Logs de cette correction dans artifacts/paladin-core-centered ; les captures
actuelles restent dans artifacts/paladin-core-attack. Pas de profilage mobile.

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
