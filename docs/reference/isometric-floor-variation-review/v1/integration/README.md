# Dalles B intégrées — 25 octobre 2026

Quatre assemblages adaptent le concept B sélectionné : équilibré, alternance de
pierres longues et courtes, grande dalle longitudinale, assemblage composite.
Ils reprennent la matière calme et les coins arrondis du sol existant. Il s'agit
d'une adaptation des formes dans le wireframe commun, pas d'une copie du PNG
de concept. L'original B, sa sélection et les anciens aperçus sont conservés.

- [Comparaison avant/après dans Godot](scene-comparison.png)
- [Quatre sprites et leurs wireframes](prepared-comparison.png)
- [Sol étendu à l'échelle du jeu](patch-seed17.png)
- [Raccords de près](patch-close.png)

Chaque sprite garde le cadre 270×138, l'ancrage et l'alpha géométrique du sol.
La grille1×1, la projection2:1 et le zoom .75 sont inchangés. Les pierres aux
frontières sont communes aux quatre variantes : mêmes volumes plans, UV de
matière et graines de finition. Elles sont peintes entières avant découpage.
Les assemblages internes varient ; aucun ancien décor de fissure ou de trou
n'est réintroduit.

La première préparation avait une différence de teinte maximale de9/255 aux
raccords. Le RGB haute résolution correspondait, mais la réduction Lanczos
échantillonnait au-delà de la marge alpha de2px. Les traits coupés à la limite
de case laissaient aussi un résidu. La préparation finale peint les pierres et
leurs traits entiers sur une marge couleur temporaire de6px, réduit l'image,
puis applique l'alpha géométrique final de2px. `colour-filter-before/` conserve
le diagnostic. Le helper historique garde sa valeur par défaut2px : aucun des
100 sprites existants ne change.

Godot sélectionne une image à la reconstruction selon les coordonnées et une
graine stable. Deux voisins horizontaux utilisent des groupes disjoints pour
éviter le même assemblage côte à côte. Les bits supérieurs du hash choisissent
à l'intérieur du groupe. Les coordonnées négatives fonctionnent également.
`floor_variants` est activé dans vingt layouts, avec `floor_variant_seed=17`.
Il reste désactivé par défaut dans le script et les anciennes revues. Un ancien
catalogue sans ces régions utilise le sol d'origine. Aucune génération d'image
ni géométrie n'est calculée à l'exécution.

## Mesures et vérifications

L'atlas contient **104 régions**, **1024×2048**, **1 463 015 octets PNG** et
**8 Mio RGBA**, sans mipmaps dans les paramètres d'import. Cela ajoute42 482
octets PNG (+2,99%) sans agrandir l'atlas. Les quatre PNG préparés totalisent
96 977 octets avant rangement et compression commune. Le paquet de ressources
pèse **1 236 542 octets**, avec **51 dépendances / 23 scènes**.

- Les 100 régions précédentes ont exactement les mêmes pixels RGBA et
  métadonnées, hormis leur position de rangement. Les six références du choix B
  gardent leurs empreintes. Les quatre nouveaux sprites sont bien dans l'atlas.
- Géométrie : couverture complète sans superposition ; 32 paires de bords
  compatibles. Les comparaisons de pixels incluent aussi 32 paires diagonales
  aux coins : 8 320 pixels opaques partagés, écart maximal1/255.
- Neuf captures ciblées : quatre variantes présentes, 256 cases de SixRoomPreview
  réparties60/67/63/66. Changer la graine modifie le sol ; restaurer17 reproduit
  les images à l'identique. Les placements des autres éléments restent identiques.
- Import, 68 captures runtime/23 scènes, import/export isolés et démarrage du
  paquet : sortie0, stderr vide. Les rendus ciblés ont été inspectés.
- Éditeur : 18 captures/cinq scènes, sortie0 ; 1 520 octets de diagnostics natifs
  de fenêtre et de libération de ressources. Son stderr n'est pas vide.
- Relecture indépendante ciblée : aucun problème concret relevé, y compris
  vérification indépendante des coins et des régions conservées.

Reproduction : `node tools/export_isometric_painted_kit.cjs`, puis import Godot,
`--script res://tools/capture_isometric_floor_variants.gd` et
`node tools/prepare_isometric_floor_integration_review.cjs`. Le dernier outil
produit les planches et `pixel-validation.json`. `validation.json` consolide
les journaux, inventaires et empreintes.

Les vérifications portent sur ces rendus et l'export de ressources, pas un APK
ou un profilage sur téléphone. Aucune suite de tests ajoutée/exécutée, aucun
commit ou push. Le jugement artistique du rendu intégré reste à l'utilisateur.
