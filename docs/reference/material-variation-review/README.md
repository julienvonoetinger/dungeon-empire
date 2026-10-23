# Variété des matières et taille des dalles

Le 23 octobre 2026, l'utilisateur a **approuvé la taille C** (« oui le C »).
Le sol lisse et ses coins arrondis sont approuvés pour intégration dans Godot.
La nouvelle gamme de murs reste une proposition séparée.

## Comparaison prioritaire : taille du dallage

`floor-size-comparison.png` montre exactement la même surface de **3 × 3 cases
logiques de 1 × 1** dans trois découpages décoratifs :

- A : six rangées par case, découpage précédent ;
- B : trois rangées par case, dalles moyennes ;
- C : deux rangées par case, grandes dalles presque carrées.

Les trois panneaux utilisent la même gamme de matières proposée, le même profil
d'éclairage et la finition B approuvée. A représente donc le découpage précédent,
pas une capture inchangée du sol de Godot. La production utilise le découpage C
avec les matières actives précédemment approuvées.

Les dimensions candidates et rapports de composition sont conservés dans
`floor-size-proposals.json`. Les pierres traversant une limite de case sont
composées entières avant le cadrage. Les overlays magenta de chaque option
conservent les joints de construction pour inspection.

## Proposition de matières

### Révision actuelle : coins des dalles arrondis

L'utilisateur accepte le sol plus lisse et demande aussi des coins arrondis comme
la maquette. Cette révision conserve exactement les matières et leur répartition.
Seul le rayon des coins du sol passe de 3.8 à 10.5 pixels de référence, avant le
facteur sol .63 : environ 6.6 pixels pour une case affichée à 256 pixels. Le joint
sur les parties droites garde sa largeur ; les murs conservent leur finition B.

- `rounded-smooth-floor-detail.png` : détail agrandi avant/après.
- `rounded-smooth-floor-comparison.png` : champ de 3×3 cases avant/après.
- `rounded-smooth-c-comparison.png` : coin NW avant/après et overlay magenta.
- `rounded-smooth-floor-recipe.json` : profil exact, sources et rapports.

Reproduire : `node tools/prepare_rounded_smooth_floor_c_review.cjs`.
Les images précédentes sont figées dans `source/*-before-rounding.png`.
Le paramètre `model.floorFinish` s'applique uniquement à cette proposition ;
`stone-finish.json` actif n'est pas modifié. Les pierres entières sont peintes
avant cadrage du champ de sol, sans créer d'arrondi sur les limites de cases.
Les contours arrondis se situent à l'intérieur des faces de construction ;
l'overlay magenta conserve volontairement les lignes géométriques droites.
**Arrondi approuvé : « Oui » à la proposition d'intégration dans Godot.**
La recette active reprend ses paramètres et quatre échantillons pour les quatre
pierres périodiques C. Voir PAINTED_GODOT.md pour l'export actif.

### Direction acceptée : sol plus lisse et discret

L'utilisateur souhaite un sol plus calme, comme la maquette, pour laisser ressortir
les futurs objets. Huit nouvelles matières proposent de légères nuances de bleu
ardoise, sans gros éclats, trous ou fissures. Leur opacité de composition passe de
.78 à .55 ; les autres paramètres du profil, le dallage C et la finition B restent
identiques. Les murs de la proposition précédente sont conservés.

- `smooth-floor-comparison.png` : ancienne proposition et sol adouci sur 3×3 cases.
- `smooth-c-comparison.png` : coin NW précédent, sol adouci et overlay magenta.
- `smooth-c-proposal.png` et `smooth-c-overlay.png` : images RGBA individuelles.
- `smooth-floor-generation.json` : prompt imagegen, références et sortie originale.
- `smooth-floor-recipe.json` : matières, profil et rapports de composition.

Source : `assets/dungeon/shared-materials/proposals/variation-review/floor-smooth-v1.png`.
Reproduire : `node tools/prepare_smooth_floor_c_review.cjs`.
Les captures précédentes sont figées dans `source/*-before-smooth.png`.

Le rapport du coin conserve 38 segments, un alpha conforme au modèle et zéro
pixel intérieur non peint. La superposition a été examinée visuellement. La
lisibilité avec des objets en jeu et les raccords d'un futur catalogue ne sont
pas démontrés par cette revue. **Proposition à valider avant intégration** ; les
matières actives de Godot restent inchangées.

### Proposition précédente sur le dallage C

- `corner-c-comparison.png` : coin supérieur gauche actuel, proposition, puis
  proposition superposée au wireframe magenta.
- `appearance-c-comparison.png` : comparaison sur un mur de six cases et une
  surface de sol C de 3×3 cases, aux mêmes dimensions et échelles.
- `corner-c-proposal.png` et `corner-c-overlay.png` : images RGBA individuelles.
- `appearance-c-recipe.json` : bibliothèque, profils et rapports de composition.

Huit matières de mur et huit de sol sont proposées. Le sol favorise les matières
calmes ; éclats, creux et fissures restent ponctuels. Le coin est un échantillon
composé de la palette. Les champs de mur/sol choisissent leurs matières par pierre
entière avant cadrage. Les pierres hautes conservent le même identifiant sur leur
dessus et leur façade. Le petit trait violet ajouté est désactivé.

Le rapport du coin reprend les 38 segments du guide, avec zéro pixel intérieur
non peint et un alpha conforme au modèle. Les contours ont aussi été examinés
sur la superposition. Aucun test automatisé exécuté. Cet aperçu ne démontre pas
les raccords d'un futur catalogue de variantes. **Apparence à valider avant
propagation**, conformément à la revue de coin prévue dans AGENTS.md.

Reproduire : `node tools/prepare_material_variety_c_review.cjs`.
Les images avant changement sont conservées dans `source/`, sans remplacement
automatique lors d'une nouvelle exécution. Les scènes Godot restent inchangées.

### Étude précédente, avant choix du dallage

`comparison.png` compare les PNG actuels et la nouvelle gamme sur un mur de six
cases et un sol de six par trois cases. Son dallage conserve six rangées par case.
Huit matières de mur et huit matières de sol sont proposées. La corruption est
peinte dans deux échantillons de mur ; le petit trait violet ajouté par le
compositeur est désactivé dans cette étude.

La source sélectionnée est `atlas-calm.png` dans
`assets/dungeon/shared-materials/proposals/variation-review/`.
`generation.json` conserve les prompts et les trois tentatives. Le précédent
`atlas.png` est un intermédiaire trop granuleux, non sélectionné.

## Reproduction

Avec Node et sharp disponibles :

```powershell
node tools/prepare_material_variation_review.cjs
# Comparaison des tailles uniquement :
node tools/prepare_material_variation_review.cjs --floor-sizes-only
```

Ce script compose des images de revue hors ligne. Il ne remplace aucun catalogue
actif, wireframe de production, sprite de jeu ou scène Godot. La source et le PNG
du sol avant C sont figés dans source/ pour ne pas altérer la comparaison.

L'intégration C couvre les sources de géométrie, les sols des portes et escaliers,
les guides transparents et les exports isolés et connectés. La variété des murs devra préserver une identité commune pour toute
pierre traversant plusieurs sprites. Les images de cette étude ne constituent
pas encore un catalogue de variantes utilisable par le jeu.
