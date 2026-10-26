# Animation du vortex

Le cœur garde son atlas et son dessin. Un masque de shader isole la spirale
intérieure ; l'anneau conserve sa silhouette, le socle et la liaison sont fixes.
Cycle12s, dérive radiale bornée et pulsation lumineuse discrète (trois par cycle).
Aucune nouvelle texture, image générée ou géométrie.

- [Aperçu interactif](preview.html), avec lecture/pause et curseur temporel.
- [Boucle animée](vortex.gif),144images sur12s, échelle mobile. Le GIF réduit les couleurs ; le HTML conserve le rendu complet.
- [Observations Godot](state-inventory.json) :17 présentations sans interface,
  notamment pause, reprise, désactivation, remplacement des sprites, récupération
  du contrôleur existant, zéro/deux cœurs et interruptions de gameplay.
- [Contrôles visuels](validation.json) : fragment identique exécuté dans un
  navigateur isolé sans fenêtre, via WebGL2. Aucune modification alpha ni pixel
  hors des masques ; début et fin de boucle identiques à l'image fixe.

Ce sont des observations Godot sans rendu et un aperçu WebGL, pas une capture
du rendu GPU de Godot ni une mesure sur téléphone. Aucun contrôle d'application
native, sauvegarde joueur, test automatisé, commit ou push.

En jeu et dans les scènes lancées, l'animation est active par défaut. L'éditeur
reste fixe. `vortex_animation_enabled` désactive l'effet. Les nouveaux matériaux
reprennent la phase courante après reconstruction ; aucun recalcul d'image.
Le contrôleur utilise une phase explicite, car le [temps des shaders Godot](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html#global-built-ins)
ne s'arrête pas avec la pause.

Reproduction : export_isometric_painted_kit.cjs ; import Godot sans interface ;
capture_heart_vortex_state.gd ; prepare_heart_vortex_review.cjs. Ce dernier utilise
Node/Sharp/Playwright et Edge en mode sans fenêtre, dans un profil temporaire
isolé. VORTEX_REVIEW_BROWSER permet de choisir un autre exécutable compatible.
Les journaux se trouvent dans artifacts/heart-vortex-*.

Les136 régions conservent leurs pixels et positions ; les deux atlas et les
paramètres du projet sont identiques au dossier before/. Seule l'entrée heart
ajoute le centre et le rayon du vortex, dérivés de la préparation existante.
