# Premier sprite peint : coin supérieur gauche

Revue du 23 octobre 2026. Un seul exemple a été demandé, avec contrôle par
superposition du wireframe transparent. **Aucune version n'est encore validée
pour une intégration dans Godot ou une déclinaison du kit.**

## Correction de lecture des deux assises

L'utilisateur a rejeté la v1 parce que son dessus semblait constitué d'une
rangée de briques ajoutée. La face horizontale du dessus doit appartenir aux
mêmes pierres que la face avant de l'assise haute. Les joints de ces pierres
se prolongent autour de l'arête ; il ne faut ni chaperon séparé, ni lèvre sombre,
ni bande de façade supplémentaire sous le dessus.

La première interprétation de l'assistant, qui visait la petite bande de dallage
au pied du mur, était erronée. La correction concerne bien le **dessus**.
Le modèle reste composé de deux assises de hauteur .94/6 chacune, sans changer
la hauteur totale 1.88/6, l'épaisseur 1/6 ou la projection (-.18,-.9).

## Résultat de la revue

| Version | Observation | Statut |
| --- | --- | --- |
| v1 | Silhouette proche, mais faux chaperon ; joints internes imparfaits | Rejet utilisateur |
| v2 | Dessus et façade haute reliés ; joints du dessus du mur gauche déplacés | Non validée |
| v3 | Lecture de deux assises conservée ; premier joint gauche encore trop bas | Non validée |
| v4 | Repart du dessin exact ; joints gauche rapprochés, mais bande de sol changée en pied de mur et joints déplacés | Échec du contrôle, non validée |

Dans la v3, le recouvrement des silhouettes est de **99,32 %** à un seuil alpha
de 128. Cela ne prouve pas la fidélité des joints. Le premier joint du dessus
du mur gauche devrait se situer vers y=322 px dans le canevas 1166 × 1349 ;
il apparaît encore vers y=350 px. La superposition montre cet écart. Le sol
reste également assez texturé pour une surface destinée à recevoir les héros.

Le guide n'a pas été déplacé ou déformé pour correspondre au résultat. Une seule
échelle uniforme de 3.83238636 transforme son canevas 304 × 352 vers la hauteur
1349 de l'image produite ; il reste 0.9545 px à droite. L'origine reste (0,0).
La v1 avait demandé 1216 × 1408, mais le générateur a livré 1166 × 1349 ; les
éditions suivantes ont explicitement conservé cette résolution.

Les PNG générés possèdent leur alpha natif et sont copiés sans modification.
Les images `nw-*-overlay.png` et `nw-*-comparison.png` sont uniquement des
documents de contrôle : ne pas les utiliser comme sprites de production.

## Exigence de raccords et limite constatée

L'utilisateur a précisé que les écarts de contours **et de joints** rendront les
raccords incorrects. Une forte ressemblance ou un bon score de silhouette ne
suffisent pas. Le wireframe reste fixe ; aucune déformation du guide n'est
autorisée pour faire paraître un candidat conforme.

La v4 repart du dessin de construction, sans image peinte précédente en entrée.
Le dessin est rasterisé au canevas 1166 × 1349 par l'échelle uniforme du contrôle,
sans changement géométrique. Cela réduit le décalage des joints du dessus gauche,
mais le générateur réinterprète la bande de sol sous le mur nord en pied de mur
sombre et déplace ses deux joints. Les façades sont éclairées comme des dessus
de dalles. Le dallage reste trop texturé. Le contrôle complet montre donc encore
des défauts de géométrie et de lecture du volume.

Au seuil alpha 128, les limites sont [33,58,1075,1319] pour la v4 contre
[31,55,1078,1323] pour le guide. Le score 99,16 % ne valide ni les détails du
contour ni les joints internes. Aucune intégration Godot n'a été réalisée.

### Alternative proposée, non exécutée

Pour verrouiller effectivement la géométrie, une méthode différente serait de
composer **hors Godot** la matière générée dans les faces exactes du wireframe,
avec contours, joints, ancrage et silhouette définis par cette géométrie. La
matière ne déciderait plus de la position des arêtes. Les sources générées
resteraient intactes ; le résultat serait un nouveau PNG préparé avant import.

Cette méthode utiliserait des masques vectoriels et un compositing déterministe.
Elle contredit les règles actuelles d'AGENTS.md sur les silhouettes natives et
l'interdiction des réparations programmatiques. Elle nécessite donc un accord
explicite de l'utilisateur avant toute réalisation. Aucun masque ou assemblage
de matière de production n'a été créé. Les calques de revue restent autorisés.

## Sources et reproduction du contrôle

`generation.json` conserve les chemins d'origine, références et statuts.
`prompt-v1.txt` à `prompt-v4.txt` contiennent les requêtes exactes
envoyées à l'outil intégré **image_gen**. Aucun appel CLI/API externe n'a été utilisé.

La géométrie provient du calque `w09_p00_e00` et du constructeur commun en mode
isolé. La seule référence de matière est `assets/dungeon/gloom-kit/reference.png`.
Les anciens sprites rejetés ne servent pas de référence de palette.

Avec Node.js et le module `sharp` accessibles :

```powershell
node tools/prepare_nw_corner_review.cjs
node tools/review_nw_corner_image.cjs assets/dungeon/gloom-kit/proposals/nw-cell-wireframe-v3.png v3 1166x1349
```

Le premier script prépare seulement les références vectorielles rasterisées.
Le second superpose le guide à une copie de revue et mesure la silhouette, sans
modifier le PNG généré. Il ne corrige jamais des pixels, des contours ou des
couleurs. Une mesure technique ne constitue pas l'approbation artistique.
