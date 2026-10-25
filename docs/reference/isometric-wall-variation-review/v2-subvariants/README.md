# Déclinaisons des familles A, C et F — 25 octobre 2026

L'utilisateur demande plusieurs variantes au sein des trois familles retenues.
Cette étude ajoute deux propositions par famille : neuf concepts au total avec
les trois sources précédemment sélectionnées. Les nouvelles apparences restent
à examiner ; aucune sélection ni intégration n'est déduite de leur génération.

| Famille | Version 1 conservée | Nouvelle version 2 | Nouvelle version 3 |
| --- | --- | --- | --- |
| A — Maçonnerie décalée | Pierres de longueurs irrégulières | Longue pierre en haut, quatre pierres en bas | Trois pierres en haut, longue pierre en bas |
| C — Blocs en relief | Bloc central supérieur saillant | Deux reliefs décalés sur les deux rangées | Relief inférieur large et dominant, avec un relief supérieur plus discret |
| F — Pierre corrompue | Racines ramifiées et cristal central | Racines étalées le long du joint, cristal décentré | Bouquet de cristaux et racines courtes |

`comparison.png` présente les neuf concepts agrandis avec leurs miniatures.
`mobile-scale.png` montre uniquement les miniatures de 114 px de large.
Ce sont des vues de concept, pas des captures Godot ni une démonstration de
raccords. Les proportions précises, les extrémités communes et les deux
orientations visibles devront être définies et vérifiées sur les wireframes.
Conserver les deux rangées principales, la projection commune et les piliers
comme jonctions. Les racines et cristaux sont montrés sur leurs murs pour
apprécier leur intégration ; leurs calques indépendants ne sont pas préparés ici.

Les six nouvelles sources viennent du générateur **ImageGen intégré**, avec une
génération séparée par proposition. `generation.json` conserve tous les prompts,
les références et les chemins originaux. Les neuf PNG de `source/` conservent
leurs pixels et leur transparence natifs ; les trois versions 1 sont des copies
exactes des sources retenues. Aucun miroir ou changement de teinte ne sert de
nouvelle variante. C3 conserve un relief supérieur malgré la demande du prompt
de le rendre plat : l'image est présentée telle quelle, avec sa description réelle.

`prepare-board.cjs` reproduit les planches avec Sharp : cadrage rectangulaire
autour des pixels d'alpha positif, redimensionnement uniforme et mise en page.
Aucun détourage, changement d'alpha ou dessin sur la source. `validation.json`
enregistre les dimensions, l'alpha et les empreintes. Les deux planches ont été
inspectées, y compris les miniatures. Les onze références figées de la sélection
A/C/F et les dix fichiers actifs de la dernière validation sont inchangés.

Pas de changement du kit, des scènes ou du rendu ; pas de test de jeu,
d'export de production, de commit ou de push dans cette étude.
