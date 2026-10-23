# Essai unique : matière dans la géométrie du coin supérieur gauche

## Autorisation et portée

**Mise à jour ultérieure :** l'utilisateur a approuvé la méthode et demandé
de la conserver avec des matières plus riches et plusieurs variantes. Voir
[le workflow actuel](../MATERIAL_WORKFLOW.md). Ce dossier conserve le premier
essai ; sa limitation initiale ci-dessous est historique.

Le 23 octobre 2026, l'utilisateur a autorisé les masques « pour cette fois
uniquement afin de faire un test ». Ce dossier contient **cet unique essai**.
Il n'autorise ni la généralisation de la méthode, ni de nouvelles variantes,
ni l'intégration dans Godot. Le résultat attend la revue artistique.

## Résultat à examiner

- [Comparaison : sprite et wireframe magenta](comparison.png).
- [Calque fin pour examiner les bords du trait](nw-thin-overlay.png).
- [Superposition avec l'épaisseur originale](nw-overlay.png).
- [PNG transparent final](../../../assets/dungeon/gloom-kit/proposals/nw-masked-experiment.png).

Le PNG mesure **1216 × 1408**, exactement quatre fois le canevas 304 × 352 du
guide, avec ancrage (96,352) et pas de case 1024. Aucun ajustement de cadrage ou
de silhouette après comparaison n'est effectué. La géométrie conserve deux
assises de mur égales ; le dessus appartient à l'assise haute. La bande étroite
au pied du mur nord appartient au dallage et reçoit sa matière.

## Fabrication

1. **image_gen intégré** a généré une matière pierre sans joints à partir de la
   seule maquette canonique `assets/dungeon/gloom-kit/reference.png`.
   [Prompt exact](material-prompt.txt). `stone-material.png` est la copie
   inchangée de la sortie générée, qui reste conservée à son emplacement original.
2. `tools/prototype_nw_masked_material.cjs` reprend les **51 segments** du guide
   `docs/reference/wireframe-overlays/cells/w09_p00_e00.svg`. Ses intersections
   délimitent 40 faces visibles : 19 de sol, 5 de dessus, 12 de façade intérieure
   et 4 d'extrémité. Aucun nouveau joint architectural n'est inventé.
3. Chaque face reçoit la matière via un masque vectoriel. Le sol atténue la
   texture ; les façades utilisent une valeur plus sombre pour rendre le volume.
   Les petits reflets restent à l'intérieur des faces. Une seule fissure violette
   décorative est ajoutée à l'intérieur d'une pierre de façade.
4. Les traits de contour et joints sont recopiés du guide, sans changer leurs
   coordonnées ou leur largeur. Le masque alpha vient du dessin de construction
   approuvé. **Ce PNG est donc composé hors ligne, pas une sortie native-alpha
   complète d'imagegen.** C'est précisément l'exception autorisée pour cet essai.
5. Le même guide est superposé sans déplacement ni déformation. Tous les fichiers
   du jeu et ses catalogues continuent d'utiliser leurs textures existantes.

`nw-painted-test.svg` garde la composition avec matière incorporée.
`face-masks.svg` montre les régions en fausses couleurs ; `silhouette-mask.png`
conserve le masque de couverture ; `locked-joints.svg` conserve les traits seuls.
Les sources peintes rejetées v1-v4 ne sont utilisées à aucune étape.

## Contrôle réalisé et limites

Le script relit le PNG exporté et produit [validation.json](validation.json) :

- déplacement des extrémités des 51 segments : **0** (coordonnées recopiées) ;
- pixels alpha différents du dessin de construction rasterisé à la même échelle : **0** ;
- différence maximale d'alpha : **0** ;
- échantillons de lignes devenus entièrement transparents : **0**.

Les images finales ont été inspectées avec le calque normal et le calque fin.
Le rendu est sombre, le sol est calme et les joints suivent le guide. Les pierres
et les reflets sont toutefois plus réguliers que ceux de la maquette. Le contrôle
géométrique ne constitue pas une validation artistique et ne prouve pas les
raccords avec d'autres sprites : aucune autre variante n'a été produite.

## Reproduire cet essai uniquement

Node.js et `sharp` sont nécessaires. Depuis la racine du dépôt :

```powershell
node tools/prototype_nw_masked_material.cjs
```

Le script est volontairement limité au coin NW. Il ne construit pas de nouveau
catalogue et ne modifie aucune scène. Toute extension de cette méthode nécessite
une nouvelle instruction explicite de l'utilisateur.
