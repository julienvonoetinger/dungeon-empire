# Étude : sol et socle dans une vue inclinée

Proposition du 24 octobre 2026, **rejetée** : elle changeait la perspective
des murs alors que l'utilisateur demandait uniquement de revoir le sol.
Voir [la correction limitée au dallage](../wireframe-v2-floor-only/README.md).
Les descriptions suivantes sont conservées comme historique de cet essai.

L'utilisateur demande de revenir au wireframe pour revoir la perspective du
sol et du cœur. Cette demande autorise une nouvelle étude malgré l'ancienne
consigne de conserver un sol vu de dessus. Elle n'approuve pas encore cet angle
de caméra ou un remplacement des sprites peints.

## Proposition

Une caméra orthographique frontale, inclinée à **35° au-dessus du sol** :

```text
écranX = x
écranY = sin(35°) × y − cos(35°) × z
direction vers la caméra = (0, cos(35°), sin(35°))
```

Les deux axes d'écran sont unitaires et orthogonaux. Le plan horizontal est
raccourci en profondeur ; les hauteurs montent verticalement à l'écran. Les
arêtes parallèles restent parallèles : il ne s'agit pas d'une perspective à
points de fuite finis. Cette propriété permet de réutiliser des sprites sur
une grille régulière, à une distance de caméra fixe.

L'angle de 35° est une proposition de l'assistant. Les dimensions physiques
restent celles du kit : cases **1 × 1**, murs d'épaisseur 1/6 et hauteur 1,88/6,
deux assises, piliers de largeur 0,24 et hauteur H + 0,035. À l'échelle de jeu
(256 px/case, zoom 0,75), une case couvre **192 × 110,13 px** à l'écran. Sa
dimension logique reste carrée.

Le modèle reproduit l'occupation de `MobileReference.tscn` : salle 3 × 2,
couloir est de trois cases en rangée 1, couloir sud de quatre cases en colonne 1,
bouts fermés. Les treize cases reprennent le motif actuel de trois rangées de
dalles, sans ajouter de joint aux limites de cases traversées par une pierre.

## Cœur

Le cœur est un **volume schématique**, construit pour cette étude, et non un
tracé exact ou une nouvelle peinture de l'image approuvée. Son emprise reste
0,8125 × 0,8125 case, centrée en (1,5 ; 1). Les marches, les quatre pierres
d'angle et le logement circulaire suivent la même caméra que le sol et les murs.
Le cercle horizontal devient donc une ellipse. Le vortex violet représente
un effet tourné vers la caméra, avec un contour circulaire.

Les volumes fermés masquent leurs arêtes arrière par intersections rayon /
triangles. Les silhouettes du logement cylindrique sont recalculées pour chaque
caméra. Le dessin exporté montre uniquement les traits visibles. Le masque du
vortex retire les traits derrière le disque, y compris dans l'export transparent.

## Fichiers

- `room.png` / `.svg` : proposition complète à 192 px par case en largeur.
- `comparison.png` / `.svg` : projection actuelle et proposée, avec les mêmes
  volumes et la même largeur de case ; cadrage rapproché sur la salle.
- `heart-detail.png` / `.svg` : agrandissement du socle et du raccord au sol.
- `room-transparent.png` / `.svg` : traits visibles sur fond transparent.
- `geometry.json` : caméra, volumes, joints, segments visibles et empreintes
  SHA256 de la scène et du kit peints au moment de l'étude.

Reproduction depuis la racine du dépôt (Node.js avec Sharp disponible) :

```powershell
node tools/prepare_ground_perspective_review.cjs
```

L'export est entièrement hors Godot. Il n'écrit que dans ce dossier de revue.
Les scènes actives, l'atlas et les originaux approuvés restent à leur état
précédent. Les images sont des dessins géométriques, pas des captures de jeu.

Si cette vue est retenue, il faudra adapter les images de l'architecture, des
portes, des escaliers, des torches et du socle à la nouvelle projection. Étaler
ou comprimer les PNG existants ne remplace pas ce travail. La sélection des
cases restera une opération sur la grille logique ; leurs positions affichées
devront utiliser le nouveau pas projeté.
