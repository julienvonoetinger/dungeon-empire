# Wireframes : construction, export et utilisation dans Godot

État de référence : 23 octobre 2026. Ce guide décrit le **catalogue de cases
carrées actuellement utilisé**, et non les anciennes tentatives de sprites peints.

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
| `docs/reference/floor-only-cell-wireframe.json` | Motif existant du sol : 19 dalles, six rangées |
| `tools/export_wireframe_cell_kit.cjs` | Construction mathématique et export SVG **hors Godot** |
| `assets/dungeon/wireframe-cells/*.svg` | Images préparées réellement utilisées |
| `assets/dungeon/wireframe-cells/*.svg.import` | Import des textures, notamment les mipmaps |
| `assets/dungeon/wireframe-cells/catalog.json` | Provenance, dimensions, ancrages et inventaire des variantes |
| `scripts/wireframe_cell_catalog.gd` | Fichier produit par l'exporteur : préchargement explicite des textures |
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
| Largeur d'un couloir | Une case |
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

Le sol reprend les `rowHeights` et `rowWidths` du JSON de la case « sol seul ».
Son cadre de dessin historique 6 × 5 est normalisé en 1 × 1 : division des
coordonnées X par 6 et Y par 5. Le motif de 19 dalles est conservé ; ne pas
inventer un autre motif pour faciliter l'assemblage. Ce motif répété par case
est distinct du dallage global de la précédente illustration de salle.

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
