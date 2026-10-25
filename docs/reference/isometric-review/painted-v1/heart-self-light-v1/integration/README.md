# Éclairage propre au cœur intégré — 25 octobre 2026

Le rendu accepté dans `../comparison.png` est maintenant utilisé dans les scènes
de production, notamment DungeonPreview sans torche. Le cœur garde sa lueur
violette et l'ombre de son socle quand les torches sont déplacées ou éteintes.

## Préservation et affichage

`../selection.json` fige les onze fichiers approuvés. L'exporteur adopte les deux
PNG préparés sans repeinture ni redimensionnement. Seules les marges entièrement
transparentes sont coupées, avec une compensation de position. Le socle et le
vortex gardent leurs pixels. Les neuf effets précédents quittent le catalogue
actif mais leurs références historiques sont conservées.

Les deux effets sont dessinés après les sols et avant les volumes : ombre en
composition normale, lueur en addition, indépendantes des lumières de torche.
Un masque de seize cases limite leur affichage aux sols réels et exclut portes
et escaliers. Les coordonnées négatives et positions fractionnaires sont prises
en charge. Le masque est recalculé à l'actualisation du placement ; pas de nouveau
calcul de géométrie, de texture ou de lumière par frame côté CPU.

Les shaders utilisent les coordonnées locales du sprite, conformément au
[repère VERTEX de Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html),
et non sa position variable dans l'atlas. Ils ne simulent pas l'occlusion par les
objets mobiles ou l'éclairage de ceux-ci. Le cœur isolé montre les effets entiers.

## Preuves

- `dungeon-preview.png` : rendu intégré, même cadre que la proposition acceptée.
- `torches-on/off/moved.png` : les paramètres des effets restent identiques.
- `edge-negative.png`, `special-neighbour.png`, `multiple-hearts.png` : placements
  proches du bord, case d'escalier voisine et plusieurs cœurs.
- `*-effects-only.png` : couches sur fond transparent. Aucun pixel non transparent
  au-delà du sol autorisé, hors tolérance de bord de rasterisation de .015 case.
- `observations.json` : contrôles ciblés, zéro échec, actualisation sans doublons.
- `pixel-validation.json` : 41 régions conservées inchangées ; pixels et échelle
  des nouveaux effets conservés ; 73 empreintes de sélections inchangées.
- `captures/` : 68 captures en jeu des 23 scènes ; `editor-captures/` : 19 vues
  dans l'éditeur, sur cinq scènes. Les vues de référence et de bord ont été inspectées.

Le résultat intégré diffère de la capture approuvée de 2/255 au maximum par canal
(moyenne .0049/255), dû au passage par l'atlas et son filtrage. La composition
approuvée, les couleurs, l'échelle et la géométrie sont conservées.

**43 régions, atlas 1024×1024, 602 507 octets PNG / 4 Mio RGBA** sans mipmaps.
La résolution native des effets est conservée. Le paquet de ressources contient
49 dépendances, dont les deux shaders : **521 921 octets**. Import, captures en
jeu, contrôles ciblés, import de la copie, export et démarrage isolé avec rendu
OpenGL : sorties 0, stderr vide. Pas d'APK ni de mesure sur téléphone.

La capture éditeur sort à 0 mais son stderr de 1518 octets comporte les diagnostics
natifs de fenêtre et de ressources à l'arrêt, dont deux shaders non libérés.
Elle n'est pas décrite comme propre. La première tentative du contrôle ciblé a
rencontré une affectation de tableau non typé dans le script de capture ; la
version corrigée s'exécute avec zéro échec et stderr vide.

La revue indépendante n'a relevé aucun problème concret dans l'intégration.
Pas de commit ni de push.

## Reproduction

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_heart_self_light_integration.gd
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-review/painted-v1/heart-self-light-v1/integration
node tools/prepare_mobile_export.cjs
```

Ne pas réexécuter le générateur de la proposition dans le dossier sélectionné :
la production charge désormais les effets approuvés avec vérification d'empreinte.
