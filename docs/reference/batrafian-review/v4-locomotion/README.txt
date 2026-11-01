BATRAFIAN — MARCHE ET COURSE
2026-11-01. Sprites complets et scènes natives isolées.

SOURCE ET PRISES
Point de départ : ../v3-equipment-orientation/batrafian-equipped-review.blend,
avec le manche de l'arc récemment remonté de .04270 unité. Quatre GLB originaux
conservés dans ../source/provenance.json. Ni peinture, ni topologie, ni montage
des accessoires modifiés. 26 os, 13 176 sommets du corps, 12 textures embarquées.

Bras gauche025→024→023, droit021→020→019. Arc parenté au poignet023, carquois
au torse003. La flèche indépendante reste masquée. Conserver les rotations
locales des mains022/018 et transporter la rotation COMPLÈTE de l'avant-bras :
sa torsion axiale fait partie de la prise approuvée, car la paume partage ses
poids avec l'avant-bras024. Une simple orientation coude-poignet la déformerait.

RECETTE
render_gaits.py repart toujours du .blend équipé immuable. Jambes009→008→007
et014→013→012 posées à longueur fixe ; enregistrement de la semelle réelle sur
les sommets évalués z<.13 du modèle source, y compris les longs orteils.
Le personnage regarde vers -Y. Les appuis reculent à la vitesse du déplacement.

Marche : 8 poses,15fps, cycle8/15s, déplacement1.125 unité modèle/s ; buste2°.
Course : 8 poses,16fps, cycle.5s, déplacement1.76 unité modèle/s ; buste6°,
foulée plus ample, pieds plus hauts et deux poses sans appui au sol.
GAITS contient toutes les valeurs de pose. Les genoux fléchissent légèrement
vers l'extérieur (pôle ±.5,-1,0), adapté à la morphologie du Batrafian.

Le premier essai avec des genoux droit devant traversait le bas du carquois
avec la tunique sur trois poses de course. Réduire seulement le rebond et la
hauteur des pieds ne suffisait pas. Le pôle de genou légèrement extérieur,
associé à une flexion/rotation de pied plus mesurée, résout les intersections
sans déplacer le carquois, changer la prise de l'arc ou retoucher les textures.

Caméra orthographique30°, échelle2.6 commune. Racine(0,-.20,0), ciblez.72.
Maîtres512px transparents, réduction uniforme256px. Quatre vues réelles SE/SW/
NW/NE, jamais miroirs. Éclairage tourné avec la caméra, comme les héros précédents.
Ancre256px(128,189.394539), échelle Godot.940425532 ; aucune recentration par pose.
Le .blend sauvegardé contient16 poses avec clés CONSTANT :1–8marche,9–16course.
Les cadences réelles sont celles des SpriteFrames ; aucune interpolation3D utilisée.

LIVRABLES
- batrafian-gait-poses.blend, poses.json : source complète posée et métadonnées.
- masters/{walk,run}/{se,sw,nw,ne} :64 rendus512px alpha.
- walk-preview.webp/run-preview.webp : boucles animées ; *-poses.png : planches.
- assets/previews/batrafian-{walk,run} :8feuilles2048x256 en tout, SpriteFrames
  et registration. PNG total2 141 227octets (~2.14Mo),8MiB RGBA par série,
 16MiB pour les deux chargées ensemble. Sources/revue exclues par docs/.gdignore.
- scenes/BatrafianWalk.tscn et BatrafianRun.tscn : ouvrir dans Godot puisF6.
  Deux couloirs aller-retour donnent les4directions. Pause/pas/reprise et×2
  partagent la même horloge que le déplacement. Aucun Game/Session/save.
- tools/verify_batrafian_gaits.gd : fixture native et captures dans
  artifacts/batrafian-gaits. Les scripts partagés Vulpin/Paladin sont inchangés.

REPRODUIRE (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v4-locomotion/render_gaits.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v4-locomotion/verify_saved_gaits.py
& $node docs/reference/batrafian-review/v4-locomotion/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_batrafian_gaits.gd' -WindowStyle Hidden -Wait -PassThru

Utiliser un Blender séparé, pas la scène ouverte de l'utilisateur. -- --pilot
produit8échantillons ; -- --poses-only mesure et sauvegarde les16poses sans image.
Relancer sans ces options avant prepare.cjs. Ce dernier réduit uniformément,
assemble les atlas et écrit les2scènes ; il ne repeint ni ne découpe le corps.
Si le .blend équipé manque, suivre ../v3-equipment-orientation/README.txt.

VALIDATION
- Relecture indépendante des16poses : géométries/prises identiques, semelles
  à la hauteur demandée, absence de pénétration du sol et12intervalles d'appui
  assortis au déplacement (erreur maximale mesurée .000519 unité modèle).
- Aucun croisement arête/triangle arc/corps hors main de prise ; aucun carquois/
  corps. Prises relatives au rig identiques à la source dans toutes les poses.
- Hashes des4GLB et de la source équipée inchangés ;12textures empaquetées.
-64images distinctes, alpha non tronqué et ancre commune. WebP533/500ms.
- Fixture native :2échecs initiaux (scènes absentes), puis708contrôles réussis :
  lecture, pause, pas,×2, demi-tours,4directions, ordre des murs, trois formats.
  Import et fixture sortent0, stderr vide. Planches et captures natives inspectées.
- Revue indépendante : aucun problème important. Hashes des64maîtres contrôlés,
 8atlas reconstruits en mémoire et comparés pixel par pixel ; cadences WebP vérifiées.

LIMITES
Proposition artistique à valider. Contrôles sur les poses maintenues, pas une
preuve de toutes les auto-intersections ni des volumes complètement inclus.
Pas d'interpolation3D, rig de doigts séparés, arc déformable, tir ou profilage
sur téléphone. Scènes d'essai uniquement ; raids inchangés, aucun APK/commit/push.
