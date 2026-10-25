# Ombre du socle : étude de contact v2

L'utilisateur rejette le rendu de l'ombre v1. La précédente revue technique ne
vaut donc pas approbation de l'apparence. Sa préférence entre défaut de contact,
forme et orientation reste à préciser.

Le contact v1 utilise un flou de .7 pixel source, soit .525 au zoom .75 : presque
tout est caché sous le socle. Le comparatif hors Godot montre les mêmes PNG de sol
et de cœur au même emplacement. Aucun éclairage de scène n'est ajouté.

- Gauche : sprite d'ombre actuellement intégré, conservé comme référence.
- Centre : contact à .70 d'opacité, étendu de 1.5 pixel source et adouci de 2.8,
  avec ombre portée actuelle adoucie de 2.4 pixels.
- Droite : même contact, projection plus étendue (direction [-1.1,-.7,1]),
  opacité .40, bord adouci de 3.2 pixels.

Il s'agit de propositions visuelles non intégrées. L'atlas, le catalogue, le
renderer, la géométrie, le sol et le cœur restent inchangés dans cette étude.
Le helper expérimental est séparé du générateur de production pour préserver
la reproduction des exports et la provenance actuelle.

Reproduction : `node tools/prepare_isometric_shadow_contact_review.cjs`.
Paramètres et cadres dans `recipe.json`, comparaison dans `comparison.png`.
Pas de tests automatisés, d'import, d'export de kit, de commit ou de push.
