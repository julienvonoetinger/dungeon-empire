# Raccords des murs : avant / après

Proposition demandée le 23 octobre 2026 après la découverte de ruptures de matière
au milieu des pierres. **Comparatif approuvé par l’utilisateur, conservé comme référence.**
La généralisation est décrite dans `../PAINTED_GODOT.md`.

## Généralisation intégrée

- `godot-final-details.png` : raccords horizontal et vertical du catalogue actif,
  agrandis depuis une capture Godot de 2x2CellRoom.
- `godot-final-arch.png` : arche devant un escalier dans ReferenceCalibration,
  après suppression des traits occultés.
- `../PAINTED_GODOT.md` : catalogue, reproduction et périmètre de revue.

## Voir le comparatif initial approuvé

- `comparison.png` : ancien rendu à gauche, proposition à droite.
- `horizontal-detail-*.png` : assise basse traversant une limite de case.
- `vertical-corner-detail-*.png` : mur vertical à la frontière de deux cases.
- `vertical-corner-after.png` : assemblage complet avec son retour d'angle.
- `*-godot-1x.png` et `*-godot-2x.png` : les PNG séparés placés dans Godot,
  avec mipmaps et filtrage linéaire comme le kit actif.

Les sous-dossiers `horizontal/` et `vertical-corner/` contiennent les cinq sprites
séparés utilisés pour cette revue. Ce sont des prototypes liés à ces deux contextes,
conservés séparément du catalogue général désormais utilisé dans Godot.

## Correction évaluée

Les guides des cases sont réunis dans un repère commun. Les régions entre leurs
joints représentent alors des pierres entières : chaque pierre reçoit une matière,
un cadrage de texture, un arrondi B et un reflet. Les images des cases sont extraites
de cette peinture commune. La palette, les volumes et la projection restent ceux
du kit existant.

Le masque du volume assemblé est rasterisé en une seule union, afin d'éviter un
trait d'anticrénelage entre deux polygones contigus. Une petite zone de pixels
identiques est partagée entre sprites, uniquement à l'intérieur du volume opaque
(8 pixels source, soit 2 pixels de référence). Elle évite que le filtrage séparé
des PNG recrée un filet sombre. Les pixels non opaques du contour partagé ont un
propriétaire unique. Cela modifie l'alpha individuel près des interfaces, sans
étendre le contour du volume assemblé.

Les petites marques violettes calculées par pierre peuvent changer de position
quand deux fragments deviennent une seule pierre. Le compositeur de production
utilise désormais une identité périodique stable par pierre entière.

## Reproduction

```powershell
node tools/prepare_wall_join_review.cjs
godot --path . --script res://tools/capture_wall_join_review.gd
```

Les rapports JSON enregistrent les guides et PNG utilisés comme état
« avant » (copies figées de ab9ebe7 dans `source/`), les fragments exportés, les ajustements de couverture et la comparaison
alpha avec la peinture entière. Les PNG actifs de Godot et les scènes ne sont pas
remplacés par cette commande. Le hook optionnel `resolveMaterials` du compositeur
sert seulement à attribuer les matières dans le repère plus large de cette revue.

## Limites

Deux assemblages et deux échelles Godot sont examinés. Cela ne valide pas tous les
voisinages du kit, les portes, les escaliers, ni les zooms extrêmes. La revue de
la généralisation est consignée séparément dans `../PAINTED_GODOT.md`.
