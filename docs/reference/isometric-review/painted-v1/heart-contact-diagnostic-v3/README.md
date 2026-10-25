# Diagnostic du contact du cœur — 24 octobre 2026

L'utilisateur rejette les propositions d'ombre v2 et indique qu'il lui est difficile
de décrire le résultat attendu. Le problème visuel reste ouvert. Il faut examiner
le rapport entre matériau, volume et sol avant une nouvelle modification de l'ombre.

La planche conserve exactement le même sol, ancrage et sprite d'ombre v1 :

1. Cœur actuel.
2. Même volume avec aplats neutres, même vortex et mêmes occultations.
3. Même volume neutre sans vortex.

Les aplats utilisent la géométrie isométrique figée. Le vortex de la colonne 2
reprend la source approuvée avec les mêmes coordonnées, échelle, masque spatial
et condition de profondeur que le compositeur actif. La source reste inchangée.
Les vues sont composées hors Godot à .75, sans éclairage de scène, puis agrandies.

Lecture proposée, non prouvée ni approuvée : le volume neutre semble davantage
posé ; les valeurs très sombres et le contraste décoratif du bas du socle peint
pourraient contribuer à la sensation de flottement. Cela oriente l'étude vers la
matière de l'assise, pas vers une nouvelle variation d'ombre seule. Cette planche
n'est pas un nouveau design simplifié proposé pour remplacer le cœur sculpté.

Reproduction : `node tools/prepare_isometric_heart_diagnostic.cjs`.
`recipe.json` conserve les empreintes, couleurs, échelle et limites du diagnostic.
Pas de changement de production, de nouvelles sources ImageGen, de tests
automatisés, d'import/export Godot, de commit ou de push.
