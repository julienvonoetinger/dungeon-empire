# Éclairage propre au cœur — essai du 25 octobre 2026

L'utilisateur souhaite que le cœur soit sa propre source lumineuse, indépendante
des torches, afin de conserver un ancrage visuel dans les salles sans torche.
Cela ouvre une nouvelle approche après les ombres orientées vers les torches.

`comparison.png` montre deux captures Godot de DungeonPreview au zoom .75, avec
le même cœur, la même caméra et les mêmes dalles. À gauche, le contact actuel ;
à droite, l'essai d'ombre et de lumière produites par le vortex. Le kit actif et
la scène de production ne sont pas modifiés. L'apparence attend un retour.

## Calcul de l'essai

- Source centrée sur `heart.orb.centre = [0,0,.56]` du wireframe figé.
- Projection ponctuelle des faces rigides sur z=0 ; neuf positions de source
  adoucissent la pénombre. Le vortex lumineux ne fait pas partie des obstacles.
- Ombre de contact sous le vrai socle, et ombre plus large des reliefs.
- Lueur violette additive sur le sol, avec atténuation en coordonnées monde,
  masquée par la même occlusion. Aucun PointLight2D ajouté.
- Deux PNG séparés, ombre et lueur, sous les objets. C'est une approximation
  artistique de l'éclairage au sol, pas une simulation physique complète.

L'obscurcissement, le rayon et l'intensité sont des choix pour cet essai, pas de
nouvelles dimensions approuvées. Le dessin et la géométrie du cœur sont inchangés.
`first-pass/` conserve l'essai initial aux ombres plus nettes et à la lueur plus
forte. La capture courante emploie une émission plus large et une lueur atténuée.

## Reproduction

```powershell
node tools/prepare_heart_self_light_review.cjs
godot --path . --rendering-method gl_compatibility --script res://tools/capture_heart_self_light_review.gd
node tools/prepare_heart_self_light_review.cjs --boards
```

Deux captures : sortie 0, stderr vide. Elles ont été inspectées visuellement.
Les fichiers du kit actif et les sélections précédentes sont inchangés par hash.
Pas d'intégration, de test automatisé, de commit ou de push. Une intégration
ultérieure devra masquer la lumière et l'ombre aux limites du vrai sol et adapter
leur rangement dans l'atlas ; cette étude utilise un cœur au milieu d'une pièce.
