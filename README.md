# Dungeon Empire — base 2D

Les 20 scènes d'architecture utilisent des **sprites peints préparés à partir des
wireframes**, sur une grille carrée 1 × 1. Les matières stylisées approuvées sont
communes aux sols, murs, piliers, portes et escaliers. Godot sélectionne et place
les PNG selon les voisins ; aucune image n'est générée pendant le jeu.

Ce projet est une étude visuelle. Aucun gameplay n'est implémenté.

## Ouvrir les scènes

Ouvrir `project.godot` dans Godot.

- **F5** : `scenes/5x5RoomVerticalCornerCorridors.tscn`.
- **F6** : lancer la scène sélectionnée.
- **SixRoomPreview** : six salles, couloirs de deux cases de large et entrée
  par escalier, sans cœur ni torches.
- **WireframeDoorCross** : les quatre orientations de portes.
- **WireframeClosedCorridors** : salle avec quatre couloirs et escaliers terminaux.
- **EntranceVariants** : les quatre images d'entrée isolées.
- **DungeonHeart** et **DungeonTorch** : props séparés conservés.

Les noms historiques « Wireframe » restent ceux des scènes ; leur rendu utilise
maintenant les sprites peints. Les études de salles 1×1, 2×2, 3×3 et 5×5 ainsi que
les couloirs sont toujours disponibles dans `scenes/`.

Dans l'éditeur, sélectionner **Dungeon → Actualiser le rendu** après la fin de
l'import pour recharger aussi les textures. Les changements de paramètres
reconstruisent automatiquement l'assemblage.

## Où sont les sprites ?

| Dossier | Contenu |
| --- | --- |
| `assets/dungeon/painted-connected/` | Sprites des salles et couloirs : cases, portes, escaliers et sol |
| `assets/dungeon/painted-cells/` | Images isolées complètes pour inspection |
| `assets/dungeon/shared-materials/` | Matières, atlas approuvé et recette active |
| `assets/dungeon/wireframe-*/` | Géométrie source réutilisable |
| `assets/dungeon/heart/`, `assets/dungeon/torches/` | Props séparés |

Voir [l'inventaire des assets](assets/dungeon/README.md).

## Reproduire les sprites

Avec Node.js et `sharp` disponibles, depuis la racine :

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
godot --headless --path . --script res://tools/export_painted_scene_contexts.gd
node tools/export_painted_connected_kit.cjs
godot --headless --editor --path . --import
```

La première commande applique `shared-materials/active-recipe.json`. Les suivantes
utilisent les masques et joints des wireframes. Ne pas substituer un ancien atlas
ou modifier la projection pour adapter une texture.

## Capturer un aperçu

```powershell
godot --path . --script res://tools/capture_wireframe_cells.gd -- 3x3CellRoom WireframeDoorCross SixRoomPreview
```

Les images sont écrites dans `artifacts/`. Cette commande produit des aperçus ;
elle ne constitue pas une suite de tests.

## Documentation

- [Règles et état implémenté](GAME_DESIGN.md)
- [Placement et catalogue Godot](docs/reference/PAINTED_GODOT.md)
- [Construction des wireframes](docs/reference/WIREFRAME_WORKFLOW.md)
- [Matières et composition hors ligne](docs/reference/MATERIAL_WORKFLOW.md)
- [Perspective commune](docs/reference/PERSPECTIVE.md)

## Nettoyage historique

Les anciens essais d'architecture, leurs renderers et outils spécifiques ont été
retirés du projet actif le 23 octobre 2026. Les suites `verify_*` et
`tools/test-mobile.ps1` décrivaient l'ancien renderer ; elles sont également retirées.

[Inventaire et récupération](docs/cleanup/2026-10-23-pre-wireframe.json).
Une copie locale récupérable reste dans `artifacts/pre-wireframe-archive-2026-10-23/`,
exclue de Git et de Godot. Les maquettes originales, les wireframes et les sources
du pipeline actuel sont conservés. Les sections anciennes de GAME_DESIGN et des
notes de revue sont historiques ; leurs anciens chemins ne sont plus actifs.
