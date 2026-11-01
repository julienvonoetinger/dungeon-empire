MYCEAN — CHUTE ET MORT
2026-11-01. Sprites complets depuis Blender, scène native isolée.

INTENTION
Les genoux cèdent, le bâton est lâché, puis le corps s'affaisse vers l'avant.
Les bras s'étendent et le buste repose près du sol ; la dernière pose reste
affichée. Pas de chute latérale rigide ni de position de pompe.
Dix poses en650ms, ralenti disponible pour examiner les appuis. La scène ne
relance pas la chute tant que Replay fall ou Repeat n'est pas demandé.

SOURCE
../v2-meshy-inspection/mycean-equipped-review.blend, source équipée inchangée.
Deux originaux GLB/SHA256 dans ../source.35os,15429sommets du corps,
10633sommets du bâton et six textures2048² embarquées. Géométrie de base,
faces, UV, poids et peinture préservés. Aucune découpe/animation de parties2D.
La main corrigée de v2 est conservée au départ : lattice, subdivision SIMPLE2
et enveloppe de contact fermée. Ne pas employer les numéros d'os du Batrafian.

Racine000, tronc010/009/008/007, cou018/tête017/chapeau016.
Jambes R006/005/004, L015/014/013. Bras R025/024/023, L033/032/031.
Forearm axial roll et orientation complète du poignet sont transportés depuis
la pose équipée pour éviter une torsion artificielle de l'avant-bras.

CHOREGRAPHIE
Durées ms :40,50,60,70,65,65,65,65,70,100.
Phases : Standing/Buckle/Lowering/Knees down/Kneeling/Reach/Falling/Catch/Settle/Dead.
Inclinaison racine0→82deg, tronc final77deg ; jambes initialement en IK puis
orientations distinctes cuisses/tibias/pieds. Les vraies surfaces des bottes
et du vêtement déterminent la correction finale du sol.
Un premier pilote relevait le bassin de.263 à.311 lors de l'agenouillement.
La cause était l'orientation des bottes et des sommets pondérés tibia/pied.
Les angles de pieds à partir de pose4 sont145/185/195/165/160/155/150deg.
Après correction, le bassin passe de.402 à.290 puis reste entre.271 et.293 ;
aucun rebond supérieur à.006. Les genoux reçoivent le poids avant le buste.
Le Mycean a des jambes très courtes : contrôler les genoux<.12 et l'abaissement
du bassin>.11, sans reprendre les hauteurs absolues du Batrafian.

Le grand chapeau ne peut pas suivre mécaniquement les82deg du buste : son
rebord traverserait le sol et la correction remonterait tout le corps.
La tête tourne progressivement à34deg en avant et-30deg sur le côté.
Les bras avancent devant les épaules, coudes finaux~171deg. Poignets près du
sol ; pas de bras sous le torse qui créeraient une posture de pompe.
La forme du chapeau reste intacte et masque encore le visage selon l'angle.
Les yeux sont peints, sans os de paupière ; ils ne se ferment pas.

BATON ET MAIN
Le bâton part de son montage exact v2. Taux de lâcher0/.20/.65/1 ; il s'incline
et se dépose à gauche du corps, puis reste parfaitement fixe dès image4.
Sa transformation mondiale est convertie dans son parent Bone_031 à chaque
pose : il n'est pas soudé visuellement à la main après le lâcher.
Le lattice de prise passe de1 à0 et le Shrinkwrap de contact est désactivé dès
la deuxième pose pour que la main se détende. Les deux aides restent attachées
au poignet et masquées au rendu. Toutes les valeurs sont clés CONSTANT, avec
restauration du montage et des modificateurs lorsque la lecture revient à1.
La main n'est jamais exclue des tests de croisement bâton/corps.

RENDUS ET LIVRABLES
Caméra orthographique3.25, racine au sol(0,-.20,0), cible(0,-.20,.46),
élévation30deg. Quatre vraies caméras SE/SW/NW/NE, éclairage tourné avec elles.
40maîtres640px alpha →320px par réduction uniforme Lanczos. Même densité par
unité que la marche/course256px à ortho2.6. Ancre(160,199.224289),
échelle native.940425532. Aucun miroir, peinture nouvelle ou changement d'échelle
individuel entre les poses.

- mycean-death-poses.blend : dix poses et six textures embarquées.
- render_death.py/rig.py : recette ; poses.json : mesures et paramètres.
- assets/previews/mycean-death : quatre atlas1600x640,40régions320px,
  frames.tres non bouclé, registration.json.1,878,373octets PNG sur disque,
  15.625MiB RGBA décodés.
- death-preview.webp :650ms +1200ms sur le corps ; death-slow.webp :
  1300ms +1200ms. death-poses.png et final-pose.png pour inspection statique.
- scenes/MyceanDeath.tscn : quatre directions sur les dalles du kit.
  F6 ; Replay fall/Pause/Next frame/0.5x/1x/1.5x/2x/Repeat.
  Réutilise paladin_action_preview.gd inchangé, sans Game/Session/sauvegarde.
  La mort n'est pas encore branchée aux raids.

REPRODUCTION (PowerShell, racine du dépôt)
$blender='C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot='C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v4-death/render_death.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v4-death/verify_choreography.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v4-death/verify_saved_death.py
& $node docs/reference/mycean-review/v4-death/prepare.cjs
Start-Process $godot -ArgumentList '--headless','--path','.','--editor','--import' -WindowStyle Hidden -Wait -PassThru
Start-Process $godot -ArgumentList '--path','.','--script','res://tools/verify_mycean_death.gd' -WindowStyle Hidden -Wait -PassThru

Blender dédié en arrière-plan uniquement. -- --pilot rend SE/NW poses4/7/10 ;
-- --poses-only enregistre sans rendre. Toujours régénérer les40maîtres avant
prepare.cjs après toute modification partagée. Sources/maîtres/revue exclus
des exports Godot par docs/.gdignore. Ne pas générer d'APK sans demande.

VALIDATION
verify_choreography ne charge jamais le générateur :12critères géométriques,
dont abaissement du bassin, absence de rebond, genoux avant torse, buste en
avant et bas, coudes ouverts, mains vers l'avant, contact au sol. La source
debout échoue10critères, puis les dix poses sauvegardées les satisfont.
verify_saved_death recharge la source et le blend final : bornes rejouées,
sol, zéro croisement de surface bâton/corps entier à chaque pose, stabilité
du bâton après dépôt, modificateurs restaurés au retour au départ. Vérifie
également la géométrie de base/UV/poids/textures, les SHA des sources,
les six images intégrées et le cadrage dans les quatre caméras.
prepare.cjs vérifie dimensions/alpha/cadrage/ancres, dix poses distinctes
par direction et les délais WebP. Rapports dans ce dossier ; preuves natives
et journaux sous artifacts/mycean-death.

Import frais et303contrôles natifs réussis, stderr vide. Pause/pas/replay/Repeat,
vitesses, durée650ms,40régions, ancre, maintien final et contrôles cadrés à
1280x720,844x390 et720x960 ; captures inspectées. Revue indépendante finale :
77contrôles de préservation/contact sur le blend rechargé,222contrôles d'assets
(40réductions, quatre atlas repackés à l'identique, ressources et pixels/délais
WebP), puis inspection native. Aucun problème important restant.

LIMITES
Proposition visuelle à juger en mouvement. Les contrôles concernent les poses
tenues et les croisements de surfaces, pas toutes les auto-intersections,
volumes contenus ou une animation3D interpolée. Le grand chapeau reste très
présent. Aucun test physique téléphone, intégration raid, APK, commit/push.
