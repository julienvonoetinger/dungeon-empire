# Porte : structure et apparence validées

**Apparence validée : [sommet en arche et ferrures en retrait](painted-art-v2/).**
L'utilisateur a demandé des ferrures moins proches du bord et une peinture
réellement arquée. La v2 corrige ces deux points sur la géométrie v8 validée.
Comparaison à l'échelle de jeu et guide superposé disponibles. L'utilisateur a
validé cette apparence avec « Ok » ; `painted-art-v2/selection.json` en conserve
les empreintes. Après le « Vas-y » de l'utilisateur, elle est maintenant
**intégrée au kit actif dans les quatre orientations**. Voir le
[bilan d’intégration](integration/) et les captures des scènes Godot.

**Étape précédente : [vantail lisse texturé, v8](painted-v8/).**
L'utilisateur a validé le [wireframe v8](wireframe-v8/) avec « Ok ».
Le contour et le volume du bois sont conservés, mais les traits intérieurs
de planches et de poignée sont retirés pour laisser le choix de la texture.
Les deux arches et le mur lisse en retrait gardent la structure validée en v7.
La proposition peinte v8 applique le bois existant d'un seul tenant, sans ferrures.
Cette base a ensuite reçu l'apparence validée ci-dessus.

**Historique : wireframe v7 validé par l'utilisateur (« Ok »).** Son
[rendu texturé précédent](painted-v7/) reste figé dans les quatre orientations.

**Structure approuvée : [wireframe-v7/](wireframe-v7/).** L'utilisateur demande
de garder la grande arche et d'ajouter une petite arche intérieure, avec de la
maçonnerie sur les côtés **et au-dessus** du bois. Le wireframe doit être validé
avant de produire de nouvelles textures ou d'intégrer la proposition au kit.
La révision 3 ajoutait une rangée de briques intermédiaire, donnant l'impression
d'une troisième arche. La révision 4 supprimait aussi l'espace, à tort.
La v5 interprétait cet espace comme un vide. L'utilisateur a précisé qu'il faut
un **mur lisse** : la v6 remplit l'espace entre les arches, au-dessus et sur les
côtés, sans joints de briques. Le gris uni représente cette surface pleine dans
le wireframe de validation ; aucune nouvelle texture n'est encore appliquée.
Dernier ajustement : le mur lisse doit être légèrement moins épais que les
arches. La v7 propose une épaisseur de 80 %, centrée, pour un retrait sur les
deux faces. Les dimensions de face des arches, du mur et du bois sont conservées.

**La révision 2 ci-dessous est rejetée :** elle conservait la hauteur de l'ancien
sommet du bois et ajoutait seulement des montants latéraux. Ses images peintes
et scripts restent une trace de l'essai, pas une référence approuvée.

## Historique : révision 2, arche conservée et montants latéraux

Proposition du 24 octobre 2026, après la demande de réduire la porte en bois et
de l'entourer d'un cadre en pierre au lieu de la raccorder directement aux murs.
L'utilisateur a rejeté la première proposition qui réduisait aussi l'arche.
Il a ensuite confirmé : garder l'arche actuelle, réduire uniquement le bois,
ajouter deux vrais montants en pierre entre la porte et les murs.
Cette révision 2 a ensuite été rejetée et remplacée par la demande d'une petite
arche intérieure. À cette étape historique, le kit actif n'était pas remplacé.

## Proportions proposées

- Vantail : largeur 0,58 case, contre 0,8333 auparavant (−30,4 %).
- Arche : PNG, ancrage, largeur et hauteur exactement conservés. Hauteur totale
  0,8967 case avant et après ; aucune réduction ou translation de l'arche.
- Bois limité à x = 0,21…0,79, conservant la courbe et la hauteur du sommet
  d'origine. Les ferrures et poignées sont repositionnées sur cette largeur.
- Montants : bandes latérales entre x = 1/12…0,20 et x = 0,80…11/12,
  du sol jusqu'à la courbe intérieure de l'arche originale. Les sommets reprennent
  exactement les segments de cette courbe, sans modifier son contour.
- Joints horizontaux des montants à H/2, H et 3H/2, avec H = 1,88/6.
- Ouverture entre montants : demi-largeur 0,30 ; bois 0,29.
- Perspective, grille 1×1, murs à deux assises, bois/pierre et poignées sur les
  deux faces sont conservés. Aucun nouvel élément n'est peint à l'exécution.

Les valeurs exactes sont une proposition d'implémentation, pas un choix chiffré
fourni ou validé par l'utilisateur. Les quatre vues sont des projections du
même modèle. L'entrée par escalier n'est pas modifiée.

## Images

- `before-after-v2.png` et `before-after.png` : même couloir avant/après,
  à 192 px par case, avec l'arche inchangée.
- `four-directions.png` : les quatre orientations proposées, à la même échelle.
- `sprites/` : arche originale, bois réduit et deux montants préparés séparément.
- `guides/` et `overlays/` : contrôle de la géométrie et des faces visibles.
- `source/` : atlas et catalogue actuels figés pour la comparaison.
- `rejected-v1/` : proposition rejetée qui réduisait toute l'arche. Ne pas
  l'utiliser comme nouvelle référence ou comme validation artistique.

Les captures utilisent le renderer mobile existant, ses règles d'occlusion et
son placement des murs. Les deux montants ont chacun leur volume de support pour
respecter l'occlusion des murs et du bois. L'arche continue d'utiliser sa région
originale dans l'atlas figé. Les images préparées sont chargées par l'outil de revue
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
