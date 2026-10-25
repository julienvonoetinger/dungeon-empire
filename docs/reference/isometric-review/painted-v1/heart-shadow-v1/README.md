# Ombre du socle — 24 octobre 2026

L'utilisateur accepte la perspective, mais demande une ombre sur les dalles pour
ancrer visuellement le socle. `comparison.png` montre les captures Godot avant et
après, à l'échelle .75 puis agrandies ×2.

`tools/isometric_ground_shadow.cjs` projette les seules faces rigides du cœur sur
z=0. Neuf échantillons autour d'une lumière statique venant du haut-gauche créent
une ombre courte ; une légère diffusion adoucit le bord. Un contact plus dense
reste au pied. Le vortex lumineux est exclu. Aucune illustration n'est régénérée.

Le sprite `heart-shadow` est séparé : **233×134**, **4 625 octets PNG**, dans le
même atlas 1024×1024. Celui-ci contient désormais **27 régions**, fait **497 846
octets PNG**, et garde **4 Mio RGBA**. Tous les PNG préparés précédents sont
identiques à ceux conservés dans `before/sprite-hashes.json` ; le changement de
compression global vient du nouvel agencement de l'atlas.

Le catalogue associe `ground_shadow` au cœur et marque l'effet `ground_effect`.
Le renderer le dessine après tous les sols, avant tous les objets. `light_mask=0`
empêche les torches d'éclaircir le sprite d'ombre ; son alpha assombrit la dalle
déjà éclairée. La zone complète doit reposer sur le sol hors portes/escaliers,
sinon l'ombre est omise dans les layouts de donjon. La scène isolée `DungeonHeart`,
sans layout, montre également l'ombre sur son fond d'aperçu. Ce n'est pas un système d'ombres dynamiques : elle ne
réagit pas aux torches et ne se projette pas sur les murs.

## Reproduction

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_shadow_review.cjs
```

Import et 68 captures runtime / 23 scènes : sortie 0, stderr vide. Les 21 captures
éditeur / cinq scènes sortent à 0, avec les diagnostics natifs de fenêtre/progression
et de ressources à l'arrêt déjà connus. L'export isolé de 45 dépendances fait
439 528 octets ; import/export/ouverture du paquet sortent à 0, stderr vide.
Pas de tests automatisés, APK, profilage téléphone, commit ni push.

La revue indépendante du code et des captures n'a trouvé aucun problème restant.
Elle a fait préciser l'exception de la scène isolée sans sol décrite ci-dessus.
