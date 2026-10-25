# Migration des scènes en wireframe isométrique — 24 octobre 2026

L'utilisateur a demandé la migration, puis choisi **les wireframes d'abord**.
Les 23 scènes actives utilisent maintenant le catalogue `assets/dungeon/isometric-kit/`.
Les textures peintes, le dessin définitif du cœur et les flammes seront adaptés
après la revue de cette géométrie. Les sources approuvées sont conservées.

## Projection et grille

La projection vient directement de `../wireframe-v1/selection.json` :

```text
screen_x = 256 * (x - y) / 2
screen_y = 256 * ((x + y) / 4 - sqrt(3/8) * z)
```

Une case logique reste un carré 1×1, affiché en losange de 256×128 pixels source,
soit 192×96 à la caméra fixe 0,75. Les petits joints cyan sont le dallage décoratif,
pas les limites des cases logiques. Le déplacement au doigt/souris reste libre,
sans zoom. Les layouts, voisins et couloirs de deux cases de SixRoomPreview
n'ont pas changé.

## Catalogue préparé

| Élément | Sprites |
|---|---:|
| Dallage | 1 |
| Murs : deux axes et quatre terminaisons | 8 |
| Pilier nu | 1 |
| Escaliers : quatre directions | 4 |
| Portes : quatre directions, deux parties chacune | 8 |
| Support schématique du cœur et vortex | 1 |
| Fixations et coupelles de torche : deux orientations | 2 |
| **Total** | **25** |

Atlas : **1024×1024**, **99 844 octets PNG**, **4 Mio RGBA** sans mipmaps.
Ce sont des images de travail, pas une mesure de la taille des futures textures.
Une petite texture de diffusion de lumière historique reste disponible au moteur,
mais aucune lumière n'est créée par ce catalogue de wireframes.

Les volumes des portes v8 sont conservés : grande arche, petite arche, mur lisse
en retrait entre elles, vantail sans joints de bois ni ferrures imposés. Leurs
occultations mutuelles sont calculées hors ligne. La porte complète est ensuite
séparée à la hauteur des murs : bas entre les murs, haut au-dessus. Aucune ligne
de coupe n'est ajoutée. Le nom technique `leaf` désigne maintenant l'ensemble
inférieur, avec ses jambages ; `arch` désigne l'ensemble supérieur. Ce découpage
évite que des arches imbriquées se masquent incorrectement lors du tri des sprites.

Les escaliers réutilisent les cinq marches existantes. Les murs conservent leurs
deux rangées. Le pilier est nu. Les deux torches montrent uniquement les volumes
rigides approuvés ; leur flamme et leur lumière sont réservées à la phase peinte.
Le cœur est le support schématique de l'étude isométrique, **pas une nouvelle
validation artistique** du cœur. L'apparence sculptée approuvée reste la référence.

## Fichiers et reproduction

- `tools/isometric_kit_geometry.cjs` : volumes XYZ, rotations et projection approuvée.
- `tools/wireframe_geometry.cjs` : retrait des arêtes cachées par rayons/triangles.
- `tools/export_isometric_kit.cjs` : PNG avec silhouette opaque, guides transparents,
  atlas et catalogue. L'alpha extérieur reste transparent ; les faces opaques
  cachent les sprites placés derrière sans dessin de géométrie à l'exécution.
- `geometry.json` : volumes, traits visibles, cadres et supports de placement.
- `guides/` : lignes magenta sur fond transparent, même cadre que les sprites.
- `sprites/` : images individuelles avant regroupement dans l'atlas.
- `recipe.json` : projection, dimensions et empreintes des sources utilisées.
- `scripts/mobile_dungeon_renderer.gd` : placement par `grid_to_local`, inverse
  `local_to_grid`, tri des supports et chargement de textures préparées.

```powershell
node tools/export_isometric_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_migration_review.cjs
```

`MobileReference` reste la scène F5. F6 ouvre la scène sélectionnée. Les caméras
enregistrées des scènes ont aussi été repositionnées pour les aperçus de l'éditeur.
Le renderer `@tool` recharge le catalogue et l'atlas après réimport. Le bouton
« Actualiser le rendu » reste disponible. Le cache de l'éditeur n'a pas été réinitialisé.

Les anciens `export_mobile_kit.cjs` et outils de revue peinte sont historiques.
Ils ne reconstruisent pas ce catalogue isométrique. Ne pas écraser leurs sélections,
sources ou captures approuvées pour les faire correspondre à la nouvelle caméra.

## Revue visuelle réalisée

- Import Godot : sortie 0, stderr vide.
- **68 captures des 23 scènes**, dont les quatre portes, les quatre escaliers,
  le cœur isolé et les deux supports de torche : sortie 0, stderr vide.
- Inspection des vues de référence, portes, escaliers, raccords, salles et couloirs.
- **21 captures éditeur sur cinq scènes**, sortie 0. Les images de référence
  et des portes ont été inspectées. Le processus de capture éditeur émet des
  diagnostics natifs de fenêtre/progression et de ressources à l'arrêt ; son
  stderr n'est donc pas vide. Ces diagnostics sont conservés dans `logs/`.
- La revue de code indépendante a relevé le cadrage éditeur ancien de
  SingleCellRoom. Il est corrigé et son nouvel aperçu a été inspecté. Aucun
  problème critique ou important n'a été signalé par cette revue.
- `scene-board.png` est une planche réduite ; `captures/*-native.png` garde
  les pixels du jeu à la caméra 0,75. Les vues `overview` cadrent tout le plan et
  ne représentent pas la distance de jeu.
- Aucun test automatisé ni profilage sur téléphone effectué. Les collisions,
  le déplacement des personnages et les interactions de sélection ne sont pas
  implémentés par cette migration visuelle ; l'inverse de projection est disponible
  pour leur future utilisation.

## Export

Le preset Android Mobile référence les **45 dépendances des 23 scènes**, avec
un seul atlas architectural actif. L'ancien atlas peint et les sources d'auteur
ne font pas partie du paquet. Préparer un cache d'export séparé :

```powershell
node tools/prepare_mobile_export.cjs
$info = Get-Content docs/reference/isometric-review/migration-v1/export-inventory.json -Raw | ConvertFrom-Json
godot --headless --editor --path $info.staging --import
godot --headless --path $info.staging --export-pack 'Android Mobile' "$PWD/artifacts/isometric-kit.zip"
```

Import de la copie, export et ouverture du paquet : sortie 0, stderr vide.
Le paquet de revue occupe **138 791 octets**. C'est un ZIP de ressources,
pas un APK ni une mesure de performance mobile. Aucun commit/push demandé.
