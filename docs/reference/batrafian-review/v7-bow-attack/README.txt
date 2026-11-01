BATRAFIAN — TIR À L'ARC SUR LE CŒUR
2026-11-01. Sprites du modèle complet et scène native isolée, quatre directions.

INTENTION ET LIVRABLES
Sortir la flèche, l'aligner, encocher, tendre, viser, relâcher et revenir au repos.
Le héros reste à deux cases du centre du cœur. La flèche est indépendante après
le lâcher ; le cœur réagit uniquement à son arrivée. Aucune attaque de mêlée.

- batrafian-attack-poses.blend : modèle équipé et 12 poses tenues, textures incluses.
- masters/{se,sw,nw,ne} : 48 images 640px alpha et quatre projectiles isolés.
- attack-poses.webp / attack-poses-slow.webp : revue du geste seul, quatre vues.
- attack-board.png / drawn-bow.png : planche et détail de la visée.
- core-attack.webp / core-attack-slow.webp : captures du vrai rendu Godot, flèche
  en vol et impact sur le cœur. Échantillonnage 40ms (dernier intervalle 30ms),
  puis 800ms de repos. Durées 1950/3100ms. Images identiques fusionnées par WebP,
  chronologie décodée vérifiée pixel par pixel contre les 30 captures sources.
- scenes/BatrafianCoreAttack.tscn : ouvrir puis F6 dans Godot. Shoot, Pause,
  Next frame, 0.5x/1x/1.5x/2x, Repeat. Sol et cœur réels du kit, quatre vues.
- assets/previews/batrafian-attack : quatre atlas 1920x640, 44 régions uniques
  320px et quatre projectiles recadrés, SpriteFrames et registration.json.
  1,510,998 octets PNG (~1.51Mo), 18.75MiB RGBA pour les atlas seuls.
  La dernière pose réutilise exactement la première : pas de scintillement
  de débruitage au retour au repos. Sources/revue exclues par docs/.gdignore.

La scène est autonome. Ni intégration aux raids, ni dégâts de simulation,
Game/Session/sauvegarde, APK ou export Android. L'impact est un retour visuel
de revue. La portée de deux cases et les 260ms de vol ne fixent pas les règles
de combat futures. Pas de modification des anciennes animations ou de la source.

SOURCE ET CAMÉRAS
Source immuable : ../v3-equipment-orientation/batrafian-equipped-review.blend.
Originaux quatre GLB/SHA256 : ../source/provenance.json. 26 os, 13,176 sommets
du corps, 9,502 sommets de l'arc, 12 images empaquetées. Matériaux, UV, poids et
peinture d'origine conservés. Toute modification concerne la copie d'animation.
Le rig.py de v6-death fournit uniquement les helpers et charge la source v3 ;
aucune pose de mort n'est utilisée. mesh_checks.py provient de v4-locomotion.

Quatre vraies caméras orthographiques SE/SW/NW/NE, élévation 30 degrés ; jamais
de miroir ni assemblage de morceaux du personnage. Ortho3.25, cible(0,-.20,.78),
racine au sol(0,-.20,0), rendus 640px puis réduction uniforme Lanczos à320px.
Ancre partagée(160.000057,226.510792), échelle native .9404255319 : résolution
par unité identique aux sprites de marche 256px/ortho2.6. Éclairage tourné avec
chaque vue. Les sprites incluent toute la silhouette et l'équipement tenu.

POSES ET CADENCE
Indices0–11 / clés Blender1–12, interpolation CONSTANT. Aucun mouvement 3D
interpolé n'est exporté ni utilisé à l'exécution. Durées en ms :
100,110,90,100,100,100,90,50,80,100,100,130 =1150ms.
Guard / Reach / Ready arrow / Align / Nock and draw / Aim / Hold / Release /
Follow-through / Recover / Lower / Guard. Lâcher690ms, arrivée950ms.
Flèche tenue visible indices1–6 ; indices2–3 elle est transportée dans la main,
indices4–6 elle est réellement encochée. À partir de7 le corps n'a plus de flèche.

Le bassin et les pieds restent fixes. Le buste004 pivote jusqu'à-80 degrés,
le cou017 compense pour garder la tête vers -Y. Chaînes gauche025→024→023 et
droite021→020→019, distal018 pour les doigts groupés. Le rig n'a pas de doigts
ou de visage indépendants : ce n'est pas une simulation précise de chaque doigt.
La prise doit conserver le roulement axial de l'avant-bras024 avec le poignet,
car la paume partage leurs poids. Rotation du poignet seul = palmure déformée.

Le poignet gauche vise(-.28,-.475,1.03), avec un arc vers l'avant de
-.22*sin(pi*élévation) sur Y. Le lacet transitoire supplémentaire de l'arc
(0,0,-30,-45,-15,0,0,0,0,-45,-20,0 degrés) évite de traverser la grosse tête,
la tunique et les jambes pendant la levée/descente. La visée retrouve son axe.
Carquois toujours parenté au torse003, orientation/échelle relatives préservées ;
glissement de sangle chestQ@(0,.14,0)*élévation pour dégager la tête lors du pivot.
La garde initiale/finale garde le montage approuvé inchangé.

CORDE, PRISE ET FLÈCHE
L'arc Meshy possède une corde dans son maillage. Copier les données du mesh et
ajouter Basis/Draw ; déformer les sommets existants en gardant UV et matériaux,
sans ajouter une deuxième corde. Bande de corde proche de x=.12-.24*z, |z|<.79.
Draw déplace les sommets en X : flexion .045*(|z|/.82)^2 et tension triangulaire
maximale .46 au point d'encoche z=.11. Valeurs Draw par pose :
0,0,0,.08,.60,.88,1,0,.04,0,0,0. La corde revient au lâcher, puis léger rebond.
Le point d'encoche est mesuré dans les vrais sommets de corde, et sa translation
dans le shape key ; poses.json les conserve. z=.11 dégage la flèche de l'avant-bras.

La main droite rejoint la corde seulement lorsqu'elle est à portée. Les premiers
essais l'exigeaient dès les poses2–3 : IK borné, main à .35m de l'encoche. Corrigé
en portant réellement la flèche jusqu'à l'alignement, puis encochant en pose4.
La sortie du carquois oriente la flèche vers(-1,-.3,-.25), pour éviter l'épaule.
L'axe +Z du GLB va de l'empennage à la pointe ; longueur équipée .79, échelle
.4153987969. En visée l'axe suit -X local de l'arc, dirigé vers -Y monde.
Au lâcher la main droite recule de .31 en Y, puis .22 pendant le suivi.

PASSAGE AU PROJECTILE NATIF
Rendu isolé de la flèche à la pose de pleine tension (index6/Blender7), même
caméra/lumière/résolution que le corps. Recadrage alpha +2px et réduction uniforme,
pas de rotation 2D ou de nouvelle peinture. registration.json fournit par vue :
- views.nock/tip : positions par rapport à la racine, déjà en unités natives.
  NE PAS appliquer l'échelle une deuxième fois.
- projectiles.anchor : point d'encoche dans la petite texture recadrée.
- projectiles.tip_offset : vecteur encoche→pointe en pixels320, à multiplier
  une seule fois par hero_scale lors du rendu natif.
À690ms, retirer la flèche du corps et afficher le projectile sur la même encoche.
Le vol suit son axe réel sans saut/rotation. L'impact est le point de cet axe
le plus proche du centre du vortex, à l'intérieur de70% de son rayon dans les
quatre vues. Le projectile termine par sa POINTE à l'impact, pas par son pivot.
À950ms il disparaît et le cœur s'éclaire pendant80ms. Aucune ellipse d'ombre
ne suit la flèche ; l'ombre du héros reste sur ses pieds immobiles.

Les stages réutilisent mobile_dungeon_renderer et le cœur réel avec son vortex,
sa lumière et son ombre. Une seule horloge commande poses, projectile et flash.
Les événements de lâcher/arrivée traversent les seuils temporels : un grand pas
à2x n'en saute aucun, et ne les duplique pas. Seek/Next frame ne créent pas
d'événement. Pause gèle aussi le vortex. Repeat attend .8s puis remet à zéro.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'

& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v7-bow-attack/render_attack.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v7-bow-attack/verify_choreography.py
& $blender --background --python-exit-code 1 --python docs/reference/batrafian-review/v7-bow-attack/verify_saved_attack.py
& $node docs/reference/batrafian-review/v7-bow-attack/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_batrafian_attack.gd' -WindowStyle Hidden -Wait -PassThru
& $node docs/reference/batrafian-review/v7-bow-attack/prepare_native_review.cjs

Blender dédié en arrière-plan, jamais la session utilisateur. Option après -- :
--pilot rend SE/SW aux indices1,3,6,7 ; --poses-only écrit source/mesures sans PNG.
Toujours finir les 48 maîtres et quatre projectiles AVANT prepare.cjs, sinon
les atlas peuvent mélanger d'anciens et de nouveaux rendus. prepare.cjs écrit
atlas, ressources, scène et revue des poses ; prepare_native_review.cjs consomme
les captures de la fixture native. Aucun de ces outils ne peint de pixels.

VALIDATION ET LIMITES
Chorégraphie indépendante :6échecs sur8 sur source debout, puis8contrôles réussis.
Rechargement indépendant du blend :12poses, positions enregistrées à1e-5, sol,
prises/encoche, corde, flèche cachée au bon moment, identiques première/dernière
géométries, cadrage de tous les sommets dans4caméras. Zéro croisement d'arêtes
équipement/corps hors zones de prise des mains. QuatreGLB/source équipée inchangés,
12textures intégrées. Ce n'est pas une preuve de toutes les auto-intersections,
des volumes contenus ou d'une animation3D interpolée.

Godot :475contrôles réussis, fixture initialement rouge sans la scène. Lâcher,
vol continu, pointe à l'impact, ordre/compteurs, pause/seek/step/Repeat/2x, vraie
cible, orientation/portée égales, 48poses et commandes cadrées à1280x720,844x390,
720x960. Import/fixture exit0, stderr vide. Planche et captures inspectées.
Logs/captures : artifacts/batrafian-attack (ignoré). Version source actuelle :
Blender5.2.1, Godot4.7.2, Sharp0.35.5. Pas de validation sur téléphone physique.
L'appréciation du geste et de sa cadence reste à valider par l'utilisateur.

Revue indépendante finale : aucun problème actionnable. Nouvelle exécution
native475contrôles, stderr vide ;294vérifications d'assets incluant hashes des
48maîtres/réductions, quatre atlas et quatre projectiles reproduits à l'identique,
cinq sources inchangées et chronologies natives décodées. Comparaison Blender
fraîche avec v3 : coordonnées de base, faces, UV, poids, matériaux, images
intégrées et squelette de repos préservés. Jambes fixes, attaches et sangle
bornée vérifiées. Chorégraphie8contrôles et rechargement des12poses repassés.
Captures/planche/documentation inspectées. Preuves : artifacts/batrafian-attack/review.
