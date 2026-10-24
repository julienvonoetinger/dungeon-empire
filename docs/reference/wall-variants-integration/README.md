# Murs A/B/C et D2 dans Godot — 23 octobre 2026

Intégration autorisée par « Go », après la sélection D2. Les scènes utilisent
des PNG complets préparés hors de Godot, sélectionnés de manière stable par case.
La recette et les règles de raccord sont dans [WALL_VARIATIONS.md](../WALL_VARIATIONS.md).

## Aperçus

- [Les 20 scènes](scenes.png), capturées dans Godot.
- [Portes, escaliers et couloirs larges](details.png) : 13 vues rapprochées.
- [Raccord large avec D2](wide-join.png).
- [SixRoomPreview](six-rooms.png) et [salle 5×5](room-5x5.png).

La planche des scènes et celle des détails ont été examinées. Les vues individuelles
ReferenceCalibration, porte ouest, escalier est et raccord large ouest ont aussi
été regardées à leur résolution de capture. Aucun raccord de matière discontinu
n'a été relevé dans ces vues. Les pierres partagées gardent une peinture commune ;
les faces intérieures éligibles prennent A/B/C/D2. Le sol reste calme et inchangé.

## Résultats et limites

| Élément | Résultat |
| --- | --- |
| Catalogue connecté | 2 900 structures uniques, 1 444 contextes, quatre chemins par contexte |
| Contextes sans structure | 161 |
| Images utilisées par style | 737, avec partage des doublons entre styles |
| Catalogue isolé | 57 PNG, 146 alias |
| Rapports d'export | Zéro écart d'alpha / pixel intérieur non peint ; joints identiques |
| Sol commun | SHA-256 identique à la version approuvée précédente |
| Godot | Import et quatre commandes de capture : sorties 0, stderr vide |
| Captures | 20 scènes × 2 dimensions + 13 détails = 53 PNG |
| Nettoyage | 641 anciens PNG sans référence, plus leurs fichiers .import |

`review.json` contient les empreintes des captures, des matières et du sol ainsi
que les résultats des rapports d'export. `retired-files.json` inventorie les fichiers
retirés ; copie locale récupérable dans `artifacts/wall-variants-retired/`.
Les anciens fichiers suivis restent également dans l'historique Git.

Aucun test automatisé n'a été exécuté. La revue visuelle ne couvre pas tous les
assemblages futurs, tous les niveaux de zoom ou la lisibilité avec les personnages
et les objets. La disposition des scènes, les deux assises des murs et la projection
sont conservées. Les proportions du sélecteur ne garantissent pas une quantité
visible de chaque motif dans une petite scène.

## Reproduire les captures

Après l'export complet et l'import décrits dans WALL_VARIATIONS.md, utiliser les
outils existants. Les captures ont besoin du moteur graphique ; ne pas ajouter
`--headless` aux commandes ci-dessous. Dans une automatisation Windows, lancer
Godot avec `Start-Process -WindowStyle Hidden -Wait`.

```powershell
$captureScenes = @(rg -l 'wireframe_cell_study.gd' scenes | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) }) + @('EntranceVariants')
godot --path . --script res://tools/capture_wireframe_cells.gd -- $captureScenes
godot --path . --script res://tools/capture_wireframe_doors.gd
godot --path . --script res://tools/capture_wireframe_entrances.gd
godot --path . --script res://tools/capture_six_room_wireframe.gd
node tools/prepare_wall_variants_integration_review.cjs
```

Les PNG complets et logs sont sous `artifacts/wireframe-*` et
`artifacts/wall-variants-*`. Les planches sont seulement des documents de revue,
jamais des images de salle utilisées par le jeu. L'éditeur déjà ouvert doit
actualiser ses textures après l'import : **Dungeon → Actualiser le rendu**, ou **F6**.
