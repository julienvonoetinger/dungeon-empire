# Variantes de murs A/B/C et D2

L'utilisateur a choisi D2, puis autorisé l'intégration avec « Go ». La recette
active combine les variantes calme, usée, ébréchée et corrompue sélectionnées
dans les revues. Cette autorisation remplace leur statut de proposition seule.

## Matières et géométrie

L'atlas `assets/dungeon/shared-materials/wall-variation-atlas-v1.png` est une copie
inchangée de l'atlas utilisé pour les propositions. Les rectangles et empreintes
de ses sept nouvelles découpes sont dans `active-recipe.json`. Les quatre IDs
historiques de pierre utilisent aussi cette palette pour la maçonnerie annexe.
Le catalogue contient 17 matières au total, avec les sols, le bois et le fer.

Le sol lisse aux grandes dalles C, ses coins arrondis, le bois et le fer gardent
leur recette. La projection, les volumes, les deux assises, les joints, l'alpha
de construction, la finition B des murs et les ancrages restent fixes.

Le petit trait violet procédural est désactivé. D2 utilise la découpe exacte
sélectionnée, dont la peinture est dépliée une seule fois entre dessus et façade
supérieure. Le changement d'éclairage au pli est conservé ; le motif ne repart
pas de son origine sur la seconde face.

## Préserver les raccords

`tools/wall_material_variation.cjs` intervient après résolution des faces
complètes du voisinage local. Une pierre touchant une frontière longitudinale
de case, sortant de la case centrale ou appartenant à un pilier conserve la
matière commune calme. Cette règle couvre les pierres partagées et la garde de
filtrage. Seules les pierres intérieures éligibles varient.

La matière du dessus est reprise par sa façade supérieure. Pour D2, les deux
faces partagent aussi les coordonnées d'une même zone dépliée. Aucun changement
de contour, de joint ou de transparence n'est utilisé pour masquer un raccord.

## Catalogue et sélection dans Godot

L'export produit des PNG complets pour A/B/C/D2 à chaque configuration de voisins,
puis partage les résultats identiques. `catalog.json.contextStyles` et le
catalogue GDScript généré donnent quatre chemins par contexte. Le chemin A reste
disponible dans les anciennes tables de compatibilité. Les chemins sont chargés
à la demande ; le catalogue ne précharge pas toutes les images en mémoire vidéo.

`scripts/painted_wall_selection.gd` choisit un indice stable selon les coordonnées
entières de la case. Les 16 catégories de base se répartissent ainsi : huit A,
quatre B, trois C et une D2. Parmi des candidats D2 voisins, seul celui dont
l'empreinte est la plus basse garde D2 ; les autres passent en A. Le départage
par coordonnées traite les égalités. Les huit voisins sont pris en compte.

Ces proportions sont celles de la sélection, pas une garantie de quantité visible
dans chaque salle : certaines géométries n'ont pas de pierre intérieure éligible.
Le changement de style ne touche ni la sélection du voisinage ni les placements.
Godot choisit un fichier préparé ; il ne crée ni texture, ni géométrie, ni couleur.

Les portes, escaliers et leurs voisinages spéciaux passent par le même export.
L'arche garde ses masques de visibilité. Les études isolées montrent D2 sur leurs
pierres éligibles ; les scènes assemblées utilisent les quatre styles.

## Reproduire

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
godot --headless --path . --script res://tools/export_painted_scene_contexts.gd
node tools/export_painted_connected_kit.cjs
godot --headless --editor --path . --import
```

La promotion initiale est conservée dans `tools/promote_wall_variation_materials.cjs`.
Ne pas la relancer pour reproduire les exports : la recette active suffit.
Après un changement de matières, utiliser l'export complet pour les quatre styles.
`--specials-only` reste réservé aux mises à jour des contextes spéciaux d'une
famille déjà exportée ; il conserve la provenance des structures ordinaires.

Les scènes et le pas de 256 pixels restent inchangés. Pour actualiser un éditeur
déjà ouvert après import : **Dungeon → Actualiser le rendu**, ou **F6**.

## État de la revue

Intégration terminée le 23 octobre 2026 : 2 900 PNG structurels uniques pour
1 444 contextes, chacun avec quatre chemins A/B/C/D2 ; 161 contextes sont vides.
Les images identiques sont partagées (737 images utilisées par chaque style).
Les 57 images isolées couvrent toujours les 146 alias. Les rapports d'export
indiquent zéro différence d'alpha, zéro pixel intérieur non peint et des calques
de joints identiques aux guides. Le hash du sol commun est strictement inchangé.

Import Godot et captures : sorties 0, stderr vide. Les 20 scènes d'architecture
ont été capturées à 1280×960 et 2560×1920, plus 13 vues rapprochées : quatre
portes, quatre escaliers et cinq détails de SixRoomPreview. Les planches de toutes
les scènes et de leurs détails ont été examinées, ainsi que ReferenceCalibration,
la porte ouest, l'escalier est et le raccord large ouest en vue individuelle.
Aucune coupure de matière n'a été relevée sur ces vues. Cette revue ne prouve
pas tous les futurs assemblages, tous les zooms ou la lisibilité en jeu.
Aucun test automatisé exécuté.

Aperçus, empreintes et reproduction : [wall-variants-integration/](wall-variants-integration/README.md).
641 anciens PNG structurels non référencés et leurs fichiers d'import ont été
retirés du dossier actif, avec copie récupérable dans l'archive locale ignorée
`artifacts/wall-variants-retired/`. Aucun layout de scène n'a été modifié.
Les revues originales, y compris D rejetée et D1 non retenue, restent historiques.
