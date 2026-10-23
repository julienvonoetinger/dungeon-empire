# Convention de perspective — donjon modulaire

## Statut et référence

**Intégration wireframe dans Godot — 23 octobre 2026.** L'utilisateur a choisi
les wireframes avant les sprites peints. Les scènes modulaires utilisent le
catalogue préparé `assets/dungeon/wireframe-cells/`, importé comme textures.
Godot sélectionne et place les images ; aucune géométrie ou image n'y est générée.
L'exporteur hors jeu est `tools/export_wireframe_cell_kit.cjs`. Les dimensions
des murs viennent du modèle carré à deux assises ci-dessous. Les piliers sont
déjà inclus dans les variantes choisies d'après les voisins en diagonale.
Le sol reprend le motif de 19 dalles de `floor-only-cell-wireframe.json`, normalisé
au carré, et non le motif provisoire nouvellement dessiné pendant l'intégration.
Le dallage global de l'illustration de salle n'est pas une tuile réutilisable :
le catalogue répète le motif de la case. La scène `WireframeClosedCorridors.tscn`
permet de revoir l'ensemble à 17 cases. Les études historiques ci-dessous restent
des documents de référence ; l'apparence importée attend la revue utilisateur.

**Dernière contrainte : grille de cases carrées 1 × 1.**
L'utilisateur a écarté la proposition de cases rectangulaires 6 × 7,5 avant
toute modification géométrique. Les dimensions de dessin 6 × 5 des études
précédentes ne valent pas approbation d'une grille logique rectangulaire.
L'utilisateur a confirmé que les couloirs restent larges d'UNE seule case.
La correction porte sur la hauteur visible des murs ; sa dernière demande
est de retirer la rangée fine sur tous les murs.

**Étude en cours : cases carrées et deux rangées de briques.**
`two-course-square-room.svg` reconstruit les 17 cases sur une grille réellement
carrée 1 × 1. La largeur historique de six unités sert d'échelle commune :
épaisseur des murs 1/6 de case, mêmes axes au sol et vecteur de hauteur
(-0,18,-0,9). Les proportions rectangulaires des anciennes études ne sont pas
reprises. Les huit piliers et les quatre couloirs fermés gardent leur rôle.

La bande fine de hauteur 0,32/6 est supprimée. Le sommet passe de z=2,2/6
à z=1,88/6 ; il reste deux rangées égales de hauteur 0,94/6 et un seul joint
horizontal. Les joints du dessus se prolongent dans la rangée supérieure,
sans décalage entre le dessus et sa façade. Les piliers n'ont que leur joint
horizontal. La même hauteur est appliquée à toutes les orientations.

Les vues `two-course-square-corridor-before.svg` et `-after.svg` comparent
les deux hauteurs sur le MÊME plan carré, avec le même dallage et la même échelle.
La référence « avec rangée fine » est donc une reconstruction carrée,
pas une copie de l'ancien dessin 6 × 5. La bande de sol visible passe de
0,336667 à 0,384667 case, soit environ 14,3 % de plus. Le gain reste modeste.
Le gabarit bleu, de hauteur 0,30 et largeur 0,18 case, est indicatif ; placé
près du mur du bas à y=0,64, ses parties masquées sont en pointillés. Il ne
définit pas la taille d'un héros du jeu. Les vues de la salle et des quatre
couloirs servent à la revue ; aucune scène Godot ni image peinte n'est modifiée.

**Variantes précédentes : quatre cases à trois murs, avec un côté ouvert.**
Les fichiers `three-wall-cell-open-north.svg`, `-east.svg`, `-south.svg` et
`-west.svg` désignent le côté **ouvert**. Chaque case conserve son emprise
6 × 5, des murs d'épaisseur 1 et de hauteur 2,2. Les volumes en U sont
construits dans les coordonnées du sol puis projetés avec les mêmes axes,
sans rotation ni miroir de l'image. Les sols sont respectivement
[1,0,5,4], [1,1,6,4], [1,1,5,5] et [0,1,5,4], à z=0. Le dallage s'arrête
aux pieds réels des murs ; les portions masquées par les façades sont occultées.
Les assises et les joints des briques suivent la convention existante.

`room-closed-corridors-wireframe.svg` ajoute une case de fermeture au bout
de chacun des quatre couloirs existants, soit 17 cases au total. L'ouverture
est tournée vers la pièce : vers le haut à (6,20), vers le bas à (6,-10),
vers la droite à (-12,5), vers la gauche à (24,5). Les huit faces de contact
entre couloirs droits et terminaisons sont internes : 96 arêtes source
omises, sans espace ni superposition des volumes. Les murs et les rangées
de dalles se poursuivent à travers ces interfaces.

Les huit piliers des raccords à la pièce sont conservés avec leurs seuls
joints horizontaux. Le dallage assemblé compte 170 dalles sur 33 rangées.
Les vues `-north`, `-east`, `-south` et `-west` montrent chaque couloir entier.
L'étude précédente à extrémités ouvertes reste conservée séparément.
Propositions en lignes uniquement, sans intégration aux scènes Godot.

**Assemblage précédent : pièce 3 × 3 avec quatre couloirs centrés.**
`room-four-corridors-wireframe.svg` conserve le couloir du bas et ajoute ceux
de gauche, de droite et du haut. Les nouvelles cases à murs haut/bas sont
placées à (-6,5) et (18,5) ; les cases à murs gauche/droit sont à (6,-5)
et (6,15). Les quatre cases centrales du bord de la pièce ont seulement du sol.
Les dimensions 6 × 5, la hauteur 2,2, l'épaisseur 1 et la projection commune
restent identiques, sans miroir ni rotation du dessin projeté.

Huit piliers de 1 × 1 × 2,2 assurent les contacts par faces complètes :
(6,0), (11,0), (0,5), (0,9), (17,5), (17,9), (6,14), (11,14).
Ils gardent uniquement les joints horizontaux. Les ouvertures libres mesurent
4 au nord/sud et 3 à l'ouest/est ; les quatre extrémités restent ouvertes.
Le dallage compte 142 dalles sur 25 rangées. Celles de y=6..9 traversent
les couloirs horizontaux et la pièce sans joint imposé aux limites des cases.
Les vues `-north`, `-east`, `-south` et `-west` détaillent les raccords.
Proposition en lignes uniquement, sans changement des scènes Godot.

**Variante précédente : case avec murs en haut et en bas uniquement.**
`north-south-cell-wireframe.svg` place deux murs à x=0..6, y=0..1 et y=4..5,
avec la hauteur 2,2, l'épaisseur 1 et la projection commune. Le sol à z=0
couvre x=0..6, y=1..4 en neuf dalles sur trois rangées de hauteurs 1, 1,1 et
0,9. Les côtés gauche et droit restent ouverts. Les joints des briques et
des pierres du dessus suivent l'étude précédente. Le mur du bas masque
une partie du dallage. Proposition en lignes, sans intégration aux scènes.

**Étude précédente — 23 octobre 2026 : dallage continu et joints de maçonnerie.**
`masonry-floor-wireframe.svg` conserve la pièce, le couloir, les deux piliers
et la projection commune. Le nouveau dallage se répartit sur le sol utilisable
dans son ensemble ; les limites logiques des cases ne deviennent plus des joints.
Le JSON enregistre 111 dalles, réparties sur 13 rangées dans la pièce et 6 dans
le couloir, avec largeurs décalées et hauteurs de rangée légèrement variées.
Le sol reste à z=0, au pied des murs, et le passage garde sa largeur de 4.

Les deux assises de façade reçoivent des joints suivant le vecteur de hauteur,
espacés de 1,9 et décalés de 0,95 entre rangées. Les pierres du dessus sont
divisées sur toute leur largeur ; leurs joints continuent sur la petite façade
entre z=1,88 et 2,2. Les angles et piliers gardent un dessus carré entier.
Selon la correction de l'utilisateur, les petits piliers conservent uniquement
leurs joints horizontaux, sans subdivision verticale de leurs faces. Les dimensions
des volumes restent inchangées. Les vues `-floor`, `-junction` et `-pillar`
permettent de revoir les détails. Étude en lignes, sans intégration au jeu.

**Pièce précédente : pilier carré de raccord.**
`pillar-junction-wireframe.svg` propose un pilier de section 1 × 1 et de
hauteur 2,2, identique aux murs. Les assises restent à z=0,94 et 1,88 ;
la projection commune reste inchangée. Le même volume est placé à (6,14,0)
et (11,14,0). Chacun offre une face de contact de 1 × 2,2 au mur de la pièce
et une autre au mur du couloir. Les faces internes sont occultées ; leurs
joints de surface restent visibles. Les arêtes colorées repèrent les piliers.

Leurs emprises x=6..7 et x=11..12, y=14..15, occupent deux petits carrés
du sol de la case du bas au centre. Le passage libre est x=7..11, largeur 4,
comme dans le couloir. Les piliers ont une section constante, sans socle évasé.
Les vues `-pillar.svg` et `-room.svg` montrent le volume isolé et la pièce entière.
Le JSON conserve les dimensions et positions. Proposition en lignes uniquement.

**Assemblage précédent : pièce 3 × 3 avec départ de couloir vers le bas.**
`room-3x3-south-corridor-wireframe.svg` reprend la pièce avec une case de
dallage seul en bas au centre, puis une dixième case à murs gauche et droit
à la position (6,15). Le couloir occupe x=6..12, y=15..20, son sol libre
x=7..11. La projection, les dimensions et le motif de dalles sont conservés.
Les six interfaces de murs communes restent internes (72 arêtes omises).

Cet assemblage exact montre une limite des pièces existantes : chaque mur
du couloir touche le mur sud de la pièce par une arête verticale, en (6,15)
ou (12,15), sans raccord de pleine épaisseur. Les faces de bout sont donc
conservées. Le pilier proposé ci-dessus apporte maintenant ce retour spécifique.
Le JSON et la vue `-seams.svg` conservent cette étude, sans intégration au jeu.

**Variante précédente : une case avec murs gauche et droit.**
`side-walls-cell-wireframe.svg` conserve les deux murs latéraux à x=0..1
et x=5..6, y=0..5, hauteur 2,2 et épaisseur 1. La projection et le vecteur
de hauteur sont identiques pour les deux murs. Le sol à z=0 couvre x=1..5,
y=0..5 : 18 dalles dont les joints reprennent le motif commun découpé aux
pieds des murs. Le haut et le bas restent ouverts. Les lignes masquées sont
cachées. Le JSON et la vue de construction conservent cette géométrie de revue.

**Assemblage précédent : pièce de 3 × 3 cases.**
L'utilisateur a corrigé sa demande initiale de 3 × 2 en 3 × 3.
`room-3x3-wireframe.svg` assemble les neuf études, avec des translations par
multiples de 6 en X et de 5 en Y. En haut : coin gauche, mur nord, coin droit ;
au milieu : mur ouest, dallage seul, mur est ; en bas : coin gauche, mur sud,
coin droit. L'emprise complète est x=0..18, y=0..15, avec sol intérieur à z=0.

La projection, les dimensions des murs et les joints de chaque pièce sont
conservés. Les huit faces de bout communes sont internes (96 arêtes omises),
et la visibilité est calculée face à tous les murs. Les joints continus du
dallage entre cases sont conservés. La version `-seams.svg` repère les limites ;
le JSON conserve les neuf modèles et leurs positions. Les vues assemblée,
écartée et étroite sont disponibles dans `artifacts/room-3x3-wireframe-*.png`.
Cette composition est une proposition en lignes, sans intégration au jeu.

**Variante précédente : case sans mur, dallage seul.**
`floor-only-cell-wireframe.svg` couvre toute la case, x=0..6, y=0..5 à z=0.
La projection reste identique et les joints reprennent le motif complet avant
découpe aux pieds des murs : 19 dalles en six rangées (hauteur 1, puis cinq
rangées de 0,8). Les quatre côtés sont ouverts. Le dessin conserve l'échelle
uniforme des études précédentes et centre le sol sans réserver de place aux
murs absents. Le JSON conserve la géométrie de cette proposition en lignes.

**Variante précédente : coin inférieur droit.**
`lower-right-cell-wireframe.svg` réunit les murs est (x=5..6, y=0..5) et sud
(x=0..6, y=4..5) en un volume en L continu, hauteur 2,2 et épaisseur 1.
Le dallage à z=0 couvre x=0..5, y=0..4. La projection commune et les joints
du sol sont conservés ; les lignes masquées par les deux murs sont cachées.
Haut et gauche restent ouverts. Le JSON et le dessin `-construction.svg`
conservent cette proposition en lignes, sans intégration aux scènes.

**Variante précédente : coin inférieur gauche.**
`lower-left-cell-wireframe.svg` réunit les murs ouest (x=0..1, y=0..5) et sud
(x=0..6, y=4..5) en un volume en L continu, hauteur 2,2 et épaisseur 1.
Le dallage à z=0 couvre x=1..6, y=0..4, avec les joints existants coupés aux
pieds des murs. La projection reste inchangée ; les lignes masquées par le
volume sont cachées. Haut et droite restent ouverts. Le JSON et la version
`-construction.svg` enregistrent cette nouvelle proposition en lignes.

**Variante précédente : mur en bas uniquement.**
`south-wall-cell-wireframe.svg` place le mur à x=0..6, y=4..5, hauteur 2,2
et épaisseur 1. Le sol à z=0 couvre x=0..6, y=0..4 ; les rangées existantes
sont conservées et la dernière est coupée au pied du mur. La projection reste
identique : le volume au premier plan masque une partie du sol. L'option
« Arêtes cachées » permet de voir ces lignes. Haut, gauche et droite restent
ouverts. Les fichiers JSON et `-construction.svg` conservent cette étude.

**Variante précédente : mur à droite uniquement.**
`east-wall-cell-wireframe.svg` conserve le mur est du coin droit à x=5..6,
y=0..5, hauteur 2,2 et épaisseur 1, avec la projection inchangée. Le sol à z=0
couvre x=0..5, y=0..5. Les cinq rangées du coin droit gardent leurs joints ;
une rangée supplémentaire remplit y=0..1. Les lignes masquées par le mur
sont cachées dans la vue normale. Haut, gauche et bas restent ouverts.
Il s'agit d'une nouvelle proposition en lignes, avec JSON et dessin de construction.

**Variante précédente : mur à gauche uniquement.**
`west-wall-cell-wireframe.svg` retire le mur nord du coin gauche et conserve
le mur ouest à x=0..1, y=0..5, hauteur 2,2. La projection et le cadrage restent
identiques. Le sol à z=0 s'étend à x=1..6, y=0..5 : une rangée de hauteur 1
occupe l'ancienne emprise du mur nord, et les cinq rangées existantes de hauteur
0,8 gardent leurs joints. Haut, droite et bas sont ouverts. Le JSON et la
version `-construction.svg` enregistrent cette proposition en lignes.

**Assemblage précédent : trois cases à la suite.**
`three-cell-wireframe-join.svg` place le coin supérieur gauche à x=0,
le mur nord seul à x=6 et le coin supérieur droit à x=12. Les trois géométries,
les joints du dallage et la projection restent identiques aux études séparées.
Les faces de bout communes deviennent internes : leurs 24 arêtes sont omises.
La visibilité du sol est calculée face à l'ensemble des murs, notamment sous
le retour est. La version `-seams.svg` marque les interfaces x=6 et x=12 ; le
JSON conserve les trois modèles. Les joints continus du dallage à ces limites
restent visibles. Cet assemblage est une proposition en lignes, hors des scènes.

**Variante précédente : coin supérieur droit.**
`upper-right-cell-wireframe.svg` conserve le mur nord et place le retour à
x=5..6, y=0..5, toujours avec hauteur 2,2 et épaisseur 1. La projection reste
exactement `75 × (x - 0,18z ; y - 0,9z)` : seul le plan du mur change de côté.
Le sol est à z=0, x=0..5, y=1..5 ; les joints de la case nord sont conservés,
avec les dalles coupées au pied du mur est. Le volume masque une partie du sol
dans la projection : ces lignes sont cachées, et consultables avec l'option
« Arêtes cachées ». Le JSON et le dessin `-construction.svg` enregistrent
cette nouvelle proposition, sans approbation artistique ni intégration au jeu.

**Assemblage précédent : coin à gauche, mur nord à sa droite.**
`two-cell-wireframe-join.svg` réunit les deux études sans modifier leurs dimensions,
leur dallage ou leur projection. La case B reçoit uniquement la translation
(6,0,0), soit 450 px dans la projection source. Les faces de bout au raccord
x=6 deviennent internes ; leurs 12 arêtes sont retirées du tracé visible.
La version `-seam.svg` repère la jonction en suivant les plans du dessus,
de la façade puis du sol. Le JSON conserve les deux modèles et leurs positions.

Le contrôle ciblé `artifacts/check_wireframe_join.cjs` compare les modèles aux
deux JSON sources et vérifie 8 points de mur et 6 points de sol : écart projeté
maximal 0 px, sans vide ni chevauchement aux limites communes. Les vues jointive,
écartée et étroite ont été examinées. Le dallage conserve un joint vertical continu
à x=6 ; le test géométrique ne valide pas ce choix visuel. Aucune scène du jeu
ni aucun sprite peint n'est modifié par cette étude.

**Variante précédente : mur en haut uniquement.** À la demande de l'utilisateur,
`north-wall-cell-wireframe.svg` reprend la même case et la même projection :
le mur nord occupe x=0..6, y=0..1, avec hauteur 2,2 et épaisseur 1. Le retour
ouest est retiré ; le sol à z=0 couvre x=0..6, y=1..5. La première dalle de
chaque rangée se prolonge à gauche, et les autres joints restent à leur place.
Les côtés gauche, droit et bas sont ouverts. Le cadrage est conservé pour
comparer directement cette variante au coin. Le fichier JSON et la version
`-construction.svg` conservent la géométrie de cette proposition en lignes.

**Géométrie du coin acceptée.** L'utilisateur a répondu « ok très bien on avance »
à `wall-wireframe-aligned.svg`, puis l'a désigné comme le coin supérieur gauche
d'une case et a demandé le dallage dans la même perspective. Conserver les
murs et leur projection. Cette acceptation concerne le wireframe, pas les
anciens sprites peints ni une modification des scènes du jeu.

La nouvelle étude `corner-cell-floor-wireframe.svg` ajoute le sol à z=0 dans
le rectangle x=1..6, y=1..5. Il rejoint les pieds des deux murs. Les dalles
sont rectangulaires, en cinq rangées de hauteur 0,8 à joints décalés (16 dalles).
Toutes leurs arêtes sont projetées par la même fonction que les murs :
`écran(x,y,z) = 75 × (x - 0,18z ; y - 0,9z)`. L'origine d'affichage et le cadrage
sont communs. Les dimensions sont celles du schéma, pas de nouvelles règles
de taille des cases du jeu. La version `-construction.svg` expose les guides ;
le fichier JSON conserve les paramètres et le découpage du sol.

**Correction d'orientation :** le mur gauche doit suivre la verticale de
l'écran. L'utilisateur a rejeté la vue à deux points de fuite ci-dessous.
La proposition courante est `wall-wireframe-aligned.svg`, accompagnée de
`wall-wireframe-aligned-construction.svg` et `wall-wireframe-aligned.json`.
Elle conserve le volume en L, l'épaisseur 1 et la hauteur 2,2. Le plan est
aligné sur l'écran : X horizontal et Y vertical. Le relief est une translation
identique sur chaque face, sans élargissement du pied.

Il s'agit d'une projection parallèle oblique, avec directions de fuite
parallèles (à l'infini), et non de la caméra à deux points de fuite finie
proposée précédemment. Le vecteur de hauteur choisi pour ce dessin est
(-0,18 ; -0,9) par unité vers le sommet ; il est conservé après acceptation du coin.
L'orientation gauche verticale est une demande explicite de l'utilisateur.
Le dallage ajouté reste une proposition ; peinture et intégration sont des étapes ultérieures.

### Wireframe précédent rejeté pour son orientation

**Nouvelle demande : wireframe à valider.** L'utilisateur a rejeté aussi
`corner-parallel-courses.png` et demande désormais uniquement des lignes,
avec des lignes de fuite et des géométries cohérentes. L'ancienne projection
oblique ci-dessous est suspendue ; son vecteur était un choix de l'assistant.

La proposition `wall-wireframe.svg` représente un prisme en L, de largeur
constante 1, de hauteur 2,2 et de branches de longueur 6 et 5. Aucun socle
évasé n'est ajouté. La caméra est un sténopé horizontal (tangage et roulis
nuls) : les verticales sont parallèles ; les deux directions du plan du sol
convergent vers deux points sur une même ligne d'horizon.
`wall-wireframe-construction.svg` expose ces deux points de fuite.
`wall-wireframe-two-point.json` conserve la caméra, les dimensions et les
segments projetés. Les versions PNG sont des rendus de ces lignes.

Cette caméra à deux points de fuite est une proposition explicite de l'assistant,
**pas une validation artistique ni un changement de caméra du jeu**. Elle fait
converger les axes du sol, contrairement à l'ancien guide oblique. Attendre
l'avis de l'utilisateur sur ce wireframe avant toute nouvelle peinture.

## Ancienne convention suspendue

Convention `dungeon-parallel-v1`, fixée le 22 octobre 2026 à la demande de
l'utilisateur de mémoriser une perspective. Elle ne gouverne plus de nouvelles
générations tant que la revue du wireframe n'est pas terminée.
Le vecteur chiffré est un choix de calibration de l'assistant, pas une mesure
exacte extraite de la maquette ni une approbation artistique de l'utilisateur.
Le rendu actuel reste à corriger selon cette convention.

La dernière maquette fournie est l'unique référence de style et de palette :
`assets/dungeon/gloom-kit/reference.png`. La projection définie ici doit
rester identique dans chaque génération. Ne pas déduire une nouvelle caméra
de la silhouette d'un sprite isolé ni d'une variante intermédiaire.

## Caméra unique

- Projection parallèle oblique en 2,5D : aucun point de fuite ni changement
  d'angle en fonction de la position dans la salle. Ne pas demander une vue
  isométrique : les axes du sol restent horizontaux et verticaux dans l'image.
- Axe horizontal du sol : droite de l'image. Axe de profondeur du sol : bas
  de l'image. Garder le quadrillage et les proportions des dalles existants.
- Le sommet est au-dessus et légèrement à gauche de son pied. Pour un mur
  de hauteur de référence, le vecteur **sommet → pied est (+16,+96)**.
  C'est un rapport de projection, pas la taille obligatoire de chaque sprite.
  À une autre échelle uniforme, multiplier les deux composantes ensemble.
- Le même vecteur s'applique à gauche, à droite, au nord, au sud, aux angles
  convexes, aux angles concaves et aux jonctions. Ne jamais le retourner
  pour montrer automatiquement une face du côté extérieur de la salle.
- Le relief se projette donc vers la droite sur les deux murs latéraux :
  vers l'intérieur de la salle pour le mur gauche, vers l'extérieur pour
  le mur droit. L'orientation d'un bord exposé choisit sa connexion, pas la caméra.

### Source commune et guide géométrique

Les valeurs sont enregistrées dans `perspective-contract.json`. Le guide
`perspective-geometry.svg` et son aperçu `perspective-geometry.png` sont produits
par `tools/render_perspective_guide.gd` à partir de ce contrat. Les formes montrent
des volumes de calibration sans texture ; elles ne sont pas des sprites du jeu.
Les faces de bout ferment ces volumes isolés. Une connexion entre modules
doit ouvrir ces bouts et joindre leurs faces, sans répéter une face de fermeture.

`perspective-room-guide.png` montre les mêmes règles sur une salle assemblée.
Les quatre flèches dorées relient un point du dessus à son pied : elles ont
toutes le même sens et la même longueur. Ce schéma explique la projection ;
son sol quadrillé et ses aplats ne remplacent pas le dallage ni la matière du jeu.

Régénération des deux schémas, sans modifier les assets de jeu :

```text
godot --headless --path . --script tools/render_perspective_guide.gd
```

Pour un point du sol `P`, une hauteur relative `h` (0 au sol, 1 au sommet) et
une échelle uniforme `s`, la projection est :

```text
écran(P, h) = origine + s × (P - h × (16, 96))
```

Un point du dessus à `T` rejoint donc son pied à `T + s × (16, 96)`.
Une façade doit rejoindre ces deux niveaux, et ses joints intermédiaires
suivent une fraction du même vecteur. Le contour du sol sous le mur est celui
du pied. Le dessus ne sert pas de bord de découpe du dallage.

Ces coordonnées sont une convention de dessin des assets 2D ; elles ne
changent pas la Camera2D, le quadrillage logique ou l'échelle du jeu.

## Un volume continu

- Le dessus, le rebord, les assises et le pied décrivent le même mur.
  La projection totale (+16,+96) se répartit sur toute sa hauteur ; ne pas
  ajouter ce décalage une deuxième fois à chaque couche.
- Correction explicite de l'utilisateur : le mur ne s'élargit pas vers son
  pied. Conserver une épaisseur constante, sans base évasée ni socle saillant.
  Un décalage de projection n'autorise pas à agrandir les pierres inférieures.
- La façade commence au bord inférieur du dessus, sans bande de fond visible
  entre les deux. Le pied rejoint le plan du sol, et non le plan des chapeaux.
- Un coin est le changement de direction d'un volume continu. Il ne doit
  introduire ni biseau diagonal indépendant ni triangle noir de compensation.
- Les pierres voisines sont séparées par un joint maçonné. Aucun espace
  transparent ne doit donner l'impression qu'une pierre flotte.
- Définir les ports sur les extrémités peintes réelles. Conserver des sprites
  entiers, sans étirement, découpe de silhouette ni chevauchement des bouts
  peints pour masquer un raccord. Si un module ne peut pas joindre, son asset
  est à reprendre ; ne pas répartir un grand vide entre les pierres.

## Matière et lumière constantes

- Une seule lumière directionnelle peinte, venant du haut gauche de l'image.
  La direction de la lumière est indépendante du côté du mur.
- Référence des dessus : les pierres non éclairées de la dernière maquette,
  `assets/dungeon/gloom-kit/reference.png`. Les anciennes planches générées,
  dont cap-muted-v11, ne sont plus des références de couleur.
- Retrouver l'ardoise sombre et les ombres bleu nuit de cette maquette, avec
  quelques fissures violettes lumineuses localisées. Garder les dalles calmes
  et lisibles ; éviter les bordures blanches et la texture en diagonales répétées.
- Dessus horizontaux, verticaux et coins : même matière, teinte et plage de
  valeurs. Seules les faces différemment orientées reçoivent l'ombre prévue.
- Chaque prompt doit joindre la référence canonique, identifier l'image de
  géométrie séparément et rappeler le vecteur (+16,+96) et la lumière haut gauche.
  Une variante générée ne remplace jamais silencieusement la référence de couleur.

## Mémoire obligatoire pour chaque génération

Lire ce document au début de chaque reprise du travail. Joindre le guide
géométrique et la même référence de matière, en précisant le rôle de chacun.
Conserver ce bloc dans chaque prompt, avec le descriptif du module demandé :

> Perspective contract: dungeon-parallel-v1. Parallel oblique 2.5D projection.
> Ground X is screen-right, ground Y is screen-down; no isometric ground axes.
> From each top point to its corresponding foot use (+16,+96), uniformly scaled.
> Use that identical vector on every side, corner, cap and masonry course.
> Never mirror the camera or the painted lighting for the opposite wall.
> Keep the attached geometry guide's axes and silhouette. Use ONLY the original
> gloom-kit/reference.png mockup for material; painted light comes from upper left.
> Preserve a continuous masonry volume and opaque mortar at internal joints.

Enregistrer l'identifiant de convention et les fichiers de référence dans la
provenance de chaque nouvelle planche. Une génération qui change de projection
est écartée, même si son détail de pierre est réussi. Une évolution de la
convention demande une modification explicite de ce document et du contrat,
ainsi qu'un nouveau guide ; ne jamais la faire implicitement dans un prompt.

## Validation avant propagation

L'utilisateur demande maintenant la validation d'un seul sprite avant d'aller
plus loin. Il aime l'aspect de la deuxième version `corner-review.png`, mais
demande de redresser sa base évasée. Il a également rejeté
`corner-straight-foot.png` : base encore incorrecte et perspectives incohérentes.
La proposition peinte suivante,
`assets/dungeon/gloom-kit/proposals/corner-parallel-courses.png`, a été rejetée.
Elle repart d'un guide où toutes les assises sont dessinées :
`corner-courses-guide.svg` et son aperçu PNG. Les deux faces de bout gardent
des côtés parallèles ; le petit bout mesure 128 px au sommet comme au pied,
et le vecteur de hauteur est (+32,+192), soit le contrat à ×2.
Le PNG généré interprète ce guide et doit être jugé visuellement ; il n'est
pas une reproduction géométrique exacte garantie. Les essais intermédiaires
et les prompts sont consignés dans `proposals/parallel-courses-review.json`
sous `assets/dungeon/gloom-kit/`.
Attendre son accord explicite
avant les autres générations et la mise à jour des scènes.

1. Assembler dans Godot un mur gauche, un mur droit, un mur horizontal et
   leurs coins, avec le sol existant, à la même échelle et sous la même caméra.
2. Examiner à taille normale et à ×2 : sens du relief, continuité dessus/façade,
   couleur commune et absence de vides entre pierres.
3. Examiner les extrémités à ×4. Une mesure de pixels aide à placer un port,
   mais ne prouve pas la qualité de la perspective.
4. Propager aux salles et couloirs seulement après cette comparaison commune.

## Historique à ne pas reproduire

- `31e72bf` : sauvegarde poussée avant cette reprise de relief.
- Premier essai de relief latéral : faces dirigées vers l'extérieur de chaque
  mur, donc deux projections opposées ; générations séparées donnant des
  différences de couleur, de largeur et des joints ouverts. Rejeté par
  l'utilisateur. Prompts archivés dans `lateral-volume-generation.json`.
  Les 14 PNG de cette famille et leurs imports sont désormais retirés de
  `assets/` et conservés dans `artifacts/lateral-volume-rejected/`. Aucun script
  actif ne les référence. En particulier, les planches `compact-relief*` ne
  doivent servir ni de guide de géométrie ni de référence de matière.
  Leurs anciens aperçus dans la conversation restent des essais rejetés.
- L'ancienne consigne « TOPS ONLY » avait aplati les murs ; elle est également
  remplacée par cette convention. Aucun de ces essais n'est un modèle approuvé.
- Une tentative de volumes complets a ensuite incliné les axes du sol. Elle
  a été écartée avant intégration ; le guide géométrique exact évite de laisser
  le générateur réinterpréter la caméra à partir du seul mot « perspective ».
