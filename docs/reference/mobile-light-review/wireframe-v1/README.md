# Torche murale : proposition de structure

L'utilisateur a signalé que les décors frontaux ne suivaient pas la perspective
des murs, puis accepté de commencer par un wireframe de torche sur un mur
horizontal et un mur vertical. Les anciennes images restent des références de
style. Elles ne valident pas la géométrie de cette proposition.

## Lecture

- `comparison.png` / `comparison.svg` : deux orientations du même volume,
  avec un agrandissement de chaque fixation.
- Cyan : plaque de fixation chanfreinée, bras et support de coupelle.
- Ambre : corps creux de la coupelle, rebord et fond intérieur.
- Gris : mur existant, deux assises en façade. Le dessus appartient à l'assise
  supérieure, ce n'est pas une troisième rangée de briques.
- `context-horizontal.png` / `context-vertical.png` : wireframes à l'échelle
  de jeu, 192 pixels affichés par case.
- `guide-*.png` / `guide-*.svg` : traits magenta sur alpha transparent, à
  256 pixels par case. Les traits masqués sont retirés, y compris ceux de la
  pierre derrière le décor. Ce sont des guides de contexte, pas des sprites peints.

La flamme est volontairement absente de cette validation de pièces rigides.
Le cristal sera à reprendre après validation de la méthode sur cette torche.

## Géométrie reproductible

Commande : `node tools/prepare_mobile_torch_wireframe.cjs` (Sharp requis).

Le script importe les constantes et la fonction de projection du kit depuis
`prepare_mobile_reference.cjs` sans appeler son export. Projection exacte :
`X = 256 × (x − 0,18z)` et `Y = 256 × (y − 0,9z)`. Le sol reste dans le plan
XY sans raccourcissement. Une ouverture circulaire horizontale conserve donc
sa forme circulaire dans cette convention ; aucun aplatissement arbitraire
de la coupelle n'a été ajouté.

Les coordonnées locales sont `u` le long du mur, `v` vers l'extérieur et `z`
la hauteur. La face arrière de la plaque est exactement sur `v = 0`, au contact
de la façade ; la plaque mesure 0,104 × 0,178 case et a 0,012 case d'épaisseur.
Le bras rejoint un support sous la coupelle, dont le centre est à 0,113 case de
la façade. Son rayon extérieur est 0,079 et le rebord culmine à z = 0,264.
Ces dimensions sont une proposition à approuver.

Pour le mur horizontal, `(u,v,z)` devient `(0,5+u,T/2+v,z)` ; pour le vertical,
`(T/2+v,0,5−u,z)`. L'orientation est appliquée au volume avant la projection.
La plaque sur le mur vertical est donc vue presque de profil. Il n'y a aucune
rotation d'un sprite existant ni changement de caméra entre les deux vues.

Les surfaces triangulées servent à retirer les traits cachés par intersection
de rayons vers `(0,18; 0,9; 1)`, avec découpage des segments visibles. Les cercles
sont approchés par 32 côtés ; seuls les contours utiles de la coupelle sont
tracés, sans grille de triangulation. `geometry.json` conserve toutes les faces,
arêtes originales, portions visibles et l'empreinte de l'atlas actif.

## État

Les exports et les deux vues rapprochées ont été inspectés visuellement. Le
script d'export termine avec le code 0. Aucun test automatisé ajouté ou exécuté.
Aucune peinture, intégration Godot, modification de l'atlas ou des scènes de
production, ni commit/push. La structure attend la validation visuelle du joueur.
