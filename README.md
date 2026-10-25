# Dungeon Empire — base 2D mobile

Les **23 scènes** utilisent **108 régions préparées dans un atlas 1024×2048** :
sol, murs, piliers, quatre portes, quatre escaliers, cœur et torches.
Les anciens décors de fissures et d'éclats de pierre ont été retirés.
Vingt scènes de disposition activent neuf variantes de murs : maçonneries,
reliefs et corruption optionnelle. Leurs pierres partagent la palette du mur
de base ; les accents violets restent distincts.
Ces vingt scènes utilisent aussi quatre assemblages de dalles B, aux formats
variés et aux surfaces calmes. Les pierres traversant les limites de cases
partagent leur géométrie et leur peinture pour assurer les raccords.
Quatre nouveaux décors de sol (fissures et corruption) sont ajoutés avec parcimonie
sur leurs dalles B correspondantes, hors portes, escaliers et socle du cœur.
Ils restent dans le même atlas et ne changent pas les bords de cases.
Le cœur possède son propre éclairage au sol : une lueur violette et les ombres
du socle, indépendantes des torches. Les deux effets sont limités aux vraies cases
de sol, hors portes et escaliers.
La projection isométrique 2:1 est commune à tous les volumes. Les images sont
préparées hors ligne ; Godot les place sur la grille logique 1×1.

Une case est affichée comme un losange de 256×128 pixels source, soit 192×96
au zoom fixe 0,75 dans la vue logique 1280×720. Déplacement au doigt ou avec le
bouton gauche de la souris ; aucun zoom utilisateur. Les matières et dessins
approuvés ont été adaptés à la géométrie isométrique, préparée d'abord en wireframe.

Ce projet est une étude visuelle. Aucun gameplay n'est implémenté.

## Ouvrir les scènes

Ouvrir `project.godot` dans Godot.

- **F5** : `scenes/MobileReference.tscn`, avec le cœur sculpté et deux torches éclairées.
- **F6** : lancer la scène sélectionnée.
- **SixRoomPreview** : six salles, couloirs de deux cases de large, entrée par escalier et cœur.
- **WireframeDoorCross** : les quatre orientations de portes.
- **WireframeClosedCorridors** : salle avec quatre couloirs et escaliers terminaux.
- **EntranceVariants** : les quatre escaliers avec le même kit que les salles.
- **DungeonHeart** et **DungeonTorch** : décors isolés dans la même projection.

Les études de salles 1×1, 2×2, 3×3 et 5×5 et les couloirs restent disponibles.
Dans l'éditeur, sélectionner **Dungeon → Actualiser le rendu** après la fin de
l'import. Le catalogue et l'atlas sont rechargés ensemble ; les réimports suivants
actualisent l'aperçu. Les grandes scènes s'explorent en déplaçant la vue.

Les 20 scènes de salles/couloirs activent les fissures et l'usure. Dans le nœud
**Dungeon**, **Surface Details** active les décors et **Surface Detail Seed**
change leur répartition. Les motifs sont espacés, stables entre actualisations,
avec une corruption rare. Les supports de torches, portes, escaliers et cases
sous le cœur sont exclus. Les props isolés et la planche des escaliers restent nus.

## Où sont les sprites ?

| Dossier | Contenu |
| --- | --- |
| `assets/dungeon/isometric-kit/` | Atlas et catalogue peints actifs |
| `assets/dungeon/mobile-kit/` | Ancien kit peint conservé ; petite texture de lumière partagée |
| `assets/dungeon/shared-materials/` | Matières et recettes peintes de référence |
| `docs/reference/isometric-review/painted-v1/` | Sprites peints, guides magenta, superpositions, recette et captures |
| `docs/reference/isometric-review/migration-v1/` | Géométrie et revue wireframe conservées |

Les sources et apparences approuvées restent conservées ; aucune n'a été régénérée.
Le cœur réutilise ses sculptures sur le support isométrique et son vortex face à
la caméra : c'est une adaptation de l'apparence, à examiner dans cette nouvelle vue.
Voir [l'inventaire des assets](assets/dungeon/README.md) et [l'historique du nettoyage](docs/cleanup/README.md).

## Reproduire les sprites

Avec Node.js et `sharp` disponibles, depuis la racine :

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
```

Les anciens exporteurs, dont `export_mobile_kit.cjs`, reconstruisent les étapes
historiques. Ils ne mettent pas à jour le catalogue isométrique actif.

## Capturer un aperçu

```powershell
godot --path . --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_migration_review.cjs
```

Les images sont dans `docs/reference/isometric-review/painted-v1/captures/`.
L'atlas peint pèse **1 504 113 octets PNG**, soit environ **1,43 Mio**, et **8 Mio
RGBA** sans mipmaps. Aucun profilage sur téléphone effectué. Ces commandes
produisent des aperçus, pas une suite de tests.

Suivre [la recette de migration peinte](docs/reference/isometric-review/painted-v1/README.md)
pour exporter les 52 dépendances actives des 23 scènes depuis une copie propre.
La dernière revue est dans
[l'intégration des décors de dalles B](docs/reference/isometric-floor-damage-review/v1/integration/README.md).

## Documentation

- [Kit isométrique peint : recette, export, mesures et limites](docs/reference/isometric-review/painted-v1/README.md)
- [Projection approuvée](docs/reference/isometric-review/wireframe-v1/selection.json)
- [Règles et état implémenté](GAME_DESIGN.md)
- [Placement et catalogue Godot](docs/reference/PAINTED_GODOT.md)
- [Construction des wireframes](docs/reference/WIREFRAME_WORKFLOW.md)
- [Matières et composition hors ligne](docs/reference/MATERIAL_WORKFLOW.md)

Les sections anciennes des documents de conception et des notes de revue sont
historiques ; leurs anciennes projections et chemins ne décrivent pas le kit actif.
