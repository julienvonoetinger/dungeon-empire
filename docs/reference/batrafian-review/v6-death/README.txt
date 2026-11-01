BATRAFIAN — CHUTE ET MORT
2026-11-01. Animation en sprites complets, scène native isolée.

INTENTION
Les genoux cèdent avant le buste ; le héros lâche l'arc, s'agenouille, avance les
mains puis s'affaisse vers l'avant. Bras presque tendus, torse au sol et tête
tournée sur le côté. La dernière pose reste affichée. Ni chute latérale rigide,
ni maintien en position de pompe. Cadence brève :650ms, ralentissable en revue.

SOURCE ET POSES
Source immuable : ../v3-equipment-orientation/batrafian-equipped-review.blend.
Originaux4GLB et SHA256 dans ../source/provenance.json.26os,13176sommets du corps,
12textures intégrées. Aucun mesh, poids ou peinture modifié. Flèche indépendante
cachée ; arc et carquois complets, jamais redessinés ni assemblés en2D.
Les yeux sont peints dans le modèle source et restent ouverts : le rig n'a pas
de paupières. La tête tournée donne la pose inerte, sans animation faciale.

render_death.py produit10poses à clés CONSTANT. Les indices Blender1–10 sont
des poses tenues, pas une animation interpolée. Durées ms :40,50,60,70,65,65,65,
65,70,100. Caméra ortho3.25, cible(0,-.20,.46), élévation30deg, racine au sol
(0,-.20,0). Rendus640px réduits uniformément à320px, ancre(160,199.224289),
échelle native.940425532 : même résolution par unité que marche/course/saut.
Quatre vraies directions SE/SW/NW/NE, sans miroir.

Pelvis000 : hauteur.734→.16 avant correction du contact. Inclinaison0→82deg,
buste final77deg ; cou017 à89deg avec rotation latérale-65deg. Jambes
009→008→007 et014→013→012 ; IK pour la flexion initiale, puis orientations
distinctes cuisse/tibia/pied. Les longs orteils comptent dans le contact réel.
Bras021→020→019 et025→024→023. Roulement de l'avant-bras préservé pendant la
prise, puis paumes ET avant-bras tournés vers le sol : ils partagent les poids.
Deux passages de correction de sol, avant/après appui des mains, évitent de
soulever le corps par une mauvaise cible de poignet. Cibles finales bras en
avant, coudes>150deg. Le modèle garde ses longueurs d'os.

L'arc est lâché avant la réception des mains, posé dès la quatrième image et
reste fixe ensuite. Son plan est calculé depuis les axes principaux du maillage
équipé ; interpolation rotation/position pendant les3premières transitions.
Le carquois reste parenté au torse003. Sa sangle accompagne la chute : décalage
local maximal(-.12,+.055,0), progressif à partir de la sixième pose, sans rotation
ni changement d'échelle du montage. Ce léger glissement supprime les croisements
avec l'épaule et la tête observés sur les4dernières poses du premier pilote.
Les poses de repos et les autres animations conservent le montage approuvé.

LIVRABLES
- batrafian-death-poses.blend :10poses entières, sources/12textures empaquetées.
- masters/{se,sw,nw,ne} :40rendus640px alpha. poses.json : mesures et recette.
- assets/previews/batrafian-death :4atlas1600x640 (5colonnes/2lignes),40régions
 320px, SpriteFrames sans boucle, registration.json. Total1,470,407octets PNG
 (~1.47Mo),15.625MiB RGBA décodés. Fichiers de revue exclus par docs/.gdignore.
- death-preview.webp :650ms +1200ms pause sur le corps ; death-slow.webp :
 1300ms +1200ms pause. Pas de rééchantillonnage ni délai10ms ambigu.
- death-poses.png : planche40poses ; final-pose.png : les4poses finales.
- scenes/BatrafianDeath.tscn : quatre directions sur dalles du kit. F6 dans
  Godot ; Replay fall/Pause/Next frame/0.5x/1x/1.5x/2x/Repeat.
  Le script partagé paladin_action_preview.gd reste inchangé. Scène autonome,
  sans Game/Session/save. La mort n'est pas encore branchée aux raids.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v6-death/render_death.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v6-death/verify_choreography.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v6-death/verify_saved_death.py
& $node docs/reference/batrafian-review/v6-death/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_batrafian_death.gd' -WindowStyle Hidden -Wait -PassThru

Blender dédié en arrière-plan seulement, jamais la session utilisateur.
-- --pilot rend SE/NW : genoux, réception, mort ; -- --poses-only sans rendu.
Refaire les40maîtres avant prepare.cjs. Ce dernier écrit lesatlas/ressources/
scène et la revue ; réduction uniforme, aucun travail de peinture par script.
Mesh checks réutilise ../v4-locomotion/mesh_checks.py.

VALIDATION
- Contrôle chorégraphique indépendant :9échecs/12 sur source debout, puis
 12contrôles réussis sur la chute enregistrée (genoux/buste/mains/coudes/sol).
- Rechargement indépendant des10poses : bornes identiques à1e-5, sol à1e-4,
  zéro croisement arc/corps hors main pendant la prise puis corps entier après
  lâcher ; zéro carquois/corps et arc/carquois. Arc fixé au sol dès image4.
- Carquois reste parenté au torse, orientation/échelle du montage préservées,
  glissement borné.4GLB/source équipée inchangés,12images intégrées.
- Cadrage de tous les sommets dans4caméras,40PNG non tronqués,40poses distinctes,
  ancres communes, dimensions/durées WebP vérifiées.
- Godot :303contrôles réussis. Pause/step/replay/Repeat/vitesses, durée650ms,
  absence de retour automatique au repos, racine immobile,4directions,40frames.
  Pixels visibles de chaque pose et commandes cadrés à1280x720,844x390,720x960.
  Import/fixture exit0 et stderr vide ; logs/captures artifacts/batrafian-death.
  Planche et captures natives inspectées.
- Revue indépendante : aucun problème d'implémentation important/actionnable.
 40hashes maîtres/réductions vérifiés,4atlas repackés à l'identique, durées WebP
 1850/2500ms et hashes sources vérifiés ; rechargement Blender/chorégraphie
  relancés indépendamment avec succès. Captures natives des3tailles inspectées.

LIMITES
Proposition artistique à valider par l'utilisateur. Les vérifications concernent
les poses tenues, pas toutes les auto-intersections/volumes contenus ni une
animation3D interpolée. Aucun test téléphone/performance physique. Pas de
branchement aux raids, modification de sauvegardes, APK, commit ou push.
