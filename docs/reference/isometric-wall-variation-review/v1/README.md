# Variantes de murs — propositions du 25 octobre 2026

L'utilisateur souhaite davantage de formes et de maçonneries pour casser la
répétition, en retrouvant le caractère de la maquette. Six concepts ImageGen sont
présentés. Le 25 octobre 2026, l'utilisateur a retenu **A, C et F uniquement** :
maçonnerie décalée, blocs en relief et pierre corrompue. `selection.json` enregistre
ce choix. B, D et E sont écartés de la suite et conservés dans l'historique.
Aucune variante n'est encore intégrée.

| Piste | Variation | Usage proposé |
| --- | --- | --- |
| A — Maçonnerie décalée | Longueurs de pierres inégales, joints déplacés | Base fréquente |
| B — Pierres usées | Coins arrondis, érosion large et silhouette moins régulière | Base fréquente |
| C — Blocs en relief | Une pierre légèrement saillante et chanfreinée | Variation ponctuelle |
| D — Mur réparé | Bloc remplacé et petites pierres de remplissage plus claires | Accent de vieillissement |
| E — Niche aveugle | Petit renfoncement fermé dans la paroi | Accent architectural rare, à différencier d'une porte |
| F — Pierre corrompue | Racines et cristal dans les joints | Accent rare ; conserver ces détails séparés du mur |

La table conserve les usages initialement proposés, sans fréquence approuvée.
L'ancienne recommandation de mélanger les six pistes est remplacée par la
sélection A, C et F. La planche et les sources restent les références originales.

`comparison.png` montre les six concepts agrandis et en petit format de 114 px
de large. Ce sont des vignettes de concept, pas des captures Godot ni des sprites
de production certifiés raccordables. La palette, les deux rangées et la direction
isométrique guident les images ; les positions de joints, silhouettes et volumes
devront être construits puis validés dans le repère commun des wireframes avant
intégration. Les variantes doivent partager leurs extrémités et garder les piliers
comme jonctions. Il faudra préparer les deux orientations visibles.

Les six PNG natifs transparents sont dans `source/`, copiés sans modification.
La planche ne fait que cadrer/redimensionner uniformément leurs aperçus ; elle ne
retouche pas les dessins. `generation.json` conserve les prompts exacts et les
chemins des sorties du **générateur ImageGen intégré**. `source-hashes.json` fige
les copies. `references/current-wall.png` et `references/mockup.png` sont les
références de forme/caméra et de direction artistique fournies au générateur.

Les six sorties et la planche ont été inspectées, y compris les petits formats.
Les dix fichiers actifs contrôlés contre la dernière validation d'intégration
sont inchangés. Aucun nouveau wireframe, atlas, scène, test, commit ou push.
