# Proposition : fer sombre et sceau violet

L'utilisateur demande une porte plus travaillée et mieux intégrée à l'ambiance
du donjon. Cette proposition ajoute deux ferrures épaisses, un anneau métallique
et un sceau violet localisé sur du bois sombre peint dans le style de la maquette.

## À regarder

- `before-after.png` : base v8 et proposition à la distance de jeu (192 px/case).
- `paint-and-guide.png` : rendu et contours magenta superposés.
- `four-directions.png` : les quatre orientations avec le même dessin de surface.
- `source/door-artwork.png` : peinture originale haute résolution, conservée
  comme source d'auteur uniquement. Elle n'est pas ajoutée à l'atlas actif.

La forme et la profondeur du vantail sont celles du wireframe v8 approuvé.
Le dessin de surface ne crée aucun joint structurel. Les deux grandes faces
reçoivent la même peinture avec sa poignée ; les chants gardent un bois calme.
Les deux arches et le mur lisse en retrait conservent leur peinture précédente.

## Génération et application

Outil : **ImageGen intégré**, avec la maquette et la revue v8 comme références.
Le prompt exact et le fichier original sont enregistrés dans `generation.json`.
Direction proposée : bois peint stylisé, grosses ferrures en fer bleuté, anneau
lisible, petite incrustation violette ; aucun cadre en pierre dans la texture.

La texture frontale est appliquée hors du jeu avec le workflow de masques validé,
selon les coordonnées locales de chaque face. La silhouette, les lignes et les
ancrages viennent du modèle v8. Aucun sprite n'est tourné comme une image plane
pour simuler une autre orientation. Le jeu ne génère aucun pixel.

```powershell
node tools/prepare_mobile_nested_door_review.cjs --art
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_nested_door_review.gd -- --art
node tools/prepare_mobile_nested_door_review.cjs --boards --art
```

## Contrôles et statut

28 parties préparées et 12 captures Godot, code de sortie 0, stderr vide.
Les captures à .75 et la superposition ont été inspectées. `export-report.json`
consigne les comparaisons d'alpha, de guides et de pierre avec v8, ainsi que les
rapports de couverture du compositeur. L'atlas actif garde son empreinte.

Proposition artistique à valider. Les ferrures sont ici peintes dans la texture
du vantail ; elles ne sont pas encore des sprites de décor indépendants.
Aucune migration des scènes, aucun test automatisé ou profilage mobile.
