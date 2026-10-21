# Dungeon Empire — conception

## 0. État implémenté : fondation visuelle 2D

Cette branche remplace le prototype mobile/2.5D par une scène statique Godot 2D.
La seule fonction actuelle est d'afficher la composition approuvée dans
`docs/reference/approved-scene.png`, à partir de ses éléments réutilisables.

### Carte et rendu

- Scène de démarrage : `scenes/DungeonPreview.tscn`.
- Carte fixe : `assets/layouts/preview.tres`, grille de **28 × 18 cases**.
- **255 cases de sol**, réparties entre **six salles** et leurs couloirs.
- Cases de **54 × 54 px**, marge de composition de **90 px**.
- Composition totale de **1692 × 1152 px**.
- Les couloirs de liaison ont une largeur de **deux cases**, soit **108 px**.
- Les chiffres `0` à `7` définissent les variantes de sol ; `.` est une case
  vide. Le choix des variantes est enregistré et ne change pas au lancement.
- **19 sprites** : huit sols, six murs directionnels et cinq angles ; une
  vingtième texture fournit le fond bleu nuit.
- Murs latéraux de 52 px d'épaisseur, segments nord de 44 px de haut, segments
  sud de 50 px de haut. Les façades et leur éclairage ne sont pas pivotés.
- Les murs se dessinent aux limites entre sol et vide. Chaque sommet examine
  ses quatre cases voisines : une case de sol produit un angle extérieur,
  trois cases de sol produisent un angle rentrant dans la case vide.
- Les dalles sont dessinées en dernier pour conserver des passages dégagés.
  Le fond, les murs et les angles n'ont aucune collision à cette étape.

### Caméra et affichage

- Fenêtre initiale de **1280 × 720 px**, rendu GL Compatibility.
- La caméra centre la composition et adapte son zoom uniformément à la fenêtre.
  Elle garde le donjon entier visible en paysage, carré et portrait.
- Le rapport largeur/hauteur est préservé. L'espace restant affiche le fond
  sombre du viewport. En portrait, le donjon apparaît naturellement plus petit.
- Aucun contrôle de déplacement, zoom manuel ou interaction tactile.

### Périmètre de cette étape

Le démarrage affiche directement la scène. Il n'existe encore ni héros, cœur,
torches animées, pièges, combat, construction, génération procédurale, interface,
économie, progression, réseau ou persistance. Il n'y a donc aucun coût, palier,
prérequis, état de victoire/défaite ou sauvegarde à appliquer. Aucun paramètre de
playtest ne remplace des règles de progression.

### Limites connues

- Le kit est une découpe du prototype approuvé, avec des variations déjà peintes.
  Il conserve ses raccords et son niveau de détail ; ce n'est pas un nouveau
  dessin du donjon.
- Les variantes de raccord implémentées couvrent la carte fixe. Les contacts
  diagonaux entre deux seules cases de sol et les dispositions arbitraires
  d'un futur éditeur ne sont pas définis dans cette étape.
- La taille de case fait partie des proportions du kit. Changer seulement
  `cell_size` ne redimensionne pas les sprites et n'est pas pris en charge.
- Le cadrage est prévu pour des proportions mobiles, mais aucun export mobile,
  test sur téléphone ou profilage de performances n'est validé à cette étape.

## 1. Direction artistique conservée

Vue 2D de dessus avec façades de murs visibles, dalles bleu ardoise, pierre
épaisse et fond bleu nuit. L'orientation, les proportions et les détails viennent
du kit approuvé. Toute future ressource doit s'intégrer à cette référence.

Le héros, le cœur et les autres éléments précédemment discutés restent des
concepts futurs. Leur présence dans un concept visuel n'est pas une mécanique
implémentée. Leur ajout nécessite une étape distincte.

## 2. Historique

Le tag Git **v1.0.0** conserve l'ancien prototype 3D, ses règles et ses ressources.
Ses systèmes ne sont plus actifs dans cette nouvelle base. Le contenu futur du
jeu sera documenté au fur et à mesure de sa réintroduction explicite.

## 3. Vérification

`tools/test-mobile.ps1 -All` importe le projet, vérifie le chargement de la scène,
la présence des 255 dalles, la connexion des six salles, l'ouverture des couloirs
principaux et le cadrage aux tailles **1280 × 720**, **720 × 1280**, **800 × 800**
et **640 × 360**. Il vérifie aussi le démarrage de la scène principale.

L'option `-Capture` produit une image réelle du rendu Godot, à comparer avec la
composition approuvée. Elle nécessite un moteur graphique disponible.
