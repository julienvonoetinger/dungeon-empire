# Mycean — inspection Meshy et assemblage du bâton

2026-11-01. Proposition statique issue des deux GLB fournis par l’utilisateur.
Le personnage et le bâton gardent leurs matériaux, UV et textures Meshy.
`index.html` présente face/dos, quatre vraies directions isométriques et la prise
avant/après. Aucun sprite de jeu, animation, APK ou changement de gameplay.

## Sources et rig

Les copies immuables sont dans `../source`, avec SHA256 et chemins d’origine.
Mycean : 35 os, 15 429 sommets, 10 371 triangles, aucun sommet non pondéré,
34 sondes de déformation/restauration réussies. Pas d’animation intégrée.
Bâton : 10 633 sommets, 10 342 triangles, sans rig. Les deux modèles comportent
ensemble six textures 2048² embarquées (couleur, normale, métal/rugosité).
Le personnage mesure 1,70 unité, regarde vers −Y, monte selon +Z. Sa gauche
anatomique est +X. Le bâton source est déjà vertical selon Z.

Repères Mycean (ne pas copier les numéros d’os du Batrafian) :

| Partie | Os |
|---|---|
| Racine / bassin | 000 / 001 |
| Jambe droite : cuisse, tibia, pied | 006, 005, 004 (puis 003, 002) |
| Jambe gauche : cuisse, tibia, pied | 015, 014, 013 (puis 012, 011) |
| Tronc, bas vers haut | 010, 009, 008, 007 |
| Cou / tête / grand chapeau | 018, 017, 016 |
| Bras droit : clavicule, bras, avant-bras, poignet | 026, 025, 024, 023 |
| Bras gauche : clavicule, bras, avant-bras, poignet | 034, 033, 032, 031 |
| Chaînes distales droite / gauche | 022→019 / 030→027 |

Les noms réels portent le préfixe `Bone_`. Les chaînes distales sont sérielles,
pas un rig indépendant de chaque doigt. Les têtes/queues exactes, hiérarchies et
résultats des sondes figurent dans `inspection.json`.

## Défaut de prise et correction

Le premier montage traversait la main. Le contrôle initial excluait la zone de
prise : il pouvait donc passer malgré le défaut. Les vues et paramètres de ce
montage sont conservés dans `before-grip` (script historique, pas le générateur actif).

La copie de travail corrige 410 sommets de la main gauche, sans changer les
coordonnées du maillage de base, ses faces ou ses UV :

1. Les poids de la main qui suivaient l’avant-bras sont rattachés au poignet,
   seulement au-delà de son plan anatomique, avec transition sur un centimètre.
2. Un lattice local 12×3×3 referme la main en C autour du manche. Il suit `Bone_031`.
3. Une subdivision SIMPLE de niveau 2 échantillonne la déformation pour le rendu
   hors ligne. Ne pas utiliser un Smooth sur ce maillage glTF aux sommets séparés :
   il ouvre les coutures. Les textures et les UV ne sont pas repeints.
4. Une enveloppe de contact fermée, masquée au rendu, évite les pénétrations.
   Le bois et les lanières Meshy sont des surfaces superposées ; un Shrinkwrap
   directement sur ces surfaces donne des normales intérieur/extérieur ambiguës.
   Le Shrinkwrap OUTSIDE utilise donc cette enveloppe, qui suit aussi le poignet.

Attention Blender : les coordonnées du lattice vont de −5,5 à +5,5 en U et de
−1 à +1 en V/W ; ne pas les supposer normalisées à ±0,5. Le générateur ajuste
explicitement sa matrice et les coordonnées déformées.

Le bâton reste une pièce rigide parentée à `Bone_031`, échelle uniforme 0,840929,
longueur avant inclinaison 1,60, inclinaison extérieure 15°. Point de prise source
vers z=−0,13, entre les bandes. Les matrices et tous les paramètres sont dans
`equipment-fit.json`. Garder le lattice et l’enveloppe lors des futurs rendus.

## Reproduction

Depuis la racine du dépôt, dans un Blender séparé en arrière-plan :

```powershell
$blender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v2-meshy-inspection/inspect_models.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v2-meshy-inspection/assemble_preview.py
& $blender --background --python-exit-code 1 --python docs/reference/mycean-review/v2-meshy-inspection/verify_saved.py
```

Blender 5.2.1, Cycles 32 échantillons avec débruitage, Standard/None, PNG RGBA
768², orthographique à élévation 30° pour les quatre diagonales. Même cadrage et
éclairage pour les six vues. `--pilot` ne produit que trois directions + prises ;
`--no-render` reconstruit seulement le blend. Ces modes ne passent pas le contrôle
final des six vues. `inspection.blend` est un intermédiaire ignoré et régénérable.
Le blend équipé est autonome, textures embarquées. Les références sont exclues
des exports Godot par `docs/.gdignore`.

## Validation et limites

`verify_saved.py` recharge réellement le blend sauvegardé. Le contrôle teste
248 904 triangles évalués du personnage contre tout le bâton, dans les deux sens,
**sans exclure la main** : 0 intersection. Désactiver la contrainte de contact
reproduit 421 intersections. Distance minimale main/bâton ~0,00962 unité ;
extrémité du bâton à ~0,019 au-dessus du plan des pieds.

Les trois attaches suivent une rotation test de 8° du poignet et se restaurent
exactement ; les originaux et copies ont leurs SHA256 inchangés. Le maillage de
base et les UV sont comparés à de nouvelles importations des GLB. Six textures
embarquées sont disponibles. `saved-scene-validation.json` contient les résultats.

Cela valide une pose statique et les attaches, pas toutes les futures animations,
ni l’absence de volumes entièrement contenus sans intersection de surface. Le
chapeau masque beaucoup le visage à 30° : sa silhouette et la taille du héros en
jeu restent à juger. Aucun test sur téléphone ni intégration au jeu cette passe.
