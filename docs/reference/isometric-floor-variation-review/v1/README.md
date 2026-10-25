# Variations de dalles — propositions du 25 octobre 2026

**Choix enregistré : B — formats variés.** L'utilisateur a retenu B seule ;
le mélange A+B suggéré n'est pas sélectionné. [selection.json](selection.json)
fige l'image de référence et les planches présentées. A et C restent archivées.

L'utilisateur souhaite varier les dalles comme les murs. Trois concepts ont été
générés avec ImageGen intégré à partir du sol actuel et d'une capture du jeu.
Les surfaces restent calmes, sans anciens décors de dégâts. Les différences
portent sur la forme des pierres et leur assemblage.

- **A — contours irréguliers** : côtés légèrement asymétriques, rythme proche
  du sol existant.
- **B — formats variés** : pierres longues, carrées et courtes, joints décalés.
- **C — coins adoucis** : silhouettes plus arrondies, petits espaces de mortier
  aux jonctions. L'arrondi est plus marqué que sur A.

Voir [la comparaison avec le sol actuel](comparison.png) et
[l'aperçu réduit](mobile-scale.png). La largeur de 192 px approche celle d'une
case au zoom .75 ; ce sont des concepts redimensionnés uniformément, pas des
captures de variantes intégrées dans Godot. La palette vise celle du sol en
place ; sa continuité devra aussi être contrôlée lors de l'adaptation finale.

Les images complètes, avec leur alpha natif inchangé, sont dans `source/`.
[generation.json](generation.json) contient les prompts exacts, références et
chemins des originaux. `prepare_isometric_floor_variants_review.cjs` prépare
les planches par recadrage des seules marges transparentes et échelle uniforme.

Le concept B est sélectionné et quatre assemblages sont désormais intégrés.
Voir [les rendus et preuves de l'intégration](integration/README.md). Ils adaptent
les proportions et assemblages de B dans le wireframe commun, avec la matière
calme existante ; le PNG de concept reste inchangé. Les planches et mesures de
cette page sont les références historiques de la proposition.

La vérification consignée dans `validation.json` confirme que sept fichiers actifs
(atlas, catalogues, exporteur et scripts) et les treize références sélectionnées
des murs sont inchangés. Planches inspectées après préparation. Aucune scène ni
géométrie de production modifiée ; pas de suite de tests, import/export Godot,
commit ou push dans cette proposition.
