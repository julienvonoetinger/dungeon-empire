# Correction : le sol uniquement

Le 24 octobre 2026, l'utilisateur rejette le changement de perspective des murs
de la proposition v1 : il demandait de travailler **seulement sur le sol**.
L'angle orthographique à 35° ne constitue donc pas une direction approuvée.

Cette proposition rétablit la projection du kit, `(x − 0,18z ; y − 0,9z)`.
Les murs, les piliers, le contour de la salle et les cases de 192 × 192 pixels
affichés restent identiques. Le repère schématique du cœur est le même dans
les deux panneaux ; son dessin n'est pas retravaillé dans cette correction.

## Seul changement proposé

Incliner les joints courts du dallage, avec une pente horizontale/verticale
de 0,18/0,9 = 0,2, rappelant celle des élévations des murs. Les joints
horizontaux, les trois rangées par case et la largeur des pierres restent
inchangés. Les segments sont construits en coordonnées globales puis limités
au sol et masqués par les volumes : aucun joint artificiel de case n'est ajouté.

Il s'agit d'un **essai de motif au sol**, pas d'une caméra physique différente.
Une modification de projection de tout le plan horizontal changerait aussi
les emprises des murs ; elle n'est pas autorisée par cette demande. Cette
distinction doit rester explicite lors de la revue.

## Reproduction

```powershell
node tools/prepare_floor_only_wireframe_review.cjs
```

Node.js et Sharp sont nécessaires. L'export produit `comparison`, `room`,
`room-transparent` et `fixed-volumes` en SVG/PNG, plus `geometry.json`.
L'export compare exactement les faces solides et les segments hors sol des
deux vues avant d'écrire la proposition. Les images sont des dessins hors
Godot, sans migration de l'atlas ou des scènes actives.

Les fichiers v1 sont conservés comme historique rejeté. Ne pas réutiliser leur
caméra ou présenter la nouvelle géométrie du cœur comme approuvée.
