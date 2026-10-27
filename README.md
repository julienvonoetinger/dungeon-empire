# Dungeon Empire — prototype 2D isométrique mobile

Une première boucle jouable est disponible dans **`scenes/game/DungeonGame.tscn`** :
aménager le donjon, observer un raid autonome, puis consulter le bilan et réparer.
Les héros utilisent encore des repères provisoires. Pointes, Entrave et Néant
ont leurs sprites peints, avec les états armé, déclenché et épuisé. Les coffres ont leurs
sprites rituels en quatre orientations vers l'espace libre : entrouverts sans
protection, fermés avec un verrou actif. La serrure reste sur la caisse dans les
deux états ; corps de72px au zoom.75. La revue du
code et le démarrage sans interface sont vérifiés ; la validation interactive
complète reste à terminer. [État détaillé](docs/gameplay/validation-2026-10-25.md).

Les **25 scènes de présentation** et la scène jouable réutilisent **120 régions
préparées dans un atlas 1024×2048**, complétées par seize régions de coffres et
d'ombres dans une page 256×1024 et quinze régions de pièges dans une page
512×1024 du même catalogue, soit **151 régions au total** :
sol, murs, piliers, quatre portes, quatre escaliers, cœur et torches.
Les anciens décors de fissures et d'éclats de pierre ont été retirés.
Le vortex du cœur tourne doucement en jeu, avec une légère pulsation violette.
Le socle reste fixe ; aucune texture supplémentaire. L'éditeur reste statique.
Vingt scènes de disposition activent neuf variantes de murs : maçonneries,
reliefs et corruption optionnelle. Leurs pierres partagent la palette du mur
de base ; les accents violets restent distincts.
Ces vingt scènes utilisent aussi quatre assemblages de dalles B, aux formats
variés et aux surfaces calmes. Les pierres traversant les limites de cases
partagent leur géométrie et leur peinture pour assurer les raccords.
Quatre nouveaux décors de sol (fissures et corruption) sont ajoutés avec parcimonie
sur leurs dalles B correspondantes, hors portes, escaliers et socle du cœur.
Ils restent dans le même atlas et ne changent pas les bords de cases.
Le cœur possède son propre éclairage au sol : une lueur violette et les ombres
du socle, indépendantes des torches. Les deux effets sont limités aux vraies cases
de sol, hors portes et escaliers.
La projection isométrique 2:1 est commune à tous les volumes. Les images sont
préparées hors ligne ; Godot les place sur la grille logique 1×1.

Une case est affichée comme un losange de 256×128 pixels source, soit 192×96
au zoom fixe 0,75 dans la vue logique 1280×720. Déplacement au doigt ou avec le
bouton gauche de la souris ; aucun zoom utilisateur. Les matières et dessins
approuvés ont été adaptés à la géométrie isométrique, préparée d'abord en wireframe.

Le kit visuel reste indépendant de la simulation ; les illustrations approuvées
n'ont pas été modifiées pour ajouter le gameplay.

## Jouer

Ouvrir `scenes/game/DungeonGame.tscn`, puis **F6** dans Godot. Choisir un nouveau
donjon, ou **Donjon d'essai** puis confirmer pour disposer d'une entrée, d'une
porte, de pointes et de trois coffres. **Lancer le raid** commence l'expédition.

Glisser sur le donjon déplace la vue ; le zoom reste fixe. Choisir un outil puis
toucher les cases pour poser en série, ou glisser l'outil depuis la palette.
**↶** annule la dernière construction de cette session. L'ancrage du cœur et le
remplacement d'un objet gardent une confirmation explicite.
La **Forge en pierre et violet** réserve une colonne aux commandes, hors de la
vue du donjon. Le catalogue commence directement par **Terrain, Portes, Pièges
et Trésors** : choisir une famille puis son outil, qui reste actif pour poser
en série. **Voir** réduit cette colonne. Les cibles gardent au moins
48 unités d'interface. Les coffres se gèrent via un panneau contextuel avec
transferts à l'unité ; les longs panneaux et bilans peuvent défiler. Le menu
accessible par la trésorerie ou Pause propose **Lancer le raid**.
Le timer reste visible au-dessus des panneaux, avec son état de pause pendant
la construction. Les couronnes dorées avec des pièces indiquent le remplissage
des coffres ; les couronnes cuivrées des pièges montrent les charges restantes.
Les montants exacts restent dans le panneau de la case sélectionnée.
La roche extérieure est réellement découpée autour des salles, à hauteur des
murs, avec un espace de sol brut. Cette ouverture suit chaque creusement.
Échap ou Retour Android ferme le choix en cours ou ouvre la pause.
L'intégration et ses limites sont décrites dans
[le relevé de la Forge](docs/gameplay/forge-integration-2026-10-25.md).
La sauvegarde `user://isometric_run_v1.save` ne remplace pas celle de l'ancien jeu.
Le démarrage principal défini localement dans `project.godot` est conservé.

## Ouvrir les scènes

Ouvrir `project.godot` dans Godot.

- **F5** : la scène de démarrage choisie dans les réglages locaux du projet.
- **F6** : lancer la scène sélectionnée.
- **MobileReference** : le cœur sculpté, deux torches et trois décors rituels.
- **DungeonDecorations** : les six décors rituels et leurs ombres.
- **DungeonTraps** : Pointes, Entrave et Néant en lignes, états prêt/déclenché/épuisé
  en colonnes. Les neuf exemples sont figés, avec leurs dalles et mécanismes de
  production. Ouvrir `scenes/DungeonTraps.tscn`, puis **F6** ; glisser déplace la vue.
- **SixRoomPreview** : six salles, couloirs de deux cases de large, entrée par escalier et cœur.
- **WireframeDoorCross** : les quatre orientations de portes.
- **WireframeClosedCorridors** : salle avec quatre couloirs et escaliers terminaux.
- **EntranceVariants** : les quatre escaliers avec le même kit que les salles.
- **DungeonHeart** et **DungeonTorch** : décors isolés dans la même projection.

Les études de salles 1×1, 2×2, 3×3 et 5×5 et les couloirs restent disponibles.
Dans l'éditeur, sélectionner **Dungeon → Actualiser le rendu** après la fin de
l'import. Le catalogue et l'atlas sont rechargés ensemble ; les réimports suivants
actualisent l'aperçu. Les grandes scènes s'explorent en déplaçant la vue.

Les 20 scènes de salles/couloirs activent les variantes et dégâts des dalles.
Dans le nœud **Dungeon**, **Floor Damage** active ces dégâts et **Floor Damage Seed**
change leur répartition stable. **Floor Corruption** active la corruption ; portes,
escaliers et supports du cœur sont exclus. Les anciens overlays Surface Details
ont été retirés. Les props isolés et la planche des escaliers restent nus.

## Où sont les sprites ?

| Dossier | Contenu |
| --- | --- |
| `assets/dungeon/isometric-kit/` | Atlas et catalogue peints actifs |
| `assets/dungeon/mobile-kit/` | Ancien kit peint conservé ; petite texture de lumière partagée |
| `assets/dungeon/shared-materials/` | Matières et recettes peintes de référence |
| `assets/dungeon/bedrock/` | Trois matières de roche pour l'extérieur découpé |
| `assets/ui/forge/` | Pierre extensible et icônes peintes de la Forge |
| `assets/ui/black-gold/` | Ancien habillage et symboles utilitaires encore réutilisés |
| `docs/reference/isometric-review/painted-v1/` | Sprites peints, guides magenta, superpositions, recette et captures |
| `docs/reference/isometric-review/migration-v1/` | Géométrie et revue wireframe conservées |

Les sources et apparences approuvées restent conservées ; aucune n'a été régénérée.
Le cœur réutilise ses sculptures sur le support isométrique et son vortex face à
la caméra : c'est une adaptation de l'apparence, à examiner dans cette nouvelle vue.
Voir [l'inventaire des assets](assets/dungeon/README.md) et [l'historique du nettoyage](docs/cleanup/README.md).

## Reproduire les sprites

Avec Node.js et `sharp` disponibles, depuis la racine :

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
```

Les anciens exporteurs, dont `export_mobile_kit.cjs`, reconstruisent les étapes
historiques. Ils ne mettent pas à jour le catalogue isométrique actif.

## APK Android jouable

`tools/prepare_android_game.cjs` prépare une copie isolée du jeu courant dans
`artifacts/`, avec les ressources chargées dynamiquement, les réglages d'import
Android et le preset `tools/android-game-export.cfg`. Le preset historique
`Android Mobile` reste réservé au kit visuel.

```powershell
node tools/prepare_android_game.cjs
$stage = (Get-Content build/android-game-inventory.json -Raw | ConvertFrom-Json).staging
# Remplacer godot par le chemin de Godot 4.7.2 si nécessaire.
godot --headless --path $stage --editor --import
godot --headless --path $stage --export-debug "Android Game" "$PWD/build/dungeon-empire-0.1.3-test.apk"
```

Les modèles Android correspondant à la version de Godot, le JDK et le SDK Android
doivent être installés et configurés dans Godot. Cet APK de test signé couvre
ARM64/ARMv7 en portrait et paysage, Android 7.0 minimum. Activez la rotation
automatique du téléphone pour basculer en tournant l'appareil ; son verrouillage
d'orientation reste respecté. Le HUD se réorganise en conservant la partie,
le centre de la caméra et l'outil sélectionné. Un geste interrompu par la rotation
est annulé pour éviter une activation au relâchement.

La signature et le démarrage natif
des ressources extraites de l'APK ont été vérifiés ; aucun essai sur téléphone
ni profilage Android n'a encore été effectué. APK et inventaire restent ignorés
par Git dans `build/`. La clé de signature n'est pas ajoutée au dépôt.

## Capturer un aperçu

```powershell
godot --path . --script res://tools/capture_mobile_kit.gd
node tools/prepare_isometric_migration_review.cjs
```

Les images sont dans `docs/reference/isometric-review/painted-v1/captures/`.
Les quatre pages du kit peint pèsent **2 015 739 octets PNG**, soit environ
**1,92 Mio**, et **12 Mio RGBA** sans mipmaps. La quatrième page contient les cadres
des portes ouvertes ; les trois pages précédentes restent inchangées. Aucun profilage sur téléphone effectué. Ces commandes
produisent des aperçus, pas une suite de tests.

Suivre [la recette de migration peinte](docs/reference/isometric-review/painted-v1/README.md)
pour exporter le kit visuel depuis une copie propre. L'exporteur du kit couvre
les 24 scènes de présentation ; il n'est pas encore un export mobile du jeu.
La dernière intégration visuelle est celle des
[trois pièges et de leurs états](docs/reference/trap-review/v7-integrated-paint/index.html).

## Documentation

- [Kit isométrique peint : recette, export, mesures et limites](docs/reference/isometric-review/painted-v1/README.md)
- [Projection approuvée](docs/reference/isometric-review/wireframe-v1/selection.json)
- [Règles et état implémenté](GAME_DESIGN.md)
- [Placement et catalogue Godot](docs/reference/PAINTED_GODOT.md)
- [Construction des wireframes](docs/reference/WIREFRAME_WORKFLOW.md)
- [Matières et composition hors ligne](docs/reference/MATERIAL_WORKFLOW.md)

Les sections anciennes des documents de conception et des notes de revue sont
historiques ; leurs anciennes projections et chemins ne décrivent pas le kit actif.
