# Projection isométrique validée : adaptation des wireframes

Le 24 octobre 2026, l'utilisateur a validé cette direction : « oui ça correspond
mieux et comme ça nous n'avons plus de paradoxe de perspective et nous pouvons
garder notre logique de wireframe. »

**La projection 2:1 et le repère géométrique commun sont retenus pour la suite.**
`selection.json` conserve le périmètre de l'accord et les empreintes des fichiers
présentés. `geometry.json` reste une photographie de l'étude avant cet accord.
Le kit peint et les scènes Godot n'ont pas encore été migrés.

## Demande et référence

Après les essais de sol, l'utilisateur propose une direction 2D isométrique et
demande si nos wireframes peuvent être adaptés à la grille visible dans
[2D Casual Isometric Object pack, Jeeyoung Lee](https://emeldalee.artstation.com/projects/4bevKn).
Les illustrations de terrain, de maçonnerie et d'escaliers, ainsi que la capture
de l'éditeur avec sa grille en losanges, ont été examinées dans le navigateur.

L'accord retient la projection commune des murs et du sol illustrée par cette
étude. Il ne vaut pas validation d'une nouvelle peinture ou d'un nouveau design
du cœur schématique. Les précédents essais restent dans `ground-perspective-review/`.

## Grille retenue

Le rapport largeur/hauteur du losange est **2:1**.
C'est le choix de cette étude validée, pas une mesure certifiée de la référence.
Cette projection est couramment appelée isométrique en 2D ; elle est dimétrique
au sens géométrique strict.

```text
écranX = 256 × (x − y) / 2
écranY = 256 × ((x + y) / 4 − sqrt(3/8) × z)
```

Les deux axes d'écran sont orthogonaux avec la même norme. Les deux axes au sol
ont la même longueur projetée. Une caméra orthographique élevée de 30°, orientée
à 45° dans le plan, donne ce rapport. La hauteur monte verticalement à l'écran.

- Une case logique reste **1 × 1**, indexée par deux entiers.
- Son losange source fait **256 × 128 px** ; affiché au zoom 0,75 : **192 × 96 px**.
- Les petites dalles sont un motif intérieur, pas les cases de construction.
- Les règles de voisinage cardinal/diagonal et les largeurs en cases restent
  celles de la grille actuelle. Les coordonnées logiques ne sont pas tournées.

## Contenu de l'étude

Le modèle reprend les treize cases de `MobileReference` : salle 3 × 2,
couloir est de trois cases et couloir sud de quatre cases, bouts fermés.
Les murs conservent leur épaisseur 1/6, leur hauteur 1,88/6 et leurs deux assises.
Les piliers conservent leur largeur 0,24 et leur hauteur H + 0,035.

Le cœur est le volume **schématique** des essais précédents. Ses marches,
ses quatre pierres d'angle et son logement circulaire sont projetés comme le
sol. Ce volume ne remplace pas le sprite approuvé et ne valide pas un nouveau
design du cœur. Le vortex est un repère circulaire tourné vers la caméra.

Les arêtes cachées sont retirées avec les mêmes intersections rayon/triangles
que les études de géométrie. La direction de vue est adaptée à cette caméra.
Les joints du dallage sont ceux du motif d'origine, sans l'inclinaison ajoutée
dans l'essai `wireframe-v2-floor-only`.

## Fichiers et reproduction

```powershell
node tools/prepare_isometric_wireframe_review.cjs
```

Node.js et Sharp sont nécessaires. Les fichiers sortent uniquement dans ce
dossier de revue :

- `room-grid.png` / `.svg` : salle avec grille logique rose.
- `room.png` / `.svg` : vue sans grille de contrôle.
- `room-transparent.png` / `.svg` : traits seuls avec fond transparent.
- `logical-grid.png` / `.svg` : mêmes coordonnées sur plan carré et losanges.
- `geometry.json` : caméra, modèle, visibilité, provenance, périmètre et hashes
  du kit/de la scène actifs au moment de l'étude.

Les planches ont été inspectées visuellement après export. Ce sont des dessins
hors Godot, pas des captures de jeu. Aucun test automatisé ou changement des
sprites/scènes actifs n'est inclus.

## Travail restant pour la migration

Nous pouvons réutiliser les modèles et la logique de voisinage. Il faudra
reprojeter portes, escaliers et fixations murales, préparer les nouvelles images
peintes, adapter la vue des accessoires et du cœur, puis modifier le placement,
la sélection d'une case au toucher et l'ordre d'affichage dans Godot.

La lisibilité des couloirs et des personnages derrière les murs de premier plan
devra être évaluée à la taille de jeu. Le prototype ne démontre pas encore leur
lisibilité ni la compatibilité de toutes les orientations. Le principe de sprites
préparés hors du jeu reste applicable ; aucune peinture ou déformation de PNG à
l'exécution n'est requise par cette direction.
