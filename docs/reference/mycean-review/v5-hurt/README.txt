MYCEAN — RÉACTION AUX DÉGÂTS
2026-11-01. Sprites complets depuis Blender, scène native isolée.

INTENTION
Recul bref du buste, flexion des genoux, bras libre légèrement ramené,
bâton toujours en main, puis récupération plus progressive. Pieds plantés
et retour exact à la posture de départ. Pas de pliure en avant qui évoquerait
un éternuement ; pas de déplacement de la cellule dans la scène de revue.

SOURCE ET POSES
Source immuable : ../v2-meshy-inspection/mycean-equipped-review.blend.
Deux GLB originaux et SHA256 dans ../source.35os,15429sommets du corps,
10633sommets du bâton, six textures2048² intégrées. Géométrie de base,
faces, UV, poids, affectations des matériaux et peinture inchangés.
Corps/bâton rendus ensemble, sans découpe2D ni miroir de direction.

Mapping Mycean : racine000 ; jambes R006/005/004,L015/014/013 ;
bras R025/024/023,L033/032/031 ; tête017. Ne pas reprendre les os du Paladin.
Les trois attaches à Bone_031 (bâton, lattice de prise, enveloppe de contact)
gardent leurs matrices relatives. Lattice et Shrinkwrap restent actifs pendant
toute la réaction, contrairement à la mort où la main lâche le bâton.
La subdivision SIMPLE2 sert uniquement au rendu hors ligne du contact de main.
Le roulement axial de l'avant-bras est transporté depuis le montage approuvé.

Huit poses : Ready/Impact/Recoil/Brace/Return/Recover/Balance/Ready.
Durées ms :65/65/90/115/100/95/90/100, total720ms. Clés CONSTANT dans Blender.
Inclinaison du bassin/buste :0/-5/-12/-17/-14/-8/-3/0degrés.
Force :0/.35/.85/1/.82/.45/.15/0. Compression du bassin-.070*force,
translation arrière+.026*force, torsion-2*force ; tête à75% de l'inclinaison.
Bras libre avance légèrement et monte ; poignet du bâton garde presque sa
verticale, avec8degrés d'inclinaison avant au maximum pour dégager le chapeau.
Les poses1 et8 reprennent les transformations de la source équipée, sans IK,
et leurs géométries évaluées correspondent exactement entre elles.

Les autres poses résolvent les jambes sans étirement puis ajustent chaque
cheville à partir des vrais sommets de semelle : moyenne X/Y et minimum Z.
La cible est mesurée dans la source, pas supposée au centre du pied. Un probe
non subdivisé ne sert qu'à ces mesures et reste caché au rendu. La vérification
indépendante exige une erreur XYZ<.0002unité, sol du corps>=-.0001 et bâton>0.
La main est incluse dans tous les contrôles bâton/corps complet. La stabilité
mesurée concerne les moyennes d'appui (erreur max.0000231), pas chaque sommet
de botte : les pondérations tibia/pied déforment un peu le cuir lors de la
flexion. Mouvement maximal mesuré.02164unité ; pour les sommets restant près
du sol, dérive horizontale max.01448, soit environ1.35pixel à l'échelle native.

RENDU ET RESSOURCES
Caméra orthographique2.6, élévation30deg, racine(0,-.20,0), cible(0,-.20,.72),
éclairage tourné avec chacune des quatre directions SE/SW/NW/NE. Cycles32 avec
débruitage, couleurs Standard/None de la source.32maîtres512px alpha réduits
uniformément en256px Lanczos. Même ancre(128,189.394539) et échelle native
.940425532 que la marche/course. Sept poses géométriques uniques par direction,
la huitième reprend délibérément la première pour récupérer sans saut.
Les32maîtres rendus restent conservés. Les rendus neutres identiques en3D
diffèrent de quelques canaux RGB à1/255 à cause de la précision du rendu.
La préparation refuse un écart supérieur à1/255 puis réutilise l'image complète
de départ pour la dernière pose. source_index/rendered_sha256 et sha256 tracent
cet alias dans validation.json ; aucun élément du personnage n'est recomposé.

- mycean-hurt-poses.blend : poses et textures empaquetées.
- rig.py/render_hurt.py : recette ; poses.json : contacts/attaches/timing.
- masters/{se,sw,nw,ne} :32rendus ; prepare.cjs : réduction uniforme/atlas.
- assets/previews/mycean-hurt : quatre atlas2048x256,8MiB RGBA décodés,
  1,330,149octets PNG sur disque, SpriteFrames non bouclés, registration.json
  et provenance.
- hurt-preview.webp :720ms +1200ms au repos ; hurt-slow.webp :1440+1200ms.
  hurt-poses.png montre toutes les poses. Les WebP de revue bouclent ;
  les ressources Godot attendent un déclenchement explicite.
- scenes/MyceanHurt.tscn : quatre vues sur les dalles du kit, F6.
  Take a hit/Pause/Next frame/0.5x/1x/1.5x/2x/Repeat, script partagé
  paladin_action_preview.gd inchangé, sans Game/Session/sauvegarde.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v5-hurt/render_hurt.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v5-hurt/verify_saved_hurt.py
& $node docs/reference/mycean-review/v5-hurt/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_mycean_hurt.gd' -WindowStyle Hidden -Wait -PassThru

Blender dédié en arrière-plan uniquement ; jamais la session ouverte.
-- --pilot rend SE/NW poses1/4/6 ; -- --poses-only enregistre sans rendre.
Toujours refaire les32maîtres après un changement partagé, puis prepare.cjs.
docs/.gdignore exclut les sources, maîtres et pages de revue des exports.

VALIDATION
Fixture native d'abord en échec car la scène n'existait pas. Le contrôle négatif
sur la source debout échoue aux trois critères de recul/compression ; le blend
enregistré satisfait200contrôles indépendants : retour exact, contacts, ancrage,
relecture des huit poses, cadrage de toutes les géométries dans les quatre vues,
originals et six textures inchangés. Aucun croisement de surface bâton/corps
détecté, main comprise. La préparation vérifie les32maîtres/alpha, les ancres,
sept images distinctes par direction et l'égalité exacte première/dernière,
les feuilles2048x256 et les délais WebP. Mesures dans validation.json et
saved-pose-validation.json ; preuves natives sous artifacts/mycean-hurt.

Import frais réussi ;275contrôles natifs sans échec, stderr vide. Retour neutre
vérifié au pixel près, lecture/pause/pas/replay/Repeat/vitesses, ancre fixe,
cadrage de chaque pose et contrôles à1280x720,844x390,720x960. Captures inspectées.
Revue indépendante :87contrôles source (rest-rig, matériaux, attaches, surfaces)
et292contrôles d'assets (32maîtres/réductions et alias explicite, quatre atlas
repackés à l'identique, ressources,64frames WebP décodées). Aucun problème
important restant. Une mauvaise référence de script généré a été repérée puis
corrigée avant import ; le générateur vérifie maintenant l'existence du script
partagé paladin_action_preview.gd. Celui-ci reste inchangé.

LIMITES
Proposition artistique à juger en mouvement. Le grand chapeau reste présent ;
yeux peints, pas de paupières animées. Les tests de poses tenues ne couvrent pas
toutes les auto-intersections/volumes contenus ni une interpolation3D. Pas de
profilage téléphone, branchement aux raids, APK, commit ou push cette passe.
