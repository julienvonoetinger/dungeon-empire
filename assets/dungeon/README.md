# Assets du donjon

## Utilisés actuellement

| Dossier | Rôle |
| --- | --- |
| `painted-connected/` | PNG par case : `cells/`, `doors/`, `entrances/`, variantes locales dans `contexts/`, et `floor.png` |
| `painted-cells/` | Versions isolées complètes pour revue et scène EntranceVariants |
| `shared-materials/` | Recette active, atlas stylisé, dix matières et provenance |
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

Les raccords utilisent désormais une peinture commune de la pierre entière,
avant son découpage entre cases. `painted-connected/catalog.json` décrit la
sélection selon les voisins. Ces PNG restent des éléments locaux réutilisables ;
aucune salle entière n'est prépeinte et Godot ne fabrique aucune texture.

Les anciens kits d'architecture ont été retirés le 23 octobre 2026. Inventaire :
`docs/cleanup/2026-10-23-pre-wireframe.json`. Leur copie locale est sous
`artifacts/pre-wireframe-archive-2026-10-23/`, hors import Godot et hors Git.
La suppression du projet actif n'efface pas l'historique Git.

Méthode et commandes : `docs/reference/PAINTED_GODOT.md`,
`docs/reference/MATERIAL_WORKFLOW.md`, `docs/reference/WIREFRAME_WORKFLOW.md`.
