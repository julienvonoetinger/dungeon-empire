LITHIDE / PALADIN — MARCHE ET COURSE
2026-11-01. Proposition animée, sprites et scènes natives de contrôle.

SOURCE
Le modèle fourni par l'utilisateur fait autorité : les trois GLB originaux sont
dans ../source avec leurs hashes. Point de départ : le .blend équipé v3, avec
prises fermées et tête du marteau tournée de -90° autour du manche (frappe
avant/arrière). Aucune peinture, topologie ou proportion d'accessoire modifiée.
9 textures restent embarquées. Aucun nouveau modèle de héros n'entre en raid.

RECETTE
render_gaits.py charge la pose approuvée, conserve les rotations locales des
doigts, pose jambes/bras à longueur fixe, puis rend tout le personnage équipé.
Chaque accessoire est parenté au poignet : Bone_023 droit, Bone_019 gauche.
Bras droit025→024→023 ; gauche021→020→019. Jambes009→008→007 et014→013→012.
Ne pas transférer les numéros d'os d'un autre modèle sans inspection.

Marche : 8 poses,12fps, cycle2/3s, déplacement .84 unité modèle/s.
Course : 8 poses,16fps, cycle.5s, déplacement1.60 unité modèle/s.
La course a une inclinaison de8° et deux poses aériennes ; marche2° et appuis
continus. Balancement contenu des bras pour les accessoires lourds. Offsets,
hauteurs de semelles, rotations et oscillations sont explicites dans GAITS.

La première version basée sur les chevilles enfouissait les pointes des bottes.
La version finale ajuste chaque jambe sur les sommets réels de la semelle, y
compris les pieds relevés. Cela corrige le pied concerné sans déplacer tout le
corps. Le modèle avance dans -Y ; les pieds d'appui reculent à vitesse assortie.

Caméra orthographique30°, échelle2.6 commune. Racine(0,-.20,0), cible àz.72.
Maîtres512px alpha, réduction uniforme256px. Quatre directions non miroir,
lumières tournées avec la caméra pour représenter le héros sous un éclairage
de scène fixe. Ancrage final analytique(128,189.394539), échelle Godot.940425532 :
la taille physique reste cohérente avec le Vulpin, malgré le cadre plus large.
Tolérance de comparaison des ancres.001px : arrondi float32 mesuré~.0002px.

Le .blend contient16 poses maintenues (clés CONSTANT) :1–8marche,9–16course.
Ces numéros sont des poses sources ; les cadences réelles sont dans SpriteFrames
et les scènes. Le jeu utilise uniquement les sprites rendus, aucun rig3D.

FICHIERS ET TAILLE
- paladin-gait-poses.blend : source posée avec textures intégrées.
- masters/{walk,run}/{se,sw,nw,ne} :64 rendus transparents reproductibles.
- walk-preview.webp/run-preview.webp : boucles de revue à4directions.
- walk-poses.png/run-poses.png : planches de toutes les poses.
- assets/previews/paladin-{walk,run} :4feuilles2048x256 + SpriteFrames + registration.
- Total PNG des8feuilles :3 236 984octets (~3.24MB), RGBA décodé16MiB pour les2
  séries chargées ensemble,8MiB par scène. Masters/blend/revue exclus par docs/.gdignore.
- scenes/PaladinWalk.tscn et PaladinRun.tscn : ouvrir dans Godot puisF6.
  Deux couloirs, allers-retours,4directions, pause/pas/reprise/vitesses. Aucun save.

REPRODUIRE (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

blender --background --python-exit-code 1 --python docs/reference/lithide-review/v4-locomotion/render_gaits.py
blender --background --python-exit-code 1 --python docs/reference/lithide-review/v4-locomotion/verify_saved_gaits.py
node docs/reference/lithide-review/v4-locomotion/prepare.cjs
godot --headless --path . --editor --import
godot --path . --script tools/verify_paladin_gaits.gd

Remplacer les noms exécutables par les chemins ci-dessus. Sur Windows, lancer
le Godot GUI avec Start-Process -PassThru et WaitForExit pour obtenir le vrai
code de sortie. Fenêtres de validation séquentielles ; WindowStyle Hidden.
Le rendu se fait dans un Blender séparé : ne pas exécuter dans une scène ouverte.
--pilot après -- limite les images à8 échantillons, mais pose/mesure les16 états.
prepare.cjs régénère les8feuilles, ressources et2scènes ci-dessus.
Pour reconstruire le .blend équipé initial : suivre ../v3-equipment-grips/README.txt.

VALIDATION
-16 poses finies, relecture indépendante des géométries et attaches ;50os et
  14680sommets pondérés. Hashes des3GLB et du .blend équipé inchangés.
- Semelles à leur hauteur demandée (<.0001 unité) et12intervalles d'appui contrôlés
  contre le déplacement ; aucun étirement de membre demandé.
- Intersections arêtes/triangles équipement/corps recomptées après relecture :
  aucune hors des mains de prise. Contact des mains volontairement exclu.
-64images distinctes, alpha non coupé, ancre et échelle communes ; boucles WebP
  marche667ms (arrondi de666.67), course500ms.
-708contrôles natifs : lecture réelle, pause, pas,×2, directions, demi-tours,
  enregistrement, atlas, ordre avec murs, trois formats. Résultats/captures dans
  artifacts/paladin-gaits. Régressions natives Vulpin marche/course passent.
- Revue indépendante sans défaut actionnable. Vues natives paysage/portrait et
  planches inspectées. Les deux scripts partagés gardent les valeurs Vulpin.

LIMITES
La qualité artistique reste à valider par l'utilisateur. Les contrôles portent
sur les poses maintenues, pas sur une interpolation3D continue ni toutes les
auto-intersections de l'armure. Le test géométrique ne détecte pas un volume
complètement enfermé dans un autre. Pas de profilage téléphone, APK, intégration
aux raids, commit ou push. Les futurs états du paladin restent à produire.
