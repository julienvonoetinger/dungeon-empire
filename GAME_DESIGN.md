# Dungeon Empire — conception

## 0. État implémenté : carte statique de six salles en 2D

La scène principale `scenes/SixRoomPreview.tscn` assemble des sprites complets
à transparence native. Le plan conserve les six salles. Les images ont été
régénérées pour fournir des éléments indépendants : la nouvelle scène ne découpe
plus les silhouettes dans l'illustration d'origine.

**État visuel non validé — 21 octobre 2026 :** l'utilisateur a rejeté le rendu
actuel. Les murs latéraux mélangent des dessus de blocs répétés, des faces de
piliers et des pierres de remplissage qui ne forment pas un volume cohérent.
Le dallage s'éloigne également du dessin de référence. Les dimensions et règles
ci-dessous décrivent l'implémentation présente, sans valider son apparence.
La correction doit d'abord établir une portion cohérente de mur, angle, pilier
et sol confrontée à la référence d'origine. Les tests techniques ne constituent
pas une validation artistique.

Contraintes de correction demandées, encore non implémentées :
- hauteur et maçonnerie communes à l'entrée et aux autres murs ;
- joints décalés entre rangées, sans longues lignes verticales répétées ni
  prolongement systématique des joints du mur dans le sol ;
- bord extérieur séparé et présent sur tout contour réellement exposé, y compris
  aux raccords ; l'exclusion de toute la hauteur d'un pilier est trop large ;
- priorité à la comparaison visuelle avec le dessin initial, les sondes étant
  mises de côté à la demande de l'utilisateur pour cette calibration.

Diagnostic actuel : l'entrée utilise une hauteur de 191 px et une autre famille
de sprites, contre 117 px pour les autres murs nord. Les paires de dalles gardent
les mêmes limites tous les 192 px malgré l'alternance large/étroite. Les bords
extérieurs sont supprimés sur des rectangles de piliers et les segments trop
courts pour le sprite disponible sont ignorés. Ces règles expliquent les défauts
signalés ; elles ne sont pas les règles artistiques à conserver.

### Carte et assemblage

- `assets/layouts/six_rooms.tres` : **28 × 18 cases**, **255 cases de sol**,
  **six salles**, couloirs de **deux cases**. Case logique **96 px**, marge
  **160 px**, composition **3008 × 2048 px**, couloirs **192 px**.
- `scripts/alpha_kit.gd` sélectionne **27 définitions de sprites complets** dans **huit PNG**
  générés de `assets/dungeon/alpha-kit/`. Les rectangles de sélection comprennent
  leurs marges transparentes. Les rectangles de mesure servent uniquement au
  placement et à l'échelle uniforme : aucun masque ni détourage n'est calculé.
- `scripts/six_room_view.gd` crée **852 sprites**. Les deux torches et le sprite
  du cœur portent ce total à **855 sprites**. Avec les trois lumières, le
  catalogue de diagnostic contient **858 éléments**. Aucun Polygon2D ni shader
  de détourage ne dessine les éléments de cette scène.
- Le sol comporte une sous-couche de **255 dalles complètes de 112 px de large**,
  assombries par le multiplicateur **(0,50 ; 0,53 ; 0,60 ; 1)**, pour couvrir les
  petits intervalles de mortier. Chaque paire de cases reçoit une dalle large
  de **144 px** et une étroite de **60 px** ; leur ordre alterne selon la rangée.
  Une case isolée reçoit une dalle de **103 px**. Leurs hauteurs suivent les
  proportions du dessin, sans déformation. Sept dalles supplémentaires prolongent
  le sol sous l'entrée.
- Les bords exposés sont regroupés en segments. Les modules complets se recouvrent
  légèrement ; les extrémités ne sont pas tronquées pour atteindre une longueur.
  Hauteurs nominales de corps : nord **117 px**, sud **101 px**, entrée **191 px**.
  Les variantes conservent leurs proportions à la largeur calculée sur le dessin
  zéro ; leurs hauteurs peuvent donc légèrement différer de ces valeurs cibles.
  Largeur du corps des murs latéraux **68 px**, des piliers d'angle **68 px**,
  des contreforts latéraux **76 px**, centrés sur le mur.
- Le corps du mur et le bord extérieur sont des sprites séparés. Le bord mesure
  **24 px** de large avec **2 px** de recouvrement derrière le corps : largeur
  combinée **90 px**. Il existe seulement sur les segments exposés vers le vide,
  entre les niveaux de sol de la section. Il s'arrête avant les façades horizontales
  et les piliers d'angle ; il peut continuer derrière un contrefort sur un mur droit.
  Le rendu courant compte **99 sprites de corps latéral** et **102 de bord extérieur**.
- Les pierres du corps latéral s'arrêtent à chaque pilier et reprennent à son pied.
  Des pierres courtes entières complètent les intervalles restants, sans découpe,
  étirement ni rangée claire visible derrière les faces des colonnes.
  Les sommets des piliers sont simples ; les motifs sont sur leur face verticale.
  Toutes les faces de hauteur sont dirigées vers le bas de l'écran, sans rotation
  ni miroir. La comparaison entrée/salle haute utilise la même échelle de caméra.
- Les longs murs latéraux portent des piliers saillants. Leur nombre par segment
  est `max(0, floor((longueur_px - 100) / 320))`, réparti uniformément.
  Les angles dont les projections se chevauchent utilisent un seul sprite
  de raccord, avec une tête unique et une face continue.
- Ordre de dessin : sous-couche **Z 0**, dalles et bords extérieurs **Z 1**, murs **Z 2**,
  piliers **Z 3**, porte et torches **Z 4**. Le cœur a un parent au **Z 4**
  et son sprite au **Z 1 relatif**.
- Le fond extérieur est uni **#080e19**. Aucune image de scène complète n'est
  affichée en fond. La référence artistique n'est plus une texture du rendu
  principal.

### Variations de pierre

- **Stone Variation** est activé par défaut ; **Variation Seed = 173**.
  Six dessins de sol couvrent trois proportions : large, moyenne et étroite.
  Les façades nord et sud ont chacune deux dessins. Les piliers, la porte et
  le cœur conservent leur dessin.
- Le choix de variante et de teinte dépend des coordonnées, de la graine et
  de l'usage, sans horloge ni état aléatoire global. Reconstruire à réglages
  identiques reproduit les mêmes sprites, positions, échelles et teintes.
- Multiplicateurs de couleur des dalles supérieures : **0,84 à 1,10** selon le
  canal ; corps des murs : **0,92 à 1,03**. Les bords extérieurs ont une teinte
  fixe **(0,43 ; 0,46 ; 0,55 ; 1)**. Leur alpha reste **1**. La sous-couche conserve
  sa teinte fixe. Le détail peint et la silhouette viennent des PNG générés.
- Désactiver les variations choisit le dessin zéro et la teinte blanche des
  surfaces supérieures ; les placements, la sous-couche et les **855 sprites**
  restent identiques. Ces propriétés se règlent dans l'éditeur, sans commande
  de partie ni sauvegarde. Aucun accessoire ou animation n'est ajouté.

### Entrée et lumière

- Entrée au **nord de la case (3,3)**, dans la salle supérieure gauche.
  Seul cet emplacement est pris en charge. Si elle est désactivée, invalide ou
  placée ailleurs, le mur ordinaire reste fermé, sans porte ni torches.
- La porte et son arche utilisent le PNG transparent `entrance.png`, sans
  maçonnerie environnante ni sol incrusté. Largeur du corps **216 px**, bas centré
  en **(546,454)**. Deux modules entiers de `entrance-walls.png` forment la façade :
  leurs extrémités sont sous les colonnes et leur raccord central derrière l'arche.
- La sous-couche de sol remonte d'au moins **22 px** derrière les pieds.
  Les contours inférieurs des PNG créent la transition avec le dallage.
- Deux instances de `scenes/DungeonTorch.tscn` partagent le PNG RGBA
  `assets/dungeon/torches/torch-violet-v1.png`. Source **1024 × 1536 px** ;
  import Godot limité à **384 px**, soit **256 × 384 px**, sans mipmaps.
  Aucun matériau ni shader ne transforme son alpha.
- Chaque torche : échelle uniforme **0,48**, `centered = false`,
  décalage **(-128,-321)**. Pieds en **(430,454)** et **(662,454)**.
  Rectangle complet **122,88 × 184,32 px**, marges transparentes comprises,
  **Z 4**, masque de lumière **1**.
- Deux lumières fixes centrées en **(430,375)** et **(662,375)** :
  texture radiale **384 × 384 px**, couleur **#f02aff**, énergie **1,5**, masque **2**.
  Tous les sols et murs reçoivent le masque **2**. Piliers, porte, torches et
  sprite du cœur gardent le masque **1** et leur éclairage peint.
- Une reconstruction remplace les éléments générés sans duplication ; désactiver
  l'entrée retire ses torches et ses deux lumières. Les flammes restent statiques.

### Cœur du donjon

- Instance enregistrée de `scenes/DungeonHeart.tscn` sous **Dungeon/Heart**,
  dans la salle supérieure droite, à **(2368,784)**, échelle **1**, **Z 4**.
- Un seul sprite transparent de `assets/dungeon/alpha-kit/heart.png` réunit
  socle carré bleu ardoise, quatre pierres d'angle, sphère noire/vortex violet
  et lien d'énergie. Aucun anneau métallique. Il reprend le concept validé,
  avec un nouveau dessin complet plutôt qu'une reproduction pixel à pixel.
- Le sprite mesure **220 px** de largeur de corps ; son origine locale est
  **(-110,-147)**. Son alpha et sa lueur peinte sont intégrés au PNG.
- Le second enfant est une lumière fixe, position **(0,-6)**, texture
  **448 × 384 px**, couleur **(0,59 ; 0,13 ; 1)**, énergie **0,85**, masque **2**.
  Il y a donc **deux enfants** du cœur et **trois lumières** dans le donjon.
- Le cœur est purement visuel : aucune vie, destruction, interaction, collision,
  animation ou sauvegarde. Les reconstructions préservent cette instance
  enregistrée et ses enfants.

### Caméra et actualisation

- La configuration courante de `project.godot` lance `3x3CellRoom.tscn` avec
  **F5** ; `SixRoomPreview.tscn` conserve la carte complète. **F6** lance la scène sélectionnée.
  Fenêtre initiale **1280 × 720**, rendu **GL Compatibility**.
- La caméra centre la composition et ajuste uniformément son zoom. En portrait,
  toute la carte reste visible mais petite. Aucun déplacement ou zoom tactile.
- Dans l'éditeur, `Dungeon` vérifie toutes les **0,5 s** les scripts chargés et
  les réglages du plan. Un changement déclenche une reconstruction différée ;
  les demandes simultanées sont regroupées. **Actualiser le rendu** permet de
  la demander manuellement.
- Seuls les enfants générés sont remplacés ; les instances enregistrées sont
  préservées. Aucune géométrie n'est sauvegardée dans la scène. La vérification
  périodique est désactivée pendant le jeu.

### Diagnostic des positions — sondes

- **F3** active ou masque les sondes, désactivées par défaut. **R / Actualiser**
  recalcule l'inspection ; **F3 / Échap** la masque. Une reconstruction actualise
  aussi le diagnostic lorsqu'il est visible.
- **644 sondes fixes** vérifient couverture, catégorie, placement et correspondance
  de texture : **635** sur maçonnerie/sol/entrée, **9** sur le cœur. Leur position
  attendue est indépendante du sprite trouvé. Les sondes de sol ignorent le cœur
  afin de contrôler son substrat.
- Les sprites doivent avoir une échelle uniforme, aucune région Sprite2D active,
  aucun matériau, aucune inversion et un seul frame. Pour les atlas, leur région
  et leur image doivent correspondre aux métadonnées déclarées.
- La sélection ignore l'alpha inférieur à **0,5**, donc les marges transparentes
  et les halos faibles. Les images sont lues une fois par texture pendant une
  inspection ; ce diagnostic ne tourne pas continuellement lorsqu'il est masqué.
- Un clic sélectionne l'élément visible au Z le plus élevé. Les filtres permettent
  de viser sols, murs, piliers, entrée, cœur, lumières et effets. Les lumières
  n'interceptent pas les clics du filtre général.
- Le cadre affiché est l'emprise du sprite complet, pas une silhouette de
  collision. Le panneau indique identifiant, origine en pixels locaux à Dungeon,
  case de l'origine, dimensions, Z, nom du PNG, région dans l'atlas et UV locales
  au sprite. Le cadre inclut ses marges transparentes ; la sélection lit l'alpha.
- **Contours** et **Sondes** contrôlent les repères séparément. Jusqu'à
  **16 identifiants d'échec** sont affichés près des points. La sélection se
  conserve par identifiant après actualisation ; les identifiants ne sont pas
  persistants entre plans différents.
- **Exporter JSON** écrit `user://dungeon-probes.json` avec chemin effectif,
  positions, emprises, contours, régions source, UV locales, teintes et résultats.
  Une erreur d'écriture est affichée. Ce rapport n'est pas une sauvegarde de jeu.

### Comportement, persistance et limites

Aucun gameplay, coût, prérequis, progression, combat, économie, transition de
porte, génération de donjon, construction interactive ou sauvegarde n'est
implémenté. Le héros, les pièges et le HUD restent absents.

L'assemblage est contrôlé pour cette carte fixe. Il ne valide pas toutes les
formes de donjon ni les entrées latérales. La brume extérieure n'est pas
reproduite. Les nouveaux PNG sont conservés à leur résolution générée ; seul
l'import de la torche est réduit. L'optimisation mémoire, le profilage, les
exports et les contrôles sur téléphone restent à réaliser.

### Direction durable : assemblage pour un donjon personnalisable

**Clarification utilisateur du 22 octobre 2026 — objectif et règles de travail,
pas une fonctionnalité déjà livrée.** Le futur joueur doit pouvoir construire
un donjon cohérent. Les salles et couloirs doivent être assemblés par un système
commun à partir de l'occupation, du contour et des voisins. Les scènes existantes
servent d'exemples et de références visuelles ; chaque nouvelle scène ne doit
pas devenir un rendu indépendant avec ses propres corrections de raccord.

- Réutiliser les images compatibles et les règles d'assemblage existantes.
  Lorsqu'une variante manque, générer une image complète à alpha natif : nouvelle
  orientation, longueur, extrémité, angle, intersection ou transition locale.
  Il n'y a pas de quota de variantes qui justifierait un raccord défectueux.
  Une image spécifique représente une configuration réutilisable, jamais une
  salle entière peinte pour contourner l'assemblage modulaire.
- Enregistrer chaque variante dans le kit partagé avec sa provenance, ses
  dimensions, son orientation, ses ancres, ses extrémités de connexion et sa
  règle de sélection. Les prochaines occurrences du même cas doivent reprendre
  cette définition. Une correction commune se propage aux scènes concernées.
- Couleur, biseaux, liserés, contours et ombres de la pierre sont dessinés dans
  les PNG générés. Godot sélectionne et positionne les sprites entiers, avec
  échelle uniforme et ordre de dessin. Aucun éclairage de bord, halo, shader,
  teinte RGB/alpha à l'exécution, découpe, étirement ou chevauchement des bouts
  peints ne doit servir à corriger la matière ou masquer un mauvais raccord.
  Les éclairages de gameplay distincts, comme les torches, sont hors de cette
  correction des éléments architecturaux.
- Comparer les petites salles, les couloirs existants et les nouvelles connexions
  à l'échelle normale et agrandie. Vérifier la continuité de perspective,
  d'épaisseur, de couleur et de contour sur chaque orientation. Des contrôles
  techniques réussis ne prouvent pas l'absence de défaut artistique.

**Palette des études modulaires, reprise du22 octobre :** les couleurs des sols,
façades, supports et pierres verticales viennent désormais des PNG générés,
avec modulation blanche. Les anciens multiplicateurs sont retirés de ces études.
La scène historique SixRoomPreview demeure distincte. La reprise préserve les
formats, la graine et l'agencement du sol ; elle n'ajoute ni éditeur joueur,
navigation, objets ni sauvegarde. Le commit **2584f57** conserve l'état précédent.

### Études visuelles : salles et couloirs modulaires

Les scènes s'ouvrent individuellement avec **F6**. Elles partagent
`modular_room_study.gd` et `modular_study_kit.gd`. Les corrections visuelles
restent à apprécier par l'utilisateur ; aucun score technique ne les approuve.

**Aperçu dans l'éditeur :** le nœud `Dungeon` reconstruit les sprites à
l'ouverture et via **Actualiser le rendu**. La propriété `refresh_action`
fournit désormais un `Callable` à chaque lecture de l'Inspecteur, au lieu de
stocker sa valeur à l'initialisation. Cela évite le bouton `Nil` après un
rechargement de script. La scène déjà ouverte peut nécessiter une réouverture
pour remplacer son ancienne instance. Inspection dans un projet éditeur isolé :
`3x3RoomCornerCorridors` conserve 302 sprites après appel du bouton, puis après
rechargement du script parent et nouvel appel. Aucun changement de géométrie,
de palette, de règles de jeu ou de sauvegarde. Journal :
`artifacts/editor-button-inspection.log`.

**Reprise de palette :** neuf atlas natifs sont enregistrés dans
`assets/dungeon/modular-study/calm-palette-generation.json` avec leurs prompts
ImageGen, sources et dimensions. La référence de couleur est conservée dans
`docs/reference/palette-concept-2026-10-22.png`. Les murs sont plus sombres et moins
saturés ; les dessus perdent les reflets presque blancs. Le sol reçoit une
surface lisse et unie, avec des variations douces et les fissures existantes.
Il reste proche en luminosité des dessus des murs, au-dessus des façades sombres.
Les anciennes images restent disponibles. La reprise de palette conservait les
régions et ports ; la correction latérale ci-dessous remesure ensuite les côtés.
Les dimensions des cases restent fixes. Les PNG générés sont copiés tels quels,
sans modification de pixels ni nettoyage alpha. Les supports utilisent leur
atlas ombré entier, au même décalage de40 unités source.

Contrôle effectué par captures Godot des sept études isolées et des cinq scènes
connectées3×3/5×5, à×1/×2 avec détails×4. La5×5 avec rangées temporaires[0,2,4]
montre les séparateurs répétés. Les captures avant sont dans
`artifacts/palette-before/`. Aucun test programmatique ni sonde artistique.
La visibilité avec de vrais héros, coffres ou pièges reste à examiner lors de
leur intégration ; ces études statiques n'en contiennent pas.

| Scène | Cases (largeur × longueur) | Ouvertures | Rangées de dallage |
| --- | --- | --- | --- |
| `1x1CellRoom.tscn` | 1×1 | Fermée | 2 |
| `2x2CellRoom.tscn` | 2×2 | Fermée | 4 |
| `3x3CellRoom.tscn` | 3×3 | Fermée | 6 |
| `1x2Corridor.tscn` | 1×2 | Nord et sud | 4 |
| `2x1Corridor.tscn` | 2×1 | Ouest et est | 2 |
| `1x3Corridor.tscn` | 1×3 | Nord et sud | 6 |
| `3x1Corridor.tscn` | 3×1 | Ouest et est | 2 |

- L'ancienne `SingleCellRoom.tscn` affichait quatre modules de sol : elle a été
  renommée **2x2CellRoom**, à la demande de l'utilisateur. La nouvelle 1×1
  contient **deux rangées de petites dalles de largeurs différentes**. Le nombre de lignes
  et colonnes de la ressource `DungeonLayout` pilote ces études ; ses anciennes
  valeurs `cell_size` et `margin` ne pilotent pas la calibration artistique.
- Les quatre coins en L sont indépendants. Les modules droits se répètent entre
  eux et les coins, sans modifier leurs pixels. Les couloirs n'ont ni coin en L
  ni mur de fermeture dans leur axe de passage. Il s'agit de cas isolés :
  ils ne constituent pas un système de jonctions pour plans arbitraires.
  La scène séparée ci-dessous étudie les connexions cardinales d'une salle.
- Les côtés verticaux montrent uniquement le dessus des pierres, sans bande
  intérieure sombre ni rangée extérieure. Les faces sombres des murs horizontaux
  sont deux assises de briques indépendantes, à joints décalés, qui passent sous
  les chapeaux et les coins sans repartir aux limites des modules. La première
  assise commence à **y=96 au nord, y=105 au sud** sous l'origine du mur,
  selon `modular_wall_profile.course_top`. Son bord entier commence sous le pied
  peint du chapeau ; l'ancien départ 88 coupait la brique sous le coin sud-ouest.
  La deuxième commence au départ + hauteur native de la première mise à l'échelle − 2. Chaque assise
  garde une seule hauteur et une seule échelle sur toute la largeur.
- Les chapeaux droits utilisent `cap-muted-v11.png` ; les coins fermés utilisent
  `cap-square-v3.png`. Deux paires latérales restent dans `cap-tight-v13.png`.
  Les longueurs complémentaires viennent de `wall-tight-v22/v23.png`
  via `modular_side_kit.gd`.
  L'épaisseur des pierres horizontales
  est rétablie : l'aplatissement de v7 avait été rejeté. Le surplomb corrigé
  dans v9 est conservé dans le dessin de la face du chapeau, mais ses briques
  inférieures intégrées sont remplacées par des assises continues pour supprimer
  les décalages aux extrémités des modules. Les côtés gardent un petit biseau,
  sans grosse face frontale répétée. La variante v16 a été rejetée pour ses
  différences de couleur et largeur. Les sources courantes utilisent une
  modulation blanche et une composition partagée des
  longueurs pour les salles fermées comme pour les passages verticaux.
  L'ancien placement par paires de **315×0,92** avançait seulement de **256**,
  soit **33,8 unités source de recouvrement**. Il est retiré, avec ses décalages.
  Les côtés remplissent maintenant l'intervalle entre les extrémités réelles des
  coins : haut **279**, bas **−166**, largeur cible **101**, centres **41,75**
  à gauche et **−38** à droite, relativement aux ancres des coins.
  La largeur est désormais fixe : aucune remise à l'échelle selon la hauteur
  disponible. Chaque silhouette conserve ses proportions et avance de sa hauteur
  naturelle à cette largeur, avec répartition du reliquat positif dans les joints.
  Aucun remplissage pour un intervalle nul ou négatif ; le contact existant entre
  les coins de la 1×1 reste inchangé. Les nouveaux contours noirs et biseaux sont
  peints dans le PNG, sans correction alpha à l'exécution.
  Le dallage et les chapeaux droits restent fixes ; le départ des assises est recalé.
  Aucune suppression de pixels par programme.
  Les raccords horizontaux ont été recalés pour préserver les deux extrémités
  peintes, notamment au coin sud-ouest. La façade est prolongée sous les chapeaux
  jusqu'au bord du mur, au lieu de former une bande en retrait.
- **Douze variantes de dalle** dans `floor-calm-v3.png` : trois proportions
  natives, chacune avec deux dessins calmes et deux fissures distinctes. Texture
  douce, sans gravure centrale ni veinage contrasté systématique. La précédente
  texture et les formats tous identiques de `floor-variants-v1.png` sont rejetés.
  **Quatre variantes de brique dans deux longueurs** (huit sprites) restent dans
  `brick-muted-v3.png`, à texture adoucie, modulation blanche.
  Aucun effet de lumière ou accessoire supplémentaire.
- Chaque dalle est un sprite entier. Graine fixe **173** : les trois formats
  sont réordonnés sur la largeur complète des rangées, sans joints ajoutés aux
  limites des cases. Quatre variantes par format sont alternées. L'agencement
  validé reste fixe. Les cinq anciennes teintes par pierre et le multiplicateur
  **(1,74;1,61;1,40)** sont supprimés au profit de surfaces peintes plus lisses,
  plus unies et moins saturées. Les fissures restent discrètes ; la différence de
  couleur entre pierres est native. Aucune correction de couleur à l'exécution.
  Les rangées se calent sur leur largeur par une échelle uniforme calculée
  d'après les largeurs natives ; leur hauteur suit les proportions des sprites.
  L'excédent passe sous les murs. Les couloirs verticaux calent uniformément
  l'ensemble du dallage sur leur longueur, sans étirer ni couper les dalles.
  Pas visuel logique d'une case toujours **(476,256)** ; le nombre de dalles
  décoratives varie selon les formats, avec deux rangées par case verticale.
- Échelle générale **0,29** ; multiplicateurs uniformes des coins **1**, chapeaux
  nord **0,99**, sud **0,97**. Tous les côtés droits utilisent désormais
  la composition uniforme décrite ci-dessous, sans multiplicateurs historiques **0,92/0,95**.
  Les briques d'une assise partagent une échelle uniforme calculée sur la somme
  de leurs largeurs ; aucun étirement horizontal ou vertical indépendant.
  Les salles fermées ont une emprise entre ancres de
  **(558,425) + (colonnes−1,lignes−1) × (476,256)**, en unités source.
- Le cadre minimal est **416 × 416 px** ; il s'agrandit avec une troisième case.
  Ordre de dessin : sol **Z0**, façade **Z1**, chapeaux/coins nord **Z2**,
  côtés **Z3**, chapeaux sud **Z4**, coins sud **Z5**. Le bouton **Actualiser le
  rendu** reconstruit les sprites et la caméra cadre uniformément la scène.
- Aucun gameplay, entrée, torche, cœur, collision, animation, sonde ou sauvegarde.
  Aucun sprite de salle complète, détourage programmatique, rotation ou échelle
  non uniforme. Les PNG générés sont copiés sans modification de leurs pixels.
- Contrôle **visuel uniquement**, demandé par l'utilisateur :
  `godot --path . --script tools/capture_modular_room.gd` capture les sept cas
  aux échelles **1 et 2**, plus leurs quatre bords à **×4**, dans
  `artifacts/<NomDeScene>.png`, `<NomDeScene>-2x.png` et
  `<NomDeScene>-{west,east,north,south}-4x.png`.
  `cell-rooms-comparison.png` et `corridors-comparison.png` présentent les cas
  à la même échelle. La commande ne contient ni assertions, ni sondes, ni scores.
  L'ancien `verify_single_cell.gd` est historique et hors suite active.

### Études de raccord : salles 3×3 et 5×5 à quatre couloirs

- **Version 5×5 avec couloirs verticaux aux coins :**
  `scenes/5x5RoomVerticalCornerCorridors.tscn`, à ouvrir avec **F6**. Même plan
  central de **25 cases**, quatre branches de largeur **1** et longueur **3**,
  deux vers le nord et deux vers le sud, sur les colonnes **0 et 4**.
  `connections=5` et `vertical_attachment_columns=[0,4]` ; bouts éloignés ouverts.
  Le réglage partagé `vertical_attachment_columns` suit les mêmes conventions
  que les rangées horizontales : liste vide = colonne centrale, liste explicite
  triée et dédoublonnée, indices hors plan ignorés, liste entièrement invalide =
  aucune branche verticale. Modifier le réglage reconstruit le plan et place le
  même dallage de passage dans chaque colonne ; le sol central reste fixe.
  Les murs proviennent du contour occupé et des mêmes sprites entiers. Aucun
  rendu propre à la scène, nouvelle image, interaction ou sauvegarde n'est ajouté.
  Capturer avec `godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomVerticalCornerCorridors`.
  Voir `artifacts/5x5RoomVerticalCornerCorridors.png`, `-2x.png` et
  `5x5RoomVerticalCornerCorridors-corners-comparison.png` pour les quatre angles
  internes à **×4**. Étude non approuvée : de petits écarts de largeur et de
  contour restent visibles entre les coins et les pierres verticales.
  Vérification : captures **×1/×2/×4** sans erreur Godot, variantes toutes colonnes,
  colonnes invalides et retour au centre recapturées ; la variante invalide est
  identique à la salle fermée. Les **huit captures ×1/×2** des quatre études
  précédentes (cardinales 3×3/5×5, coins horizontaux 3×3/5×5) sont identiques
  octet pour octet à leur état avant ce changement. La suite globale s'arrête
  encore sur `verify-scene`, qui attend SixRoomPreview pour F5 au lieu de la
  cible actuelle 3x3CellRoom. Les captures ont été exécutées directement.
- **Version 5×5 avec couloirs horizontaux aux coins :**
  `scenes/5x5RoomCornerCorridors.tscn`, à ouvrir avec **F6**. Le plan partagé
  `study_5x5.tres` apporte **25 cases** centrales et **10 rangées de dallage**.
  Quatre branches horizontales de largeur **1**, longueur **3**, se raccordent
  aux rangées **0 et 4** à l'ouest et à l'est : `connections=10`,
  `horizontal_attachment_rows=[0,4]`. Leurs bouts éloignés restent ouverts.
  Cette scène utilise exactement les scripts et sprites de la version 3×3 ;
  seul le plan et la liste des rangées changent. Aucune règle de rendu spéciale,
  nouvelle image, interaction ou sauvegarde n'est ajoutée. Étude non approuvée.
  Capturer avec `godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomCornerCorridors` ;
  examiner `artifacts/5x5RoomCornerCorridors.png`, `-2x.png` et
  `5x5RoomCornerCorridors-corners-comparison.png` pour les quatre angles à **×4**.
  Captures produites sans erreur Godot et inspectées à **×1/×2/×4** : les murs
  intérieurs opposés sont séparés dans cette version, mais les jonctions entre
  coins et pierres verticales montrent encore des écarts de contour et de largeur.
  Aucun raccord parfait n'est validé. La suite `tools/test-mobile.ps1 -All -Capture`
  s'arrête toujours sur l'ancien contrôle `verify-scene` de la cible F5 ; les
  captures de cette scène ont donc été exécutées directement.
- **Couloirs horizontaux aux quatre coins : `scenes/3x3RoomCornerCorridors.tscn`**,
  à ouvrir avec **F6**. Salle centrale **3×3** (9 cases, 6 rangées de dallage),
  quatre branches horizontales de largeur **une case** et longueur **3** :
  ouest/est sur les rangées logiques **0 et 2**, bouts éloignés ouverts.
  `connections=10` active uniquement est/ouest ; il n'y a pas de branche nord/sud.
  Le plan 3×3, les sprites et les fonctions de rendu restent partagés.
- Le nouveau réglage réutilisable `horizontal_attachment_rows` est une liste
  de rangées commune aux côtés est/ouest activés. Par défaut, la liste vide
  conserve le raccord central. Une liste explicite ignore les doublons et les
  indices négatifs ou supérieurs/égaux au nombre de lignes, puis trie les indices.
  Une liste explicite entièrement invalide ne crée aucun couloir horizontal.
  Changer les rangées reconstruit le plan et le rendu ; aucun état n'est sauvegardé.
  Les deux rangées de dalles de chaque case de raccord se prolongent sans déplacer
  le sol central. Les bornes physiques sont conservées par branche. Les supports
  hérités sont posés sous la première rangée de chaque passage.
- Les longues rangées de chapeaux ouvertes aux deux bouts et traversant la salle
  utilisent les extrémités natives établies par les murs à angles. Leur nombre
  de modules entiers et leur origine se calent sur ces bornes, avec cadence **476**
  et échelles **0,99/0,97** inchangées : aucune compression par segment ou coupe.
- **Séparateur étroit commun :** deux frontières horizontales opposées, séparées
  par une seule rangée logique vide, sélectionnent désormais un séparateur si
  elles ont la même portée, une extrémité commune fermée et l'autre ouverte.
  La règle vient du contour dans `modular_connection_plan.gd`, sans nom de scène
  ni taille de salle particulière. Les deux rangées de chapeaux, les deux angles
  et le petit retour vertical sont retirés de l'assemblage. Un dessus large
  unique, une terminaison maçonnée complète gauche/droite et deux assises droites
  les remplacent.
  Il n'y a plus de double bande de dessus dans ce cas.
- La première version à terminaisons plates (`narrow-separator-ends-v5.png`) a
  été rejetée : le dessus paraissait posé sur une façade mince, comme un rideau.
  `modular_separator_kit.gd` utilise maintenant `narrow-separator-muted-v4.png` pour les
  trois pierres droites et `solid-separator-muted-v9.png` pour les terminaisons.
  La v7 a été rejetée : sa grande face oblique introduisait une autre perspective.
  La v8 intègre deux pierres de dessus et deux assises projetées uniquement vers
  le bas. Le bord fermé garde la même abscisse du dessus au pied, sans face latérale
  en diagonale. Aucun lit de briques séparé n'est dessiné dessous.
  L'atlas **1964×801** contient deux régions complètes **982×801**.
  Régions complètes à alpha natif, teinte blanche, échelles uniformes seulement ;
  cadence **476**, hauteur commune d'environ **162** unités source avant ×0,29.
  Les bouts ouverts gardent leurs bornes d'origine ; le nez suit les dimensions
  natives de ses nouvelles pierres (environ **344/345×277** unités pour le module
  entier gauche/droite). Les corps natifs mesurent **669/671×539**, hauteur de
  chapeau **316** ; ports d'assises **322/422** depuis le haut du corps.
  La façade droite rejoint les ports des deux assises de la terminaison ; le
  nombre de briques entières de chaque assise est choisi selon sa hauteur native.
  Les rangées ne redémarrent pas à chaque module droit. Le dallage central reste
  inchangé. La reprise de palette utilise la variante native brick-muted-v3 sans modulation.
  Provenance et prompts : `solid-separator-generation.json` ; les essais plats
  restent consignés dans `narrow-separator-generation.json`.
- Les bandes plus larges, les îlots fermés des deux côtés et les séparateurs
  verticaux ne sont pas couverts par cette nouvelle règle. La scène reste **en
  attente d'approbation visuelle** ; elle ne valide pas des donjons arbitraires.
- Capturer avec `godot --path . --script tools/capture_room_corridors.gd -- --scene=3x3RoomCornerCorridors`.
  Voir `artifacts/3x3RoomCornerCorridors.png`, `-2x.png` et
  `3x3RoomCornerCorridors-corners-comparison.png` : les **deux terminaisons**
  du séparateur à **×4**, en remplacement des quatre anciens angles superposés.
  Les coins extérieurs de la salle sont traversés par des murs horizontaux continus.
- Contrôles précédents, avant le séparateur commun : captures à **×1/×2** et des quatre angles
  à **×4**, ainsi que des variantes toutes rangées, liste invalide et retour au
  réglage central. La liste invalide rend la même image que la salle fermée.
  Les quatre captures **×1/×2** des anciennes scènes cardinales **3×3/5×5** sont
  identiques octet pour octet à leurs références avant ce changement. La matrice
  des 16 masques et longueurs 1/2/3 a été recapturée. La commande globale
  `tools/test-mobile.ps1 -All -Capture` reste arrêtée par `verify-scene`, qui
  attend SixRoomPreview pour F5 alors que la cible actuelle est 3x3CellRoom.
  Ces anciens contrôles n'avaient pas résolu le chevauchement intérieur.
- Vérification de la correction du séparateur : inspection des captures Godot
  **×1/×2**, des deux nez **×4**, des sept études isolées, de la 3×3 à couloirs
  centrés, de la 5×5 à couloirs horizontaux éloignés et de la 5×5 à branches
  verticales aux coins. Une capture supplémentaire de la 5×5 avec
  `--rows=0,2,4 narrow-strips` montre quatre séparateurs sélectionnés par la même
  règle. Ce réglage est temporaire pour la capture ; les scènes enregistrées
  conservent leurs paramètres. Aucun score ni sonde programmatique dans cette
  correction, conformément à la demande de contrôle visuel de l'utilisateur.
- Reprise de perspective v8 : captures Godot de la 3×3 à **×1/×2** et des deux
  terminaisons à **×4**, de la 5×5 temporaire `--rows=0,2,4 narrow-strips`, et des
  sept études isolées. Les images `3x3RoomCornerCorridors-before-perspective.png`
  et `-before-perspective-details.png` conservent la v7 rejetée. Cette inspection
  visuelle ne remplace pas l'approbation artistique de l'utilisateur.

- **Nouvelle scène de comparaison : `scenes/5x5RoomFourCorridors.tscn`**, à ouvrir
  avec **F6**. `assets/layouts/study_5x5.tres` définit **5 colonnes × 5 lignes**,
  soit **25 cases** centrales et **10 rangées** de dallage. Les quatre branches
  centrées sont actives (**15**), largeur **une case**, longueur **3** ouest/est
  et **4** nord/sud comme la scène 3×3. Il n'y a pas d'entrée, gameplay ni sauvegarde.
  La scène sélectionne une autre ressource de plan ; elle utilise les mêmes
  scripts `room_corridor_study.gd`, `modular_connection_plan.gd` et les mêmes
  sprites. Aucun rendu ou correctif de raccord propre à la taille 5×5 n'est ajouté.
  Emprise entre ancres : **2462×1449 unités source**, échelle **0,29**.
- Cette taille expose des segments horizontaux fermés de **deux colonnes**
  autour des branches nord/sud : ils utilisent les angles séparés et chapeaux
  droits partagés. Les modules doubles réservés à **une colonne** ne sont donc
  pas utilisés dans cette configuration à quatre branches. L'étude sert à
  examiner ces raccords ; sa création ne valide pas leur qualité artistique.
- Capturer avec `godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomFourCorridors`.
  Sorties `artifacts/5x5RoomFourCorridors.png`, `-2x.png`, quatre directions à
  **×4**, et **12 coins individuels** `-corner-X-Y-4x.png`, déduits du plan et
  des ancres réelles. `5x5RoomFourCorridors-corners-comparison.png` les regroupe
  à leur échelle **×4**. Les anciens détails de portions de mur ne couvrent pas
  toute la largeur 5×5 : utiliser les douze gros plans pour examiner tous les coins.
- Vérification de cette étude : captures **×1/×2**, quatre directions et douze
  coins **×4** produites et examinées. Les captures générales 3×3 avant/après
  restent identiques. Les raccords coins/chapeaux séparés restent à apprécier
  visuellement : cette scène expose leurs variations, elle ne les corrige pas
  à l'aide d'une recette propre au 5×5. La commande globale
  `tools/test-mobile.ps1 -All -Capture` s'arrête encore au contrôle historique
  F5 qui attend la scène à six salles ; les captures ont été lancées directement.

- `scenes/3x3RoomFourCorridors.tscn`, à ouvrir puis lancer avec **F6** :
  une salle **3×3**, avec des couloirs centrés de largeur logique **une case**.
  `connections` est un masque **nord=1, est=2, sud=4, ouest=8**, défaut **15**.
  `corridor_length` vaut **2** dans le script, réglable de **1 à 3**. La scène
  utilise actuellement **3** à gauche/droite et **4** en haut/bas : après l'ajout
  d'une case aux quatre branches, une case supplémentaire a été demandée pour
  les branches verticales le 22 octobre, afin de mieux examiner leur continuité.
  `vertical_corridor_length` vaut **0** dans le script : zéro reprend
  `corridor_length`, une valeur positive fixe uniquement la longueur nord/sud,
  les valeurs négatives reviennent à zéro. La scène le règle à **4**.
  Le même réglage pilote l'occupation, les ouvertures terminales, le dallage,
  les murs latéraux et les cadrages ; il reconstruit le rendu sur la même instance.
  C'est une configuration d'étude visuelle,
  sans changement des sprites, teintes ou règles d'assemblage. Les extrémités
  éloignées sont ouvertes. Une direction désactivée retrouve son mur de salle.
  Changer ces propriétés reconstruit toute la composition et recadre la caméra,
  y compris sur la même instance. Aucun état de construction n'est sauvegardé.
- `modular_connection_plan.gd` déduit les arêtes exposées et les angles orientés
  de l'occupation logique, puis rassemble les segments droits. Les ouvertures
  terminales sont explicites. Ce calcul prépare la construction future ; le
  rendu de sol accepte actuellement une salle rectangulaire impaire d'au moins
  3×3, des branches nord/sud centrées et des branches horizontales sur des rangées
  configurables. **Les scènes 3×3 et 5×5 sont examinées ici,
  sans approbation artistique ni validation de toutes les tailles impaires.**
  Aucun éditeur joueur, navigation, collision ni plan arbitraire complet n'est
  implémenté. Les contacts diagonaux et les plans de plusieurs salles restent
  à traiter et à examiner visuellement.
- **Correction du 22 octobre, après rejet des carrés de raccord :** le profil
  des murs est partagé avec les sept petites scènes dans
  `modular_wall_profile.gd` et les fonctions de `modular_room_study.gd`.
  Chapeaux nord **0,99**, sud **0,97**, cadence **476** unités source, façade
  commençant à **y=96 au nord, y=105 au sud** : aucune compression des chapeaux par segment et aucun
  départ de façade propre à la grande scène. Les deux assises passent sous les
  angles avec des joints décalés. Les segments courts combinent des briques
  entières et demi-longues natives, à échelle uniforme pour chaque assise.
  Les captures 1×/2× antérieures servent de référence pour le dallage et les
  murs horizontaux. La révision latérale commune décrite ci-dessous modifie
  volontairement les scènes qui possèdent des portions verticales.
- `room_corridor_study.gd` réutilise le dallage central exact de la salle fermée,
  graine **173**, six rangées, proportions natives et multiplicateur de lumière
  **(1,74;1,61;1,40)**. Les couloirs emploient les mêmes douze variantes.
  Les couloirs ouest/est prolongent directement
  les rangées centrales **2 et 3** (indices à partir de zéro), à leur hauteur
  et échelle exactes. Des dalles entières de formats mélangés continuent chaque
  rangée ; les deux dernières, à l'extrémité ouverte, se calent uniformément sur
  la longueur restante. Aucune composition indépendante ne recouvre les pierres
  centrales. La longueur logique compte les modules droits ; l'emprise visible
  inclut aussi les bras natifs des angles de transition. **Deux modules ne
  signifient donc pas une branche horizontale totale de 952 unités source.**
  Le calage sur une grille de construction/navigation reste à définir.
  Des dalles de support entières, **Z0**, sont décalées de **40 unités source**
  vers le haut derrière le pied des façades ; leur couleur assombrie vient de
  `floor-calm-support-v1.png`, avec modulation blanche. Le multiplicateur **0,70**
  est retiré. Elles ne remplacent ni les pierres visibles ni leur contour.
  Le fond opaque hérité est aussi à Z0 et passe avant ses enfants. L'ensemble
  des sprites de cette étude est relevé d'une couche : les supports auparavant
  à Z−1 étaient cachés sous le fond, ce qui laissait apparaître un filet de vide.
  Le dallage nord finit au début de la première rangée centrale ; celui du sud
  commence après la dernière dalle centrale. Chaque branche conserve **deux
  rangées par case**, ajustées ensemble uniformément sur sa longueur. Le sud
  couvre `longueur × 256 + 6` unités ; le nord conserve au minimum la place
  d'une pierre latérale complète entre son extrémité et l'angle. Aucun pixel
  n'est coupé ni étiré et aucune dalle centrale n'est recouverte au raccord.
- L'emprise entre ancres de la salle reste **1510×937 unités source**, échelle
  générale **0,29**. Les chapeaux et les deux assises de façade sont interrompus
  aux ouvertures. Les assises restent continues et décalées sur chaque segment.
  Les extrémités peintes complètes des chapeaux ne sont pas superposées pour
  cacher les joints.
- **Révision des largeurs et ancres, 22 octobre, après le signalement 24721 :**
  les anciens ports ne décrivaient pas le centrage horizontal des bras. Un même
  module double plaçait sa tige droite au-delà de la limite logique ; les pierres
  de côté changeaient aussi de largeur selon la longueur à remplir. Un partage
  de PNG ne suffisait donc pas à garantir une géométrie commune.
- **`paired-cap-square-v7.png`** fournit quatre transitions complètes à deux
  coudes, sans sol ni façade. Le segment horizontal fermé d'une colonne utilise
  un module entier ; les deux anciens sprites d'angle ne sont pas dessinés dessous.
  Atlas **1536×1024**, régions **768×512**, ancre source **(96,256)**. Ordre :
  NW/SE nord, SW/NE nord, SW/NE sud, NW/SE sud. Les mesures de chaque tige sont
  enregistrées dans `modular_join_kit.gd` : étendue horizontale, extrémités
  verticales et profil de l'assise. `paired_fit` applique une seule échelle
  uniforme et une translation à tout le module, puis aux mêmes ports.
  Les centres des tiges deviennent **x=41 et x=517**, soit **476** d'écart,
  relativement à l'ancre gauche. Le milieu de la tranche est aligné sur le
  profil droit nord/sud partagé. Les profils natifs remesurés de square-v7 sont
  **[−26,95]** au nord et **[−91,32]** au sud. Les deux centres des bras déterminent
  l'échelle uniforme ; les ports utilisent exactement ce même transform.
  L'ancien écart de0,55px décrivait muted-v8 et ne valide pas cette nouvelle image.
  Le contrôle actuel est visuel ; ces mesures ne découpent jamais l'image.
- Les angles individuels compatibles utilisent **`cap-elbows-square-v7.png`**.
  Leurs régions complètes sont conservées. Profils **[−14,99]** NW/NE et
  **[1,114]** SW/SE ; extrémités verticales **[−19,165]** NW, **[−19,164]** NE
  et **[−61,120]** SW/SE.
  Leurs largeurs et centres horizontaux natifs sont maintenant mesurés aussi.
  L'échelle reste dérivée du profil droit **0,99/0,97** ; la translation x
  centre réellement chaque tige sur **±41**, au lieu de supposer son centrage.
  Le recalage des courts retours traite les intervalles positifs ET négatifs
  d'amplitude au plus **82**, en déplaçant des rangées entières ; il n'ajoute
  ni entretoise ni chevauchement peint. Les façades partagent les départs **96/105**
  et leurs limites sous les coins ; leur recette horizontale reste partagée.
- **Extrémités carrées, correction du biseau :** les angles fermés square-v3,
  les angles compacts square-v7 et les doubles coudes square-v7 prolongent la
  **face bleue de la pierre** jusqu'à l'extrémité. Une plaque noire ajoutée autour
  de l'ancien coin coupé ne convient pas : l'essai compact-v4 a été rejeté sur
  capture par l'utilisateur. La tranche frontale reste horizontale ; les bras
  verticaux gardent uniquement leur dessus. Les pixels viennent des PNG natifs,
  avec leur alpha, sans masquage, retouche par programme ni modulation RGB.
  Le cadre de calibration des profils compacts reste inchangé : inclure leur
  contour noir supplémentaire dans l'échelle rétrécissait les bras horizontaux.
  Les coins fermés square-v2 sont écartés : leur pierre voisine raccourcie
  réintroduisait des espaces et des petits éléments isolés dans la2×2.
  Prompts, sources, variantes et mesures : `square-corners-generation.json`.
  Captures Godot des sept scènes isolées et des cinq scènes connectées, à taille
  normale et agrandie. La vue `5x5RoomVerticalCornerCorridors-north-span-2.5x.png`
  conserve ensemble les deux coins et la façade pour examiner cette perspective.
  Pas de sonde artistique ni de validation de plans arbitraires ; l'approbation
  visuelle de l'utilisateur reste distincte de cette inspection.
- **Côtés à largeur fixe :** deux paires entières de `cap-tight-v13.png`, quatre
  longueurs de `wall-tight-v22.png`, quatre de `wall-tight-v23.png` et deux
  paires compactes de `cap-compact-pairs-v24.png`.
  Ces dernières remplacent les deux carrés isolés qui semblaient flotter dans
  la 2×2. Elles sont disponibles pour tout intervalle compatible du kit commun.
  Régions entières **(50,450,230,350)** et **(980,450,250,350)**, ancres locales
  **(46,52)/(71,52)**, corps natifs **113×265 / 115×267**.
  La largeur commune des ports de coins fermés est recalibrée de **103 à101**
  unités source (**0,58 px** de différence à l'échelle0,29), sans déplacer les
  coins ni calculer la largeur en fonction de la hauteur. La première version
  remplissait l'intervalle de237 de la2×2 avec la paire10 de236,858.
  Avec les nouveaux coins square-v3, l'intervalle est **236** : la paire11 de
  **234,496** est sélectionnée, avec **0,752** de joint positif à chaque extrémité.
  Aucun bout peint n'est superposé.
  Les deux atlas complémentaires mesurent **1254×1254**. V22 utilise quatre régions
  de **627×627** ; v23 sépare les deux rangées à **y=550** dans la marge transparente,
  avec des régions de **627×550** et **627×704**. Les silhouettes restent entières.
  Leurs ancres et corps mesurés sont dans `modular_side_kit.gd`.
  V16 est écartée pour sa couleur/largeur, v17/v18 pour leurs bandes noires aux
  extrémités. Les essais v19/v20 ont conservé des bandes ou créé des débords noirs ;
  v21 restait trop bleu. V23 ajoute les longueurs manquantes aux petits intervalles.
  Couleur et contours sont générés dans le PNG ; **modulation blanche**, aucun
  éclairage de bord ni shader. La teinte RGB latérale est supprimée.
- `make_run` sélectionne des longueurs natives à largeur fixe. Une recherche par
  pas de **0,25 unité source** privilégie les paires des coins et les paires
  compactes (indices **0,1,10,11**) : coût **2** par paire, **5** par longueur complémentaire, **0,15**
  pour une répétition consécutive. Le reliquat est réparti entre les sprites et
  les deux extrémités. Le score pénalise de **100** chaque unité de joint au-delà
  de **2**, puis de **0,1** sa taille. Aucun ajustement final de largeur.
  La longueur n'est plus limitée à quatre sprites. La largeur cible vient du
  port du coin raccordé ; les couloirs verticaux isolés réutilisent cette même
  fonction avec une cible **94**. Le petit dessus v9 reste réservé aux intervalles
  plus courts que **1,5× la largeur**, jamais répété le long d'un grand mur.
  Les salles fermées partagent cette composition entre les ports remesurés des
  coins, au lieu des anciennes paires superposées. Le dallage approuvé,
  sa graine et ses positions restent fixes. La reprise de palette ultérieure
  remplace aussi les teintes des sols, façades et supports par des PNG natifs.
  La correction des carrés flottants est documentée dans
  `compact-pairs-generation.json` : PNG natif, essais écartés et captures des
  sept études isolées, de3×3RoomFourCorridors, de3×3RoomCornerCorridors et
  de5×5RoomVerticalCornerCorridors. Le sol et les façades ne changent pas.
  `tight-joints-generation.json` conserve la correction précédente ;
  `vertical-width-color-generation.json` conserve l'étape de largeur fixe,
  `vertical-outline-generation.json` conserve la tentative précédente rejetée.
  Inspection des captures Godot des sept études isolées et des scènes connectées
  3×3 centrée, 5×5 centrée et 5×5 aux coins horizontaux/verticaux, avec détails ×4.
  Les détails `*-southwest-4x.png` ciblent la brique auparavant coupée par le coin.
  Aucun test programmatique. L'approbation artistique reste à l'utilisateur.
- Les essais de coins élargis `cap-elbows-ports-v11/v12.png` et de faces plus
  profondes `paired-cap-transitions-v3.png` sont **inutilisés** : leurs proportions
  déplaçaient les jonctions horizontales ou épaississaient trop la tranche.
  La v4 a été rejetée pour un fond semi-opaque ; les v2/v5/v6 sont des étapes
  inutilisées au profil moins compatible. Aucun nettoyage alpha programmatique
  n’a été appliqué. Ces essais ne sont pas une référence approuvée. Provenance et prompts :
  **`port-width-generation.json`**. `native-transitions-generation.json` décrit
  l'étape précédente. Les PNG actifs sont copiés sans retouche depuis ImageGen.
- Ordre de cette étude : supports **Z0**, dallage **Z1**, façades **Z2**,
  chapeaux/angles nord **Z3**, côtés **Z4**, chapeaux sud **Z5**, angles sud **Z6**.
  L'ordre relatif partagé reste identique ; les sept scènes isolées ne changent
  pas de couche. Leur matière latérale est actualisée comme décrit ci-dessus. Le cadre est
  calculé sur les rectangles complets des sprites, gouttières comprises, avec
  **40 px** de marge. Le bouton **Actualiser le rendu** reconstruit l'étude.
  Aucun coût, prérequis, gameplay, collision,
  éclairage ajouté, sonde, animation, état persistant ni sauvegarde de jeu.
- Inspection visuelle avec `godot --path . --script tools/capture_room_corridors.gd` :
  `artifacts/3x3RoomFourCorridors.png`, `3x3RoomFourCorridors-2x.png` et les quatre
  `3x3RoomFourCorridors-{north,south,west,east}-4x.png`. Sans assertions ni scores.
  Trois régressions visuelles supplémentaires couvrent les problèmes signalés :
  `3x3RoomFourCorridors-{west-floor,corridor-wall-foot,corner-style}-4x.png`.
  `godot --path . --script tools/capture_module_connections.gd` reconstruit les
  **16 masques**, les longueurs **1/2/3**, puis ferme et rouvre les passages sur
  la même instance. Voir `connection-masks-comparison.png`,
  `connection-lengths-comparison.png` et `connections/rebuild-roundtrip.png`.
  `wall-profile-shared-comparison.png` compare le mur du couloir 2×1 à celui du
  raccord, à **×4**. `junction-perspective-comparison.png` compare les carrés
  rejetés aux angles en L actuels. `junction-continuity-comparison.png` compare
  les entretoises et angles gris v5 aux retours actuels à **×4**. Les captures
  `junction-profile-comparison.png` et `wall-profile-shared-comparison.png`
  isolent le calage des dessus et des tranches ; la seconde cadre le mur
  raccordé depuis son origine déplacée pour le comparer à la même hauteur
  que le couloir 2×1. Les nouveaux détails **west/east-upper/lower-return**
  cadrent chaque courte assise en entier ; **north-side/south-side** montrent
  la matière latérale. Voir `junction-native-parts-comparison.png`,
  `vertical-material-comparison.png` et `junction-all-returns.png`, à **×4**.
  Les comparaisons `junction-ports-{west-upper-return,west-lower-return,north,south}-comparison.png`
  confrontent directement le signalement 24721 à la révision des ports et largeurs.
  Les captures
  sont aussi branchées dans
  `tools/test-mobile.ps1 -All -Capture`, dont un contrôle historique attend
  encore une autre scène F5. **F5 reste `3x3CellRoom.tscn`.**
  Les rendus ne constituent pas une approbation artistique ; les raccords
  parfaits pour un donjon arbitraire restent un objectif à valider.

### Étude visuelle en cours — distincte de la carte principale

`scenes/ReferenceCalibration.tscn` s'ouvre avec **F6** pour examiner une portion
de salle à partir de la référence d'origine. Elle n'est pas encore approuvée et
ne remplace pas `SixRoomPreview.tscn`. Cadre logique **920 × 640 px**, caméra
ajustée uniformément à la fenêtre. Il s'agit d'une étude d'assets, pas d'un kit
procédural validé ni d'une correction achevée de la carte complète.

- **Sept sprites** : sol continu, maçonnerie d'entrée avec arche intégrée, angle est,
  bord extérieur indépendant, vantail, deux torches. Les cinq premiers utilisent des PNG entiers
  de `assets/dungeon/reference-study/`, sans masque ni découpe ; les torches
  conservent leur ressource existante.
- L'arche séparée devant les raccords ouest/est a été rejetée : elle paraissait
  toujours collée au mur. `entry-masonry-v3.png` dessine désormais les trois
  rangées de mur, leurs raccords à l'arche, les embrasures et le seuil dans un
  **même module de maçonnerie**. L'ouverture possède son alpha natif. Seul le
  vantail est dessiné derrière elle, au **Z 2**, puis la maçonnerie au **Z 3**.
  Le sommet du mur reste vers **y = 60**, son pied vers **y = 225**. Le sol v2 et
  le bord extérieur indépendant conservent leurs images et positions.
- Échelles uniformes : sol **0,62**, maçonnerie **0,44** en **(27,-86)**,
  angle est **0,75** en **(0,-75)** au **Z 4**, bord **0,458**, vantail **0,128**
  en **(238,43)**. L'angle `east-corner-v1.png` conserve son pilier, qui recouvre
  le raccord avec la façade. Teintes : angle **(0,90 ; 0,90 ; 0,90 ; 1)**,
  vantail **(0,78 ; 0,80 ; 0,85 ; 1)**, bord **(0,64 ; 0,64 ; 0,70 ; 1)**.
- `door-leaf-v4.png` contient uniquement le bois, les deux ferrures et l'anneau.
  Le vantail v3 a été rejeté pour son style trop distinct : bois orangé très
  contrasté et ferrures brillantes. Le nouveau PNG natif **1137 × 1383 px**
  reprend des plages de bois brun plus sobres et un fer sombre moins réfléchissant.
  Son échelle uniforme conserve l'emprise visible précédente ; aucun traitement
  de pixels ni masque ne produit ce changement de style.
  Son sommet et ses côtés passent derrière les embrasures de la maçonnerie.
  Les pieds de l'arche atteignent environ **y = 243**, soit **18 px** au-delà
  du pied du mur. Le seuil est également dessiné dans la maçonnerie. Le sol
  continu remonte vers **y = 213**, sous les pieds et le seuil. Aucun masque,
  détourage programmatique, étirement ou rotation ne réalise ces raccords.
- L'ouverture trop large a été redessinée avec son arche : les mesures alpha
  dans l'étude passent de **118 × 113 px** à **107 × 119 px** (largeur à y = 160,
  hauteur à x = 307). Les pierres conservent une échelle uniforme. La régression
  de proportions accepte un rapport largeur/hauteur de **0,70 à 0,90** ; elle
  détecte le retour à l'ouverture presque carrée, sans valider le style.
- Les torches restent à **0,36**, soit **25 %** plus petites que leur ancienne
  échelle **0,48**. Leur placement est calculé depuis l'axe visible de l'arche
  **x = 310**, avec un décalage symétrique de **150 px**. Les anciennes positions
  x = 150/450 conservaient un axe obsolète à x = 300 après le changement d'arche.
- Deux lumières fixes **#955dff**, énergie **0,85**, texture radiale **384 × 384**,
  masque **2**, centrées en **(160 ; 176,25)** et **(460 ; 176,25)**, pour suivre les
  flammes réduites. La porte reçoit désormais
  ce même éclairage que la maçonnerie et le sol. Les pieds des torches
  sont en **(160,225)** et **(460,225)**. Chaque lumière suit son instance de torche
  avec le décalage **(0 ; -48,75)**. Le mur reste à la même hauteur sur toute
  la largeur ; le dessin de l'arche dépasse son sommet.
- `tools/capture_reference_calibration.gd` produit le rendu normal, le rendu à
  **×2** et une comparaison avec deux extraits de l'original. Les extraits sont
  uniquement dans la planche de comparaison ; la scène ne dessine jamais une
  illustration complète en remplacement de ses éléments.
  Si `artifacts/door-perspective-before.png` est présent, il produit également
  `door-perspective-comparison.png` : original, avant, nouvelle porte en scène.
  `door-integration-before.png` permet la comparaison ciblée
  `door-integration-comparison.png`. `door-masonry-comparison.png` compare
  l'original, la dernière version rejetée et le module commun dans Godot.
  `door-proportions-comparison.png` compare l'original, l'ouverture trop large
  et le rendu corrigé, si `door-proportions-before.png` est présent.
  `torch-spacing-comparison.png` compare les torches avant/après recalage avec
  l'original, si `torch-spacing-before.png` est présent. La régression mesure
  les bords extérieurs des jambages à **y = 230** et compare les deux distances
  aux torches avec **2 px** de tolérance pour le dessin irrégulier des pierres.
  Elle vérifie également les mêmes hauteur, texture et échelle des torches,
  et les positions de leurs lumières.
  `door-style-comparison.png` présente l'original, le battant v3 rejeté et le
  battant v4 dans la scène, si `door-style-before.png` est présent. La capture
  à ×2 permet d'examiner le bois et les ferrures ; aucune mesure numérique
  ne remplace la validation artistique de ce nouveau dessin.
  `door-integration-opening.png` masque temporairement **le vantail uniquement** :
  l'arche, les embrasures et le seuil restent visibles avec le mur.
  Une ressource de sprite manquante fait échouer la capture.
  Une régression ciblée vérifie cinq points d'ouverture sans maçonnerie derrière
  le vantail, deux appuis de jambages sur le sol à **y = 240**, le placement du
  vantail derrière la maçonnerie, les échelles uniformes et l'absence de régions
  ou matériaux de découpe. Ces points
  contrôlent uniquement ce défaut d'assemblage, pas la fidélité artistique.
- Les générations et prompts sont consignés dans `generation.json`. Le sol v1
  est conservé comme essai non utilisé. Aucune approbation artistique n'est
  déduite de l'import des PNG ou de la réussite des captures. Les sondes sont
  laissées de côté pour cette étude, à la demande de l'utilisateur.

## 1. Direction artistique et production des images

La référence reste `assets/dungeon/perspective/reference-atlas.png` :
pierre épaisse bleu ardoise, sol vu en plongée, façades et dessus visibles,
piliers saillants et lumière violette localisée. Les murs bas et portes
latérales rejetés ne constituent pas des variantes approuvées.

- Tous les éléments de la scène principale utilisent désormais une véritable
  transparence alpha provenant des images générées.
- Aucun détourage programmatique : contours de rendu tracés, masques calculés,
  suppression de couleur/luminance ou shaders de détourage sont interdits,
  y compris lors de la préparation des fichiers.
- Générer autant de variantes complètes que nécessaire. Un élément manquant
  ne doit pas être remplacé par une découpe approximative ou une déformation.
- Les atlas peuvent sélectionner des sprites complets avec leurs marges alpha.
  Les mesures d'ancrage ne servent pas à modifier la silhouette.
- Contrôler les raccords dans le rendu réel à l'échelle normale et à **2×**.
  Les sondes complètent cette inspection sans la remplacer.
- `assets/dungeon/alpha-kit/generation.json` conserve les prompts et les noms
  des sorties originales. Les PNG ont été copiés sans retouche de pixels.
  `walls.png` est un brouillon inutilisé, conservé à titre de provenance.

## 2. Étude de référence et anciennes expérimentations

`scenes/PerspectiveRoom.tscn` conserve l'étude historique de l'entrée :
cadre **(0,120,560,510)**, **55 éléments** de `reference_pieces.gd`.
Ses anciens polygones et son éclairage peint servent uniquement à la comparaison.
Ils ne sont plus une dépendance du rendu principal ni une technique à réutiliser.

`scenes/DungeonPreview.tscn` et `scenes/EntranceVariants.tscn` restent des
expérimentations antérieures accessibles avec F6. Leurs proportions et portes
latérales ont été rejetées. Le tag **v1.0.0** conserve le prototype 3D antérieur.

## 3. Vérification

`tools/test-mobile.ps1 -All -Capture` exécute les contrôles de scène,
transparence, sondes, variations, cycle de reconstruction, captures et rendu GPU.

- `verify_alpha_assets.gd` interdit les Polygon2D de production, matériaux,
  régions de découpe Sprite2D et échelles non uniformes ; vérifie l'alpha des PNG
  et les limites des **27 régions**. Un bord d'atlas ne doit pas dépasser
  **2/255 d'alpha** ; ce contrôle lit les images sans les modifier.
- `verify_wall_layers.gd` vérifie la séparation des corps et des bords, l'arrêt
  aux angles et façades, ainsi que l'absence de pierres claires sous les piliers.
  Masquer les bords extérieurs doit conserver les corps de mur et leur placement.
- Le plan, les **255 cases**, les **858 éléments**, les **644 sondes**, le cœur
  enregistré et le cadrage sont contrôlés. Formats : **1280 × 720**,
  **720 × 1280**, **800 × 800**, **640 × 360**.
- Les variations sont reproductibles après reconstruction, désactivation et
  retour à la graine **173**. **590** est une graine temporaire de test.
- Le test d'éditeur utilise une copie isolée sous
  `artifacts/editor-refresh-project` : changement de plan/script/graine,
  absence d'accumulation et conservation du cœur et de ses deux enfants.
- Les régressions des sondes déplacent temporairement un mur de **100 px**,
  sa région source de **40 px**, son décalage de dessin de **500 px**, multiplient
  son échelle X par **1,3**, masquent le sol, déplacent le cœur de **80 px**
  et une torche de **50 px**. Tous ces défauts sont restaurés dans le test.
  Le rapport doit conserver le chemin PNG et la région des AtlasTexture.
- GPU sans lumières : **599 points** sur la carte (**471 sol/couloir**,
  **120 murs latéraux**, **8 volume/raccord**), **3828** autour de l'entrée,
  **2809** autour du cœur. Tolérance **4/255** par canal.
  Le calcul CPU combine les PNG alpha, teintes, transformations et ordre de
  dessin actuels. Il vérifie la composition des pixels, pas indépendamment
  la fidélité de ces transformations à la référence.
- Les captures de sondes vérifient F3, clic, R, les marqueurs d'échec et le retour
  au même rendu lorsque le diagnostic est masqué.
- Captures à inspecter : `dungeon-2d.png`, `six-room-details.png`,
  `vertical-wall-details.png`, `alpha-joins-2x.png`,
  `entrance-seams-detail.png`, `heart-detail.png`,
  `stone-variation-before-after.png`, `wall-projection-comparison.png` et
  `reference-comparison.png`.
  Rapports GPU : `alpha-six_rooms-report.json`, `entry-seams-report.json`,
  `alpha-heart-report.json`, dans `artifacts/`.
- La comparaison de référence mesure seulement l'étude historique de l'entrée.
  Aucun score ni échantillonnage ne constitue une validation artistique
  exhaustive ou une validation sur téléphone.
