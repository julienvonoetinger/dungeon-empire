# Mur lisse légèrement en retrait — wireframe à valider

**Structure validée par l'utilisateur : « Ok », le 24 octobre 2026.**
`selection.json` fige cette validation et les empreintes du dessin/de la géométrie.
Le statut dans le JSON géométrique décrit sa création avant validation ; la
sélection ci-dessus enregistre la décision ultérieure. Rendu : [painted-v7](../painted-v7/).

L'utilisateur demande un mur légèrement plus fin que l'arche. Le dessin propose
de réduire sa profondeur à 80 % de celle des arches, en le gardant centré :

- Arches : profondeur 1/6 case, inchangée.
- Mur lisse : profondeur .133333 case, entre y=.433333 et y=.566667.
- Retrait : .016667 case sur chaque face, soit environ 3.2 pixels à l'échelle
  de jeu actuelle (192 pixels par case).
- Rayons des deux arches, largeur de la bande de mur, taille du bois inchangés.

Le mur reste plein, lisse et sans joints. La vue de face conserve les mêmes
proportions. La perspective montre les contacts avec la surface en retrait.
Le gris est un aplat explicatif et non une proposition de texture. Les volumes
des arches et des murs du couloir occultent correctement cette surface reculée.

Le taux de 80 % est une proposition pour visualiser « légèrement plus fin ».
La validation de ce wireframe précède les textures et toute intégration.

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs --legacy-detailed-leaf
```

`wireframe.png` / `wireframe.svg` : face et perspective ; `perspective.png` :
perspective seule ; `geometry.json` : paramètres, volumes, lignes et sources.
Aucun changement au kit actif, aux matériaux ou aux scènes Godot.
