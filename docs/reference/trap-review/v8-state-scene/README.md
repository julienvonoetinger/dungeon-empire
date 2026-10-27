# Présentation de tous les états des pièges

Ouvrir `scenes/DungeonTraps.tscn` dans Godot et lancer **F6**.

- Lignes : Pointes, Entrave, Néant.
- Colonnes : prêt, déclenché, épuisé.
- États volontairement fixes ; glisser déplace la caméra au zoom de référence 0,75.
- Sprites, dalles et projection isométrique de production, sans nouvel asset.

`scripts/trap_states_preview.gd` est un outil d’éditeur et utilise le même
`mobile_dungeon_renderer.gd` que le jeu. La scène ne crée aucune session de jeu
et ne lit ni n’écrit de sauvegarde.

`tools/capture_trap_states_preview.gd` produit `overview.png` et l’inventaire des
15 couches natives : neuf dalles et six mécanismes. Capture GPU à 1280×720
inspectée ; sortie 0, stderr vide, les neuf états sont présents. Import Godot
également terminé sans erreur. Ce contrôle porte sur la présentation statique,
pas sur les transitions ou l’équilibrage des pièges pendant un raid.
