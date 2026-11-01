PALADIN — ATTAQUE AU MARTEAU
1 novembre 2026

Demande : créer l'animation d'attaque après marche/course/dégâts/mort.
Proposition : garde, levée du marteau, armement, frappe descendante rapide,
léger rebond, récupération puis retour en garde. Le bouclier reste tenu et
les semelles portent le personnage pendant le transfert de poids.

10 poses tenues sur 900 ms ; impact à 450 ms (index5). Durées en ms :
90,110,110,80,60,45,65,100,120,120. La dernière pose recopie exactement les
transformations de la première. Les atlas réutilisent aussi son image entière :
9 images distinctes par direction, soit36sprites,4atlas2880x320,14.0625MiB RGBA.
Poids PNG :1,915,166octets, détail dans validation.json. Aucun morceau de corps recomposé en2D.

SOURCE ET REPÈRES
- Scène équipée approuvée v3, GLB/body/UV/textures d'origine inchangés.
  Les9textures sont embarquées dans paladin-attack-poses.blend.
- Marteau rigide sur Bone_023, bouclier sur Bone_019 ; matrices de prise et
  doigts fermés conservés. Aucune animation3D dans le jeu : uniquement sprites.
- Cadrage orthographique30deg dans4vues réelles, pas de miroir. Masters640px
  réduits uniformément à320px, ortho3.25, même densité que256px/2.6 des marches.
- Le repère au sol(0,-.20,0) est celui de toutes les actions Paladin précédentes.
  Le cadrage vertical monte à1.04 pour ne pas couper le marteau levé ; ancre
  (160,248.681001), échelle native.9404255319 inchangée.
- La borne est une géométrie de test, pas un nouveau décor peint. Son dessus
  correspond au point de contact mesuré sur la face avant du marteau, projeté
  par chaque caméra. Son tri avant/arrière dépend du point d'appui projeté.

CORRECTIONS RETENUES
Le premier essai traversait la borne après l'impact et coupait le marteau dans
la vue sud-ouest. Rebond plus haut et cadrage relevé. Une frappe à main trop
haute faisait traverser l'armure par l'arrière du manche ; le poignet frappe
plus bas. Les contrôles de contacts sont conservés pour éviter de le reproduire.
La seule correction verticale des semelles laissait un petit glissement XY :
le solveur enregistre maintenant leur appui initial et corrige aussi leur
centre XY. Le contrôle porte sur les véritables sommets en contact avec le sol,
pas sur le haut de la botte qui doit pouvoir fléchir avec le tibia.
La garde finale est la première pose exacte, pour éviter les écarts dus à une
nouvelle résolution IK. Les grips, proportions et géométrie source ne changent pas.

SCÈNE GODOT
scenes/PaladinAttack.tscn, lancer avecF6. Quatre directions, bouton Attack,
pause, image suivante, vitesse0.5/1/1.5/2x, répétition optionnelle désactivée.
Un seul coup est joué puis la garde est maintenue. La borne s'éclaire au contact.
L'événement de test détecte le franchissement temporel de450ms, même si une
image est sautée à2x. Le scrubbing ne simule pas de dégâts. Aucun accès à une
session, aux sauvegardes ou aux règles de combat ; roster Vulpin inchangé.
Les WebP bouclent avec1seconde de pause pour la revue uniquement.

REPRODUCTION DEPUIS LA RACINE DU DÉPÔT
Utiliser Blender5.2.1 en processus séparé, jamais la session Blender de travail.
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v7-hammer-attack/render_attack.py
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v7-hammer-attack/verify_attack.py
  node docs/reference/lithide-review/v7-hammer-attack/prepare.cjs
  godot --headless --path . --editor --import
  godot --path . --script tools/verify_paladin_attack.gd
  godot --path . --script tools/verify_paladin_reactions.gd
  node docs/reference/lithide-review/v7-hammer-attack/prepare_native_review.cjs
NODE_PATH doit exposer sharp (runtime Node Codex existant). Exécuter les
fixtures Godot graphiques successivement sous Windows. Les captures et logs
vont dans artifacts/paladin-attack, ignoré parGit. docs/.gdignore exclut les
sources Blender, masters et pages de revue des exports.
render_attack.py -- --measure-only reconstruit uniquement les poses ;
-- --pilot produit les poses0/3/5/7 sous2angles à12samples. Relancer ensuite
le rendu complet à32samples avant de préparer les atlas définitifs.

VALIDATION ET LIMITES
verify_attack.py recharge réellement le blend, contrôle les quatre cadrages,
contact/sol, appuis XY, prises rigides, intersections accessoires/corps hors
mains de prise et entre accessoires, pose finale exacte et hashes source.
Le test natif contrôle chronologie, pause, pas-à-pas, vitesses, répétition,
contact enregistré et cadrages en1280x720,844x390,720x960.
Les premiers échecs et contrôles finaux restent dans artifacts/paladin-attack.
Résultat final :165contrôles Blender,281contrôles natifs attaque et354contrôles
de non-régression dégâts/mort passent. Journaux natifs stderr vides ; captures
des trois formats inspectées. Revue indépendante sans anomalie restante.
Ce sont des poses discrètes, pas une simulation physique continue. Les tests
arête/triangle ne prouvent pas l'absence de toute inclusion ou auto-intersection
de l'armure. Pas de profilage sur téléphone. L'appréciation artistique reste
à confirmer par l'utilisateur. Aucun APK, commit/push ou intégration aux raids.
