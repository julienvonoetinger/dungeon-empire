# Kit d’architecture mobile — 24 octobre 2026

La demande « terminer l’optimisation avec le reste du kit » autorise la migration
du prototype vers les 21 scènes d’architecture. Le cœur sculpté validé est
désormais intégré au même atlas et aux aperçus concernés. La torche reste séparée.

## Assets actifs

`assets/dungeon/mobile-kit/atlas-256.png` contient **48 sprites**, avec la
[porte approuvée](../mobile-door-frame-review/integration/) et le
[cœur sculpté](../mobile-heart-review/ritual-v3/integration/) :

| Élément | Nombre |
| --- | ---: |
| Sol périodique commun | 1 |
| Mur horizontal / vertical, quatre combinaisons d’extrémités | 8 |
| Pilier nu | 1 |
| Dessus creusé optionnel, séparé | 1 |
| Porte : huit composants préparés, quatre orientations | 32 |
| Escalier complet, quatre orientations | 4 |
| Cœur sculpté avec vortex, sprite complet | 1 |

`catalog.tres` contient les AtlasTexture, régions, ancrages et volumes de support.
Les subresources référencent toutes le même atlas, avec extrusion de 4 pixels
et `filter_clip`. Le JSON et `recipe.json` documentent l’export ; le jeu charge
le Resource préparé, sans lire les matières ni les anciens catalogues.

- Atlas : **1024 × 2048**, PNG **974 698 octets** (951,9 Kio).
- RGBA sans compression GPU, sans mipmaps : **8 Mio** pour l’atlas complet.
- Résolution : **256 px par case 1×1**, affichage à **192 px/case** dans la vue
  logique 1280×720. Zoom constant 0,75 ; déplacement au doigt ou souris gauche.
- Paquet de ressources Godot mesuré : **705 339 octets** (688,8 Kio), scènes et scripts
  compris, hors exécutable/moteur Android, APK, signature et bibliothèques natives.
  Le relevé exact et les fichiers exportés figurent dans `package-report.json`.

Ancien catalogue complet : 2 901 PNG connectés, 1 704 405 576 octets ; 57 PNG
isolés, 40 159 996 octets. Ces familles incluaient les variations A/B/C/D2 et de
nombreux contextes. Leurs fichiers générés ont été supprimés après la migration ;
les versions suivies restent récupérables dans Git. Les chiffres de comparaison
sont figés dans `legacy-catalog-inventory.json`, afin que l’export mobile ne
dépende plus de la présence des anciens PNG. Matières, géométries et références
d’auteur restent conservées. Voir [le nettoyage](../../cleanup/README.md).
Leur volume cumulé n’était pas la VRAM simultanément utilisée : l’ancien système
chargeait les contextes à la demande. Ne pas présenter cette somme comme un
gain de mémoire mesuré en jeu.

## Construction et raccords

- Projection parallèle inchangée : `(x − 0,18z, y − 0,9z)`, grille entière 1×1.
- Épaisseur du mur 1/6 case, hauteur 1,88/6, deux assises de façade. Les murs
  mobiles sont centrés sur les frontières de cases. Le dessus appartient à
  l’assise supérieure. Les piliers de largeur 0,24 terminent les murs aux virages.
- Les huit murs sont déjà coupés pour toucher les piliers. Pas de calcul de
  longueur de brique, de matière, de pixels ou de déformation dans Godot.
- Les marches réutilisent les cinq hauteurs de la source. Leur largeur et le
  départ rejoignent les nouvelles faces intérieures des murs à T/2 de la grille.
  Leurs pièces de construction sont fusionnées hors ligne en un sprite par sens.
- La porte garde exactement sa grande arche, portant sur les murs. Elle contient
  désormais une petite arche et un mur lisse entre les deux, en retrait sur les
  deux faces (épaisseur 0,8T). Le bois réduit a un véritable sommet arqué, des
  ferrures en retrait et une poignée sur chaque face. Géométrie v8 et apparence
  `painted-art-v2` sont approuvées. Les quatre vues sont reprojetées depuis le
  modèle, jamais des rotations du bitmap.
- Chaque porte utilise huit composants préparés : grande arche, vantail, petite
  arche, deux montants et trois parties de mur lisse. L’entrée du vantail dans le
  catalogue déclare les six éléments ajoutés via `companions`. Le renderer place
  leurs textures et ordonne leurs volumes de support avec les murs, sans produire
  de pixels. Le dessus décoratif suit son pilier pour rester occultable.
- Les trois rangées de sol sont peintes comme des pierres périodiques entières
  avant recadrage. La grille logique ne devient pas un joint ou un biseau.

La matière calme du prototype est commune aux orientations. Les A/B/C/D2 peints
dans des familles complètes ne sont plus utilisés. Les futurs décors devront être
des sprites séparés. Le dessus creusé est activable dans l’inspecteur ; cette
migration ne transforme pas la proposition en validation artistique définitive.

## Scènes et éditeur

`wireframe_cell_study.gd` conserve ses paramètres et ses règles de grille, puis
transmet le plan à `mobile_dungeon_renderer.gd`. Les layouts n’ont pas été changés.
SixRoomPreview garde ses 256 cases et ses couloirs larges. EntranceVariants est
une planche de quatre cases utilisant les mêmes éléments que les salles.

Le cœur est présent dans MobileReference, SixRoomPreview et DungeonPreview.
Les centres au sol sont réglables via `Dungeon → Heart Positions`, en unités de
case. L’emprise complète doit rester sur le sol et hors des portes/escaliers.
`DungeonHeart.tscn` reste disponible comme prop autonome avec le même atlas.
Son sprite complet mesure 289 × 289 pixels source, pour un socle d’environ
156 pixels affichés à la distance de jeu. Il partage l’ordre des murs et piliers.

F5 ouvre MobileReference. F6 lance la scène active. La caméra ne réduit plus
automatiquement le donjon pour le montrer en entier : déplacer la vue pour
explorer les grandes scènes. Les captures `*-overview` utilisent temporairement
un cadrage d’inspection dans l’outil seulement.

Sélectionner **Dungeon → Actualiser le rendu** après un export. Le renderer
recharge ensemble la définition et l’atlas, attend la fin de l’import et écoute
les réimports. Il se réabonne en revenant sur une scène et conserve les réglages.
Les anciens sprites générés directs sont retirés lors d’un changement de renderer,
sans toucher aux nœuds appartenant à la scène. MobileReference a maintenant le
même nœud Dungeon que les autres scènes ; accepter le rechargement du fichier de
scène si Godot le signale. Aucun redémarrage forcé de l’éditeur n’est effectué.

## Reproduction

Avec Node + `sharp` et Godot accessibles :

```powershell
node tools/export_mobile_kit.cjs
godot --headless --editor --path . --import
godot --path . --script res://tools/capture_mobile_kit.gd
node tools/prepare_mobile_kit_review.cjs
```

Le pipeline commun est `prepare_mobile_reference.cjs` (primitives et packing),
`mobile_special_parts.cjs` (arches originales/escaliers), `mobile_approved_doors.cjs`
(promotion des portes v8/art-v2), `mobile_pillar_cap.cjs` (dessus) et
`mobile_approved_heart.cjs` (sprite complet approuvé).
La promotion vérifie les empreintes approuvées et refuse une différence de
pixels ou de placement des pièces ajoutées. La grande arche est comparée à
l’atlas initial au même stade de composition alpha. L’apparence v2 est choisie
explicitement, indépendamment des options CLI des anciens outils de revue.
`recipe.json` enregistre les empreintes des sources, profils et audits de masques.
`guides/`, `overlays/`, `sprites/` contiennent les sorties de contrôle, exclues du
jeu. Les guides d’escalier fusionnés masquent les traits derrière les marches.

L’ancien `prepare_mobile_reference.cjs` exécuté directement reconstruit seulement
le prototype historique à deux densités. Il ne met pas à jour le kit actif.
`capture_mobile_reference.gd` est désormais un raccourci de la capture actuelle.

### Paquet mobile sans sources historiques

Le preset **Android Mobile** exporte explicitement les 42 dépendances actives des
22 scènes, dont DungeonHeart. Les scripts hérités, le catalogue et le PNG y figurent.
Pour éviter les anciennes dépendances conservées dans le cache d’un éditeur déjà
ouvert, préparer une copie limitée avec un cache neuf :

```powershell
node tools/prepare_mobile_export.cjs
$info = Get-Content docs/reference/mobile-kit/export-inventory.json -Raw | ConvertFrom-Json
godot --headless --editor --path $info.staging --import
godot --headless --path $info.staging --export-pack 'Android Mobile' "$PWD/artifacts/mobile-kit.zip"
```

La copie est sous `artifacts/`, ignorée et reproductible ; elle ne modifie pas le
cache ni les scènes non sauvegardées de l’éditeur de l’utilisateur. Le ZIP est
un paquet de ressources, pas un APK installable. Une future génération d’APK
nécessitera les outils Android et la configuration de signature habituels.

## Revue et limites

- Export des images, import Godot, 60 captures de 21 scènes et export du paquet :
  codes de sortie 0 ; stderr de l’import, des captures en jeu et de l’export vide.
- Paquet ouvert avec Godot : sortie 0, stderr vide. Son inventaire contient un
  seul `.ctex` et aucune ancienne famille de textures.
- Deux planches de scènes inspectées, plus vues natives MobileReference,
  portes des quatre sens, escaliers, ReferenceCalibration et SixRoomPreview.
- Nouvelle capture éditeur de WireframeDoorCross, ReferenceCalibration et
  MobileReference : 13 images, dont les sept vues centrées sur les portes et
  escaliers identiques au jeu. MobileReference natif est aussi identique. Les
  vues natives des deux autres scènes conservent la caméra d’édition à zoom 1,
  alors que leur script non `@tool` initialise la caméra du jeu à 0,75 ; ces deux
  images ne sont donc pas identiques. Les vues centrées imposent le même cadrage.
  Le processus de capture éditeur sort avec code 0 mais signale des erreurs
  natives d’écran/fenêtre et de nettoyage des ressources ; son stderr n’est pas
  vide. Ces diagnostics sont conservés dans la revue d’intégration.
- Revue indépendante de cette intégration : aucun problème de code actionnable
  identifié. Les catalogues de revue historiques, sans `companions`, restent
  compatibles. Les 28 composants approuvés et les 19 sprites conservés ont été
  comparés à leurs références dans l’atlas final ; pixels et placement identiques.
- Aucun test automatisé ajouté ou lancé. Pas de mesure FPS, mémoire GPU réelle,
  consommation, installation Android ou qualité sur appareil. Les raccords de
  toutes les configurations futures arbitraires restent à examiner.
