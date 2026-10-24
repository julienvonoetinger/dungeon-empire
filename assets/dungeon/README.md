# Assets du donjon

## Utilisés actuellement

| Dossier | Rôle |
| --- | --- |
| `painted-connected/` | PNG par case : `cells/`, `doors/`, `entrances/`, styles dans `variants/`, voisinages dans `contexts/`, et `floor.png` |
| `painted-cells/` | Versions isolées complètes pour revue et scène EntranceVariants |
| `shared-materials/` | Recette active, atlas stylisés, 17 matières et provenance |
| `wireframe-cells/`, `wireframe-doors/`, `wireframe-entrances/` | Géométrie source des exports peints |
| `heart/` | PNG du cœur, sa référence originale et son placement |
| `torches/` | Torche conservée comme prop séparé |

## Références conservées

- `perspective/reference-atlas.png` est une maquette originale de l'utilisateur.
- `gloom-kit/reference.png` est une autre copie originale de référence.
- Les essais de masques dans `gloom-kit/proposals/nw-*` datent du travail sur les
  wireframes. Ils documentent la méthode ; ce ne sont pas des sprites actifs.
- Les propositions de matières plus récentes restent dans `shared-materials/proposals/`.
  La recette de matières active est `shared-materials/active-recipe.json`.
  La finition B des angles est définie dans `shared-materials/stone-finish.json`.
  Le sol lisse utilise `shared-materials/floor-smooth-atlas-v1.png` ; ses découpes
  et l'arrondi accru sont dans `active-recipe.json` (floorPattern, floorFinish).
  Les murs et les marches gardent B.
  Les variantes A/B/C et D2 utilisent `shared-materials/wall-variation-atlas-v1.png`.
  `active-recipe.json.wallVariation` décrit leurs matières et règles de raccord.

Les raccords utilisent désormais une peinture commune de la pierre entière,
avant son découpage entre cases. `painted-connected/catalog.json` décrit la
sélection selon les voisins. Ces PNG restent des éléments locaux réutilisables ;
aucune salle entière n'est prépeinte et Godot ne fabrique aucune texture.

`contextStyles` fournit quatre chemins préparés par voisinage, dans l'ordre
A/B/C/D2. Les images identiques sont partagées. Godot choisit un chemin avec
`scripts/painted_wall_selection.gd` et charge uniquement les textures utilisées.
Les veines D2 gardent une seule peinture dépliée entre dessus et façade.

Les anciens kits d'architecture ont été retirés le 23 octobre 2026. Inventaire :
`docs/cleanup/2026-10-23-pre-wireframe.json`. Leur copie locale est sous
`artifacts/pre-wireframe-archive-2026-10-23/`, hors import Godot et hors Git.
La suppression du projet actif n'efface pas l'historique Git.

Méthode et commandes : `docs/reference/PAINTED_GODOT.md`,
`docs/reference/MATERIAL_WORKFLOW.md`, `docs/reference/WIREFRAME_WORKFLOW.md`.
