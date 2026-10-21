# Dungeon Empire — nouvelle base 2D

Une scène Godot qui reproduit le donjon approuvé avec ses vrais éléments 2D :
six salles, des couloirs ouverts, des dalles bleues et des murs en pierre.

## Ouvrir la scène

1. Importer `project.godot` dans Godot 4.3 ou plus récent.
2. Lancer le projet avec **F5**.

La scène principale est `scenes/DungeonPreview.tscn`. La caméra cadre
automatiquement toute la carte quand la fenêtre change de taille. Le rendu
utilise GL Compatibility. Aucun service externe ni téléchargement d'assets
n'est nécessaire.

## Contenu actuel

- Carte fixe de 28 × 18 cases, avec 255 dalles et des couloirs de deux cases.
- 19 sprites du kit approuvé, plus une petite texture de fond.
- Murs et angles choisis à partir des cases voisines ; le sol conserve toute
  la largeur des passages.
- Aucune mécanique de jeu, interaction, interface ou sauvegarde pour l'instant.

La carte est dans `assets/layouts/preview.tres` : chaque chiffre de `0` à `7`
choisit une variante de sol, chaque point représente une case vide.
Le rendu utilise les PNG de `assets/dungeon/`, et non une image du donjon entier.
Les proportions des sprites sont prévues pour des cases de **54 px**.

## Organisation

| Dossier | Contenu |
| --- | --- |
| `assets/dungeon/` | Sprites, fond et coordonnées de découpe des sources |
| `assets/layouts/` | Carte fixe |
| `scenes/` | Scène principale |
| `scripts/` | Données de carte, dessin 2D et cadrage |
| `docs/reference/` | Prototype source, kit et composition approuvée |
| `tools/` | Vérification de scène et capture du rendu Godot |

`GAME_DESIGN.md` décrit le périmètre implémenté et les limites de cette étape.
Les références de `docs/` sont exclues de l'import Godot.

## Vérification sous Windows

```powershell
./tools/test-mobile.ps1 -All
./tools/test-mobile.ps1 -All -Capture
```

Si nécessaire, ajouter `-Godot 'C:\chemin\godot.exe'` ou définir `GODOT_BIN`.
Le script importe le projet, vérifie les connexions et le cadrage en quatre
formats, puis lance brièvement la scène principale. `-Capture` produit
`artifacts/dungeon-2d.png` avec le moteur graphique ; une session graphique est
nécessaire pour cette option. Les sorties et captures restent locales.

Le nom `test-mobile.ps1` est conservé comme point d'entrée. Il vérifie désormais
la base 2D : il ne certifie pas encore un export ni les performances sur téléphone.

## Ancienne version

Le prototype 3D et ses ressources ont été retirés de cette branche. La version
précédente reste disponible dans Git au tag **`v1.0.0`**. L'historique Git garde
donc les anciennes ressources, même si elles ne font plus partie du projet actif.
