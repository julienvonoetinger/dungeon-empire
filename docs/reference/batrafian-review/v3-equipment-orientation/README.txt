Batrafian — correction du sens du carquois et de la prise de l'arc
1 novembre 2026

Remplace le montage statique v2, rejeté pour ces deux orientations.
Les originaux GLB, peintures, tailles uniformes et positions des jambes restent
conservés. Cette scène ne remplace aucun asset ou animation dans le jeu.

Corrections
- Le carquois présentait sa tranche : son orientation axiale passe de -90° à180°,
  face large extérieure vers l'arrière du personnage. Il est incliné de24° vers
  l'épaule droite et de12° en arrière pour éviter la tête. Position de référence
  (-.14,.435,.91), même hauteur.92 et attache torso Bone_003.
- La main gauche était horizontale. Sa base est maintenant orientée avec la
  paume vers l'intérieur, le pouce vers le haut et les doigts vers l'avant.
  Le coude, le poignet et les longueurs de bras restent identiques au v2.
- Une partie des sommets de la paume est influencée par Bone_024 (avant-bras).
  Tourner le poignet seul tordait cette zone. L'avant-bras roule autour de son
  axe pour rejoindre le même plan de paume, sans déplacer coude ou poignet.
  Le modificateur d'armature conserve le volume ; le pli groupé des doigts est
  réduit à40°. Aucun nouveau mesh, changement de peinture ou retouche raster.
- Arc tourné à60° autour de la poignée : sa corde reste à côté de l'avant-bras.
  Attache main gauche Bone_023 et taille1.25 inchangées.
- Ajustement demandé ensuite : arc remonté de.04270 unité pour centrer la prise
  sur le cuir. Ancre source Z -.015→-.080 ; pose des mains et orientation de l'arc
  conservées. before-bow-centering.py et les captures before-bow-centering*
  gardent la position précédente pour reproduction et comparaison.
- Flèche indépendante.79 et masquée au repos, comme dans v2.

Contrôles
verify_orientation.py recharge v2 et v3 indépendamment. Il mesure les axes réels
de paume/pouce et face large du carquois : les deux erreurs apparaissent dans v2
et passent dans v3. verify_saved.py vérifie les12 textures intégrées, les quatre
GLB immuables, le suivi/restauration des attaches et les intersections de surface
hors contact de main. Six vues complètes et trois gros plans rendus nativement.
Le cadrage, les matrices d'attache et les rapports sont conservés dans ce dossier.

Limites
Rig à26 os sans doigts individuels : prise statique améliorée mais pas un grip
anatomique par phalange. La corde/les branches restent rigides ; l'animation de
tir et le détachement de la flèche ne sont pas encore réalisés. Les tests ne
valident ni tous les mouvements, ni les volumes entièrement contenus.

Reproduction depuis la racine du dépôt (PowerShell)
$blender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$review = 'docs/reference/batrafian-review/v3-equipment-orientation'
# Prérequis : inspection.blend généré par v2-meshy-inspection/inspect_models.py.
& $blender --background --python-exit-code 1 --python "$review/assemble_preview.py"
& $blender --background --python-exit-code 1 --python "$review/verify_saved.py"
& $blender --background --python-exit-code 1 --python "$review/verify_orientation.py"
& $blender --background --python-exit-code 1 --python "$review/inspect_details.py"
Vérifier chaque code de sortie avant de poursuivre.
