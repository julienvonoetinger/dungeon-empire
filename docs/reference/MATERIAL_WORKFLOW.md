# Matières communes appliquées aux wireframes

## Décision utilisateur — 23 octobre 2026

Après l'essai avec masques, l'utilisateur a approuvé cette méthode et demandé
de la conserver pour que les futurs éléments utilisent les mêmes textures.
La limitation initiale à un seul essai est levée pour la méthode. Le rendu de
cet essai était toutefois trop simple : il faut une peinture plus riche et
plusieurs variantes, cohérentes avec la maquette.

Cette décision autorise les masques et la composition **hors Godot**. Elle
supplante l'ancienne obligation d'une silhouette entièrement issue d'imagegen
pour ce workflow. Elle ne valide pas automatiquement les nouveaux sprites.

## Références et responsabilités

- Style et palette : `assets/dungeon/gloom-kit/reference.png`, la maquette utilisateur.
- Géométrie : wireframes approuvés et calques `wireframe-overlays/`.
- Matières : `assets/dungeon/shared-materials/catalog.json`, fichiers PNG communs.
- Prompts et sorties originales : `shared-materials/generation.json` et `prompts/`.
- Présentation des huit matières : `shared-materials/material-board.png`.

Le générateur crée **la matière**, sans décider de la silhouette, de la perspective,
des briques ou des joints. L'export hors jeu applique la matière dans les faces
exactes. Godot affiche désormais les sprites préparés via le catalogue connecté décrit plus bas.

## Bibliothèque actuelle, apparence à valider

| Famille | Variantes | Usage |
| --- | --- | --- |
| Murs | planes, fissures, layers, pits | Facettes, fissures fines, couches de schiste, petites cavités |
| Sol | calm, fine-crack, worn, marks | Dalles plus douces, détails espacés, héros et objets lisibles |
| Portes | oak, iron | Bois et ferrures communs aux quatre orientations |

Les atlas sont conservés sans modification. Chaque quart des atlas de pierre,
ou moitié de l'atlas bois/métal, est extrait avec une marge intérieure de 8 px
pour exclure la séparation entre échantillons. Ce sont
des matières opaques, pas des silhouettes architecturales détourées.

Réutiliser ces fichiers par identifiant. Ne pas régénérer indépendamment une
palette pour chaque orientation. Le dessus et la façade haute d'une même pierre
emploient le même identifiant. Les orientations reçoivent une valeur lumineuse
cohérente avec la caméra et l'éclairage, via le **profil commun** du catalogue ;
ne pas corriger chaque scène avec une teinte ou un éclairage runtime.

L'export choisit les matières de façon déterministe, utilise majoritairement
des dalles calmes et garde les fissures rares. Chaque rapport enregistre
l'identité de matière de chaque face. Les planches sont dérivées de la même
bibliothèque et du même profil d'éclairage hors jeu.

## Construction et contrôle

1. Garder les dimensions, la caméra, les deux assises et les ancrages existants.
2. Construire les faces et le masque alpha depuis le guide, sans l'ajuster à l'art.
3. Appliquer les matières partagées ; garder les reflets peints à l'intérieur des faces.
4. Reprendre exactement les coordonnées et largeurs des traits architecturaux.
5. Exporter un nouveau PNG versionné, puis superposer le calque magenta immobile.
6. Contrôler alpha, coordonnées et lecture visuelle. La précision géométrique ne
   prouve pas la fidélité artistique, ni les raccords d'un kit complet non assemblé.

La version actuelle n'autorise aucun changement de caméra, de dimensions, de
nombre de rangées ou de placement de joints pour améliorer la texture.

## Reproduction du prototype actuel

Avec Node.js et `sharp`, depuis la racine :

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/prototype_nw_masked_material.cjs --materials-v2
```

Le second script produit `assets/dungeon/gloom-kit/proposals/nw-shared-materials-v2.png`
et `docs/reference/nw-material-review-v2/` : comparaison, avant/après, calques
normal et fin, composition SVG, masques et mesures. Il garde 1216 × 1408 pixels,
ancrage (96,352), pas 1024 ; les 51 traits et le contour alpha correspondent au guide.
Sans option, il reproduit l'ancien essai, conservé comme comparaison historique.

## Export des autres images — 23 octobre 2026

L'utilisateur a demandé de produire les autres images. L'export général couvre
les **146 identifiants de guides isolés**, avec **57 PNG distincts** : 47 formes
de cases, un sol, un pilier, quatre entrées à escalier et quatre portes. Les
guides identiques partagent un fichier par alias ; aucun identifiant n'est perdu.

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
```

- Images et catalogue : `assets/dungeon/painted-cells/`.
- Planches, superpositions magenta et rapports : `docs/reference/painted-kit-review/`.
- Compositeur : `tools/painted_material_renderer.cjs`.
- Export ciblé pour diagnostic : `--only=doors/west,pillar` ; cela ne réécrit pas
  le catalogue global ni les planches. Relancer l'export complet pour les actualiser.

Les images sont rendues à ×4, avec ancrage et pas multipliés uniformément.
Les régions délimitées par les traits fournissent les masques de matière. Les
bords de sol ouverts sans trait ferment leurs masques via le volume d'origine,
sans ajouter d'encre. Pour les portes, une visibilité calculée depuis les
triangles 3D sépare pierre, arche, bois et sol, même si un contact entre volumes
n'a pas de trait d'intersection. Le veinage du bois suit les coordonnées locales
de la porte projetées avec la caméra commune. Aucun miroir de sprite n'est utilisé.

Le contrôle compare les coordonnées/largeurs des traits et l'alpha exporté au
volume projeté indépendamment ; il détecte aussi les trous avant application
du masque final. Le même guide magenta est superposé sans ajustement.

Ces images présentent les extrémités visibles de pièces **isolées**. Elles restent
les références de revue. Les scènes utilisent les variantes connectées ci-dessous.

## Intégration des scènes — 23 octobre 2026

L'utilisateur a demandé de mettre à jour toutes les scènes Godot. L'export
`node tools/export_painted_connected_kit.cjs` prépare 96 PNG structurels
et un sol raccordable dans `assets/dungeon/painted-connected/`, puis génère
`scripts/painted_cell_catalog.gd`. Les 128 identifiants de structure réutilisent
les images identiques par alias ; 16 états ordinaires n'ont pas de murs.

Les guides isolés servent à identifier les régions de matière. Les contours
connectés décident de la visibilité finale et des traits : les faces internes
aux raccords sont retirées hors jeu. Les polygones projetés ont un sens de parcours
commun pour que leur union ne crée aucun trou. Les portes conservent la séparation
pierre/bois par leur volume. Sol à z=0 puis structure à z=1 dans Godot.

Le sol reprend ses 26 traits connectés. Les trois contours de fermeture nécessaires
à la revue isolée ne sont pas ajoutés au PNG connecté. `--floor-only` réexporte
uniquement ce sol, en conservant le catalogue structurel existant ; `--only=doors/west`
reste un export de diagnostic sans réécriture du catalogue global.

Correction du raccord vertical : retirer les traits seuls ne suffisait pas,
car les reflets des bords et les coordonnées de texture repartaient à chaque
case. `wrapFloorX` réunit les fragments gauche/droit de chaque rangée en une
pierre complète périodique. Les deux fragments ont la même matière, le même
placement de texture et la même graine de biseau. La limite de cellule coupe
la peinture hors ligne ; elle n'est jamais traitée comme une arête de pierre.
Le placement du dallage est conservé. Le PNG du sol connecté
est exporté dans le cadre exact de la case : 1024×1024 opaque, ancrage (0,0),
au lieu de 1056×1056 avec une marge transparente de 16 px et un ancrage (16,16).
Cela évite le filet d'alpha créé par le filtrage aux frontières. Le joint nord
de la rangée suivante est répété au bord sud lors de l'export pour conserver
sa largeur complète. `outputFrame` et `repeatInkY` enregistrent cette convention.
Les volumes de murs, portes et escaliers sont conservés ; leurs sols suivent la révision du motif ci-dessous.

Les rapports du catalogue et les calques dans `artifacts/painted-connected/`
contrôlent les traits, l'alpha et la couverture. Les captures Godot contrôlent
l'assemblage. Voir [PAINTED_GODOT.md](PAINTED_GODOT.md). La fidélité artistique
reste à apprécier par l'utilisateur dans les scènes.

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
