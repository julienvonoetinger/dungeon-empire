# Entrées du donjon : quatre orientations d'escalier

État du 23 octobre 2026 : la première orientation et son raccord ont été examinés
par l'utilisateur. À sa demande, les trois autres orientations sont maintenant
préparées et les quatre entrées sont intégrées à la scène de test Godot pour
revue visuelle. Le matériau peint et le fonctionnement d'une entrée restent à faire.

## Demande et orientation

Première des quatre orientations demandées : murs au nord, à l'ouest et à
l'est, ouverture au sud. Le haut de l'escalier est au fond de la case ; les
marches descendent vers le bas de l'image jusqu'au sol du donjon.

L'image reste une étude de lignes. Aucun matériau ni sprite peint n'est proposé.

## Sources reproductibles

| Fichier | Rôle |
| --- | --- |
| `tools/export_entrance_stair_wireframe.cjs` | Construction et export hors Godot |
| `two-course-square-room.json`, modèle `after` | Projection et dimensions des murs actuels |
| `floor-only-cell-wireframe.json` | Motif existant du palier |
| `entrance-stairs-open-south-wireframe.svg` | Dessin vectoriel de la proposition |
| `entrance-stairs-open-south-wireframe.json` | Dimensions, volumes, arêtes sources et visibles |
| `entrance-stairs-open-south-wireframe.png` | Aperçu raster du SVG |

Depuis la racine du dépôt :

```powershell
node tools/export_entrance_stair_wireframe.cjs
```

Le script requiert seulement Node.js et ses modules standard. Il reconstruit
le SVG et le JSON, sans lire d'image temporaire ni appeler le jeu. Le PNG est
un aperçu du SVG rendu par un navigateur ; il n'est pas une source géométrique.
Consulter [WIREFRAME_WORKFLOW.md](WIREFRAME_WORKFLOW.md) pour le catalogue existant.

## Géométrie

Les murs reprennent exactement le contrat actuel : case 1 × 1, épaisseur
`T=1/6`, hauteur `H=1.88/6`, joint horizontal `J=.94/6` et projection
`(x-.18*z, y-.9*z)`. Deux assises, aucune bande mince supplémentaire.

La proposition d'escalier utilise :

- Cinq marches de largeur constante `1-2T=2/3`, entre `x=T` et `x=1-T`.
- Une volée entre `y=T` et `y=.84` ; profondeur de marche `(.84-T)/5`.
- Une hauteur de contremarche `.05` ; dessus successifs à `.25`, `.20`,
  `.15`, `.10`, `.05`. La dernière contremarche arrive à `z=0`.
- Un palier entre `y=.84` et `y=1`, au niveau du sol, ouvert au sud.
- Le motif de dallage existant sur ce palier, normalisé comme dans le catalogue.

Le nombre de marches, leur hauteur et la longueur du palier viennent de la
première proposition, conservée pour la revue des quatre orientations demandée.
Le trait au bord sud marque la limite de cette case isolée ; ce n'est pas un seuil
surélevé. Les côtés des marches touchent les murs, sans vide ni élargissement.

## Construction et visibilité

1. Construire le contour en U des trois murs réunis, puis leurs arêtes et joints.
2. Construire les cinq marches comme des volumes pleins jusqu'à `z=0`.
3. Ajouter leurs dessus, contremarches et contacts avec les murs, sans lignes
   internes entre les volumes pleins.
4. Garder le dallage uniquement sur le palier découvert.
5. Calculer la visibilité de toutes les lignes contre **tous** les volumes,
   murs et escalier, avec la direction de vue `(0.18,0.9,1)`.
6. Appliquer la même projection à toutes les arêtes visibles et exporter le SVG.

Il ne faut pas superposer simplement l'image complète des murs existants sur
les marches : certaines surfaces de l'escalier sont devant la face du mur nord.
Le futur asset complet devra déjà représenter ces occultations correctement.
Godot continuera à charger des images préparées, sans construction de marches.

Pour les trois autres orientations, modifier les
coordonnées dans le plan, puis appliquer la projection commune. Ne pas tourner
ni retourner l'image de cette proposition. Navigation, accès au niveau supérieur,
collisions et comportement d'entrée ne sont pas implémentés par ce dessin.

## Assemblage demandé dans la salle de test

L'utilisateur a demandé de remplacer le cul-de-sac du haut dans l'image de test
précédente. `room-north-entrance-wireframe.svg` et son détail `-north.svg`
reprennent la salle 3 × 3 et ses quatre branches fermées, soit 17 cases.
L'entrée remplace exactement la case terminale `(1,-2)` ; son ouverture sud
rejoint la case de couloir `(1,-1)`. Aucune mise à l'échelle, rotation ou symétrie
n'est appliquée à l'escalier.

```powershell
node tools/export_entrance_stair_wireframe.cjs
node tools/export_entrance_room_wireframe.cjs
```

Le second script lit les deux JSON sources et écrit les vues SVG et leurs
métadonnées dans `room-north-entrance-wireframe.json`. Il conserve les autres
modules et les huit piliers. Les joints des murs à l'extérieur de la case
remplacée suivent les mêmes longueurs et positions que l'étude précédente.

Les dix arêtes des faces terminales de l'entrée au contact du couloir sont
internes et ne sont donc pas dessinées. Douze points de contact (quatre bords
à trois hauteurs) ont un écart projeté nul, enregistré dans le JSON. Cette
coïncidence géométrique ne vaut pas validation artistique de l'assemblage.

Le dallage global de l'ancienne salle est conservé, y compris sur le palier.
Les cinq marches masquent le sol qu'elles recouvrent. Le dessin de la case
isolée utilise le motif local du catalogue : ce sont deux contextes de dallage
distincts, déjà documentés dans le guide général. Les murs et l'escalier ont
la même géométrie dans les deux présentations.

Pour produire la présentation avec les vues « Salle complète » et « Entrée et
raccord au couloir », passer `--inline CHEMIN_ABSOLU.html` au second script.
Le fichier `entrance-room-preview.template.html` est le modèle de cette
présentation ; toutes ses lignes proviennent de l'export géométrique. Le rendu
en navigateur des deux vues a été inspecté. Le changement de vue fonctionne
sans erreur JavaScript observée. Cette première présentation précède
l'intégration Godot décrite ci-dessous.

## Quatre variantes et scène Godot

`tools/export_wireframe_entrances.cjs` lit le JSON de la première proposition.
Il écrit quatre SVG complets dans `assets/dungeon/wireframe-entrances/`, leur
`catalog.json` et `scripts/wireframe_entrance_catalog.gd`. Il sauvegarde aussi
les copies de revue `entrance-stairs-open-<direction>-connected.svg`.

| Fichier / côté ouvert | Transformation des coordonnées 3D | Masque de murs | Extrémité de la scène |
| --- | --- | --- | --- |
| `south.svg` | `(x,y,z)` | 11 | Nord, `(1,-2)` |
| `north.svg` | `(1-x,1-y,z)` | 14 | Sud, `(1,4)` |
| `east.svg` | `(y,1-x,z)` | 13 | Ouest, `(-2,1)` |
| `west.svg` | `(1-y,x,z)` | 7 | Est, `(4,1)` |

Ces transformations précèdent la projection commune ; les images projetées ne
sont pas retournées. Les dimensions des marches, des murs et du palier sont
identiques. Le sol utilise le motif de 19 dalles **dans ses axes d'origine**,
sans le faire tourner avec l'escalier. Son occultation est calculée contre tous
les volumes de la case pendant l'export.

Le générateur omet les faces de bout du port connecté. Il prépare seulement
les remplissages de sommet et des faces +X/+Y visibles ; une face interne ou
arrière ne doit pas recouvrir les lignes d'un voisin. Les vrais ports nord/ouest
reçoivent le joint de dessus et sa continuation dans l'assise supérieure,
selon la même règle que le catalogue de murs. La cellule du côté +X/+Y possède
ce joint. Les premières captures avaient montré une trace partielle au raccord :
la case isolée tournée ne contenait pas ce joint partagé. La règle commune est
maintenant appliquée, sans changer le volume ni ajouter une réparation à l'affichage.

Les textures font 304 × 352 px, ancrage `(24,88)`, pas 256 px, modulation blanche
et mipmaps activées. `entrance_at_closed_ends`, défaut **false**, sélectionne
uniquement les clés w14/w13/w11/w07 avec p00/e00. Chaque entrée utilise un seul
Sprite2D complet sur la couche des murs, en remplacement du sol et du mur ordinaires.
Le renderer n'exécute aucun exporteur et ne calcule aucune marche.

`scenes/WireframeClosedCorridors.tscn` active ce réglage : même salle 3 × 3,
quatre branches de deux cases et huit piliers, mais quatre entrées à leurs bouts.
Ouvrir cette scène puis **F6**. Le raccourci F5 conserve sa scène configurée.

Reproduction et revue :

```powershell
node tools/export_entrance_stair_wireframe.cjs
node tools/export_wireframe_entrances.cjs
godot --headless --editor --path . --import --quit
godot --path . --script res://tools/capture_wireframe_cells.gd -- WireframeClosedCorridors 2x2CellRoom
godot --path . --script res://tools/capture_wireframe_entrances.gd
```

Adapter le nom de l'exécutable à l'installation. Les deux dernières commandes
requièrent le rendu GPU. Les captures sont dans `artifacts/`, ignoré par Git :
vue complète normale/double et `wireframe-entrance-{north,east,south,west}-detail.png`.
Les noms de ces captures désignent la branche de la scène, contrairement aux
noms des textures qui indiquent le côté ouvert. L'import, les deux scènes et
les quatre gros plans ont été exécutés sans erreur Godot observée ; quatre
sprites d'entrée sont présents. Ces contrôles ne remplacent pas la revue artistique.
