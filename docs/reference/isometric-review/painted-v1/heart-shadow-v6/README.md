# Ombre du cœur orientée selon les torches

**Version retenue par l'utilisateur** après présentation de la planche des
déplacements et de ses limites. `selection.json` conserve les empreintes de
cette version ; les rapports de validation restent les instantanés antérieurs
à cette acceptation. Les exemples présentés montrent les directions 2, 7 et 1.

L'utilisateur apprécie la direction unique de v5, mais questionne son orientation.
Il accepte de lier le choix à une torche proche et rappelle que les positions
des torches seront libres. Les PNG ne supposent donc aucun placement de scène.

## Fonctionnement

- Huit ombres préparées dans le plan XY, à partir du support rigide inchangé.
  La longueur artistique, l'opacité .32, le contact .38 et les douceurs 1.2/.7
  pixels source sont conservés. L'empreinte au sol ne grandit pas radialement.
- `emitter_world` donne le centre lumineux réel de chaque orientation de torche.
  À chaque reconstruction, le cœur choisit la torche active la plus proche
  dans sa portée lumineuse, avec un trajet au sol sans vide ni porte/escalier.
- Les propriétés de placement déclenchent cette reconstruction en jeu et dans
  l'éditeur. Les captures de déplacement utilisent ces mêmes propriétés sur
  une seule scène vivante. Les scènes enregistrées ne sont pas modifiées.
- Le choix d'image oppose la projection de l'ombre à la position de la lumière
  dans le plan du sol. Il n'y a aucune rotation du PNG en espace écran.
- Pas de torche admissible, lumières désactivées ou projection débordant du sol :
  contact seul, s'il tient sur le sol. Même comportement pour DungeonHeart isolé.

Une image par cœur est dessinée entre les sols et les volumes. Le vortex
lumineux ne projette pas d'ombre. Ce système propose huit orientations discrètes,
de longueur fixe : pas de simulation de plusieurs lumières, de changement de
longueur selon la distance, ni de suivi direct de nœuds PointLight2D déplacés
hors du plan. Le contrôle de trajet ne traite pas les autres objets comme
obstacles. Le débordement des lumières Godot entre murs reste une limite séparée.

## Résultat et coût

`comparison.png` : direction fixe v5 contre direction choisie dans MobileReference.
`placement-comparison.png` : positions initiales, cœur déplacé vers la gauche,
puis torche déplacée. Haut : pixels Godot .75 non redimensionnés ; bas : détail ×2.
`observations.json` conserve l'image et la torche retenues pour sept captures.

35 régions, atlas 1024×1024, **570 722 octets PNG / 4 Mio RGBA**. Les neuf effets
diffus sont empaquetés à demi-résolution ; leurs dimensions logiques et leurs
bounds restent en coordonnées source. Cela évite un atlas de 8 Mio. Les sprites
peints du cœur, sol, murs, torches et portes sont inchangés par empreinte.
`sprites/heart-shadow*.png` dans le dossier parent conserve la préparation à
pleine résolution avant réduction dans l'atlas. `before/` fige v5.

## Reproduction

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_isometric_shadow_orientation.gd
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_shadow_orientation_review.cjs
```

Import, captures runtime et export isolé : voir `validation.json`. L'éditeur
émet encore ses diagnostics natifs de progression et de ressources à l'arrêt.
La revue indépendante a relevé un départage instable des distances presque
égales ; la comparaison utilise maintenant une seule distance quantifiée.
Les captures ont été refaites après correction. Aucun test automatisé, APK,
profilage sur téléphone, commit ou push. La préférence visuelle v5 ne constitue
pas une approbation automatique de toutes ces orientations.
