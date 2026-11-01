BATRAFIAN — SAUT PAR-DESSUS UN PIÈGE
2026-11-01. Proposition en sprites complets, scène native isolée.

INTENTION ET SOURCE
Bond vers l'avant : préparation, flexion des jambes, poussée, repli en vol,
extension pour toucher le sol, amortissement et retour au repos. La logique
ranger existante franchit déjà un piège connu vers la case située derrière lui
en1seconde (TRAP_JUMP_TIME). Cette proposition visuelle ne modifie pas cette logique.

Source immuable : ../v3-equipment-orientation/batrafian-equipped-review.blend.
Quatre GLB originaux et leurs SHA256 dans ../source/provenance.json. L'arc garde
son ancre remontée et la prise approuvée ; carquois003, arc023, flèche masquée.
Forearm roll024 conservé : la paume partage ses poids avec l'avant-bras.
12textures emballées,26os,13176sommets du corps. Aucun mesh/poids/texture retouché.

POSES ET TRAJECTOIRE
render_jump.py contient12poses à clés CONSTANT, première/dernière identiques.
Durées ms :60,70,70,60,80,90,90,80,70,70,100,160. Total1000ms, pas de boucle native.
Les12indices Blender sont des poses, pas une animation3D interpolée à12fps.
Caméra iso30deg, ortho2.6, cible(0,-.20,.72), ancre256(128,189.394539), échelle
Godot.940425532 : identiques à la marche/course. Quatre vues, jamais miroirs.

Les sprites contiennent la flexion des jambes et du buste, PAS l'altitude du
bond ni son déplacement. La scène fait avancer le point d'appui de2cases entre
.20s et.67s. En dehors de cet intervalle, aucun déplacement au sol. En vol :
u=clamp((t-.20)/.47,0,1), hauteur=4*.55*u*(1-u). Sommet à.435s.
Conversion verticale :256/2.6*cos30deg*.940425532 ≈80.19pixels/unité modèle.
Ne pas appliquer simultanément ce décalage et une altitude déjà peinte.
L'ombre reste sur le point au sol, légèrement réduite/atténuée au sommet.

Jambes009→008→007 et014→013→012. Pôle(±1.2,-1,0), pieds légèrement écartés pour
la flexion de grenouille. Chaque semelle évaluée, y compris les longs orteils,
est ajustée à la hauteur locale demandée. Le buste s'abaisse jusqu'à.17unité
dans l'anticipation et.14à la réception. Les poignets remontent pour que l'arc
reste dégagé du sol. Bras gauche025→024→023 ; droit021→020→019.

LIVRABLES
- batrafian-jump-poses.blend : source complète,12poses, textures empaquetées.
- poses.json et saved-pose-validation.json : mesures avant/après rechargement.
- masters/{se,sw,nw,ne} :48rendus512px alpha, dont4retours au repos identiques.
- assets/previews/batrafian-jump :4atlas1536x512,44sprites distincts256px,
  SpriteFrames et registration. Six colonnes/deux lignes, dernière case vide ;
  la pose finale réutilise la première région entière, évitant un scintillement
  de débruitage. PNG total1,556,616octets (~1.56Mo),12MiB RGBA décodés.
- jump-preview.webp / jump-slow.webp : revue sur place, mouvement vertical et
  ombre,1x/0.5x. Échantillonnage20ms, pause800ms avant répétition. Les décodeurs
  WebP peuvent remplacer10ms par100ms : garder20ms minimum. Le natif conserve
  les durées exactes ; la revue WebP arrondit certaines transitions de10ms.
- scenes/BatrafianJump.tscn : quatre vues avec sol/piège réels, bond avant de
  deux cases, Jump/Pause/Next frame/Repeat/vitesses0.5x à2x. Ouvrir puisF6.
  Aucun Game/Session/save ; les scripts partagés Paladin sont inchangés.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v5-jump/render_jump.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v5-jump/verify_saved_jump.py
& $node docs/reference/batrafian-review/v5-jump/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_batrafian_jump.gd' -WindowStyle Hidden -Wait -PassThru

Blender séparé uniquement. -- --pilot rend6images de flexion/repli/réception;
-- --poses-only n'effectue pas de rendu. Toujours refaire le rendu complet avant
prepare.cjs, qui écrit les atlas/ressources/scène et les revues sans repeindre.
Le module d'inspection mesh_checks.py est partagé avec ../v4-locomotion.
Pour reconstruire la source équipée, suivre ../v3-equipment-orientation/README.txt.

VALIDATION
- Rechargement indépendant des12poses, contacts réels des semelles (<.0001),
  retour au repos identique corps/accessoires, prises relatives au rig conservées.
-0croisement d'arête/triangle arc/corps hors main de prise,0carquois/corps dans
  les12poses. Aucun élément visible ne pénètre le plan local du sol.
-4GLB/source équipée inchangés,12textures intégrées, flèche indépendante cachée.
-48rendus non tronqués,44sprites distincts, ancres et dimensions communes.
- Fixture native :1échec initial (scène absente), puis363contrôles réussis.
  Trajectoire/hauteur/apex, absence de double élévation, immobilité avant/après
  vol, ombre au sol,12poses, pause/step/x2, réception finale, replay/Repeat,
  mouvement réel et cadrage des images/contrôles à1280x720,844x390 et720x960.
  Import et fixture exit0/stderr vide ; captures et logs dans artifacts/batrafian-jump.
  Planches et captures natives inspectées.
- Revue indépendante sans problème important : hashes des48maîtres/sprites,
 4atlas reconstruits à l'identique, sources et durées WebP vérifiés.

LIMITES
Qualité artistique à valider par l'utilisateur. Vérifications sur poses tenues,
pas une preuve de toutes les auto-intersections/volumes inclus ou d'une animation
3D interpolée. Revue sans gameplay : piège immobile, aucune charge consommée,
aucun nouveau héros en raid. Pas de téléphone physique/APK/commit/push.
