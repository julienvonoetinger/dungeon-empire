# Sprites peints dans Godot

État : 23 octobre 2026. Intégration demandée par l'utilisateur, après la préparation
des images isolées. La géométrie et les matières sont partagées par toutes les scènes.

## Raccords de pierres entières

Le comparatif des raccords horizontal et vertical a été approuvé. Le compositeur
connecté utilise maintenant le voisinage 3×3 pour retrouver les faces complètes
des pierres qui traversent une frontière de case. Leur matière, cadrage de texture,
graine d'arrondi et accent sont stables dans ce repère. Les PNG sont découpés
seulement après cette peinture commune ; les guides géométriques restent inchangés.

Une garde de deux pixels de référence (huit pixels source) existe uniquement
dans le volume opaque commun. Elle protège le raccord du filtrage et des mipmaps.
Sur le contour transparent, une seule case porte la couverture alpha commune.
L'alpha **individuel** change donc près des interfaces ; l'ancien constat « mêmes
masques alpha qu'avant B » ci-dessous décrit uniquement la promotion précédente.
La garde ne doit jamais agrandir la silhouette de l'assemblage ni combler un vide.

Le catalogue contient les voisinages ordinaires de huit voisins et les extrémités
ouvertes, ainsi que les quatre portes/escaliers et les voisinages spéciaux des
scènes inventoriées. Les images identiques sont partagées. Les chemins de PNG
sont chargés à la demande, afin de ne pas réserver la mémoire de toutes les
combinaisons à l'ouverture d'une scène. Un sol commun puis au plus une structure
complète sont toujours placés sur chaque case, sans texture ni géométrie créée
pendant le rendu.

Reproduction :

```sh
godot --headless --path . --script res://tools/export_painted_scene_contexts.gd
node tools/export_painted_connected_kit.cjs
godot --headless --editor --path . --import
```

L'inventaire `painted-scene-contexts.json` décrit des configurations locales, avec
les scènes uniquement comme provenance. Pour une nouvelle combinaison de portes
et d'escaliers voisins, refaire cet inventaire et l'export avant la revue des
raccords. L'aperçu utilise sinon la variante générique préparée et signale le
contexte manquant ; cette variante de secours ne valide pas la continuité.

Le comparatif approuvé est figé dans `wall-join-review/`, avec ses PNG d'origine
dans `source/` (commit ab9ebe7). Il ne lit plus les images actives comme « avant ».
Les exports isolés restent disponibles pour contrôler un élément seul ; les
scènes assemblées utilisent exclusivement le catalogue connecté.

## Revue de la généralisation

Les 20 scènes d'architecture ont été capturées dans Godot à 1280×960 et
2560×1920, sans erreur ni avertissement. Les murs nord/ouest/sud ont été examinés
en détail ; les quatre portes, quatre escaliers et les jonctions autour des
piliers ont été revus. Une occultation de traits d'escalier sur l'arche a été
corrigée, puis les sept scènes contenant les pièces spéciales ont été recapturées.
Voir `wall-join-review/godot-final-details.png` et `godot-final-arch.png`.

L'export rapporte zéro pixel intérieur non peint et zéro différence d'alpha
avec son modèle de contexte. Les empreintes des sources et des 737 structures
correspondent au catalogue. 208 PNG intermédiaires non référencés ont été retirés
du projet actif ; copie récupérable dans `artifacts/whole-stone-retired/`.
Logs et captures complets : `artifacts/whole-stone-*.log` et
`artifacts/wireframe-*.png`. Cette revue ne démontre pas tous les futurs
assemblages de pièces spéciales ni tous les niveaux de zoom.

## Gamme et finition précédemment approuvées

La gamme active est désormais **stylisée**, approuvée par l'utilisateur le
23 octobre : grandes facettes peintes, sol calme, bois simplifié et accents violets
localisés. Les PNG sont réexportés avec `shared-materials/active-recipe.json` et
`stylized-atlas-v2.png`. Les 20 scènes conservent leurs références et leur layout.

La finition **B — angles adoucis** est approuvée à son tour. Sa recette durable
est `assets/dungeon/shared-materials/stone-finish.json`, appliquée par
`tools/stone_edge_finish.cjs` pendant les deux exports peints. Les pierres des
murs, sols, piliers, escaliers et arches ont des angles légèrement émoussés et des
reflets continus. Les textures sources et les couleurs restent celles de la gamme
stylisée ; le bois et le métal gardent leur finition.

Les paramètres B sont : rayon 3,8, retrait 0,55, irrégularité 0,12 et biseau 2,2
pixels de référence, avant l'export ×4. Le sol utilise un facteur 0,63 ; les faces
étroites sont réduites proportionnellement. La comparaison approuvée et ses
entrées figées restent dans `stone-edge-review/`.

L'arrondi reste dans l'enveloppe maçonnée opaque : il ne crée aucun trou alpha
entre les pierres. Les fragments périodiques du sol partagent une pierre entière,
ses coordonnées de texture et sa graine de finition. Les arêtes absentes du guide
connecté ne reçoivent pas de nouveau biseau de terminaison. Les contours du modèle,
la projection, la taille des cases et les dispositions des scènes sont conservés.

Les rapports distinguent maintenant `constructionJointLayerMatchesGuide` des
joints visibles : B modifie volontairement leur aspect autour des coins arrondis.
Le calque magenta conserve les traits de construction d'origine. Une correspondance
de ces traits ne signifie pas que chaque pixel de mortier peint est sur le trait.

Revue historique de l'intégration B, avant correction des raccords : export de 57 images isolées et 96 structures connectées
avec un sol commun, soit 154 PNG. Leurs 154 masques alpha sont identiques à ceux
d'avant B. Import Godot et captures effectués sans erreur pour `2x2CellRoom`,
`3x3RoomCornerCorridors`, `WireframeDoorCross`, `WireframeClosedCorridors` et
`SixRoomPreview`. Les vues normales et agrandies montrent l'arrondi, les quatre
portes et les quatre escaliers. Le sol conserve un motif répétitif commun ; cette
revue ne démontre pas tous les assemblages possibles d'un futur donjon libre.
Logs, captures et comparaison alpha : `artifacts/soft-stone-b/` et
`artifacts/wireframe-*.png`.

Les exports remplacent désormais chaque fichier terminé de façon atomique, avec
une reprise bornée si Windows le verrouille brièvement pendant l'import Godot.
Ils ne ferment pas l'éditeur ouvert par l'utilisateur.

## Catalogue actif

| Élément | Source |
| --- | --- |
| Textures connectées | `assets/dungeon/painted-connected/` : 737 PNG structurels + un sol |
| Inventaire et provenance | `assets/dungeon/painted-connected/catalog.json` |
| Mesures d'export | `assets/dungeon/painted-connected/validation.json` |
| Catalogue de chemins Godot | `scripts/painted_cell_catalog.gd` |
| Sélection sur grille | `scripts/wireframe_cell_layout.gd`, clé de voisinage |
| Placement et actualisation | `scripts/wireframe_cell_study.gd` |
| Matières et profils communs | `assets/dungeon/shared-materials/catalog.json` |
| Revues isolées conservées | `assets/dungeon/painted-cells/`, `docs/reference/painted-kit-review/` |

Les 1 444 clés de voisinage réutilisent 737 PNG structurels distincts ; 161 clés
sans structure n'ajoutent aucun sprite de murs. Les 128 identifiants de base
restent disponibles comme variantes génériques. Les portes et escaliers suivent
la même sélection locale. Les faces internes aux raccords sont absentes des PNG.
Les pièces isolées de revue gardent leurs extrémités complètes ; ne pas substituer
ces images aux variantes connectées dans les scènes sur grille.

## Placement

- Case carrée 1×1, pas de 256 pixels ; géométrie commune `écran=(x−.18z,y−.9z)`.
- Épaisseur 1/6 ; hauteur 1,88/6 ; deux assises, joint à 0,94/6.
- PNG à ×4, échelle Godot uniforme 0,25 ; mipmaps et filtrage linéaire.
- Ancrages logiques : sol (0,0), murs/escaliers (24,88), portes (24,128).
- Tous les sols à z=0, puis toutes les structures à z=1, ordonnées par ligne/colonne.
- Un sol et au plus une structure par case. Les portes et escaliers connectés
  ne contiennent pas de sol ; leur image couvre celui-ci là où leur volume l'occulte.
- Le sol reprend les 26 traits de son SVG connecté. Les trois contours ajoutés
  aux guides isolés pour fermer la revue ne deviennent pas des bordures de cases.
- Les fragments de dalle aux bords gauche/droit appartiennent à une même pierre
  qui continue dans la case voisine. Le compositeur peint cette pierre entière,
  avec la même matière, les mêmes coordonnées de texture et les mêmes reflets,
  puis limite l'export à la case. Aucun biseau n'est peint sur cette limite virtuelle.
- Le sol connecté a un cadre opaque exact de 1024×1024 px (256×256 affichés),
  sans marge transparente susceptible de former un filet sombre avec les mipmaps.
  Le joint nord de la case suivante fournit sa moitié inférieure au bord sud,
  afin de garder la largeur entière du joint entre deux rangées de cases.
  Ce recadrage d'export change l'ancrage du sol de (4,4) à (0,0), sans déplacer
  le dallage. Les sprites structurels et les revues isolées gardent leur cadre.
- Modulation blanche ; pas de miroir, de rotation, d'étirement, de masque,
  de lumière ou de dessin correctif au runtime.

Le bouton « Actualiser le rendu » conserve son getter Callable. Dans l'éditeur,
il recharge aussi chaque texture utilisée depuis son fichier importé, une seule
fois par image, avec `ResourceLoader.CACHE_MODE_REPLACE`. Cela remplace les pixels
gardés en mémoire après un export/import externe. Les changements de paramètres
reconstruisent les sprites sans forcer cette lecture ; F6 charge les chemins sélectionnés avec le cache
normal. L'éditeur et F6 partagent le même renderer. Le nom historique
`wireframe_cell_study.gd` est gardé pour préserver les références des scènes.

Après un remplacement des PNG, laisser Godot terminer l'import puis sélectionner
`Dungeon` et cliquer « Actualiser le rendu ». Un import effectué par un second
processus ne garantit pas la mise à jour des textures dans l'éditeur déjà ouvert.
Le bouton recharge les ressources importées ; il ne remplace pas l'étape d'import.

## Scènes

Ces **16 scènes déjà sur grille** gardent leurs dimensions et paramètres :

- `1x1CellRoom`, `2x2CellRoom`, `3x3CellRoom`, `SingleCellRoom`.
- `1x2Corridor`, `1x3Corridor`, `2x1Corridor`, `3x1Corridor`.
- `3x3RoomCornerCorridors`, `3x3RoomFourCorridors`.
- `5x5RoomCornerCorridors`, `5x5RoomFourCorridors`, `5x5RoomVerticalCornerCorridors`.
- `WireframeClosedCorridors`, `WireframeDoorCross`, `SixRoomPreview`.

SixRoomPreview conserve ses 256 cases, son escalier d'entrée, les six salles et
les couloirs larges de deux cases. Pas de torches ou de cœur dans cet aperçu.
WireframeDoorCross garde ses quatre portes et WireframeClosedCorridors ses quatre
escaliers terminaux. Les noms de ces scènes restent utilisables.

Les **quatre anciennes démonstrations** sont remplacées par les formes du kit :

| Scène | Contenu actuel |
| --- | --- |
| DungeonPreview | Même composition que SixRoomPreview |
| PerspectiveRoom | Salle 3×3 avec une case d'escalier au nord |
| ReferenceCalibration | Passage de trois cases, porte sud au centre, escaliers aux deux extrémités |
| EntranceVariants | Quatre sprites d'entrée isolés, sol compris, en quatre panneaux |

DungeonHeart et DungeonTorch sont des scènes de props séparées, sans remplacement
dans ce kit d'architecture. Elles conservent leurs assets. Les anciens scripts et
images d'architecture antérieurs aux wireframes ont été retirés du projet actif
le 23 octobre. L'inventaire et le commit de récupération sont conservés dans
`docs/cleanup/2026-10-23-pre-wireframe.json`, avec une copie locale dans
`artifacts/pre-wireframe-archive-2026-10-23/`. Le cœur utilise désormais
`assets/dungeon/heart/heart.png`, identique au PNG précédemment dans `alpha-kit`.

## Reproduire

Depuis la racine, avec Node.js et `sharp` disponibles :

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
godot --headless --path . --script res://tools/export_painted_scene_contexts.gd
node tools/export_painted_connected_kit.cjs
godot --headless --editor --path . --import
```

Remplacer `godot` par le chemin de l'exécutable local. L'export connecté réunit
les guides des cases voisines avant d'extraire les pierres complètes. Il masque
les traits occultés par une pièce voisine, notamment un escalier derrière une
arche. Les matériaux utilisent la bibliothèque partagée. L'export génère les PNG
et le catalogue de chemins GDScript.

`--floor-only` actualise le sol en conservant les structures, leurs métadonnées
et le sélecteur. `--specials-only` actualise seulement les contextes contenant
une porte ou un escalier ; l'utiliser uniquement après une modification limitée
à ces contextes, sur un catalogue complet existant. Pour tout changement commun
de géométrie, matière ou finition, relancer l'export complet. Le diagnostic
`--only=doors/west` appartient à l'exporteur isolé
`export_painted_image_catalog.cjs` ; il est refusé par l'exporteur connecté.

Les variantes d'entrée isolées utilisées par EntranceVariants sont produites par
`tools/export_painted_image_catalog.cjs` et importées avec mipmaps.

## Revue dans Godot

Ouvrir une scène et appuyer sur **F6**. F5 reste configuré sur
`5x5RoomVerticalCornerCorridors.tscn`. Les helpers existants capturent le rendu
actuel, malgré leur nom historique :

```powershell
godot --path . --script res://tools/capture_wireframe_cells.gd -- SixRoomPreview WireframeDoorCross WireframeClosedCorridors
godot --path . --script res://tools/capture_wireframe_doors.gd
godot --path . --script res://tools/capture_wireframe_entrances.gd
godot --path . --script res://tools/capture_six_room_wireframe.gd
```

Les captures et logs sont dans `artifacts/`, ignoré par Git. L'export contrôle les
traits et la couverture alpha ; les captures montrent l'assemblage réel. Ces
contrôles n'accordent pas une validation artistique à la place de l'utilisateur.
Le dallage répète encore un motif commun par case ; aucune variation de layout
aléatoire n'est ajoutée. Les portes restent fermées, sans interaction, collision,
navigation, progression ou sauvegarde.

## Révision du rythme du dallage — 23 octobre 2026

Le précédent motif réunissait de grandes portions gauche/droite en une seule
pierre à chaque raccord. Ces pierres mesuraient jusqu'à 0,78 case et formaient
une colonne répétée. Le découpage est maintenant défini dans
`docs/reference/floor-periodic-cell.json` : six rangées de hauteur inchangée,
26 fragments dans la case, représentant 20 pierres complètes périodiques.
Les joints sont décalés par rangée. Toutes les pierres complètes, y compris
celles qui traversent une frontière de case, mesurent entre 0,24 et 0,40 case.

Le fichier `floor-only-cell-wireframe.json` conserve l'étude historique.
Le nouveau motif sert aux exports connectés, aux calques isolés et au sol visible
des variantes de portes/escaliers. Les PNG correspondants sont réexportés avec
les matières communes. La grille reste 1×1, le pas 256 px, la projection et les
murs inchangés. Le sol connecté reste opaque à 1024×1024, ancrage (0,0), avec
peinture continue aux frontières. Godot place les images préparées.

Ordre de reproduction après changement du découpage :

```powershell
node tools/export_wireframe_cell_kit.cjs
node tools/export_arched_door_orientations.cjs
node tools/export_wireframe_entrances.cjs
node tools/export_wireframe_doors.cjs
node tools/export_wireframe_overlays.cjs --png
node tools/export_painted_image_catalog.cjs
node tools/export_painted_connected_kit.cjs
```
