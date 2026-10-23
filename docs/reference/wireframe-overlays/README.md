# Calques transparents pour contrôler les futurs sprites

Ces guides répondent à la demande du 23 octobre 2026 : superposer les wireframes
aux futures images peintes pour comparer leurs contours, leur perspective et
leurs joints. La couleur choisie pour ce premier export est le **magenta #ff00ff**.
L'utilisateur a demandé une couleur très voyante, sans imposer de teinte précise.
La correction suivante précise que chaque image sera examinée **seule** : garder
tous les contours visibles, y compris ceux des extrémités des murs, mais jamais
les arêtes cachées par un volume. Le fond transparent peut apparaître noir dans
un lecteur ; aucun fond noir ne doit être enregistré dans le PNG.

Le motif de sol actuel vient de `docs/reference/floor-periodic-cell.json` :
26 fragments, joints décalés, largeur des pierres périodiques bornée à 0,24..0,40 case.

## Fichiers

- `cells/` : 136 identifiants du catalogue, avec le sol visible et les murs/piliers,
  présentés comme des pièces isolées complètes. Plusieurs identifiants connectés
  deviennent visuellement identiques une fois leurs extrémités rétablies.
- `floor.svg` et `floor.png` : sol seul dans son cadrage d'origine.
- `entrances/` : les quatre escaliers complets.
- `doors/` : les quatre portes complètes.
- `pillar.svg` et `pillar.png` : le pilier seul, sans sol ; deux assises, un joint
  horizontal et aucun joint vertical.
- Chaque guide existe en SVG et PNG RGBA, sans fond ni face opaque.
- `catalog.json` : dimensions, ancrages, sources et empreintes SHA-256.
- `comparison.png` : planche de présentation sur damier. **Le damier appartient
  uniquement à cette planche**, jamais aux PNG individuels.

Les versions blanches de construction et les scènes Godot restent disponibles.
Ces fichiers sont des guides de revue ; aucun sprite peint n'est généré ici.
Le total est de **146 guides**, pas une liste de 146 images peintes à commander.
L'utilisateur a écarté la composition « sol + deux piliers » de la planche des
pièces à produire : elle réutilise le sol et le même pilier à deux emplacements.
Sa variante reste disponible comme référence technique de raccord.

## Superposition

1. Choisir le même identifiant de variante et la même orientation que le sprite.
2. Conserver la taille du canevas, sa marge transparente et son point d'ancrage.
3. Placer le PNG magenta dans un calque au-dessus du sprite, à la même position.
4. Afficher/masquer le calque pour examiner les écarts. À une autre résolution,
   appliquer exactement la même échelle uniforme à l'image et au guide.

| Famille | Canevas à 256 px/case | Ancrage logique (0,0,0) |
| --- | --- | --- |
| Cases complètes, avec sol | 304 × 352 | (24,88) |
| Sol seul | 264 × 264 | (4,4) |
| Escaliers complets | 304 × 352 | (24,88) |
| Portes complètes | 304 × 392 | (24,128) |
| Pilier seul | 96 × 144 | (24,88), coin NW de son pied |

Ne pas recadrer automatiquement aux pixels visibles, retourner une vue gauche
pour obtenir la droite, étirer l'image ou déplacer le calque pour compenser un
défaut de perspective. Le pas reste **256 px**, pas la largeur du canevas.

Les cases ordinaires du renderer actuel utilisent deux images (sol puis murs).
Le guide `cells/` représente leur composition dans le cadre des murs : pour une
comparaison externe, le sol se place à **(20,84)** dans ce cadre. Ce décalage est
la différence entre les deux ancrages des images isolées, pas une modification de géométrie.
Le sol connecté peint, opaque et sans marge, a l’ancrage (0,0) : le placer à
(24,88) dans ce même cadre, à l’échelle logique 256 px.

Les traits conservent leurs épaisseurs : contour 3 px, joints 2 px, sol 1,5 px.
Le pilier mesure exactement 1/6 × 1/6 de case et 1,88/6 de haut ; son unique joint
est à 0,94/6. Il conserve le même pas de 256 px/case et la même projection que les
murs. Seule la planche de présentation l'agrandit ×2 pour rendre ses traits lisibles.
Les références servent à juger la géométrie. Les détails peints pourront varier
avec le style accepté ; ce guide ne remplace pas une revue artistique.

## Visibilité et limites d'assemblage

La première version des calques reprenait les images connectées : leurs contours
étaient incomplets aux extrémités. L'utilisateur a explicitement corrigé ce choix.

- Les cases utilisent la construction commune en mode `standalone=true` : les
  mêmes volumes, mais avec leurs faces terminales présentes. Le calcul de
  visibilité conserve uniquement les arêtes en ligne de vue.
- Les portes reprennent exactement `visibleEdges` dans les quatre études
  `door-arch-facing-*-wireframe.json`, dont la vue sud montrée par l'utilisateur.
- Les escaliers reprennent les arêtes complètes de leur étude isolée, tournées
  dans le monde ; leur visibilité est recalculée sous la caméra commune. Le
  dallage reste orienté dans les axes du monde.
- Les bordures du sol isolé sont présentes. Les joints cachés sous les faces
  des murs sont retirés avant d'omettre les remplissages blancs.

Chaque guide décrit **une pièce isolée**. Ces contours fermés servent à la revue
image par image et ne remplacent pas les textures connectées dans Godot : une
face terminale redevient interne lorsque deux murs se touchent. Le renderer et
les scènes restent inchangés ; aucun mode de superposition global n'est ajouté.

## Reproduction

Après une modification des sources, régénérer d'abord les catalogues connectés
avec les commandes de [WIREFRAME_WORKFLOW.md](../WIREFRAME_WORKFLOW.md), puis :

```powershell
node tools/export_wireframe_overlays.cjs
```

Ce mode demande seulement Node.js et réécrit SVG, catalogue et planche SVG.
Pour produire également tous les PNG transparents, rendre le module `sharp`
accessible à Node.js puis utiliser :

```powershell
node tools/export_wireframe_overlays.cjs --png
```

Sans `--png`, les PNG déjà présents ne sont pas actualisés. Il faut donc utiliser
ce paramètre avant de livrer une nouvelle révision des calques. `sharp` rasterise
les vecteurs : aucune suppression de couleur ou découpe d'une image peinte.

Le script ne lit aucune ancienne proposition peinte. Il utilise la géométrie
commune de `export_wireframe_cell_kit.cjs`, les sources isolées des escaliers et
des portes, ainsi que les catalogues actuels pour leurs tailles et ancrages.
L'export est hors ligne ; aucun calcul d'image n'est ajouté au jeu.
