# Corruption sans motif doublé — 23 octobre 2026

## Choix utilisateur : D2

L'utilisateur a choisi **D2**. La variante sélectionnée est
`horizontal/D2.png` / `vertical/D2.png`, matière `corruption-v2-1`.
La découpe et les empreintes retenues sont consignées dans `selection.json`.
Conserver la peinture continue entre dessus et façade. D1 reste une comparaison
non retenue ; l'ancien D reste rejeté. Le coin de la planche historique montre
D1, pas D2. Cette décision valide l'apparence D2 ; sa propagation complète
dans les assets Godot reste à réaliser.

## Historique de la proposition

L'utilisateur a rejeté la variante D de `wall-variation-review/` parce que
le motif se répétait à l'identique. Les autres variantes n'ont pas encore
reçu de validation globale. D2 est maintenant retenue, comme indiqué ci-dessus.

## Cause et correction

Le compositeur utilisait le même fichier de matière sur le dessus et sur la
façade supérieure, mais recalculait l'origine et l'échelle pour chaque face.
La fissure et son centre violet étaient ainsi dessinés deux fois sur la même
pierre. Partager seulement un identifiant de matière ne suffit pas.

Le nouvel export déroule le dessus et la façade supérieure dans un seul
rectangle de texture. Les coordonnées de matière sont identiques sur leur
arête commune. La façade montre donc la suite de la peinture, avec son éclairage
plus sombre, et non une seconde copie du motif.

- D1 reprend la fissure de la première proposition avec ce placement corrigé.
- D2 utilise une autre veine du même atlas généré, avec une découpe différente.
- Le mur de douze cases place D1 et D2 une fois chacun parmi A, B et C.
- Les pierres aux frontières de cases restent communes. Les joints, volumes,
  arrondis B, ancrages et sols ne changent pas.

## Images

- `comparison.png` : ancienne D, D1, D2 et exemple d'assemblage.
- `corner-comparison.png` : ancien coin, nouveau coin D1 et overlay magenta.
- `vertical-comparison.png` : les mêmes propositions sur un mur vertical.
- `horizontal/` et `vertical/` : quatre PNG préparés, overlays et rapports.

Les fichiers `source/*-before.png` et `source/previous-recipe.json` sont figés.
Ne pas les remplacer après une promotion. La première proposition D reste
conservée uniquement comme comparaison rejetée.

## Reproduction

```powershell
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' tools/prepare_wall_corruption_review.cjs
```

Le script utilise l'atlas généré existant `atlas-calm.png`, sans nouvel appel
de génération ni retouche libre. Les découpes exactes sont dans `recipe.json`.
La méthode de masquage hors Godot déjà autorisée reste utilisée.

Le compositeur commun accepte maintenant une propriété optionnelle
`face.textureTransform` appliquée à la peinture et à sa finition. Seule cette
revue fournit cette propriété. Les exports de production gardent leur
placement antérieur ; aucun catalogue actif ou PNG Godot n'a été remplacé.
Les matrices, origines et dimensions du dépliage sont conservées dans les
rapports `*-report.json`, sous `mappedFaces`.

## Revue et limites

Export terminé sans erreur. Les cinq rapports (quatre murs et coin NW)
conservent les joints de construction, avec zéro différence d'alpha par
rapport au modèle, zéro trou intérieur et zéro débordement intérieur.
Les comparaisons horizontale, verticale et du coin avec overlay ont été
examinées visuellement. Aucun test automatisé n'a été exécuté.

Cette correction couvre les faces sélectionnées des deux variantes droites
et le coin NW montré. Elle ne valide pas tous les voisinages, portes ou
escaliers. Les profils d'éclairage restent propres à chaque face ; une
variation de luminosité au pli est attendue. L'apparence D2 est validée ;
son intégration Godot n'a pas encore été effectuée.
