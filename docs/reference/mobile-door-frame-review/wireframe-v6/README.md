# Deux arches séparées par un mur lisse — wireframe à valider

Version avant l'ajustement d'épaisseur : voir [v7](../wireframe-v7/) pour le mur
légèrement en retrait demandé ensuite par l'utilisateur.

Dernière précision : l'espace entre les arches doit être un mur lisse et plein.
La v5 l'avait interprété à tort comme un vide. Les deux arches restent distinctes.

- Grande arche blanche : géométrie originale conservée, rayons 5/12 et 7/12.
- Petite arche cyan : rayons .27 et .35, avec ses propres joints de pierres.
- Mur intermédiaire gris : plein, sans joints de briques, continu sur les côtés
  et au-dessus. Aucune coupure horizontale ne traverse cette surface au départ
  des arcs. Largeur de la bande : 5/12 − .35 = .066667 case.
- Bois ocre : rayon/demi-largeur .26, inchangé depuis la v3.

Le gris est un aplat explicatif de la surface du mur, pas une texture proposée.
Le volume plein masque les lignes cachées ; les murs du couloir au premier plan
masquent également l'aplat lorsqu'ils le recouvrent dans la projection du kit.

`wireframe.png` / `wireframe.svg` montrent la vue de face et celle du jeu.
`perspective.png` isole cette dernière. `geometry.json` conserve la géométrie.

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs --legacy-flush-wall
```

La proposition reste au stade du wireframe pour validation. Aucun matériau,
sprite actif, atlas ou scène Godot n'est modifié.
