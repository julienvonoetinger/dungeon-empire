# Assets du donjon

## Kit mobile actif — 24 octobre 2026

mobile-kit/atlas-256.png et mobile-kit/catalog.tres sont les seuls assets
d’architecture chargés par les 21 scènes. 23 sprites, atlas 1024×2048, 256 px/case.
Sol calme à trois rangées, murs communs, piliers nus, dessus optionnel, quatre
portes et quatre escaliers. [Recette et commandes](../../docs/reference/mobile-kit/README.md).

Les props heart/ et torches/ restent autonomes. Les dossiers ci-dessous sont
désormais des sources ou références historiques exclues du paquet mobile.

## Ancien kit peint — historique

| Dossier | Rôle |
| --- | --- |
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

Les anciens dossiers `painted-connected/` et `painted-cells/`, leurs catalogues,
les scripts `painted_cell_catalog.gd` / `painted_wall_selection.gd` et les caches
intermédiaires ont été supprimés le 24 octobre 2026. L'ancienne copie locale
`artifacts/pre-wireframe-archive-2026-10-23/` a également été supprimée.
Les inventaires, empreintes et commits de récupération sont documentés dans
`docs/cleanup/README.md`. L'historique Git n'a pas été réécrit.

Le kit mobile réutilise la peinture commune sur des primitives préparées, avec
des piliers distincts aux jonctions. Les anciens outils de revue A/B/C/D2 sont
historiques ; utiliser `export_mobile_kit.cjs` pour reconstruire les assets actifs.

Méthode et commandes : `docs/reference/PAINTED_GODOT.md`,
`docs/reference/MATERIAL_WORKFLOW.md`, `docs/reference/WIREFRAME_WORKFLOW.md`.
