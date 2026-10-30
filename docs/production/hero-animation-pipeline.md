# Produire les animations 2D des héros depuis un modèle 3D

Référence de production au 28 octobre 2026. Le Vulpin sert de premier cas
complet : **modèle Meshy riggé → poses fixes dans Blender → rendus de tout le
personnage → sprites 2D → scènes de contrôle dans Godot**. Cette méthode conserve
le même modèle et la même peinture dans toutes les images, sans assembler des
morceaux d'illustration pendant le jeu.

Les scènes du Vulpin restent disponibles pour inspecter les poses. Leurs sprites
sont maintenant aussi utilisés dans les raids jouables par
`scripts/game/vulpin_actor.gd` (intégration du 28 octobre). Les performances sur
téléphone et le verrouillage précis des pieds pendant les déplacements restent
à vérifier. Un test technique réussi ne constitue pas une validation artistique.

## Points de départ

- [Index des sources actuelles et des essais abandonnés](../reference/vulpin-review/README.md).
- [Commandes de reproduction et contrôles](hero-animation-reproduction.md).
- [Original Meshy et provenance](../reference/vulpin-review/source/README.md).
- [Inventaire vérifiable des fichiers indispensables](../reference/vulpin-review/pipeline-manifest.json).
- [Décisions et historique détaillé](../../AGENTS.md).
- [Branchement aux états du raid](vulpin-gameplay.md).

Pour un nouveau héros, lire les étapes ci-dessous, puis partir de la recette de
l'action correspondante dans l'index. Les scripts actuels sont des recettes
Vulpin spécialisées, pas un système automatique de transfert d'animation.

## Ce qui fait autorité

La silhouette et les matières des animations actuelles viennent du GLB Meshy
fourni par l'utilisateur. Les illustrations [v3 sans armes](../reference/vulpin-review/v3-free-hands/)
et [v4 des états](../reference/vulpin-review/v4-action-states/) restent les
références d'intention. Les parties cachées des références multivues étaient des
interprétations : elles ne sont pas des images calibrées d'un même modèle.

Le Vulpin vole et n'attaque pas le cœur. Il n'a aucune arme. Seuls les deux petits
outils de crochetage apparaissent pendant les actions de crochetage. Le repos
est une image fixe par orientation. La mort actuelle comporte une chute sur les
genoux, puis en avant, suivie d'une image fixe : cette décision du 28 octobre
remplace l'ancienne consigne « pas de chute ».

Ne pas reprendre les anciennes animations de mannequin, la marionnette peinte
par morceaux, ni l'ancien APK d'essai comme versions actuelles. L'utilisateur
avait rejeté leur qualité ou leur mouvement.

## Préserver les entrées avant de poser

Conserver le GLB original immuable, son SHA256, les images de référence, la
provenance et les versions des outils. L'original Vulpin est maintenant archivé
dans `docs/reference/vulpin-review/source/`, sous `.gdignore`. Il ne sert pas au
rendu du jeu. Les recettes courantes utilisent cette copie relative au dépôt,
sans dépendre du dossier Téléchargements.

Le GLB Vulpin contient un maillage `output_unwrapped`, une armature
`SmartRigArmature` de 57 os, des poids et des textures intégrées. Il n'a ni clips
d'animation ni morphs de visage. Un import réussi ne prouve pas que le rig se
déforme correctement : tester séparément jambes, bras, tête, doigts et queue,
puis restaurer la pose et vérifier le retour exact.

L'[inspection enregistrée](../reference/vulpin-review/v15-meshy-inspection/inspection.json)
et son [script](../reference/vulpin-review/v15-meshy-inspection/inspect_model.py)
montrent comment relever les données. Exclure l'objet caché de visualisation
des os, `Icosphere`, des dimensions et du cadrage du personnage.

## Retrouver les os et construire les poses

Les numéros des os Meshy ne sont pas un standard. Pour chaque nouveau héros,
relever la hiérarchie, les positions de repos et les sommets influencés avant
de remplacer les noms dans les recettes.

| Fonction sur le Vulpin | Os ou chaîne actuelle |
| --- | --- |
| Racine du corps | `Bone_000` |
| Colonne vers la tête | `001 → 004 → 003 → 002 → 022 → 021` |
| Tête | `Bone_021` |
| Jambe droite / gauche | `009 → 008 → 007` / `014 → 013 → 012` |
| Bras droit / gauche | `026 → 025 → 024` / `031 → 030 → 029` |
| Référence de direction de la main droite / gauche | `023` / `028` |
| Queue | `019 → 018 → 017 → 016 → 015` |
| Doigts | chaînes `035→034→033`, `038→037→036`, `041→040→039`, `044→043→042`, `047→046→045`, `050→049→048`, `053→052→051`, `056→055→054` |

Dans ce modèle, Z est vertical et l'avant est −Y. Les recettes mémorisent les
matrices de repos en coordonnées monde (`R`), les têtes d'os (`H`) et l'inverse
de la matrice de l'armature (`AI`). `set_world` applique une rotation par rapport
au repos et une position de tête, puis reconvertit dans l'espace de l'armature.
Le maillage évalué par le dependency graph sert aux mesures, pas le maillage
de repos.

Les coudes et genoux utilisent une résolution à deux segments de longueur fixe
avec un pôle de flexion. Une cible hors d'atteinte doit conduire à déplacer la
posture ou la cible, pas à allonger le membre. La chute utilise une limitation
explicite des cibles à la portée ; contrôler ensuite la position réellement
obtenue. Les vecteurs `mathutils` sont en précision simple : une marge intérieure
de 1 mm et une tolérance cohérente évitent les erreurs numériques aux limites.

Chaque pose choisie est enregistrée sur une image Blender avec des clés
`CONSTANT` pour position, quaternion et échelle des os, ainsi que la translation
de l'armature. Les images Blender sont des indices de pose, **pas la cadence
finale**. Les durées sont stockées séparément. Le `.blend` doit être sauvegardé
avec ses ressources intégrées et rechargé dans un second processus pour vérifier
toutes les poses.

## Garder la même perspective et le même ancrage

La projection du jeu vient de
[`catalog.tres`](../../assets/dungeon/isometric-kit/catalog.tres), pour une case
source de 256 pixels :

```text
projection_x = (0.5, -0.5, 0)
projection_y = (0.25, 0.25, -0.6123724356957945)
écran_x = 128 × (x − y)
écran_y = 64 × (x + y) − 156.7673435 × z
```

Le coefficient vertical n'est pas 181 pixels par unité. Le relire dans le
catalogue si la projection change. La caméra orthographique Blender est à
30 degrés d'élévation, donnant un sol en losanges 2:1.

| Paramètre | Actions debout ou accroupies | Chute actuelle |
| --- | --- | --- |
| Rendu maître carré | 512 px | 768 px |
| Canevas logique du sprite | 256 px | 384 px |
| Échelle orthographique | 2.35 | 3.525 |
| Racine au sol du modèle | `(0, −0.20, 0)` | identique |
| Cible caméra au-dessus de la racine | Z +0.72 | Z +0.46 |
| Ancre dans le sprite | environ `(128, 195.92598)` | environ `(192.00009, 235.39716)` |
| Échelle native du héros | 0.85 | 0.85 |

Le rapport `256/2.35 = 384/3.525` conserve la densité de pixels. Agrandir le
canevas de chute ne grossit donc pas le personnage. Recalculer l'ancre en
projetant la racine avec `world_to_camera_view`; ne pas la deviner à partir du
rectangle visible. Utiliser les métadonnées de la ressource ou de
`registration.json`, particulièrement pour la chute.

Les vecteurs caméra relatifs à la cible sont : SE `(-1,-1,√(2/3))`, SW
`(1,-1,√(2/3))`, NW `(1,1,√(2/3))`, NE `(-1,1,√(2/3))`, normalisés à une
distance de 8. Les quatre directions sont de vrais rendus du même modèle,
pas des miroirs susceptibles d'inverser poche ou outils.

Conversion modèle vers grille pour les actions à caméra standard : soustraire
la racine, donc utiliser `(x,y+0.20,z)`, puis multiplier par
`k = 0.85 / (2.35 × √0.5) ≈ 0.5115240545` :

```text
SE : (−y, −x, z)    SW : (x, −y, z)
NW : ( y,  x, z)    NE : (−x, y, z)
```

Conserver un canevas et une ancre communs à toutes les poses d'une action.
Ne jamais recentrer chaque silhouette sur ses propres limites : cela fait
glisser les pieds et les mains, même si chaque image isolée paraît correcte.

## Rendu et traitement des images

Recette actuelle : Blender 5.2.1 LTS, Cycles 40 échantillons avec débruitage,
PNG RGBA transparent, transformation de vue `Standard`, look `None`. Garder
les matières du GLB. Les lumières tournent avec la caméra pour conserver la
même lecture visuelle dans chaque orientation.

L'éclairage exact est défini dans chaque script de rendu : monde
`(0.55,0.58,0.65)` à 0.65 ; trois lumières AREA DISK, Key 520, Fill 200, Rim 290,
tailles 5.1 / 5.1 / 3.4. Leurs positions de base `(-2,-3,4)`, `(3,-1,2)` et
`(1,3,3)` sont multipliées par 1.7 puis décalées de +0.8 en Z ; elles visent
Z=0.8. Ces valeurs sont une recette Vulpin, à contrôler sur la peinture du
nouveau héros avant de produire tout son jeu d'images.

`prepare.cjs` réduit uniformément les maîtres avec Sharp, sans déformer un
membre ni repeindre une articulation. Les sprites gardent une interpolation
linéaire. Contrôler le rendu à l'échelle du jeu et à grande taille : une image
très détaillée de près n'assure pas sa lisibilité sur téléphone.

Les six actions à huit poses utilisent actuellement quatre feuilles
2048×256 par action. La chute est le modèle plus compact : elle coupe les
marges transparentes puis place les 40 images dans un atlas 1024×1315 avec une
marge de préparation de 1 pixel et un padding de 2 pixels par côté, soit
4 pixels entre rectangles. Les
`AtlasTexture.margin` restituent le canevas logique 384×384 :

```text
region = rectangle de l'image dans l'atlas
margin = Rect2(trimX, trimY, canvasW − trimW, canvasH − trimH)
filter_clip = true
```

La mort fixe réutilise la dernière image de chute. Le repos réutilise le
premier sprite neutre des feuilles de dégâts. Le charger seul charge cependant
les feuilles de dégâts complètes : partage des fichiers ne signifie pas
chargement de quatre petits rectangles seulement.

## Mouvement et contacts déjà résolus

### Marche et course

La translation sur le couloir et le choix de pose utilisent une horloge unique.
La vitesse vient du déplacement du pied en phase d'appui, converti vers la
grille avec l'échelle du héros. Accélérer uniquement le sprite ou uniquement le
déplacement produirait du patinage.

La marche a été créée à 10 poses/s et 0.65 unité modèle/s. Le choix utilisateur
de l'ancien ×1.5 comme base donne **15 poses/s et 0.975 unité/s** dans la scène
native. Les anciens WebP de v16 restent à leur cadence d'auteur. La course est
à **16 poses/s et 2 unités/s**, soit environ 2.05 fois la marche actuelle.
Les changements de direction aux bouts des couloirs sont instantanés ; aucune
animation de demi-tour n'a été créée.

Pour la marche, les sommets des semelles sont identifiés au repos par Z<0.045
et le côté en X. Contrôler le pied d'appui et la levée du pied de retour.
Pour la course, autoriser explicitement les deux poses aériennes. Refaire ces
masques pour un héros ayant une autre anatomie.

### Dégâts

v18 basculait le torse de −16° à +16° très rapidement et ressemblait à un
éternuement. v19 conserve un recul vers l'arrière, jusqu'à −25°, avec les mains
levées, une tenue de 120 ms au maximum et un retour progressif. Les pieds
restent fixes. La présentation ne doit pas ajouter de recul de case ni de
retard à la simulation. Sans rig facial, les yeux et la bouche ne reproduisent
pas l'expression de l'illustration de référence.

### Porte et coffre

La position du héros doit venir de la cible de contact projetée, pas d'un
décalage visuel arbitraire :

```text
offset_outil = (pointe_projetée_dans_sprite − ancre) × échelle_héros
position_héros = inverse_projection(cible_dans_le_donjon − offset_outil)
```

Lire les contacts, limites et orientations dans les `registration.json`,
les scripts de stage et le catalogue natif. La porte utilise une serrure à
Z=0.32 case (v26, porte compacte v11/v12). La cible source est
`(0,−1.06,0.32/k)` : l'ancien −0.86 alignait l'outil mais faisait pénétrer la
tête dans la couronne. La tentative à Z=.49 masquait les mains sous la tête.
V26 garde les pieds et la caméra, avance les poignets de .10 unité et les
écarte de .035. Le contrôle actuel découpe les triangles du personnage selon
les boîtes XZ de chaque face de maçonnerie, puis vérifie leur séparation en Y.
Ne pas utiliser un plan infini de couronne : il couvre artificiellement
l'ouverture. Une projection XZ entièrement disjointe est un succès sans
distance minimale de contact, pas une distance infinie mesurée.
Voir [le contrôle de passage et de maçonnerie](../../tools/verify_compact_door_passage.py)
et [la sélection intégrée](../reference/door-redesign/seal-v1/hero-fit-v12-integrated/selection.json).

La vérification géométrique de l’ouverture ne suffit pas à garantir la superposition
des sprites pendant la traversée. Depuis v14, les deux montants, la couronne et
le battant fermé sont des supports de tri indépendants. Conserver ce découpage
pour les prochains héros ; comparer leur passage complet, pas seulement une pose
centrée. Voir [la preuve de traversée](../reference/door-redesign/seal-v1/hero-fit-v14-passage/README.md)
et `tools/capture_door_passage.gd` (quatre directions et 49 positions).

Le coffre verrouillé a une cible à Z=0.15 case et une pointe source
`(0,−1.0,0.15/k)`. Les centres de serrure visibles sont mesurés dans les
textures préparées, puis reconvertis par le catalogue. Les deux serrures
masquées sont déduites par symétrie de leur décalage dans la grille ; ce sont
des positions inférées. Les mesures et leur calcul sont conservés dans
[`calibrate_chests.cjs`](../reference/vulpin-review/v22-chest-lockpick/calibrate_chests.cjs)
et [`chest-contacts.json`](../reference/vulpin-review/v22-chest-lockpick/chest-contacts.json).

Ne pas tester le coffre comme un plan vertical infini : la tête peut dépasser
ce plan au-dessus du couvercle sans collision. Le contrôle retient les
triangles qui atteignent sa hauteur réelle et ses limites de catalogue.
Ces limites sont une approximation de placement d'une peinture 2D, pas un
modèle exact du couvercle et des pointes.

Le crochetage garde un coffre **fermé et verrouillé** pendant toute la boucle.
L'action sans serrure garde un coffre **entrouvert et déverrouillé** pendant
toute la séquence. Aucun changement automatique fermé→ouvert dans cette
dernière ; son couvercle n'est pas animé. L'image d'ombre doit correspondre à
l'état du coffre.

Les stages réutilisent l'ordre des volumes du renderer du donjon. Une vue
fantôme est utile pour contrôler les outils, mais seule la vue normale permet
de juger les occultations. Ne pas forcer systématiquement le héros devant la
porte ou le coffre avec un z-index élevé.

### Chute et mort

La chute ne consiste pas à incliner le personnage rigide. Les hanches
descendent, les genoux prennent appui, les bras vont vers l'avant, puis le
torse se pose. Le thorax peut s'incliner indépendamment du bassin et la tête
tourne sur le côté. Le visage du modèle reste inchangé, yeux ouverts.

Les corrections à conserver sont les suivantes :

- Des bottes orientées comme debout pendant l'agenouillement traversaient le
  sol. Corriger les pieds avant la translation globale de mise au sol, sinon
  cette translation fait remonter les hanches et crée un rebond.
- Pour le corps couché, mesurer l'ensemble du maillage, pas le masque des
  semelles. La queue, la cuisse, le museau ou les doigts peuvent devenir les
  points les plus bas.
- Orienter la paume avec une base complète, pas seulement la direction de
  l'os : l'alignement le plus court laissait la main sur la tranche.
- Inclure les chaînes de doigts dans le contrôle de contact, pas seulement
  les poignets.
- L'impression de pompes venait notamment des mains trop proches des
  épaules. La pose finale avance désormais les mains de plus de 0.26 unité
  devant les épaules, avec un angle de coude supérieur à 165°. Le test de
  relecture du `.blend` protège ces deux critères.

La durée actuelle est **550 ms**, l'ancien ×2 devenu ×1. Les dix durées sont
`[40,45,45,45,50,50,50,50,70,105]` ms. Changer cette cadence met à jour les
métadonnées, la ressource, le contrôle natif et les aperçus ; les pixels n'ont
pas besoin d'être rendus de nouveau. Le cadavre persiste. La pause de 1.2 s
des démonstrations en boucle est une aide de lecture, pas une durée de mort
dans le gameplay.

## Contrôler avant de multiplier les héros

1. Vérifier le SHA de l'original, les poids, les noms et la géométrie finie.
2. Poser un premier cycle et le montrer dans une direction avant de multiplier
   les rendus. Garder la même caméra et l'ancre.
3. Contrôler les appuis, les cibles accessibles et les contacts selon l'action.
4. Recharger le `.blend` et retrouver toutes les poses enregistrées, leurs
   limites et les pointes d'outil. Ne pas se contenter d'un script qui a fini.
5. Vérifier alpha non vide, absence de découpage, images distinctes, séquence,
   durées, dernière image persistante et marges d'atlas.
6. Dans Godot, vérifier les quatre directions, pause, pas à pas, reprise,
   vitesses relatives, répétition optionnelle, positions et occultations avec
   les vraies portes/coffres. Contrôler portrait et paysage court.
7. Regarder les planches complètes, les vues avant/arrière, le mouvement à
   vitesse normale et ralentie, puis à la taille mobile réelle. Les mesures
   ne prouvent pas l'absence d'auto-intersection ni le naturel de l'animation.
8. Mesurer séparément PNG sur disque, mémoire RGBA décodée et coût réel sur
   téléphone. Ne pas annoncer la taille d'un APK à partir des seuls PNG.

Les commandes natives utilisent les scènes de revue sans instancier la partie
ni accéder aux sauvegardes. Un APK exige une nouvelle demande explicite de
l'utilisateur. La validation native n'autorise pas sa construction.

## Ajouter le prochain héros sans repartir de zéro

Créer son propre dossier de sources et une fiche reprenant : identité et
accessoires autorisés, SHA du modèle, os sémantiques, axes et unité, taille
dans une case, caméra, ancre, éclairage, états, durées, déplacement par cycle,
cibles d'outils, contacts et limites connues. Adapter les paramètres liés à
l'anatomie ; garder la projection du donjon et les contrats de ressources.

Commencer par repos + marche dans un couloir. Faire valider silhouette, taille
et mouvement, puis course, dégâts, interactions et mort. Les scripts Vulpin
réutilisables donnent les solveurs, le rendu, la préparation et les contrôles ;
ils ne donnent pas les bonnes longueurs, cibles et poids pour un autre rig.

Pour chaque action, conserver ensemble : recette de pose, `.blend` intégré,
`poses.json`, recette de préparation, atlas/ressources/registration, rapports
de validation, captures et référence à la décision utilisateur. Les maîtres
sont régénérables mais utiles pendant la revue. Documenter immédiatement
toute modification d'ancre, de cadence, de cible ou de version retenue dans
l'index et l'inventaire. Ne pas supprimer les anciennes versions tant qu'une
recette active y lit un fichier.

La copie locale et les hashes protègent contre une dépendance oubliée ou une
modification accidentelle. Ils ne remplacent pas une sauvegarde hors de la
machine. Les commits/pushes doivent inclure les sources utiles et les rapports, en
contrôlant les fichiers ignorés et les gros fichiers.
