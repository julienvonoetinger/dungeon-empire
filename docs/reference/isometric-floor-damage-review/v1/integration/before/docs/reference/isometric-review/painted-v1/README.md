# Textures du kit isométrique — 24 octobre 2026

L'utilisateur a demandé d'appliquer les textures après la migration wireframe.
Les **23 scènes** utilisent maintenant **104 régions préparées**, regroupées dans
`assets/dungeon/isometric-kit/atlas-256.png` avec son catalogue `.tres`.

Dernière modification : [intégration de quatre assemblages de dalles B](../../isometric-floor-variation-review/v1/integration/README.md).
Les captures et validations ci-dessous décrivent aussi les étapes historiques ;
les preuves de cette intégration restent dans son propre dossier.

## Géométrie et apparence

La géométrie provient de `../migration-v1/geometry.json`, conservé sans changement.
Son empreinte SHA256 est vérifiée par l'exporteur. La projection reste :

```text
screen_x = 256 * (x - y) / 2
screen_y = 256 * ((x + y) / 4 - sqrt(3/8) * z)
```

Une case logique 1×1 fait 256×128 pixels source, soit 192×96 au zoom fixe .75.
Déplacement libre au doigt/souris, mêmes layouts et couloirs de deux cases dans
SixRoomPreview. Les trois rangées du dallage sont un motif décoratif.

- **Sol et murs** : matières mobiles sobres déjà approuvées, finition B arrondie
  à l'intérieur des masques, deux rangées de briques. Les pierres du sol qui
  traversent une limite de case sont peintes entières avant découpage. Leur
  finition utilise leurs contours complets, distincts du guide visible tronqué.
  Une couverture périodique de deux pixels autour du losange évite les raccords
  de transparence au filtrage ; les limites logiques restent 1×1.
- **Piliers** : base nue plus un dessus sculpté optionnel. Le dessin existant du
  dessus est projeté sur le plan XY, avec le même bord et une transition intérieure.
- **Portes** : quatre orientations, deux arches v8, remplissage lisse en retrait,
  peinture v2 sur les deux faces du vantail. Les volumes sont peints ensemble
  pour conserver leurs occultations mutuelles, puis séparés à hauteur du mur.
  Les pixels finaux de la porte complète alimentent les deux parties. Une garde
  de couleur opaque de deux pixels à la coupe interne évite un filet dû au filtrage
  linéaire à .75. Elle ne modifie ni les volumes ni l'alpha extérieur. Les cadres
  gagnent trois pixels de marge de chaque côté par rapport au wireframe.
- **Escaliers** : les cinq marches existantes, dans les quatre orientations,
  reçoivent les matières de pierre et de sol.
- **Torches** : métal approuvé et flamme-v3 à base arrondie. La flamme conserve
  une seule échelle à l'écran ; la coupelle masque physiquement sa base. Les
  lumières locales existantes sont réactivées dans MobileReference et DungeonTorch.
- **Cœur** : les sculptures, le champ rituel et les bordures de ritual-v3 sont
  réutilisés sur les plans du support isométrique. La moitié arrière du champ
  rituel, cachée dans l'original, réutilise par symétrie la moitié visible. Le vortex
  reste face à la caméra, extrait par masque spatial adouci, avec occultation par
  le support. Le halo dispose de 20 pixels de marge supplémentaires en haut.
  La tranche basse prélève la pierre au-dessus de l'ombre peinte d'origine
  (lignes 242–252), pour ne pas étirer cette ombre en bande noire. L'assise reste à z=0.
  **C'est une adaptation de l'apparence**, pas une nouvelle illustration approuvée
  ni une réutilisation inchangée de l'ancien PNG complet.
- **Éclairage du cœur** : deux images préparées à partir de la source centrale
  du vortex, une ombre de contact/reliefs et une lueur violette additive au sol.
  Les torches n'influencent plus leur sélection. Les images approuvées gardent
  leurs pixels et leur échelle ; seules les marges alpha-zéro sont coupées.
  Un masque de 4×4 cases, calculé lors de l'actualisation, limite les effets aux
  sols existants, hors cases spéciales. Les shaders ne créent ni géométrie ni
  texture ; ils masquent les PNG déjà préparés. Les effets restent sous les
  volumes. Le cœur isolé les affiche sans masque de sol. Les neuf anciens
  effets liés aux torches restent des références historiques.

Aucune source approuvée n'a été régénérée. Les fichiers originaux et leurs
sélections restent conservés. Les guides du cœur décrivent son support schématique
et le placement du vortex ; ils ne valident pas chaque détail de sa sculpture.

## Fichiers

| Fichier ou dossier | Rôle |
| --- | --- |
| `tools/export_isometric_painted_kit.cjs` | Export actif, atlas/catalogue et provenance |
| `tools/isometric_paint_geometry.cjs` | Projection, intersections et profondeur hors ligne |
| `tools/isometric_stone_paint.cjs` | Pierre, sols, escaliers et portes |
| `tools/isometric_prop_paint.cjs` | Dessus sculpté, cœur et torches |
| `sprites/` | PNG individuels ; les deux `*-metal.png` sont des vues d'inspection |
| `guides/` | Traits visibles magenta sur alpha, avec les cadres des PNG peints |
| `overlays/` | Guide superposé à chaque PNG |
| `recipe.json` | Dimensions, matières, empreintes, masques et adaptation des décors |
| `captures/` | Vues Godot au zoom .75, détails et vues d'ensemble |
| `editor-captures/` | Aperçus produits dans le contexte éditeur |
| `logs/` | Sorties d'import, captures et export |

Les guides sont translatés lorsque le cadre d'un effet ou d'une porte s'agrandit ;
leurs coordonnées dans la scène ne changent pas. Le catalogue contient 1 sol,
8 murs, 1 pilier, 1 dessus optionnel, 4 escaliers, 8 parties de porte, 1 cœur et
2 torches, 2 effets de socle et 15 détails de surface. Godot ne fabrique pas de
géométrie ou de textures : il place les PNG, applique leur masque de sol et trie les
supports avec les métadonnées de projection existantes.

## Reproduction

Avec Node.js, Sharp et Godot disponibles :

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_migration_review.cjs
```

F5 ouvre MobileReference ; F6 lance la scène sélectionnée. Le renderer recharge
ensemble atlas et catalogue après import ; le bouton « Actualiser le rendu »
reste disponible. Le cache et l'état de l'éditeur utilisateur ne sont pas réinitialisés.

`tools/export_isometric_kit.cjs` rétablit volontairement l'étape wireframe. Pour
reproduire ses captures, passer `-- --output-root=res://docs/reference/isometric-review/migration-v1`
au script Godot ; utiliser `--wireframe` pour ses outils de planche/export. Ne pas
écraser les sélections ou captures approuvées historiques avec le rendu peint.

## Mesures et revue

Atlas **1024×2048**, **1 463 015 octets PNG**, **8 Mio RGBA** sans mipmaps. La texture
de lumière partagée reste séparée : 128×128, 5 151 octets PNG / 64 Kio RGBA.
Les 23 scènes dépendent de 51 fichiers source ; les sources artistiques et anciens
atlas ne sont pas inclus dans le paquet actif.

La revue précédente des murs ajoutait 72 profils pour neuf motifs et conservait les
43 anciennes régions à l'identique. Son export de ressources fait 1 192 581
octets. Depuis, douze régions de fissures puis trois régions d'éclats ont été
retirées sans modifier les 100 régions conservées. Les quatre dalles B ajoutées
ensuite conservent aussi ces 100 régions à l'identique. Le paquet fait désormais
1 236 542 octets. Les preuves actuelles sont dans le lien ci-dessus ; les points suivants
conservent le compte rendu historique de la migration peinte.

- Import et **68 captures runtime / 23 scènes** : sortie 0, stderr vide.
- **21 captures éditeur / cinq scènes** : sortie 0. Le processus de capture
  éditeur émet encore des diagnostics natifs de fenêtre/progression et de ressources
  à l'arrêt ; son stderr n'est pas vide. Ce constat était déjà présent en wireframe.
- Inspection des sols, murs, portes, marches, piliers, cœur et torches, ainsi que
  des superpositions. `scene-board.png` utilise des miniatures ; les images
  `*-native.png` sont les captures à l'échelle du jeu.
- La revue indépendante a relevé le risque de transparence à la séparation
  filtrée des portes et deux dépendances manquantes dans la provenance. La garde
  intérieure et les empreintes des helpers géométriques ont été ajoutées.
- La dernière intégration ajoute des contrôles ciblés de masque et d'indépendance
  aux torches ; pas d'APK ni de profilage sur téléphone. Les PointLight2D
  n'ont pas d'ombres calculées ; leur débordement entre murs reste une limite.
  L'éclairage du cœur utilise ses propres images préparées et ne dépend pas
  des PointLight2D. Il ne simule pas l'éclairage ou les ombres des objets mobiles.

## Export isolé

```powershell
node tools/prepare_mobile_export.cjs
$info = Get-Content docs/reference/isometric-review/painted-v1/export-inventory.json -Raw | ConvertFrom-Json
godot --headless --editor --path $info.staging --import
godot --headless --path $info.staging --export-pack 'Android Mobile' "$PWD/artifacts/isometric-painted-kit.zip"
```

La copie isolée évite de modifier l'inventaire de dépendances de l'éditeur ouvert.
Le ZIP produit est un paquet de ressources, pas un APK. Les résultats finaux sont
consignés dans `validation.json`. Aucun commit ou push n'est effectué dans cette étape.

## Correction des raccords et de l'assise

`floor-seams-v2/comparison.png` compare les bandes du sol et la tranche du cœur
avant/après correction. Seuls les pixels de ces deux sprites changent ; les autres
PNG préparés sont identiques. La géométrie et les sources artistiques restent
inchangées. Voir `floor-seams-v2/README.md` pour la cause et la reproduction.
L'export isolé après ces deux corrections faisait **436 713 octets**. L'ajout
ultérieur de l'ombre séparée portait le paquet à **439 528 octets**. Sa version
agrandie v4 faisait **454 207 octets** et la version directionnelle v5
**453 767 octets**. La version courante sélectionne son orientation selon les
placements : voir `heart-shadow-v6/comparison.png`, `placement-comparison.png`
dans ce même dossier et son README. Les métriques d'export sont dans `validation.json`.
