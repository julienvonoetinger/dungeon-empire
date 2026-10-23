# Case porte — proposition en wireframe

## État de la revue

**Choix visuel plus récent :** l'utilisateur préfère la porte en bois dans un
cadre de pierre **voûté**, montrée dans l'exemple peint inspiré de la maquette.
Il demande de supprimer les torches et leurs emplacements latéraux, pour garder
un couloir compact d'une seule case. Sa dernière correction précise que
**l'arche part directement des murs gauche et droit** : les montants ajoutés
à l'intérieur du passage sont supprimés et les murs eux-mêmes portent la voûte.
L'utilisateur a ensuite demandé d'en faire le wireframe. La proposition actuelle
est `door-arch-cell-west-east-wireframe.svg` ; ses dimensions attendent sa revue.
L'exemple peint resserré fournit la forme et le style, sans modifier la caméra
commune ou la taille de case. Cette première étape ne modifiait pas les scènes.

L'utilisateur a ensuite demandé les **trois autres orientations**. Les quatre
vues sont préparées par `export_arched_door_orientations.cjs` et présentées dans
`door-arch-four-orientations.svg`. Cette demande concerne les variantes en
wireframe. Il a ensuite autorisé leur intégration dans une nouvelle scène en « + ».

**Dernière correction : porte à double face.** Le bouton/anneau doit exister
des deux côtés, avec les ferrures et les divisions de planches. L'utilisateur
signale aussi que le vantail paraît absent à l'ouest. L'ancien modèle plaçait
son revers trop profondément dans le cadre : recul arrière .11666667 contre
.025 à l'avant. Il était masqué par la voûte dans cette vue presque de profil.
Le vantail occupe désormais le centre du cadre, avec le même recul .025 de
chaque côté. Sa face avant reste à sa position précédente.

## Proposition actuelle : porte voûtée

L'exporteur `tools/export_arched_door_cell_wireframe.cjs` prépare :

- `docs/reference/door-arch-cell-west-east-wireframe.svg` : dessin en lignes.
- `docs/reference/door-arch-cell-west-east-wireframe.json` : paramètres,
  volumes d'occultation, segments 3D et chemins projetés.
- `docs/reference/door-arch-cell-west-east-wireframe.png` : aperçu navigateur.

La case reste 1 × 1, les murs à x = 0..1/6 et x = 5/6..1, sur toute la longueur
y = 0..1. Ils gardent leur hauteur H = 1.88/6 et leur joint à J = .94/6.
La projection est toujours (x − .18z, y − .9z). Le motif normalisé de 19 dalles
reste au sol à z = 0. Les sources sont les mêmes que pour la première proposition.

| Partie proposée | Dimension en unités de case |
| --- | --- |
| Centre du cadre | x = .5, y = .5 |
| Profondeur | 1/6 ; y = .41666667.. .58333333 |
| Appuis | dessus des murs existants : x = 0..1/6 et x = 5/6..1, sur la profondeur du cadre |
| Départ de la voûte | z = H = .31333333 |
| Épaisseur de la voûte | 1/6, comme les murs |
| Rayon extérieur | .5 |
| Rayon intérieur | 1/3 |
| Largeur libre | 2/3, toute la largeur entre les murs |
| Sommet extérieur | z = .81333333 |
| Sommet de la porte | z = .64666667 |
| Pierres de la voûte | 7 secteurs identiques, dont une pierre centrée au sommet |
| Vantail | y = .44166667.. .55833333 ; épaisseur .11666667 ; recul .025 de chaque côté |
| Quincaillerie | un anneau et deux ferrures sur chacune des deux faces |

**La voûte dépasse les murs bas.** Ce choix proposé permet de retrouver une porte
verticale arrondie avec les proportions de l'exemple. Il ne rajoute aucune assise
aux murs latéraux et ne change pas l'emprise carrée. La voûte repose sur toute
l'épaisseur des murs gauche et droit ; aucun montant indépendant n'empiète dans
le passage. La porte s'élargit jusqu'aux faces intérieures de ces murs.

La voûte est un demi-anneau extrudé suivant Y. Chacune de ses sept pierres est
subdivisée en huit secteurs convexes pour calculer la courbe et sa visibilité.
Les subdivisions de calcul ne sont pas dessinées : seules les limites entre
les pierres sont visibles. Le contour apparent à la tangente de la caméra est
également dessiné à travers la profondeur, pour fermer correctement la silhouette.

Le vantail suit le même profil intérieur arrondi. Les planches s'arrêtent sur ce
profil exact ; les deux ferrures et l'anneau de chaque côté restent dans le
plan de leur face. Les deux poignées partagent les mêmes coordonnées x/z,
comme les extrémités d'un même axe, sans déplacement selon la caméra.
Les joints des planches s'interrompent derrière les ferrures. Tous les éléments
sont construits en coordonnées 3D puis projetés avec la même formule.

L'occultation utilise les profils convexes extrudés des murs, de la voûte et
du vantail fermé, avec le rayon (.18, .9, 1). Ne pas remplacer la
voûte par une boîte opaque : cela masquerait à tort son ouverture arrondie.
Les arêtes internes des appuis entre le dessus des murs et les pieds de la voûte
sont omises. Les joints de pierres sur les faces avant et arrière sont conservés.

Cette révision est identifiée `door-arch-cell-west-east-wireframe-v3-double-sided`
dans le JSON. La v2 apportait les appuis directs sur les murs, mais son vantail
de .025 d'épaisseur était décentré et n'avait des ferrures qu'à l'avant.
La première voûte avait des montants de .075 dans le passage et un
rayon extérieur de 1/3 : ces dimensions sont remplacées par les appuis sur murs.

Reproduire le SVG et le JSON depuis la racine :

```powershell
node tools/export_arched_door_cell_wireframe.cjs
```

Pour la présentation inline, avec le même modèle de présentation que la première
proposition :

```powershell
node tools/export_arched_door_cell_wireframe.cjs --inline "C:/chemin/du/fil/porte-voutee-wireframe.html"
```

Le PNG est une capture du SVG à sa taille native de 696 × 834. Actualiser cet
aperçu après chaque modification. Cette proposition est destinée à la revue
de forme et de proportions ; elle ne constitue pas encore une image du catalogue
Godot, ni une implémentation d'ouverture de porte.

## Quatre orientations avec une caméra fixe

Les directions indiquent la normale de la **face avant de référence**. Les deux
faces portent désormais ferrures et anneau. La référence regarde vers le sud. Les
transformations suivantes s'appliquent aux coordonnées du monde, avant la
projection commune ; elles ne tournent jamais l'image projetée.

| Direction | Transformation depuis la source | Murs | Face visible depuis la caméra |
| --- | --- | --- | --- |
| Nord | (1−x, 1−y, z) | Ouest et est | Arrière |
| Est | (y, 1−x, z) | Nord et sud | Avant, presque de profil |
| Sud | (x, y, z) | Ouest et est | Avant ; référence |
| Ouest | (1−y, x, z) | Nord et sud | Arrière, presque de profil |

Les appuis, la voûte, les murs, l'épaisseur et le recul du vantail sont conservés.
Les quatre images utilisent le même cadrage et la même échelle. La hauteur
projetée des arches latérales demande un cadrage plus haut que celui de la seule
source sud ; il est calculé depuis les bornes des quatre orientations.

Le dallage est reconstruit depuis le motif normalisé existant **dans les axes du
monde**, puis limité aux pieds des murs correspondants. Il ne tourne pas avec la
porte. Les deux faces complètes sont produites par l'exporteur source ; celui
des orientations n'ajoute plus une version partielle du revers. Les détails
restent soumis à l'occultation physique. À l'ouest, les planches et le vantail
sont visibles, mais l'anneau proche du bord est caché par la voûte avec cette
caméra. Ne pas dessiner cet anneau par-dessus la pierre pour le faire apparaître.
Le vantail est un seul volume fermé, pas deux portes superposées.

La visibilité est recalculée pour chaque direction : le point du monde et le
rayon de caméra sont ramenés dans les coordonnées locales des prismes convexes.
L'intersection avec la profondeur tient compte des deux signes possibles du
rayon. Le contour apparent de la voûte est recalculé avec ce rayon local. Les
segments `role: apparent-contour` de la source sont donc exclus, puis remplacés
par ceux de la nouvelle vue. Ne jamais simplement tourner les segments déjà
visibles ni conserver le contour apparent de la caméra précédente.

Fichiers produits :

- `door-arch-facing-north-wireframe.svg` et JSON/PNG.
- `door-arch-facing-east-wireframe.svg` et JSON/PNG.
- `door-arch-facing-south-wireframe.svg` et JSON/PNG, pour comparaison.
- `door-arch-facing-west-wireframe.svg` et JSON/PNG.
- `door-arch-four-orientations.svg` et JSON/PNG : planche d'ensemble.
- `door-orientations-preview.template.html` : présentation inline avec choix
  d'une orientation pour l'agrandir.

Commandes de reproduction, depuis la racine :

```powershell
node tools/export_arched_door_cell_wireframe.cjs
node tools/export_arched_door_orientations.cjs
```

Pour la présentation inline :

```powershell
node tools/export_arched_door_orientations.cjs --inline "C:/chemin/du/fil/portes-quatre-orientations-wireframe.html"
```

Les exporteurs écrivent les SVG et JSON. Capturer ensuite les SVG au navigateur
pour actualiser les PNG : variantes 687 × 921, planche 840 × 1240. Les dimensions
des variantes sont aussi enregistrées dans `previewSize`. L'angle très étroit
des portes est/ouest est la conséquence de la caméra retenue ; ces vues ne
changent pas de perspective pour rendre artificiellement la porte de face.

## Intégration Godot : croisement avec quatre portes

La scène `scenes/WireframeDoorCross.tscn` réutilise `wireframe_cell_study.gd` et
le layout `single_cell.tres`. Une case centrale et quatre branches de longueur
3, fermées aux bouts, forment une croix de **13 cases**. Le centre reçoit les
quatre piliers du catalogue. Les portes se trouvent dans la deuxième case de
chaque branche : nord (0,−2), est (2,0), sud (0,2), ouest (−2,0). Les noms
indiquent toujours la normale avant de référence, ici dirigée vers l'extérieur.

Le nouveau réglage `door_cells` associe une case entière à une direction.
Il reste vide dans les autres scènes. Les portes nord/sud nécessitent
`w10_p00_e00` et les portes est/ouest `w05_p00_e00`, avec deux voisins réels.
Une orientation inconnue, une case absente ou un masque incompatible est signalé
par un avertissement ; le renderer garde alors les images ordinaires.

`tools/export_wireframe_doors.cjs` lit les quatre études et prépare
`assets/dungeon/wireframe-doors/{north,east,south,west}.svg`, `catalog.json` et
`scripts/wireframe_door_catalog.gd`. Chaque image est complète : sol, murs,
arche et porte à double face. Elle remplace les deux sprites ordinaires.
L'export retire les arêtes et faces de bout aux deux raccords internes, puis
garde le joint de pierre du contact nord/ouest selon la règle du catalogue.
Les contours des murs priment sur les joints de sol lorsqu'ils coïncident.
Les faces neutres et l'occultation sont préparées hors ligne.

Le pas est toujours 256 px, sans rotation ni mise à l'échelle des variantes.
Les portes ont une image 304 × 392, ancrage (24,128), pour laisser la place à
l'arche latérale. Le renderer utilise cet ancrage et les dimensions réelles
pour le cadrage. Les imports activent `mipmaps/generate=true`.

```powershell
node tools/export_arched_door_cell_wireframe.cjs
node tools/export_arched_door_orientations.cjs
node tools/export_wireframe_doors.cjs
godot --headless --editor --import --path .
godot --path . --script res://tools/capture_wireframe_cells.gd -- WireframeDoorCross
godot --path . --script res://tools/capture_wireframe_doors.gd
```

Remplacer `godot` par l'exécutable local si nécessaire. Les captures de revue
sont `artifacts/wireframe-WireframeDoorCross.png`, sa version `-2x.png` et
`artifacts/wireframe-door-{direction}-detail.png`. Le dossier est ignoré par Git.
Ouvrir la nouvelle scène et utiliser F6 ; la cible F5 reste inchangée.
Les portes restent fermées : aucune interaction, animation, collision,
navigation ou sauvegarde de leur état n'est introduite.

## Historique : première porte rectangulaire

Le 23 octobre 2026, l'utilisateur a demandé une case avec un mur à gauche et à
droite et une porte au milieu. Il a confirmé la proposition suivante : couloir
vertical de **1 × 1**, ouvert au nord et au sud, avec une porte fermée placée
en travers du passage. Cette première image attend sa validation visuelle.

L'encadrement rectangulaire, le vantail unique et les dimensions propres à la
porte sont des choix proposés. Cette étude ne modifie aucun catalogue Godot,
aucune scène, collision, navigation ou règle de gameplay.

### Sources et fichiers de la proposition rectangulaire

- `tools/export_door_cell_wireframe.cjs` : construction déterministe hors ligne.
- `docs/reference/two-course-square-room.json`, `models.after` : projection,
  épaisseur et hauteur actuelles des murs.
- `docs/reference/floor-periodic-cell.json` : motif révisé de 26 fragments,
  normalisé de 6 × 5 vers 1 × 1, comme le catalogue actuel.
- `docs/reference/door-cell-west-east-wireframe.svg` : dessin de revue.
- `docs/reference/door-cell-west-east-wireframe.json` : paramètres, volumes,
  segments 3D sources et visibles, chemins projetés.
- `docs/reference/door-cell-west-east-wireframe.png` : aperçu du SVG.
- `docs/reference/door-cell-preview.template.html` : présentation dans la conversation.

### Géométrie de la proposition rectangulaire

| Élément | Construction en coordonnées du monde |
| --- | --- |
| Case | x = 0..1, y = 0..1 |
| Projection | écran = (x − .18z, y − .9z) |
| Mur gauche | x = 0..1/6, y = 0..1 |
| Mur droit | x = 5/6..1, y = 0..1 |
| Hauteur des murs | H = 1.88/6 = .31333333 |
| Joint horizontal des murs | J = .94/6 = .15666667 ; deux assises |
| Encadrement | centre y = .5 ; profondeur 1/6 |
| Montants | largeur .05 chacun, joints horizontaux à J |
| Linteau | hauteur .05 ; sommet à H |
| Passage dans le cadre | x = .21666667.. .78333333, z = 0.. .26333333 |
| Vantail fermé | épaisseur .025 ; face avant reculée de .025 par rapport au cadre |
| Sol | z = 0, motif existant devant et derrière la porte |

Le vantail touche le sol et ferme l'ouverture entre les montants. Les divisions
de planches et la poignée servent uniquement à identifier la porte dans cette
proposition. Leurs lignes de hauteur suivent la même projection que la maçonnerie.
Le cadre ne dépasse pas la hauteur des murs. Aucun seuil surélevé n'est ajouté.

Les interfaces coplanaires entre les murs et le cadre deviennent internes.
Les arêtes du cadre dessinent l'ouverture et ses retours ; la coupe horizontale
sous le linteau décrit son assemblage, pas une troisième assise sur les murs.

La visibilité est calculée contre les six volumes : deux murs, deux montants,
le linteau et le vantail. Le rayon vers l'observateur est (.18, .9, 1). Chaque
segment est partagé aux transitions de visibilité avant projection. Les traits
du dallage cachés par cette architecture ne sont donc pas dessinés.

### Reproduction de la proposition rectangulaire

Depuis la racine du dépôt :

```powershell
node tools/export_door_cell_wireframe.cjs
```

Cette commande réécrit le SVG et le JSON. Pour préparer également la présentation
inline, fournir un chemin HTML absolu dans le dossier de visualisations du fil :

```powershell
node tools/export_door_cell_wireframe.cjs --inline "C:/chemin/du/fil/porte-couloir-wireframe.html"
```

Le modèle HTML contient un fragment littéral ; l'exporteur y insère seulement les
données projetées. Le PNG est une capture navigateur du SVG à sa taille native
696 × 834. Actualiser cet aperçu après chaque modification du dessin.

## Suite après revue

Pour une autre orientation, construire la géométrie dans le monde puis appliquer
la projection commune. Ne jamais tourner ou retourner l'image projetée. Conserver
le motif du sol dans les axes du monde.

L'intégration actuelle prépare les images complètes hors ligne avec la même
cadence que le kit et un ancrage adapté à leur marge haute. Les extrémités
connectées suivent les règles du catalogue. Toute future variante devra
conserver ce principe : Godot choisit et place des images préparées, sans
générer de briques, de cadre ou de porte à la volée.
