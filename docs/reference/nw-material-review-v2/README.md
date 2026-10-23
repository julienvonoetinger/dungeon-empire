# Coin NW : matières plus variées

L'utilisateur a approuvé la méthode des masques et demandé de conserver des
textures communes plus riches et variées. Cette proposition applique quatre
variantes de mur et quatre variantes de sol au **même wireframe**.

- [Avant et après](before-after.png).
- [Sprite et calque magenta](comparison.png).
- [Calque fin](nw-thin-overlay.png).
- [PNG transparent](../../../assets/dungeon/gloom-kit/proposals/nw-shared-materials-v2.png).
- [Bibliothèque de matières](../../../assets/dungeon/shared-materials/material-board.png).
- [Méthode, sources et reproduction](../MATERIAL_WORKFLOW.md).

Les matières ont été générées par **image_gen intégré**, avec la maquette seule
comme référence. Les prompts exacts et fichiers d'origine sont référencés dans
`assets/dungeon/shared-materials/generation.json`. Le prototype applique ensuite
les masques, le profil de lumière commun et des reflets intérieurs moins réguliers.

La comparaison conserve le cadrage, les 51 traits, les deux assises et l'alpha de
l'essai précédent. Les sources et mesures détaillées sont dans `validation.json`.
L'inspection visuelle montre davantage de facettes, fissures et petites cavités
sur les murs ; le sol conserve une texture moins contrastée. Le rendu reste une
proposition artistique à approuver. Aucune scène ni autre variante n'est modifiée.
