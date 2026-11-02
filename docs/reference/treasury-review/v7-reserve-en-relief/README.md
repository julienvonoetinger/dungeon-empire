# Réserve en relief

Cette étude conserve la salle, les quatre dalles peintes et les murs de V5/V6. Le contenu des deux niches est rendu hors ligne en 3D. Le sprite transparent d’une orientation contient la partie visible du trésor et les ombres reçues par le kit à cette position précise. Le jeu n’a pas à charger les mailles des pièces. Ce compositing convient à cette scène statique de revue. Un acteur qui traverse le butin dans une future scène jouable devra être intégré à l’ordre de dessin.

## Reproduire la revue

Depuis la racine du projet, avec Sharp dans le chemin de modules Node, exécuter les étapes suivantes.

1. `node docs/reference/treasury-review/v7-reserve-en-relief/geometry.cjs` récupère les deux supports validés et les murs natifs de chacune des huit pièces.
2. `blender -b --factory-startup --python-exit-code 2 -P docs/reference/treasury-review/v7-reserve-en-relief/render.py` rend les huit vues. Après `--`, on peut passer un ou plusieurs identifiants comme `S1 N1` pour reprendre un rendu ciblé. La recette a été exécutée avec Blender 5.2 et Cycles. Les motifs frappés proviennent de pièces isolées dans la feuille V6 `source/monnaie-plan.png`.
3. `node docs/reference/treasury-review/v7-reserve-en-relief/prepare.cjs` réduit les huit rendus, conserve leur ancrage et écrit la coupe géométrique.
4. Ouvrir Godot avec `--path . --rendering-method gl_compatibility --script res://docs/reference/treasury-review/v7-reserve-en-relief/capture.gd` pour capturer les vues. La scène de revue désactive la persistance.
5. Ouvrir `index.html` pour comparer chaque entrée avec la version à plat. Les répertoires intermédiaires sous `artifacts/treasury-volume` sont régénérables.

L’export contrôle quatre points de référence de la projection Blender à moins de 0,001 pixel du kit. Il vérifie aussi tous les sommets du butin au voisinage du seuil, le dégagement central et la hauteur des pièces dans chaque alcôve. Le compte des centres cachés teste la visibilité par rapport aux maçonneries selon le rayon de la caméra. Il ne dénombre pas les pièces cachées par d’autres pièces. La coupe de Sud 1 intersecte les faces des pièces et des murs avec un plan vertical.
