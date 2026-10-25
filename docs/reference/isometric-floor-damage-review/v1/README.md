# Dalles B : fissures et corruption — propositions

**État actuel :** les quatre propositions ont été acceptées puis
[intégrées au kit](integration/README.md). Le texte et les enregistrements de
génération ci-dessous décrivent la proposition initiale ; `selection.json`
consigne l’acceptation et `integration/` les rendus préparés et vérifications.

Le 25 octobre 2026, l’utilisateur demande plusieurs variantes comportant de la
corruption ou des fissures, après l’intégration des quatre assemblages B.
Ces nouveaux concepts ne réintroduisent pas les anciens petits dégâts retirés.

## Quatre apparences à comparer

- A : deux fissures courtes sur des pierres différentes, avec des directions variées.
- B : une fracture ramifiée, plus continue, limitée à quelques pierres voisines.
- C : une veine violette dans la pierre, avec des segments lumineux localisés.
- D : des racines corrompues dans les joints et un petit éclat violet.

[Planche comparative](comparison.png) et [aperçu réduit](mobile-scale.png).
Le sol B sélectionné sert de référence d’assemblage ; le sol actuel fournit la
palette, et le mur F2 le langage des racines. Les images gardent la majorité des
surfaces lisses. À 192 px de large, les fissures sont discrètes tandis que les
accents violets restent plus perceptibles. Les deux planches ont été inspectées.
Une répartition clairsemée parmi les sols intacts est proposée, pas encore validée.

## Sources et portée

Quatre appels au générateur ImageGen intégré, un par variante. Sources natives
transparentes dans `source/`, copiées sans modifier leurs pixels. Les prompts
exacts, références et chemins d’origine figurent dans [generation.json](generation.json).

La préparation des planches utilise uniquement un recadrage des marges entièrement
transparentes et une réduction uniforme. 192 px représente approximativement la
largeur d’une case à zoom .75 ; ce n’est pas une capture Godot. Les légères différences
de cadrage natif ne constituent pas une mesure d’échelle ou un raccord validé.

Ces apparences restent des propositions. Il faudra adapter les détails retenus aux
assemblages B réels, respecter leurs joints/bords communs, conserver la palette,
préparer les masques et vérifier le rendu en scène. Ne pas paver le jeu avec les
concepts directement, ni régénérer les sources déjà sélectionnées pour le sol.

Reproduction : `node tools/prepare_isometric_floor_damage_review.cjs` (avec Sharp).
[validation.json](validation.json) confirme la copie exacte des quatre originaux,
leur transparence native, les neuf fichiers actifs de référence inchangés et les
dix-neuf fichiers de sélection sol/murs inchangés. L’atlas actif conserve ses
104 régions, 1 463 015 octets PNG et 8 Mio RGBA.

Aucune intégration en production, aucun test automatisé, import/export Godot,
profilage mobile, commit ou push pour cette proposition.
