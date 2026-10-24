# Dungeon Empire — base 2D mobile

Les **21 scènes d’architecture** partagent **23 sprites dans un atlas 1024×2048** :
sol, murs, piliers, portes et escaliers dans les quatre directions. Les images
sont préparées hors ligne ; Godot place leurs régions sur la grille 1×1,
sans créer de pixels ni de textures pendant le jeu.

La vue est fixe : 256 pixels source par case, zoom 0,75, soit 192 pixels affichés
par case dans la vue logique 1280×720. Déplacement au doigt ou avec le bouton
gauche de la souris ; aucun zoom utilisateur. Les bases sont sobres et communes.
Le dessus sculpté des piliers reste un décor séparé et optionnel.

Ce projet est une étude visuelle. Aucun gameplay n'est implémenté.

## Ouvrir les scènes

Ouvrir `project.godot` dans Godot.

- **F5** : `scenes/MobileReference.tscn`.
- **F6** : lancer la scène sélectionnée.
- **SixRoomPreview** : six salles, couloirs de deux cases de large et entrée
  par escalier, sans cœur ni torches.
- **WireframeDoorCross** : les quatre orientations de portes.
- **WireframeClosedCorridors** : salle avec quatre couloirs et escaliers terminaux.
- **EntranceVariants** : les quatre escaliers avec le même kit que les salles.
- **DungeonHeart** et **DungeonTorch** : props séparés conservés.

Les noms historiques « Wireframe » restent ceux des scènes ; leur rendu utilise
maintenant les sprites peints. Les études de salles 1×1, 2×2, 3×3 et 5×5 ainsi que
les couloirs sont toujours disponibles dans `scenes/`.

Dans l'éditeur, sélectionner **Dungeon → Actualiser le rendu** après la fin de
l'import. Le catalogue et l’atlas sont rechargés ensemble ; les réimports suivants
actualisent l’aperçu. Les grandes scènes s’explorent en déplaçant la vue.

## Où sont les sprites ?

| Dossier | Contenu |
| --- | --- |
| `assets/dungeon/mobile-kit/` | Atlas et catalogue actifs dans toutes les scènes d’architecture |
| `assets/dungeon/shared-materials/` | Matières, atlas approuvé et recette active |
| `assets/dungeon/wireframe-*/` | Géométrie source réutilisable |
| `assets/dungeon/heart/`, `assets/dungeon/torches/` | Props séparés |

Voir [l'inventaire des assets](assets/dungeon/README.md).

Les anciens PNG haute résolution et leurs caches intermédiaires ont été supprimés.
Les matières, wireframes et références nécessaires à la reconstruction restent
conservés. Voir [le relevé du nettoyage](docs/cleanup/README.md) pour les chemins,
empreintes et possibilités de récupération.

## Reproduire les sprites

Avec Node.js et `sharp` disponibles, depuis la racine :

```powershell
node tools/export_mobile_kit.cjs
godot --headless --editor --path . --import
```

Le pipeline conserve les matières communes et les masques fixes. Les exporteurs
des anciennes familles A/B/C/D2 ne mettent plus à jour les scènes actives.

## Capturer un aperçu

```powershell
godot --path . --script res://tools/capture_mobile_kit.gd
node tools/prepare_mobile_kit_review.cjs
```

Les images sont dans `docs/reference/mobile-kit/captures/`. Le kit actif pèse
620,5 Kio en PNG et 8 Mio en RGBA sans mipmaps. Le paquet de ressources exporté
pèse environ 458 Kio, hors moteur Android. Aucun profilage sur téléphone effectué.
Ces commandes produisent des aperçus et des audits d’export, pas une suite de tests.

Suivre le [guide mobile](docs/reference/mobile-kit/README.md) pour exporter les
40 dépendances actives depuis une copie propre, sans embarquer les anciens assets.

## Documentation

- [Kit mobile : recette, export, mesures et limites](docs/reference/mobile-kit/README.md)
- [Règles et état implémenté](GAME_DESIGN.md)
- [Placement et catalogue Godot](docs/reference/PAINTED_GODOT.md)
- [Construction des wireframes](docs/reference/WIREFRAME_WORKFLOW.md)
- [Matières et composition hors ligne](docs/reference/MATERIAL_WORKFLOW.md)
- [Perspective commune](docs/reference/PERSPECTIVE.md)

## Nettoyage historique

Les anciens essais d'architecture, leurs renderers et outils spécifiques ont été
retirés du projet actif le 23 octobre 2026. Les suites `verify_*` et
`tools/test-mobile.ps1` décrivaient l'ancien renderer ; elles sont également retirées.

[Inventaire et récupération](docs/cleanup/2026-10-23-pre-wireframe.json).
Une copie locale récupérable reste dans `artifacts/pre-wireframe-archive-2026-10-23/`,
exclue de Git et de Godot. Les maquettes originales, les wireframes et les sources
du pipeline actuel sont conservés. Les sections anciennes de GAME_DESIGN et des
notes de revue sont historiques ; leurs anciens chemins ne sont plus actifs.
