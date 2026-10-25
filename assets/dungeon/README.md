# Assets du donjon

## Kit isométrique actif — 25 octobre 2026

`isometric-kit/atlas-256.png` et `isometric-kit/catalog.tres` contiennent les
108 régions préparées (dont l'ombre et la lueur propres au cœur,
72 profils de variantes de murs, quatre assemblages de dalles B et quatre décors de sol) pour les 23 scènes.
Atlas 1024×2048, 1 504 113 octets PNG, 8 Mio RGBA, losange source 256×128,
caméra fixe .75. Sol, murs, pilier nu et
dessus sculpté optionnel, quatre portes et escaliers, cœur et deux torches.
[Recette et commandes](../../docs/reference/isometric-review/painted-v1/README.md).

Le kit peint `mobile-kit/`, les sources heart/ et torches/ et les dossiers
ci-dessous restent des références historiques et sources de peinture.
Seule la petite texture de lumière de mobile-kit reste une dépendance partagée ;
les torches du catalogue peint utilisent les lumières locales existantes.
Les deux effets du cœur gardent leur résolution approuvée. Seules leurs marges
entièrement transparentes sont retirées ; ils sont indépendants des torches.
Un masque limite l'ombre et la lueur aux cases de sol au moment de l'affichage.
Les anciens décors de fissures et d'éclats de pierre ont été retirés de l'atlas
et du placement automatique, sur le sol comme sur les murs. Les sources de
revue restent historiques. Voir
[le retrait des derniers décors de dégâts](../../docs/reference/isometric-decoration-review/remove-chip-2026-10-25/README.md).

Les neuf murs A1–A3/C1–C3/F1–F3 existent dans les deux orientations et quatre
profils de jonction : 48 régions de structure et 24 couches de corruption avec
leur fond de maçonnerie. Les nouveaux profils sont préparés à la densité utile
du zoom .75. Toutes les régions conservées gardent exactement leurs pixels.
`wall_variants`, `wall_variant_seed` et `wall_corruption` contrôlent leur
répartition à la reconstruction. Les murs nus entre les variantes sont conservés.
[Preuves et comparaison de palette](../../docs/reference/isometric-wall-variation-review/v2-subvariants/integration/README.md).

Les dalles B partagent des pierres entières aux quatre frontières de case.
Leurs assemblages intérieurs varient ; la matière et les coins arrondis du sol
restent communs. `floor_variants` et `floor_variant_seed` contrôlent ce choix
stable à la reconstruction. Les vingt layouts l'activent, avec la graine17.
Le sol historique reste disponible quand l'option est désactivée.
[Rendus, wireframes et vérifications](../../docs/reference/isometric-floor-variation-review/v1/integration/README.md).

Les quatre nouveaux décors A/B/C/D sont des petits sprites avec leur fond de pierre,
préparés pour un assemblage B précis. Ils sont dessinés juste après ce sol, avant
les ombres et les objets. `floor_damage`, `floor_damage_seed` et `floor_corruption`
contrôlent une répartition stable et espacée ; les vingt layouts l'activent.
Les sources acceptées sont conservées. Ces nouveaux décors ne réutilisent pas les
anciens éclats/fissures retirés. [Rendus et limites](../../docs/reference/isometric-floor-damage-review/v1/integration/README.md).

## Ancien kit peint — historique

| Dossier | Rôle |
| --- | --- |
| `shared-materials/` | Recette active, atlas stylisés, 17 matières et provenance |
| `wireframe-cells/`, `wireframe-doors/`, `wireframe-entrances/` | Géométrie source des exports peints |
| `heart/` | PNG du cœur, sa référence originale et son placement |
| `torches/` | Torche conservée comme prop séparé |

## Références conservées

- `perspective/reference-atlas.png` est une maquette originale de l'utilisateur.
- `gloom-kit/reference.png` est une autre copie originale de référence.
- Les essais de masques dans `gloom-kit/proposals/nw-*` datent du travail sur les
  wireframes. Ils documentent la méthode ; ce ne sont pas des sprites actifs.
- Les propositions de matières plus récentes restent dans `shared-materials/proposals/`.
  La recette de matières active est `shared-materials/active-recipe.json`.
  La finition B des angles est définie dans `shared-materials/stone-finish.json`.
  Le sol lisse utilise `shared-materials/floor-smooth-atlas-v1.png` ; ses découpes
  et l'arrondi accru sont dans `active-recipe.json` (floorPattern, floorFinish).
  Les murs et les marches gardent B.
  Les variantes A/B/C et D2 utilisent `shared-materials/wall-variation-atlas-v1.png`.
  `active-recipe.json.wallVariation` décrit leurs matières et règles de raccord.

Les anciens dossiers `painted-connected/` et `painted-cells/`, leurs catalogues,
les scripts `painted_cell_catalog.gd` / `painted_wall_selection.gd` et les caches
intermédiaires ont été supprimés le 24 octobre 2026. L'ancienne copie locale
`artifacts/pre-wireframe-archive-2026-10-23/` a également été supprimée.
Les inventaires, empreintes et commits de récupération sont documentés dans
`docs/cleanup/README.md`. L'historique Git n'a pas été réécrit.

Le kit mobile réutilise la peinture commune sur des primitives préparées, avec
des piliers distincts aux jonctions. Les anciens outils de revue A/B/C/D2 sont
historiques ; utiliser `export_isometric_kit.cjs` pour reconstruire les assets actifs.

Méthode et commandes : `docs/reference/PAINTED_GODOT.md`,
`docs/reference/MATERIAL_WORKFLOW.md`, `docs/reference/WIREFRAME_WORKFLOW.md`.
