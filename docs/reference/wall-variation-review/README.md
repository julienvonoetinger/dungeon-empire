# Variantes de murs — proposition du 23 octobre 2026

Statut : **proposition pour validation visuelle**, sans intégration Godot.
L'utilisateur demande de travailler sur la répétition des murs après avoir
validé et intégré les grandes dalles lisses aux coins arrondis.

## Images à examiner

- `comparison.png` : mur actuel, assemblage varié et quatre sprites distincts.
- `vertical-comparison.png` : même principe sur un mur vertical.
- `corner-comparison.png` : coin supérieur gauche actuel/proposé/overlay magenta.
- `join-detail.png` : agrandissement du raccord entre deux variantes B/A.

Les quatre variantes sont complémentaires : A calme, B usée, C ébréchée,
D avec corruption violette localisée. La séquence horizontale montrée est
A/B/A/C/B/D/A/C, avec un seul élément D parmi huit cases. Ce rythme est un
exemple de placement, pas un nouvel algorithme actif dans le jeu.

## Méthode et limites

- Huit PNG distincts : quatre variantes horizontales et quatre verticales.
  Chacun est préparé sur un voisinage local de trois cases avant découpage.
  Les planches assemblent ensuite ces PNG ; ce ne sont pas des textures de
  salle précalculées destinées au jeu.
- Les pierres touchant une frontière longitudinale de case, y compris celles
  qui s'y terminent, gardent une matière calme commune. Cela couvre aussi la
  garde de filtrage existante. Les autres pierres varient à l'intérieur.
- Le dessus et la façade supérieure d'une pierre utilisent la même matière.
  Projection, joints, silhouettes, arrondi B et ancrages sont conservés.
- Le petit trait violet procédural est désactivé dans cette proposition.
  La lueur D appartient à la peinture générée de la pierre.
- Le sol conserve sa recette approuvée, ses grandes dalles C et son arrondi.
  Les PNG de référence et le catalogue de matériaux actifs à la création de
  cette revue sont figés dans `source/`. Ne pas les remplacer lors d'une
  promotion future.
- Les raccords communs limitent volontairement la variation aux extrémités.
  Le rythme des joints reste celui des wireframes approuvés.
- Le coin NW est une proposition isolée supplémentaire. Cette revue ne couvre
  pas encore toutes les configurations de coins, piliers, portes et escaliers,
  ni toutes les combinaisons de voisins du catalogue de production.

## Sources et reproduction

La peinture provient de l'atlas généré existant
`assets/dungeon/shared-materials/proposals/variation-review/atlas-calm.png`.
Sa provenance et ses prompts restent dans `material-variation-review/`.
Il n'y a pas de nouvelle génération indépendante par orientation.

Trois découpes supplémentaires se trouvent dans `materials/` : pierre calme
de raccord, éclat et corruption. Leurs rectangles source et empreintes sont
dans `recipe.json`. Elles rendent les motifs lisibles sur les faces étroites
sans déplacer aucun joint. Les huit échantillons de la proposition précédente
restent disponibles ; seuls les matériaux effectivement utilisés sont peints.

```powershell
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' tools/prepare_wall_variants_review.cjs
```

Le script réutilise le compositeur et les contextes connectés existants. La
recette enregistre les empreintes des sources, des outils et des textures.
Reproduire avec les mêmes versions ; ne pas réinterpréter une évolution des
sources de géométrie comme une validation de cette revue historique.

## Revue effectuée

Export terminé sans erreur. Les huit rapports de murs et celui du coin
indiquent des joints de construction identiques aux guides, zéro pixel
d'alpha différent du modèle, zéro trou intérieur et zéro débordement intérieur.
Le coin conserve ses 38 segments source. Les quatre planches ci-dessus ont
été examinées visuellement, dont le raccord agrandi et l'overlay du coin.

Ces mesures portent sur les exports montrés ; elles ne prouvent pas tous les
raccords possibles. Aucun test automatisé ni changement de scène Godot pour
cette proposition. La validation artistique reste à demander à l'utilisateur.
