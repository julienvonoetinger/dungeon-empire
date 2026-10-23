# Wireframes : construction, export et utilisation dans Godot

État de référence : 23 octobre 2026. Ce guide décrit le **catalogue de cases
carrées qui définit la géométrie actuelle**. Les scènes affichent désormais les PNG
peints dérivés de ces sources ; voir la section 14 et PAINTED_GODOT.md.

## 1. Principe à conserver

Les images sont préparées **avant** leur utilisation dans le jeu. Godot charge
les textures, choisit la variante adaptée aux voisins et la place sur la grille.
Il ne crée ni image, ni maillage, ni dalle, ni brique pendant l'affichage.

Le catalogue contient 16 combinaisons de murs cardinaux. En tenant compte des
piliers concaves, il existe 47 états sans sortie extérieure forcée. Les bouts
de couloirs explicitement ouverts portent le total à 136 enregistrements,
dont 16 états sans aucun mur ou pilier. Ces derniers ne nécessitent pas de
sprite de murs. Ce sont des images complètes préparées, pas 136 algorithmes
de dessin dans Godot.

## 2. Sources et responsabilités

| Fichier versionné | Rôle |
| --- | --- |
| `docs/reference/two-course-square-room.json` | Projection, épaisseur et modèle `models.after` des murs actuels |
| `docs/reference/floor-periodic-cell.json` | Motif actuel : 26 fragments, 20 pierres périodiques, six rangées |
| `tools/export_wireframe_cell_kit.cjs` | Construction mathématique et export SVG **hors Godot** |
| `assets/dungeon/wireframe-cells/*.svg` | Sources géométriques connectées pour l’export peint |
| `assets/dungeon/wireframe-cells/*.svg.import` | Import des textures, notamment les mipmaps |
| `assets/dungeon/wireframe-cells/catalog.json` | Provenance, dimensions, ancrages et inventaire des variantes |
| `scripts/wireframe_cell_catalog.gd` | Ancien catalogue SVG, conservé pour référence |
| `scripts/painted_cell_catalog.gd` | Catalogue PNG réellement utilisé par les scènes |
| `scripts/wireframe_cell_layout.gd` | Occupation logique, ouvertures et sélection d'une clé de catalogue |
| `scripts/wireframe_cell_study.gd` | Placement des images et actualisation de l'aperçu |
| `tools/capture_wireframe_cells.gd` | Captures Godot pour la revue humaine |

Les sources nécessaires au catalogue sont dans Git. L'exporteur n'utilise ni
conversation, ni HTML du dossier local de visualisations, ni image temporaire,
ni service de génération. Il nécessite Node.js et ses modules standard seulement.

Les anciens SVG/PNG/JSON de `docs/reference/` conservent les études précédentes.
L'exporteur du catalogue ne reconstruit pas à l'identique toutes leurs mises en
page ou leurs illustrations de salles entières. Pour le catalogue actuel, les
deux JSON et l'exporteur cités dans le tableau font référence. Les instructions
historiques en 6 × 5 ou avec une troisième rangée ne doivent pas les remplacer.

## 3. Géométrie commune

| Paramètre | Valeur |
| --- | --- |
| Case logique | 1 × 1 |
| Largeur d'un couloir | Une ou plusieurs cases ; deux dans SixRoomPreview |
| Épaisseur d'un mur `T` | 1/6 de case |
| Hauteur `H` | 1,88/6 de case |
| Joint entre les deux assises `J` | 0,94/6 |
| Axe X au sol | Horizontal vers la droite |
| Axe Y au sol | Vertical vers le bas |
| Vecteur de hauteur | (-0,18 ; -0,9) |

La projection parallèle, en unités de case, est :

```text
écran(x, y, z) = (x - 0.18*z, y - 0.9*z)
```

Tous les murs et piliers suivent cette même formule. Un mur à droite est construit
à droite dans les coordonnées du sol, puis projeté. **Ne jamais retourner l'image
du mur gauche.** Les axes au sol restent parallèles à l'écran : il n'y a pas de
points de fuite finis ni de rotation isométrique. La base ne s'élargit pas.

Les emprises, avant projection, sont :

- Nord : `x=0..1`, `y=0..T`.
- Est : `x=1-T..1`, `y=0..1`.
- Sud : `x=0..1`, `y=1-T..1`.
- Ouest : `x=0..T`, `y=0..1`.
- Pilier : carré `T × T` dans le coin concerné, de hauteur `H`.

Les murs adjacents sont réunis en un volume commun. Un pilier ne reçoit qu'un
joint horizontal à `J`, **aucun joint vertical**.

L'exporteur actuel utilise une subdivision fixe de 6 × 6 pour ces emprises.
Changer seulement `wallThickness` dans le JSON ne suffit donc pas à modifier
correctement l'épaisseur : il faudrait revoir cette construction conjointement.
Les dimensions convenues ne doivent pas être changées sans nouvelle demande.

## 4. Sélection des variantes et raccords

Les bits cardinaux sont `N=1`, `E=2`, `S=4`, `W=8`. Les coins de piliers sont
`NW=1`, `NE=2`, `SE=4`, `SW=8`. Le nom `w09_p00_e00.svg` signifie : murs nord
et ouest, aucun pilier supplémentaire, aucune sortie extérieure forcée.

| Forme | Masque de murs `w` |
| --- | --- |
| Sol seul | 0 |
| Mur N / E / S / W | 1 / 2 / 4 / 8 |
| Coin NW / NE / SE / SW | 9 / 3 / 6 / 12 |
| Couloir avec murs N et S | 5 |
| Couloir avec murs W et E | 10 |
| Trois murs, ouverture N / E / S / W | 14 / 13 / 11 / 7 |
| Quatre murs | 15 |

Pour une case occupée :

1. Lire ses quatre voisins cardinaux réels.
2. Poser un mur sur chaque côté sans voisin, sauf ouverture explicitement forcée.
3. Pour chaque coin, si les deux voisins cardinaux sont présents mais leur
   diagonale est absente, sélectionner une variante contenant le pilier de ce coin.
4. Une ouverture forcée n'est pas un voisin réel : elle garde les faces de bout
   du mur. Une connexion à une autre case rend les faces de contact internes.
5. Composer la clé `w%02d_p%02d_e%02d`, puis charger l'image correspondante.

Exemple : au débouché sud de la salle, la case centrale du bord n'a pas de mur
sud. Si les cases diagonales sud-ouest et sud-est sont absentes alors que les
voisins ouest, est et sud sont présents, son image contient les deux piliers sud.
Ces piliers touchent les murs voisins par des faces complètes.

Cette règle dépend des voisins, jamais d'un nom de scène ou d'une taille de salle.
Une case inconnue dans le catalogue signale une erreur ; les états volontairement
vides sont énumérés séparément dans `EMPTY_VARIANTS`.

## 5. Construction des images dans l'exporteur

`geometry(w, p, e)` construit les emprises des murs et piliers, puis :

1. Réunit les zones occupées et extrait leurs contours extérieurs.
2. Omet les faces de contact avec une vraie case voisine.
3. Regroupe les segments colinéaires ; supprime les arêtes internes et doublons.
4. Ajoute sommet, pied, joint horizontal et joints des pierres des murs.
5. Masque les traits cachés par le volume avec une direction de vue commune
   `(0.18, 0.9, 1)`, puis applique la projection ci-dessus.
6. Écrit les faces neutres et les lignes visibles dans le SVG complet.

Les joints du dessus se prolongent dans l'assise supérieure. Dans une case,
les positions des joints supérieurs sont `0`, `1.6/6` et `3.5/6`, sous réserve
des limites et ouvertures. L'assise inférieure utilise une phase `0.7/6` et
un pas `1.9/6`. Ces constantes sont dans l'exporteur ; ne pas les recalculer
par orientation dans Godot.

Les faces blanches servent à cacher les traits situés derrière le volume.
C'est le dessin vectoriel d'une étude géométrique. Cette méthode n'autorise
pas le détourage ou la réparation programmatiques des futurs sprites peints.

## 6. Sol et ancrages

Le sol reprend les `rowHeights` et `rowWidths` de `floor-periodic-cell.json`.
Son cadre de dessin 6 × 5 est normalisé en 1 × 1 : division des coordonnées
X par 6 et Y par 5. À la demande de l'utilisateur, ce motif de 26 fragments
remplace l'ancien motif de 19 fragments qui créait des colonnes de grandes dalles.
Les premiers et derniers fragments d'une rangée forment une seule pierre ;
leur largeur cumulée doit rester comparable à celle des pierres intérieures.

Les coordonnées au sol sont projetées à `z=0`. Ne jamais aligner le sol sur les
bords surélevés du dessus des murs : le sol touche leurs pieds.

| Image | Dimensions | Ancrage du point logique (0,0,0) |
| --- | --- | --- |
| Murs | 304 × 352 px | (24,88) |
| Sol | 264 × 264 px | (4,4), marge transparente de 4 px |

Le pas de grille est **256 px dans les deux axes**. Pour la case `(cx,cy)` :

```text
position du sprite = (cx,cy)*256 - ancrage
```

Ne pas utiliser la largeur du fichier image comme pas de grille : ses marges
contiennent le débord de perspective et les traits complets. Les images restent
entières ; aucune découpe, teinte, rotation ou correction de forme à l'affichage.

Les sols sont placés sur la couche 0, les murs sur la couche 1 ; les cases sont
ordonnées de haut en bas puis de gauche à droite. Cela ne constitue pas encore
le tri des personnages devant/derrière les murs : ce gameplay reste à implémenter.

## 7. Régénérer le catalogue

Depuis la racine du dépôt, avec Node.js accessible dans le terminal :

```powershell
node tools/export_wireframe_cell_kit.cjs
```

L'export remplace les images du catalogue, `catalog.json` et
`scripts/wireframe_cell_catalog.gd`. Avec les sources actuelles, il annonce
**136 variantes de murs et une texture de sol**. Le fichier GDScript contient
les préchargements ; ne pas le modifier à la main, car l'export l'écraserait.

Ouvrir ensuite `project.godot` et laisser Godot importer les SVG. Conserver les
fichiers `.svg.import` versionnés : `mipmaps/generate=true`. Le renderer utilise
`TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`, pour éviter que les traits fins disparaissent
quand une grande salle est réduite à l'écran. Si un nouvel asset est ajouté,
vérifier son réglage d'import après le premier import.

L'exporteur n'est jamais lancé depuis un script du jeu, le bouton d'actualisation
ou la construction d'un donjon. **Actualiser le rendu** recharge seulement les
images choisies. Garder `refresh_action` sous forme de getter Callable pour
éviter le précédent défaut de valeur `Nil` après rechargement des scripts.

## 8. Revue dans Godot

Ouvrir `scenes/WireframeClosedCorridors.tscn`, puis F6 : salle 3 × 3, quatre
branches de longueur deux fermées, 17 cases et huit piliers. F5 conserve la
scène définie dans `project.godot` ; consulter ce fichier au lieu de supposer
que F5 lance l'exemple fermé.

Pour les captures, si l'exécutable Godot est accessible sous le nom `godot` :

```powershell
godot --path . --script res://tools/capture_wireframe_cells.gd -- WireframeClosedCorridors 1x1CellRoom 2x1Corridor 3x3RoomCornerCorridors 5x5RoomVerticalCornerCorridors
```

Sinon, remplacer `godot` par le chemin de l'exécutable installé. Ne pas utiliser
le mode `--headless` pour ces captures GPU. Les fichiers sont écrits dans
`artifacts/wireframe-<scène>.png` et `-2x.png`, à 1280 × 960 et 2560 × 1920.
Ce dossier de captures est local et ignoré par Git.

Examiner le rendu normal et agrandi :

- Même projection pour gauche, droite, murs horizontaux et coins.
- Deux assises partout, sans bande fine ajoutée ni base évasée.
- Continuité aux limites de cases, sans face terminale au milieu d'un mur.
- Faces de bout présentes aux vraies extrémités ouvertes.
- Piliers complets aux raccords concaves, sans division verticale.
- Sol au niveau des pieds, traits lisibles et aucun changement de motif caché.

L'absence d'erreur Godot ne remplace pas l'acceptation visuelle de l'utilisateur.
La suite peinte devra conserver dimensions, projection, ancrages et ports, avec
de vraies images à transparence native. La seule référence de palette demeure
`assets/dungeon/gloom-kit/reference.png` : ardoise sombre et accents violets
localisés. Les propositions peintes rejetées ne sont pas des références approuvées.

## 9. Nouvelle entrée en cours de revue

Les quatre orientations d'escalier sont documentées dans
[ENTRANCE_STAIRS.md](ENTRANCE_STAIRS.md). L'exporteur séparé
`tools/export_wireframe_entrances.cjs` prépare quatre images **complètes** dans
`assets/dungeon/wireframe-entrances/` et leur catalogue GDScript. Les images
comprennent déjà murs, marches et sol ; ne pas ajouter un sol ou un mur par-dessus.

La scène `WireframeClosedCorridors.tscn` active `entrance_at_closed_ends=true`.
Les quatre cellules terminales deviennent des entrées, avec leur ouverture vers
la salle. Le réglage partagé reste `false` dans les autres scènes. Les seuls
masques sélectionnés sont w14/w13/w11/w07, p00/e00 ; aucune image n'est construite
dans Godot. Les quatre imports ont également `mipmaps/generate=true`.

Régénérer d'abord la source de l'escalier, puis les images connectées :

```powershell
node tools/export_entrance_stair_wireframe.cjs
node tools/export_wireframe_entrances.cjs
```

Les vrais raccords nord/ouest conservent leurs joints de pierres selon la règle
du catalogue partagé, mais pas leurs faces de bout internes. Le remplissage ne
contient que les faces visibles et omet la face du port connecté. Les captures
de détail utilisent `tools/capture_wireframe_entrances.gd`, qui cadre les quatre
entrées dans la scène réelle, avec une partie de chaque couloir voisin.

## 10. Première case porte en revue

La proposition avec murs ouest/est et porte au centre est décrite dans
[DOOR_CELLS.md](DOOR_CELLS.md). L'utilisateur a choisi une porte en bois dans un
cadre voûté sans torches. L'exporteur actuel
`tools/export_arched_door_cell_wireframe.cjs` produit son SVG et ses données de
construction hors ligne. Elle conserve la projection, les deux assises des murs
latéraux et le motif de sol du catalogue ; seule la voûte dépasse les murs bas.
L'ancien exporteur rectangulaire reste historique. Les études isolées servent
de sources à l'intégration demandée ensuite, décrite ci-dessous.

Les quatre orientations demandées sont préparées ensuite par
`tools/export_arched_door_orientations.cjs`. Les noms nord/est/sud/ouest indiquent
la face avant du vantail. La géométrie tourne dans le monde, la caméra et le
motif du sol restent fixes. La visibilité et le contour apparent de la voûte
sont recalculés pour chaque vue. `door-arch-four-orientations.svg` présente les
quatre variantes ensemble. L'utilisateur a ensuite demandé leur intégration.

Le vantail est à double face : planches, deux ferrures et un anneau de chaque
côté sont définis dans la source commune. Le recul est identique sur les deux
faces (.025), avec une épaisseur .11666667. L'ancien revers trop enfoncé et
sans poignée faisait disparaître la porte dans la vue ouest. Garder les
occultations réelles et les poignées sur le même axe physique ; ne pas déplacer
les détails pour les tourner artificiellement vers la caméra.

### Scène en « + » avec les quatre portes

`WireframeDoorCross.tscn` utilise une case centrale et quatre branches de trois
cases, avec des bouts fermés : 13 cases. Une porte se trouve dans la deuxième
case de chaque branche. Le renderer partagé expose `door_cells` (vide par défaut),
avec les directions `north/east/south/west`. Les masques admis sont
`w10_p00_e00` pour nord/sud et `w05_p00_e00` pour est/ouest. Les placements
incompatibles sont signalés et gardent l'image ordinaire.

Après les deux exporteurs de revue, lancer `node tools/export_wireframe_doors.cjs`.
Il prépare les quatre images **complètes** dans `assets/dungeon/wireframe-doors/`
et leur catalogue GDScript. Aucun sol ni mur supplémentaire ne doit être ajouté
sur ces images. Les deux faces terminales sont omises aux contacts avec de vrais
voisins, et le joint nord/ouest est conservé. La priorité des contours de murs
évite qu'un joint de sol superposé amincisse le pied du mur.

Le pas reste 256 px ; l'ancrage des portes est (24,128), leurs images 304 × 392.
La marge haute contient toute l'arche. Conserver les mipmaps. Utiliser
`tools/capture_wireframe_cells.gd -- WireframeDoorCross` pour l'ensemble et
`tools/capture_wireframe_doors.gd` pour les quatre raccords agrandis.
Cette scène reste statique ; ouvrir la scène et F6 pour sa revue.

## 11. Six salles et couloirs de deux cases

L'utilisateur a demandé de migrer `SixRoomPreview.tscn` en conservant les
couloirs de **deux cases de large**. C'est une configuration voulue pour le futur
donjon personnalisable. La contrainte 1 × 1 concerne les cases, pas une largeur
universelle de passage. Les scènes précédentes gardent leurs couloirs d'une case.

La scène utilise maintenant le renderer commun et
`assets/layouts/six_rooms_wireframe.tres`. Ce layout conserve les 255 cases de
`six_rooms.tres`, coordonnées et chiffres compris, et ajoute uniquement (3,2)
pour l'entrée par escalier. La grille reste 28 × 18, avec 256 cases occupées.
`entrance_at_closed_ends=true` choisit la variante déjà préparée ouverte au sud,
`w11_p00_e00`. Une seule case du plan est terminale. Le pas partagé reste 256 px.

Le cœur et le panneau de sondes historiques ont été retirés de la scène.
Le changement de renderer retire la porte d'entrée peinte, les torches et leurs
lumières. Les ressources historiques restent disponibles dans le dépôt.
Les murs, coins et piliers utilisent les mêmes règles de voisinage et les mêmes
images que les autres scènes ; aucun correctif propre à cette salle n'est dessiné.

```powershell
godot --path . --script res://tools/capture_wireframe_cells.gd -- SixRoomPreview
godot --path . --script res://tools/capture_six_room_wireframe.gd
```

Remplacer `godot` par l'exécutable local si nécessaire. La première commande
produit les vues d'ensemble à 1×/2×. La seconde produit cinq détails : entrée,
croisement, raccord ouest, sortie sud-ouest et raccord inférieur. Ils sont
enregistrés dans `artifacts/`, ignoré par Git. Pour la revue dans Godot, ouvrir
`SixRoomPreview.tscn` puis F6 ; la cible F5 demeure inchangée.

## 12. Calques transparents pour les futurs sprites

L'utilisateur a demandé de préparer les wireframes pour les superposer aux futures
images peintes : fond et faces transparents, traits d'une couleur très voyante.
Les nouveaux guides utilisent le **magenta #ff00ff**. Les sources de construction
blanches, la géométrie validée et les scènes actuelles sont conservées.

`tools/export_wireframe_overlays.cjs --png` prépare **146 guides SVG + PNG RGBA**
dans `docs/reference/wireframe-overlays/` : les 136 variantes de cases complètes,
le sol seul, quatre escaliers, quatre portes et le pilier seul. Node.js suffit pour les SVG ;
le paramètre `--png` utilise le module `sharp` pour rasteriser les vecteurs.

Les pièces doivent être examinées **une par une** : l'utilisateur a demandé de
rétablir tous les contours visibles des extrémités, absents dans la première
version dérivée des images connectées. Les portes suivent les études isolées ;
les cases réutilisent la géométrie commune avec `standalone=true`. Les lignes
cachées par les volumes restent omises. Le pilier seul garde les dimensions
actuelles et son unique joint horizontal, sans sol ni division verticale.
La variante « sol + deux piliers » reste une référence de raccord, pas une image
peinte supplémentaire à produire : elle réutilise sol et pilier.

Les traits conservent leurs coordonnées et épaisseurs. Les lignes du sol cachées
par les faces de murs sont retirées avant d'omettre les remplissages blancs :
la transparence ne doit pas créer un dessin en rayons X. Aucun détourage de sprite
peint ni changement de perspective n'intervient.

Lire [le mode d'emploi des calques](wireframe-overlays/README.md) pour les tailles,
ancrages, commandes et limites de visibilité entre cases. `catalog.json` conserve
la provenance et les empreintes des sources. `comparison.png` montre quatre
exemples isolés sur damier ; les fichiers individuels ne contiennent pas ce damier.
Le mode de superposition d'une scène entière dans Godot reste à implémenter.

## 13. Matières peintes communes sur géométrie fixe

Après le premier essai, l'utilisateur a approuvé la méthode des masques pour
conserver des textures identiques entre éléments. Il demande plusieurs variantes
plus riches, tout en gardant la géométrie exacte. La restriction du premier essai
« pour cette fois uniquement » est donc supersédée pour cette méthode.

Suivre [MATERIAL_WORKFLOW.md](MATERIAL_WORKFLOW.md). La bibliothèque préparée
`assets/dungeon/shared-materials/catalog.json` contient quatre matières de mur,
quatre de sol, du bois, du métal et un profil de rendu commun. Les sources générées, prompts et
empreintes sont conservés. Les masques et joints viennent du wireframe ; la
texture ne peut jamais imposer un changement de caméra, de rangée ou de contour.

`tools/prototype_nw_masked_material.cjs --materials-v2` prépare la nouvelle
proposition NW avec cette bibliothèque. La comparaison se trouve dans
`docs/reference/nw-material-review-v2/`. Ce prototype reste conservé.

À la demande de l'utilisateur, `tools/export_painted_image_catalog.cjs` prépare
désormais les autres images avec le compositeur partagé
`tools/painted_material_renderer.cjs`. Les 57 PNG dans `assets/dungeon/painted-cells/`
couvrent les 146 identifiants de guides isolés par alias. Ce catalogue comprend
les cases, le sol, le pilier, les quatre escaliers et les quatre portes.
Les rapports, planches et calques sont dans `docs/reference/painted-kit-review/`.
Ils conservent traits, projection, deux assises, alpha du volume et ancrages ×4.
La séparation bois/pierre des portes vient des volumes 3D, pas de la seule
fermeture des traits visibles. Les scènes Godot utilisent maintenant les versions connectées peintes.

## 14. Scènes Godot avec les sprites peints

La migration demandée par l'utilisateur conserve cette géométrie et les réglages
des 16 scènes sur grille. Quatre anciennes démos d'architecture utilisent aussi
la nouvelle famille. Lire [PAINTED_GODOT.md](PAINTED_GODOT.md) pour l'inventaire.

Les sections précédentes décrivent la construction des SVG sources. Pour le
rendu actuel, `wireframe_cell_study.gd` charge `painted_cell_catalog.gd` :
un sol PNG par case, puis au plus un PNG de structure (murs, porte ou escalier).
Les portes et entrées **connectées peintes** ne contiennent pas de sol. Cette
organisation remplace leur ancienne texture SVG complète décrite aux sections 9/10.
Les variantes de revue isolées restent complètes, avec leurs faces terminales.

L'export `tools/export_painted_connected_kit.cjs` reprend les contours connectés
et les mêmes matériaux que les revues isolées. Les PNG sont à ×4 ; Godot applique
uniquement l'échelle uniforme 0,25 et les ancrages du catalogue peint.
Le sol connecté est désormais cadré à 1024×1024 sans marge transparente, ancrage
(0,0), pour éviter les filets de filtrage entre cases. Ses dalles de bord partagent
une peinture continue avec la case voisine ; voir PAINTED_GODOT.md.
Tous les sols sont à z=0 et toutes les structures à z=1. Aucune génération d'image,
retouche, teinte, miroir ou découpe pendant le rendu. Les noms des scripts de
capture restent historiques, mais leurs sorties montrent les PNG actuels.

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
