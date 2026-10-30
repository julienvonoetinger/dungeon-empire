# Bandeau C avec ses dix runes de vie — 2026-10-28

L'utilisateur choisit C dans v12 et rappelle que les runes représentent la vie du cœur. La silhouette C est retenue ; restaurer le mécanisme visuel existant, ne pas traiter les runes comme des ornements facultatifs.

`proposal.png` est une maquette ImageGen : dix runes dans le logement de pierre central, exemples à 100 % et 60 %. Les dix secteurs commencent en haut et se suivent dans le sens horaire ; six sont lumineux à 60 %, les quatre autres restent gravés mais éteints. Le contour extérieur anguleux et les grandes plaques emboîtées de C sont conservés dans la proposition.

Références : `../v12-header-shapes/proposals.png` et `assets/ui/master/eye.png`. Prompt exact dans `prompt.txt`. Original conservé : `C:/Users/A/.codex/generated_images/01a15ce9-67f0-77e2-a485-14b09d65f5da/exec-d78e0eb6-1682-4e3c-9be4-7952620d4ae1.png`.

Le shader de production actuel utilise déjà dix secteurs, avec `ceil(life * 10)` : une tranche encore partiellement remplie reste allumée. Ce fonctionnement devra être conservé avec le nouveau graphisme. Cette image de comparaison n'est pas un atlas ni une preuve de rendu Godot ; la lisibilité aux tailles mobiles et l'alignement exact des secteurs devront être vérifiés lors de l'intégration.

Aucun fichier de production modifié, aucun APK, commit ou push. La correction graphique est présentée pour revue.
