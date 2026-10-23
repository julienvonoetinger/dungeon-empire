# Dallage C — plan d'intégration

> Exécution dans cette session avec le guide executing-plans. La sélection C est
> déjà approuvée ; aucune nouvelle validation préalable n'est nécessaire.

**Objectif :** appliquer les grandes dalles C aux sources, sprites et guides.

**Architecture :** conserver la source commune de dallage, puis régénérer les
wireframes, les guides isolés et leurs PNG peints. Dans les scènes connectées,
seul le sol commun contient le dallage : actualiser ce PNG avec --floor-only.
Les structures connectées et leur sélecteur restent valides.

**Technologies :** Node.js/sharp, SVG/JSON, Godot 4.

**Spécification :** choix utilisateur « oui le C », décrit dans
docs/reference/material-variation-review/floor-size-proposals.json, option size-2.

## Contraintes

- Deux rangées de hauteur 2,5 dans le repère 6×5 ; largeurs
  [1,15; 3,05; 1,8] puis [2,3; 3,15; 0,55]. Grille logique 1×1 inchangée.
- Pierres entières aux frontières, pas 256, export ×4 et finition B conservés.
- Le choix porte sur la taille du dallage. La nouvelle gamme de matières et la
  variété des murs restent une proposition séparée ; matières actives conservées.
- Pas de tests ajoutés ou exécutés, conformément aux instructions actuelles.
- Pas de commit/push demandé pour cette intégration.

## Étapes

- [x] Figer les sources de la comparaison acceptée, mettre à jour le motif commun
  et supprimer les hypothèses de six rangées dans le compositeur.
- [x] Réexporter les sources de dallage/portes/escaliers, overlays et 57 sprites
  isolés, puis le sol connecté. Importer les ressources Godot.
- [x] Mettre à jour AGENTS.md, GAME_DESIGN.md et PAINTED_GODOT.md ; conserver
  les paramètres et la portée dans la documentation durable.

## Points de revue de source

- Les fragments gauche/droit représentent la même pierre, sans biseau de case.
- Les portes et escaliers gardent un dallage orienté dans le repère du monde.
- L'export --floor-only conserve les 737 structures et la sélection de contexte.
- Le bouton d'actualisation recharge les nouvelles ressources importées.
- L'ancienne comparaison A/B/C ne doit pas lire le nouveau sol comme référence A.

## Journal

- Périmètre : taille C approuvée ; les textures de la comparaison ne sont pas
  promues implicitement. Les scènes existantes réutilisent le même sol préparé.
- La propagation n'exige aucune modification de layout ou de mécanique de jeu.
- Sources et overlays réexportés : 146 guides, quatre portes et quatre escaliers.
- Export isolé terminé : 57 PNG / 146 alias, code de sortie 0.
- Export connecté --floor-only terminé, code de sortie 0 ; sélecteur et
  contextes structurels conservés. Les empreintes du nouveau sol sont séparées
  des empreintes historiques des structures non régénérées.
- Aucun test ni commit exécuté. Les rapports intégrés aux exports décrivent
  leur couverture géométrique ; ils ne prouvent pas tous les assemblages.
- Import Godot : sortie 0, stderr vide. Cinq scènes rendues aux deux résolutions
  par capture_wireframe_cells.gd ; vues normales inspectées, sorties sans erreur.
- Revue indépendante de source (review_large_floor_c) : aucun problème important
  signalé dans le périmètre. Aucun test ni génération exécuté par le reviewer.
- Limite visuelle : les textures actives répètent encore leurs motifs. Le présent
  changement applique la taille C ; la proposition de matières reste distincte.
