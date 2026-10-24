# Porte avec vantail lisse — proposition texturée

Le wireframe v8 est validé par l'utilisateur (« Ok »). Son vantail conserve
le volume de v7, avec un contour seul : aucun joint de planche ni accessoire
ne contraint le dessin intérieur. La texture `door-oak.png` existante est
appliquée d'un seul tenant, dans la perspective de chaque orientation.

Cet aperçu montre la base sans ferrures. Leur dessin pourra être ajouté comme
décor sur les deux faces. Les veines visibles appartiennent à la texture ;
elles ne constituent pas des subdivisions imposées par le guide.

Les deux arches, le mur lisse en retrait et les ancrages restent ceux de v7.
La grande arche provient exactement de l'atlas figé dans `../source/`.
Sept parties préparées par direction permettent de conserver leur occlusion
avec les murs du couloir. Aucune image n'est fabriquée à l'exécution.

## Images

- `paint-and-guide.png` : rendu à 192 pixels par case et superposition magenta.
- `before-after.png` : porte du kit actif et nouvelle proposition.
- `four-directions.png` : nord, est, sud, ouest.
- `captures/` : douze images Godot originales.
- `sprites/`, `guides/`, `overlays/` : 28 parties et leurs guides.

## Reproduction

```powershell
node tools/prepare_mobile_nested_door_review.cjs
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_nested_door_review.gd
node tools/prepare_mobile_nested_door_review.cjs --boards
```

Les outils acceptent `--legacy-v7` pour reproduire l'ancien rendu (après `--`
pour Godot). Les sorties v7 existantes sont conservées.

## État

`proposal.json` contient les sources et rapports par partie ; `export-report.json`
en résume les résultats : zéro différence d'alpha de construction, zéro trou
intérieur et zéro pixel extérieur excédentaire. Les douze captures se terminent
avec code 0 et stderr vide. Les vues et guides ont été inspectés à l'échelle de
jeu. L'atlas actif conserve son empreinte d'origine.

La proposition attend la revue artistique ; aucune scène ni atlas actif n'est
remplacé. Aucun test automatisé ajouté ou exécuté, aucun profilage mobile.
