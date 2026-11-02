# Le coffre du tribut

Revue artistique isolée. La salle garde ses huit accès possibles, les murs et les empreintes de V5, le volume de V7 et un seul accès libre dans chaque configuration. Un coffre entrouvert occupe la grande alcôve. Les deux bourses peintes ont des silhouettes distinctes. Le butin central reste un ensemble de décor de la réserve pour cette revue.

## Sources et reproduction

Depuis la racine, avec Sharp disponible pour Node, exécuter dans cet ordre.

1. `node docs/reference/treasury-review/v7-reserve-en-relief/geometry.cjs` réexporte les masques des murs et les paramètres de la caméra.
2. `node docs/reference/treasury-review/v8-coffre-et-cuir/inputs.cjs` prépare les motifs, les bourses et les quatre dalles de chaque orientation. Les faces ordinaires reprennent une pièce peinte dans le master sud du coffre. Le losange du HUD est utilisé plus ponctuellement. Les deux vues du coffre utilisent le master directionnel de l’atlas du jeu, son empreinte, son échelle et son point d’appui. Le script vérifie les hashes des masters et leur ancrage avant de préparer les textures.
3. `blender -b --factory-startup --python-exit-code 2 -P docs/reference/treasury-review/v8-coffre-et-cuir/render.py` rend les huit calques avec les maçonneries de V5 comme surfaces d’occultation et de réception des ombres. Les peintures de coffre et de bourses suivent des surfaces de profondeur, projetées dans la caméra de V7. Ce sont des supports pour une caméra 2D fixe.
4. `node docs/reference/treasury-review/v8-coffre-et-cuir/prepare.cjs` conserve le point d’appui de chaque calque et vérifie les pigments visibles de la serrure et du couvercle à la position prévue. Les contrôles s’ajoutent à l’inspection visuelle des captures.
5. Ouvrir Godot avec `--path . --rendering-method gl_compatibility --script res://docs/reference/treasury-review/v8-coffre-et-cuir/capture.gd`, puis exécuter `node docs/reference/treasury-review/v8-coffre-et-cuir/verify.cjs` pour vérifier les dalles et générer le détail. La page `index.html` propose le comparatif avec V7.

Les sources peintes sont documentées dans `sources.json`. Les intermédiaires Blender sont sous `artifacts/treasury-painted`. Ce prototype fixe la présentation d’une salle statique. Il n’ajoute pas de règle de vol de coffre ou d’ordre de dessin pour un héros en déplacement.
