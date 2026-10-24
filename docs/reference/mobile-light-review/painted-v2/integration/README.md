# Torches approuvées intégrées — 24 octobre 2026

Après l'approbation de la flamme à base arrondie, « continuons » autorise son
intégration. Les images et la sélection d'apparence restent figées : l'export
adopte les deux PNG préparés sans les redessiner, les étirer ou les recolorer.

## Utilisation dans Godot

Ouvrir `scenes/MobileReference.tscn` et lancer F6. Le nœud `Dungeon` expose :

- `torch_north_cells` : cases avec une torche sur leur mur nord ; exemple `(1,0)`.
- `torch_west_cells` : cases avec une torche sur leur mur ouest ; exemple `(0,1)`.
- `torch_lights_enabled` : active la lumière locale, indépendamment du sprite.

Ces listes utilisent des coordonnées entières de cases, comme le donjon. Le
mur doit exister : les passages ouverts, limites absentes, cases de porte ou
d'escalier sont ignorés avec un avertissement. Un doublon n'ajoute pas de torche.
Les autres faces ne sont pas incluses dans l'illustration approuvée ; aucune
rotation ou symétrie artificielle du PNG n'est appliquée.

`scenes/DungeonTorch.tscn` est aussi migrée vers le kit commun. Son inspecteur
permet de sélectionner la version horizontale ou verticale. Les autres salles
conservent leurs dispositions et ne reçoivent pas de torches par défaut.

## Préparation et rendu

`tools/mobile_approved_torches.cjs` contrôle les empreintes de la sélection,
les dimensions, les proportions et les ancrages. Il fournit directement les
PNG au rangement commun dans l'atlas. Les métadonnées conservent les volumes
du support et le point lumineux de la scène approuvée.

Le moteur place ces AtlasTexture dans le même ordre que les murs et piliers.
Un PointLight2D optionnel utilise un dégradé partagé de 128×128 pixels, déjà
préparé hors ligne. Les torches ne reçoivent pas cet éclairage additionnel :
leur peinture intègre déjà leur lumière propre. Le rafraîchissement éditeur
recharge catalogue, atlas et dégradé ensemble ; un rebuild retire les anciens
sprites et lumières avant de les recréer.

## Mesures

| Élément | Valeur |
| --- | ---: |
| Sprites de l'atlas | 50, dont 2 torches |
| Atlas | 1024×2048, 991 208 octets PNG |
| Supplément du PNG d'atlas | 16 510 octets |
| Atlas en RGBA | 8 Mio, inchangé |
| Dégradé lumineux partagé | 128×128, 5 151 octets PNG, 64 Kio RGBA |
| Torche horizontale | 58×84 pixels source |
| Torche verticale | 56×108 pixels source |
| Paquet de ressources | 726 759 octets |
| Dépendances sources / scènes exportées | 45 / 23 |

La taille du ZIP représente les ressources Godot, pas un APK ni une mesure
sur téléphone. L'export ne contient ni sources d'auteur, ni ancienne torche.

## Éléments examinés

- `atlas-report.json` : les 48 anciennes régions conservent leurs pixels et
  leurs placements. Les deux torches correspondent aux pixels approuvés après
  la même composition alpha que l'atlas. Le rendu après extinction/rallumage
  est identique au rendu initial.
- `game-view.png` : MobileReference à l'échelle fixe .75, avec le cœur.
- `attachment-details.png` : les deux fixations en pixels de jeu agrandis ×2.
- `captures/` : 7 vues, lumières activées/désactivées, salle correspondant à
  l'approbation et les deux orientations du sprite autonome.
- `scenes/` : 63 captures de 21 scènes, plus 3 vues de l'éditeur MobileReference.
  Les 3 vues éditeur/jeu à caméra identique sont égales pixel par pixel.
- Import, captures en jeu, import isolé, export et démarrage du paquet : code 0,
  stderr vide. Le processus de capture éditeur termine avec le code 0, mais
  émet les diagnostics natifs de fenêtre/progress/resources à sa fermeture.
  Son stderr n'est donc pas vide ; les journaux sont conservés.
- Revue indépendante des changements : aucune anomalie de code actionnable.
  Le rappel de terminer l'inventaire/export a été traité.

Les lumières sont statiques, sans animation ni ombres portées. La propagation
entre salles et le coût sur appareil mobile restent à étudier. Aucun test
automatisé ajouté/exécuté, aucun commit/push demandé dans cette intégration.
L'éditeur de l'utilisateur et son cache ont été préservés.

## Reproduction

Ne pas relancer les générateurs d'art pour une simple intégration : utiliser
les fichiers approuvés et leurs empreintes.

```powershell
node tools/export_mobile_kit.cjs
& $godot --headless --editor --path . --import
& $godot --path . --rendering-method gl_compatibility --script res://tools/capture_approved_torches.gd
node tools/prepare_approved_torch_review.cjs
& $godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/mobile-light-review/painted-v2/integration/scenes
& $godot --editor --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/mobile-light-review/painted-v2/integration/scenes MobileReference
node tools/prepare_mobile_export.cjs
$info = Get-Content docs/reference/mobile-kit/export-inventory.json -Raw | ConvertFrom-Json
& $godot --headless --editor --path $info.staging --import
& $godot --headless --path $info.staging --export-pack 'Android Mobile' "$PWD/artifacts/mobile-torches-kit.zip"
```

`source/` fige l'atlas et le catalogue avant intégration pour rendre la
comparaison reproductible. La sélection d'apparence originale n'est jamais
réécrite pour faire correspondre une nouvelle exportation.
