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

- Style et palette actifs : `assets/dungeon/shared-materials/stylized-reference.png`,
  la maquette utilisateur jointe lors de la correction de style.
- Géométrie : wireframes approuvés et calques `wireframe-overlays/`.
- Matières : `assets/dungeon/shared-materials/catalog.json`, fichiers PNG communs.
- Prompts et sorties originales : `shared-materials/generation.json` et `prompts/`.
- Présentation des dix matières : `shared-materials/material-board.png`.

Le générateur crée **la matière**, sans décider de la silhouette, de la perspective,
des briques ou des joints. L'export hors jeu applique la matière dans les faces
exactes. Godot affiche désormais les sprites préparés via le catalogue connecté décrit plus bas.

## Peindre les pierres entières aux raccords

Le compositeur connecté réunit les guides d'un voisinage local avant de peindre
les faces. Une pierre traversant une frontière de case garde la même matière,
les mêmes coordonnées de texture, le même arrondi B et les mêmes reflets. Les
PNG des cases sont découpés ensuite, avec une garde de filtrage uniquement dans
le volume opaque commun. Les traits cachés derrière une pièce voisine sont
retirés avant la subdivision en faces ; une marche derrière une arche ne doit
pas devenir un joint peint sur cette arche.

Voir `PAINTED_GODOT.md` pour l'inventaire des voisinages spéciaux, le catalogue
actif, les commandes et les limites. Godot sélectionne des PNG déjà préparés.

## Bibliothèque active et historique des revues

### Variantes A/B/C et D2 — intégration autorisée

Après son choix D2, l'utilisateur a dit « Go ». Les textures et le dépliage D2
sont promus dans la recette active. Les exports connectés produisent quatre
styles complets, puis Godot choisit un PNG stable selon la case, avec des D2
espacées. Les pierres partagées aux raccords gardent une peinture commune.
Voir [WALL_VARIATIONS.md](WALL_VARIATIONS.md) pour les règles et la reproduction.
Cette section supplante les anciennes restrictions de proposition seule ci-dessous.

### Correction de la corruption D — D2 retenue

L'utilisateur a sélectionné **D2**. Employer `corruption-v2-1` et le dépliage
continu de la pierre. `wall-corruption-review-v2/selection.json` conserve la
décision et les empreintes des images retenues. D1 et le coin D1 restent des
comparaisons historiques ; la propagation D2 dans Godot reste à réaliser.

L'utilisateur rejette D car le motif est dupliqué. La cause est le placement
de texture recalculé indépendamment pour le dessus et la façade, malgré leur
matière commune. `wall-corruption-review-v2/comparison.png` montre la correction
D1 et une autre veine D2, ainsi qu'un assemblage avec des accents espacés.

`tools/prepare_wall_corruption_review.cjs` déroule une seule zone de matière
autour de la pierre. Les coordonnées coïncident au pli ; la façade montre la
suite du motif. L'éclairage par face et les raccords entre cases restent fixes.
L'option `face.textureTransform` du compositeur sert uniquement à cette revue.
Les PNG actifs dans Godot ne sont pas remplacés. Voir le README de la revue,
le coin avec overlay et les matrices enregistrées dans ses rapports.

### Variantes des murs — proposition du 23 octobre 2026

Après le sol, l'utilisateur demande de réduire la répétition des murs.
`wall-variation-review/comparison.png` montre quatre variantes complémentaires
(calme, usée, ébréchée, corruption violette), des sprites distincts assemblés
horizontalement et leur comparaison avec les murs actifs. Le dossier contient
aussi le mur vertical, le coin NW avec son overlay et un raccord B/A agrandi.

Reproduction : `node tools/prepare_wall_variants_review.cjs` avec sharp disponible.
Le script reprend l'atlas généré existant de `material-variation-review/`, avec
trois découpes supplémentaires consignées dans la recette. Les pierres qui
touchent une frontière de case utilisent une matière calme commune ; les
autres changent selon la variante. Le compositeur peint les pierres entières
avant découpage, dans la géométrie et la finition B existantes.

Cette proposition désactive le petit trait violet procédural et conserve le
sol approuvé. Huit variantes droites et un coin sont présentés ; la famille
complète de contextes, portes et escaliers n'est pas encore déclinée.
La palette des murs actifs et les scènes Godot restent à leur état précédent
jusqu'à validation de cette proposition. Voir son README et ses rapports.

### Sol lisse aux coins arrondis approuvé et intégré — 23 octobre 2026

L'utilisateur a validé le sol lisse puis l'arrondi pour intégration dans Godot.
La recette active conserve murs, bois et métal et sélectionne les matières
6, 2, 4 et 3 de `shared-materials/floor-smooth-atlas-v1.png`. Les huit
échantillons restent dans l'atlas ; quatre servent aux quatre pierres entières
périodiques C. Les IDs historiques de sol sont conservés.

`active-recipe.json` conserve découpes et empreintes, opacité .55,
`floorPattern` et `floorFinish` (rayon 10.5 avant facteur .63). Les murs et
les marches gardent B ; les marches prennent la palette douce. La grille,
le motif C et la projection restent fixes. La promotion initiale est conservée
dans `tools/promote_smooth_floor_materials.cjs`. Reproduction : PAINTED_GODOT.md.

Les sections de revue suivantes sont historiques. Les murs variés proposés
restent distincts de la validation du sol.

### Variété des matières sur le dallage C — proposition en attente

L'utilisateur accepte désormais le sol lisse et demande des coins arrondis.
`material-variation-review/rounded-smooth-c-comparison.png` montre cette finition
sur le même coin avec overlay ; `rounded-smooth-floor-detail.png` agrandit les
joints. Le rayon proposé est 10.5 avant facteur sol .63 ; seul ce paramètre
change. Les murs gardent B et la recette active reste intacte. Reproduire avec
`node tools/prepare_rounded_smooth_floor_c_review.cjs`. Le profil complet est dans
`rounded-smooth-floor-recipe.json`. Cet arrondi attend une validation visuelle.

Dernière correction demandée : rendre les dalles plus lisses et discrètes pour
laisser ressortir les objets. `material-variation-review/smooth-c-comparison.png`
montre cette révision sur le coin NW avec overlay ; `smooth-floor-comparison.png`
compare les sols sur 3×3 cases. Huit matières douces viennent de
`proposals/variation-review/floor-smooth-v1.png`, composées avec une opacité .55.
Les murs proposés, le dallage C et la finition B restent fixes. Reproduire avec
`node tools/prepare_smooth_floor_c_review.cjs` ; provenance et recette dans
`smooth-floor-generation.json` et `smooth-floor-recipe.json`. Cette révision reste
en attente d'approbation visuelle et n'a pas remplacé les matières actives.

Après validation des grandes dalles C, l'étude
`material-variation-review/corner-c-comparison.png` applique la bibliothèque
proposée de huit murs/huit sols au coin NW actuel. Le troisième panneau porte
les lignes magenta. `appearance-c-comparison.png` présente un mur long et un sol
3×3 pour juger la répétition. Reproduire avec
`node tools/prepare_material_variety_c_review.cjs`.

Les matières viennent de `proposals/variation-review/atlas-calm.png`, déjà généré
à partir de la référence stylisée. La petite branche violette ajoutée par code
est retirée dans ces aperçus. Les accents restants viennent des crevasses peintes.
Le dallage C, la projection et la finition B restent fixes. La gamme active
ci-dessous n'est pas encore remplacée ; la recette et les rapports du nouvel
aperçu sont conservés dans `appearance-c-recipe.json`.

### Gamme stylisée approuvée et active — 23 octobre 2026

L'utilisateur a accepté le dernier aperçu : **« oui utilise cette nouvelle gamme
de texture »**. Les matières de `stylized-material-review/` deviennent la gamme
commune des cases, sols, piliers, escaliers et portes. Les trois pistes réalistes
précédentes et le bois vieilli intermédiaire restent des essais historiques.

`assets/dungeon/shared-materials/active-recipe.json` conserve les découpes exactes,
les empreintes des pixels approuvés et les profils de composition. La source active
est `stylized-atlas-v2.png` ; `stylized-reference.png` est la copie de la maquette
utilisateur employée pour cette génération. Les identifiants de matière restent
stables. Trois découpes de pierre simple et une de pierre corrompue fournissent les
quatre murs ; quatre découpes du même sol calme et le bois simplifié complètent
la gamme. Le métal reste celui de l'aperçu accepté.

Préparation et export de la gamme active :

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
godot --headless --path . --script res://tools/export_painted_scene_contexts.gd
node tools/export_painted_connected_kit.cjs
```

La préparation utilise cette recette par défaut, contrôle ses empreintes et
recalcule les métadonnées de provenance et de couleur. Elle ne revient plus aux
anciens atlas réalistes. Les images isolées, les structures connectées et le sol
raccordable utilisent la même bibliothèque. La correction des raccords modifie
les masques individuels aux interfaces pour protéger le filtrage ; la géométrie,
la projection, le dallage périodique et les paramètres de placement restent fixes.

### Correction : retrouver le dessin stylisé de la maquette

L'utilisateur précise que les propositions A/B/C sont trop réalistes. Leur
grain, les multiples éclats minéraux et le bois ressemblant à de l'écorce
s'éloignent du dessin d'origine. Elles restent des essais rejetés comme
références de style, même si leur géométrie est correcte.

Le nouvel essai `stylized-material-review/comparison.png` emploie de grandes
facettes peintes, quelques marques d'usure franches, un veinage simplifié et
des accents violets localisés. La maquette jointe par l'utilisateur est la seule
référence artistique de cette génération ; sa copie exacte, le prompt et
l'original généré sont référencés dans `stylized-material-review/generation.json`.

Les quatre surfaces de l'atlas sont pierre simple, pierre corrompue, sol calme
et bois. Le fer et la construction des contours/biseaux restent ceux du
compositeur existant. Cette proposition porte sur les matières ; elle conserve
les masques, joints, caméra et ancrages. Les deux sorties et leurs superpositions
magenta sont reproduites par `node tools/prepare_stylized_material_review.cjs`.
Cet aperçu a ensuite été approuvé pour l'intégration décrite ci-dessus.

### Trois pistes de corruption — 23 octobre 2026

L'utilisateur juge l'ensemble trop lisse et propre et demande plusieurs variantes.
La comparaison `corruption-material-review/comparison.png` présente l'art actuel
puis trois propositions, sur les mêmes masques de coin NW et de porte nord :

- **A — Crypte humide** : pierre rongée, taches sombres, bois dégradé, violet discret.
- **B — Pierre maudite** : éclats et fissures avec des foyers d'énergie violette.
- **C — Corruption organique** : racines noires incrustées, fines traces violettes.

Les trois atlas générés avec imagegen contiennent chacun pierre de mur, pierre
de sol, bois et fer. Des prélèvements rectangulaires différents dans chaque
surface varient les pierres sans inverser leur éclairage. Les profils de
composition sont communs aux trois propositions. Aucun fichier actif dans
Godot n'est remplacé : le choix artistique reste à faire.

Sources : `assets/dungeon/shared-materials/proposals/corruption/` ; prompts,
originaux et recettes : `docs/reference/corruption-material-review/`.
Reproduction : exécuter `node tools/prepare_corruption_material_review.cjs`
avec `--variant=01-humide`, `--variant=02-fissures`, puis `--variant=03-racines`
dans des processus séparés ; sans option, la commande assemble la comparaison.
Les six sorties conservent les traits et l'alpha du modèle. Ce contrôle ne
valide ni l'apparence finale ni la continuité de futurs ornements entre cases.

### Proposition de bois de porte — 23 octobre 2026

L'utilisateur signale que les textures des portes s'intègrent mal au donjon.
Le bois actuel présente une dominante orange et un grain très contrasté.
`docs/reference/door-material-review-v2/comparison.png` propose un bois brun grisé
plus calme, appliqué aux mêmes masques, avec les pierres, ferrures et sols actuels.
Cette apparence attend la revue utilisateur ; les PNG utilisés dans Godot et le
catalogue actif restent ceux du commit `ddb80ce`.

La source générée avec l'outil intégré imagegen est conservée dans
`shared-materials/proposals/door-oak-v2.png`. Le prompt exact et le profil de
composition sont dans `door-material-review-v2/prompt.txt` et `recipe.json`.
`node tools/prepare_door_material_review.cjs` reproduit les quatre aperçus
connectés, leurs superpositions magenta et la comparaison en couloir.
Le nouveau bois est commun aux quatre orientations ; aucune géométrie ne change.

### Catalogue actif

| Famille | Variantes | Usage |
| --- | --- | --- |
| Murs | planes, fissures, layers, pits | Trois prélèvements de pierre peinte simple et un de pierre corrompue violette |
| Sol | calm, fine-crack, worn, marks | Quatre prélèvements du sol peint calme, avec quelques marques graphiques |
| Portes | oak, iron | Bois stylisé et fer conservé, communs aux quatre orientations |

Les atlas sources sont conservés sans modification. Les rectangles exacts de
`active-recipe.json` sélectionnent les matières approuvées : ils ne correspondent
pas tous à un quart entier. Les coordonnées, tailles et empreintes doivent rester
identiques à cette recette. Les noms historiques `layers`, `pits` et `fine-crack`
sont conservés pour les références ; ils n'imposent pas des détails réalistes.
Ces prélèvements sont des matières opaques, pas des silhouettes architecturales.

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
`node tools/export_painted_connected_kit.cjs` prépare les PNG structurels et un
sol raccordable dans `assets/dungeon/painted-connected/`, puis génère
`scripts/painted_cell_catalog.gd`. Le catalogue courant et ses nombres de
contextes/images sont décrits dans `PAINTED_GODOT.md`.

Les guides connectés voisins servent à identifier les pierres entières. La
visibilité finale masque les traits cachés par les volumes voisins ; les faces
internes aux raccords sont retirées hors jeu. Les polygones projetés ont un sens de parcours
commun pour que leur union ne crée aucun trou. Les portes conservent la séparation
pierre/bois par leur volume. Sol à z=0 puis structure à z=1 dans Godot.

Le sol reprend ses 26 traits connectés. Les trois contours de fermeture nécessaires
à la revue isolée ne sont pas ajoutés au PNG connecté. `--floor-only` réexporte
uniquement ce sol, en conservant le catalogue structurel existant. Le diagnostic
`--only=doors/west` est réservé à l’exporteur isolé, sans réécriture de son catalogue.

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
