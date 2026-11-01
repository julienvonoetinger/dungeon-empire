MYCEAN — MARCHE ET COURSE
2026-11-01. Sprites complets issus du modèle Meshy, scènes de revue isolées.

SOURCE
../v2-meshy-inspection/mycean-equipped-review.blend, avec la prise corrigée.
Les deux GLB immuables et leurs SHA256 restent dans ../source. Aucun changement
de peinture, de texture, de maillage de base ou d'UV. Les corrections locales
de la main présentes dans v2 sont réutilisées, sans les réinventer.

ANATOMIE ET PRISE
35 os : bras gauche033→032→031, droit025→024→023 ; jambes gauche015→014→013,
droite006→005→004. Le personnage regarde vers -Y, +Z est vertical.
Le bâton, MyceanGripCorrective et StaffGripContactEnvelope suivent tous031.
Leur transformation relative au poignet reste identique sur les16poses.
Conserver l'orientation complète de l'avant-bras, y compris sa torsion axiale.
La prise n'est JAMAIS exclue des tests de collision avec le bâton.

POSES
Marche :8poses,15fps,1.125unité modèle/s, cycle8/15s, buste2°.
Course :8poses,16fps,1.6unité modèle/s, cycle.5s, buste5°, deux poses aériennes.
Les pieds sont opposés d'une demi-période. Le bras libre accompagne la foulée.
Le grand chapeau conserve sa géométrie d'origine ; son balancement suit le buste.

En marche, la main gauche est relevée de.075 et le bâton reste presque vertical.
En course, la main est relevée de.10, le poignet annule les15° d'inclinaison
latérale initiale puis incline le bâton de42° vers l'avant, en plus du buste.
Cela dégage à la fois le chapeau et les bottes. Le premier port vertical
traversait le bord du chapeau ; l'inclinaison latérale seule amenait le pied du
bâton dans la botte. Ne pas déplacer le bâton seul à l'intérieur de la prise.

Les jambes sont courtes. Le premier contact de course abaissait insuffisamment
le bassin : le solveur limitait la portée, donnant.0736765unité de déplacement
de semelle au lieu de.1. Les poses0/4 descendent maintenant le bassin de.13.
Les appuis sont enregistrés sur la SEMELLE RÉELLE, en hauteur ET en déplacement
longitudinal, pas uniquement sur le point d'os de cheville. La copie cachée
MyceanSoleProbe garde seulement le modificateur d'armature : les corrections
de main et la subdivision SIMPLE n'affectent pas les semelles. Elle ne se rend
jamais. Le corps détaillé complet reste utilisé pour tous les tests de contacts.

Projection orthographique30°, ortho2.6, racine(0,-.20,0), ciblez.72, lumière
tournée avec les quatre vraies caméras SE/SW/NW/NE. Maîtres512² RGBA puis
réduction uniforme256² ; aucune découpe de membre, aucun miroir ni peinture
procédurale. Ancre256px(128,189.394539), échelle native.940425532. Le même cadrage
est employé sur les64images. Le blend contient les16poses, clés CONSTANT :
images1–8 marche,9–16 course. Le runtime lit uniquement les sprites.

SCÈNES NATIVES
scenes/MyceanWalk.tscn et scenes/MyceanRun.tscn : ouvrir dans Godot et F6.
Deux couloirs donnent les quatre directions en aller-retour. Pause, Next frame,
Restart et0.5x/1x/1.5x/2x ; même horloge pour les poses et le déplacement.
Réutilisation sans modification des scripts vulpin_walk_preview/corridor.
Le Mycean n'est pas ajouté aux raids. Aucun Game/Session/save, aucun APK.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v3-locomotion/render_gaits.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v3-locomotion/verify_saved_gaits.py
& $node docs/reference/mycean-review/v3-locomotion/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_mycean_gaits.gd' -WindowStyle Hidden -Wait -PassThru

Blender séparé en arrière-plan, pas la session de travail de l'utilisateur.
Options après -- : --pilot rend SE/NW poses0/3 ; --poses-only enregistre les
16poses sans image ; --check-pose=run:1 mesure une seule pose sans remplacer
le blend ni poses.json ; --gait=run limite les images mais recalcule les16poses.
Toujours régénérer les64maîtres après un changement partagé du solveur, de la
caméra ou de la prise. Ne pas préparer un mélange de pilotes et d'anciens maîtres.
inspect_models.py puis assemble_preview.py dans v2 reconstruisent la source si
nécessaire ; consulter son README et conserver les trois attaches de la main.

VALIDATION
verify_saved_gaits recharge le blend et recontrôle les16poses, les semelles,
le sol, les trois attaches, les surfaces complètes du corps contre le bâton,
les retours exacts au début de boucle, les six textures embarquées et les hashes
des sources. Les12transitions d'appui sont obligatoires (8marche,4course), avec
tolérance.0002unité et sans ignorer un déplacement de mauvais signe.
Le maximum mesuré après correction est.000049942unité ; bâton au minimum
.0185913au-dessus du plan du sol. Aucun croisement de surface détecté sur les
16poses, main incluse. Ce n'est pas une preuve de toutes les auto-intersections
du personnage, des volumes entièrement contenus, ou d'une interpolation3D.

prepare.cjs vérifie64images distinctes par série/direction, alpha complet,
ancre commune, dimensions et durées WebP533ms/500ms ; il assemble huit feuilles
2048x256, soit16MiB RGBA pour les deux séries chargées ensemble (8MiB par série).
La taille PNG est de1,357,937octets pour la marche et1,375,667pour la course,
soit2,733,604octets au total ; détails dans validation.json. Tous les modèles,
maîtres et rapports de revue restent exclus de Godot via docs/.gdignore.

La fixture native passe par les vrais scripts de couloir : lecture, pause,
pas,2x, demi-tours, quatre directions, tri des murs et trois tailles d'écran.
Import frais réussi,708contrôles natifs sans échec, stderr vide. Captures
1280x720,844x390 et720x960 inspectées. Revue indépendante :22comparaisons de
préservation de la source,64maîtres/réductions,8feuilles, timelines WebP et
placement pieds/ombre vérifiés, sans anomalie importante restante.
Ses rapports/captures sont dans artifacts/mycean-gaits. Les limites visuelles
restent à juger par l'utilisateur, en particulier le visage caché par le grand
chapeau à30°. Pas de profilage physique sur téléphone ni d'intégration aux raids.
