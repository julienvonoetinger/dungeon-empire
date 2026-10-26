# Forge — passe 2 (26 octobre 2026)

Réponse à la revue du PDF de la passe 1. Canevas Claude Design :
https://claude.ai/artifact/8jkFUgqyG3KxoqmUNmCiQx (planches de la passe 1 conservées,
planches « P2 » ajoutées). Export hors ligne : `revue-ui-forge.pdf` (13 pages).

- `captures/` et `presentation.json` : 78 vues natives, 6 formats (844×390, 740×360,
  667×375, 390×844, 320×568, 1280×720). `scale-before` = même vue avec l'ancien zoom
  de 0,75, à dimensions identiques. Reproduire :
  `godot --path . --script res://tools/capture_forge_navigation.gd -- --design-pass-2`.
- `interaction/` : session isolée `tools/review_forge_interactions.gd` (clics
  synthétiques dans le vrai viewport, emplacement de revue supprimé ensuite,
  sauvegarde du joueur vérifiée par SHA-256). 53 contrôles, 0 échec.
- `mock-kit/` : pierre (normale, sélection, désactivée) et icônes exportées par
  Godot, tuile de roche. `tools/build_forge_review_boards.cjs` en tire les
  maquettes du canevas et la page d'impression du PDF ; `artifact-assets.json`
  associe chaque fichier à sa ressource dans le canevas.

Limites : captures statiques et clics synthétiques ; pas de toucher réel sur téléphone,
de DPI ou de zones sûres physiques, ni de mesure de performances. Les maquettes
reprennent une capture 1280 réduite pour le monde : leurs anneaux paraissent plus
petits que les anneaux natifs, maintenus à 32 px.
