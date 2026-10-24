# Torche peinte sur la structure approuvée

## Intégration

L'utilisateur a ensuite demandé de continuer. Les deux sprites approuvés sont
intégrés au kit mobile et à MobileReference, avec leur lumière locale optionnelle.
La sélection et les fichiers approuvés ci-dessous restent figés. Résultat actuel,
commandes, captures et mesures : [intégration](integration/README.md).

## Base arrondie : apparence approuvée

L'utilisateur a répondu « Ok » à la comparaison de la base arrondie.
`selection.json` enregistre cette approbation et les empreintes des sources,
des sprites préparés, de la recette et des images de référence. Conserver
l'illustration et ses proportions pour la suite. Les fichiers de génération
restent les instantanés de la proposition ; la sélection porte le statut actuel.

L'utilisateur a signalé que le bas de la flamme v2 semblait incorrect. Sa pointe
et son étranglement donnaient l'impression d'une goutte suspendue dans le métal.
La nouvelle source `source/flame-v3.png`, redessinée avec ImageGen, possède une
base pleine et arrondie. Prompt exact et provenance :
`flame-base-review/generation.json`.

L'image entière est réduite uniformément : hauteur de 0,215 case, base à z = 0,20.
Les deux axes utilisent la même échelle avant la projection commune au kit.
Le rebord masque le bas arrondi et la partie basse reste dans la coupelle.
La géométrie et la matière de métal approuvées sont conservées.

`flame-base-review/before/` fige la version pointue ; `comparison.png` compare
avant/après depuis les pixels Godot agrandis ×2. Les deux orientations et le
rendu à taille réelle ont été inspectés : capture code 0, stderr vide.
L'apparence est approuvée. Cette étape d'approbation précédait l'intégration
décrite ci-dessus et n'avait ajouté aucun test automatisé ou commit/push.

## Historique : flamme v2, proportions conservées mais base pointue

L'utilisateur a repéré que la correction précédente allongeait visuellement
la flamme. C'était bien une compression de la largeur seule. Cette version
est remplacée par `source/flame-v2.png`, redessinée avec ImageGen : pied étroit,
corps plus ample au-dessus. Le prompt exact et la provenance sont conservés
dans `flame-shape-review/generation.json`.

Le compositeur utilise une seule échelle d'image : `worldPerPixelX` est égal
à `worldPerPixel`. Seule la projection de hauteur commune au kit reste appliquée.
Le centre est mesuré sur les 8 % inférieurs du dessin. La base descend à
z = 0,186, au fond de la coupelle, pour que son pied étroit soit masqué par le
métal. La hauteur source reste 0,27 case. La géométrie approuvée est conservée.

`flame-shape-review/before/` fige la proposition comprimée. Sa comparaison
`comparison.png` montre avant/après avec les pixels Godot agrandis ×2.
Les deux orientations ont été capturées et inspectées : code 0, stderr vide.
L'apparence reste à valider ; aucun test automatisé ou changement de production.

## Historique : première correction du débordement, remplacée

L'utilisateur a signalé que les flammes sortaient des côtés de la coupelle.
Le calibrage utilisait seulement la hauteur de l'image : au niveau du rebord,
le feu opaque mesurait 0,181 case de large pour une ouverture de 0,120 case.
Le masque de profondeur cachait les pixels derrière le métal, mais ne pouvait
pas retenir les pixels de feu qui débordaient à côté du volume de la coupelle.

Le compositeur déduisait le rayon intérieur du rebord depuis les faces
approuvées. Il ajustait la largeur du plan de flamme à 90 % de ce diamètre, soit
0,108 case au maximum, en conservant sa hauteur et sa position de base. La
réduction horizontale est faite hors ligne ; aucune retouche de l'image source
ni modification du support. Les nouveaux réglages figurent dans `prepared.json`
(`worldPerPixelX` et `apertureFit`). L'alpha natif reste échantillonné sans seuillage.

`flame-fit-review/before/` conserve les anciens sprites, images et réglages.
`flame-fit-review/comparison.png` compare les pixels du jeu avant/après. Les deux
orientations corrigées ont été inspectées dans Godot, avec et sans lumière
locale. Capture : code 0, stderr vide. Pas de tests automatisés.

---

L'utilisateur a répondu « Oui » à la planche des deux wireframes. La sélection
`../wireframe-v1/selection.json` enregistre l'approbation de la plaque, du bras,
de la coupelle creuse et de leurs deux orientations. La peinture reste une
proposition visuelle, présentée ici à l'échelle de jeu dans Godot.

## Images à consulter

- `game-view.png` : recadrage du rendu Godot à 0,75, sans redimensionnement.
- `attachment-details.png` : deux raccords agrandis ×2 depuis les pixels du jeu.
- `structure-comparison.png` : métal, guide magenta superposé et torche complète,
  avec les pixels des sprites préparés agrandis ×3.
- `captures/` : salle entière avec/sans lumière locale.
- `TorchReview.tscn` : scène de revue indépendante, Espace bascule la lumière.
  `docs/` reste exclu de l'import ; ouvrir/lancer cette scène par son chemin.

## Préparation

`source/metal.png` et `source/flame.png` sont les deux premiers originaux image_gen.
`generation.json` conserve leurs prompts et leur provenance. Le métal reste actif ;
la flamme active est maintenant `source/flame-v3.png`, avec son prompt distinct
dans `flame-base-review/generation.json`. Toutes ces sources gardent leur alpha
natif. La torche frontale précédente sert uniquement de référence de style.

Le compositeur hors ligne `prepare_mobile_torch_paint.cjs` lit directement les
faces du `geometry.json` validé et vérifie son empreinte contre la sélection.
Il ne modifie aucun sommet, silhouette, position de fixation ou dimension.
Les deux orientations ont les mêmes coordonnées de matière locales. Un masque
de profondeur retire les surfaces cachées. La texture de métal, les nuances
selon la face et les reflets chauds sont appliqués dans les limites de ce masque.
Les contours sombres restent à l'intérieur de la silhouette structurelle.

La flamme est projetée sur un plan vertical XZ passant par le centre de la
coupelle, avec la même direction de hauteur que l'architecture. Elle conserve
les valeurs d'alpha de sa source, sauf l'occlusion physique par le mur ou le
rebord. Son seuil alpha 128 ne sert qu'à mesurer la taille du sujet. Sa base
se trouve à z = 0,20 et sa hauteur solide proposée est 0,215 case. Le rebord
devant masque donc le bas de la flamme. Cette forme libre n'était pas incluse
dans l'approbation du wireframe.

Tout est composé hors ligne en un PNG par orientation. Godot place ces PNG avec
leurs ancres et l'ordre physique commun aux murs et piliers ; aucune génération
de texture, déformation ou rotation de sprite au lancement. Le halo sur les
surfaces voisines reste un PointLight2D local, séparé de l'illustration.

| Orientation | Taille avec marges alpha | PNG |
| --- | --- | --- |
| Mur horizontal | 58 × 84 px | 6 975 octets |
| Mur vertical | 56 × 108 px | 8 943 octets |

Les marges incluent la source de flamme entière ; ces dimensions ne sont pas
celles de la silhouette opaque. Densité : 256 pixels par case, zoom fixe 0,75.

## Reproduction

Avec Node/Sharp et `$godot` défini vers l'exécutable Godot :

```powershell
node tools/prepare_mobile_torch_paint.cjs
& $godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_torch_paint_review.gd
node tools/prepare_mobile_torch_paint.cjs --boards
```

Ne pas régénérer les fichiers d'approbation du wireframe pour une retouche de
peinture. Le compositeur utilise leurs faces figées. Le kit de production, son
atlas, la scène principale et les scènes existantes restent dans leur état
antérieur.

Deux captures Godot ont terminé avec le code 0 et un stderr vide. Le rendu à
taille de jeu, les raccords et la superposition du guide ont été inspectés.
Pas de tests automatisés ajoutés/exécutés ni de profilage sur téléphone. Les
lumières sont statiques, sans ombres portées ; leur occlusion entre pièces
reste à traiter avant une intégration générale. Le cristal n'est pas révisé
dans cette proposition. Aucun commit/push demandé.
