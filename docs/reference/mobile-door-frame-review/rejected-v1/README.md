# Porte plus petite avec encadrement complet en pierre

Proposition du 24 octobre 2026, après la demande de réduire la porte en bois et
de l'entourer d'un cadre en pierre au lieu de la raccorder directement aux murs.
Le kit actif n'est pas remplacé avant la revue visuelle.

## Proportions proposées

- Vantail : largeur 0,58 case, contre 0,8333 auparavant (−30,4 %).
- Ensemble : hauteur 0,7133 case, contre 0,8967 (−20,4 %).
- Deux montants en pierre du sol jusqu'à H = 1,88/6, joint horizontal à H/2.
- L'encadrement tient entre les faces intérieures des murs : x = T/2 et 1−T/2.
- Ouverture : demi-largeur 0,30 ; vantail 0,29, léger retrait de son contour.
- Arche : couronne intérieure 0,26 au-dessus de H ; extérieure 0,40.
- Perspective, grille 1×1, murs à deux assises, bois/pierre et poignées sur les
  deux faces sont conservés. Aucun nouvel élément n'est peint à l'exécution.

Les valeurs exactes sont une proposition d'implémentation, pas un choix chiffré
fourni ou validé par l'utilisateur. Les quatre vues sont des projections du
même modèle. L'entrée par escalier n'est pas modifiée.

## Images

- `before-after.png` : même couloir avant/après, à 192 px par case.
- `four-directions.png` : les quatre orientations proposées, à la même échelle.
- `sprites/` : arche avec montants et vantail préparés séparément.
- `guides/` et `overlays/` : contrôle de la géométrie et des faces visibles.
- `source/` : atlas et catalogue actuels figés pour la comparaison.

Les captures utilisent le renderer mobile existant, ses règles d'occlusion et
son placement des murs. Les images préparées sont chargées par l'outil de revue
uniquement ; aucun rendu de matériau ou déformation n'est ajouté au jeu.

## Reproduction

```powershell
node tools/prepare_mobile_door_frame_review.cjs
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_door_frame_review.gd
node tools/prepare_mobile_door_frame_review.cjs --boards
```

`proposal.json` garde les paramètres, empreintes des sources et rapports du
compositeur. `export-audit.json` compare les exports par défaut aux anciens
sprites et l'atlas actif à sa copie initiale. Aucun test automatisé ajouté.
La validation artistique et les raccords de configurations arbitraires ne sont
pas déduits de ces quatre vues.
