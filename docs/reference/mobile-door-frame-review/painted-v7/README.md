# Porte à deux arches — proposition texturée

Le wireframe v7 est validé par l'utilisateur. Cette revue applique les matériaux
du kit à sa géométrie dans les quatre orientations, avant validation du rendu.

## Images à examiner

- `before-after.png` : porte actuelle et proposition, à 192 pixels par case.
- `paint-and-guide.png` : proposition et superposition magenta.
- `four-directions.png` : nord, est, sud et ouest à la distance de jeu.
- `captures/` : les douze captures Godot originales, 400×420 pixels.
- `sprites/`, `guides/`, `overlays/` : parties préparées pour cette revue.

La grande arche utilise exactement les régions de l'atlas d'origine figé dans
`../source/`. Le nouveau bois, la petite arche et le mur lisse sont préparés
séparément. Le mur a 80 % de la profondeur des arches et reste centré, avec
un retrait de .016667 case de chaque côté. Aucun joint de briques n'est ajouté
sur sa surface. Les poignées sont présentes sur les deux faces du bois.

## Préparation

Sept nouveaux éléments par orientation : bois, petite arche, deux montants,
partie haute et deux parties latérales du mur lisse. Cette séparation permet
au renderer commun de traiter leur profondeur de support. Le mur lisse utilise
la pierre commune avec une opacité de texture de .20 et un repère UV commun.
Ses limites de découpe au départ de l'arc ferment seulement les zones à peindre,
sans trait ni nouveau chanfrein visible à la jointure.

Les matériaux viennent de la bibliothèque existante. La proposition ne change
ni le compositeur commun ni les exports de production par défaut. Aucun
matériau, dessin de perspective ou pixel n'est fabriqué dans le jeu.

```powershell
node tools/prepare_mobile_nested_door_review.cjs --legacy-v7
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_nested_door_review.gd -- --legacy-v7
node tools/prepare_mobile_nested_door_review.cjs --boards --legacy-v7
```

Le générateur lit la géométrie du wireframe v7 dont la validation est enregistrée
dans `../wireframe-v7/selection.json`. `proposal.json` garde la provenance et
les rapports du compositeur ; `export-report.json` résume les sorties.

## État de la revue

28 parties préparées. Rapports d'export : zéro différence d'alpha de construction,
zéro pixel intérieur non peint, zéro pixel extérieur excédentaire. Douze captures
Godot produites, processus terminé avec code 0 et stderr vide après correction
de l'inférence du type String dans l'outil de capture. Les quatre vues et la
superposition ont été inspectées. L'atlas actif garde l'empreinte de la référence
figée. Aucun test automatisé ajouté ou exécuté, aucun profilage mobile.

Le rendu texturé attend la revue de l'utilisateur. Il n'est pas intégré à l'atlas
actif ni aux scènes du projet ; l'entrée par escalier reste hors de cette revue.
