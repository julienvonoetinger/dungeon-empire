# Dungeon Empire — base 2D

Une carte fixe de six salles reliées par des couloirs, avec entrée et cœur du
donjon. Le rendu utilise des sprites complets à transparence native : sols,
murs, piliers, raccords, porte, torches et cœur. Aucun gameplay n'est implémenté.

**Rendu en correction :** l'assemblage actuel des murs et piliers a été rejeté
visuellement le 21 octobre 2026. La transparence native est implémentée, mais la
perspective et la fidélité au dessin d'origine restent à corriger. Les captures
et tests techniques ne constituent pas une approbation de cette apparence.

## Lancer

Ouvrir `project.godot` dans Godot puis **F5**.
La configuration courante de **F5** lance `scenes/3x3CellRoom.tscn`.
La carte à six salles reste dans `scenes/SixRoomPreview.tscn`.
La caméra affiche la carte entière en conservant ses proportions.

- **Stone Variation** et **Variation Seed** se règlent sur le nœud `Dungeon`.
  Valeurs par défaut : activé, graine **173**.
- L'aperçu éditeur s'actualise lors des changements ; **Actualiser le rendu**
  permet une reconstruction manuelle.
- **F6** lance la scène sélectionnée, notamment les études séparées ci-dessous.

Pour les études modulaires, le bouton **Actualiser le rendu** du nœud `Dungeon`
fournit sa fonction via un getter afin de rester valide après rechargement des
scripts. Si un ancien onglet affiche encore un aperçu vide ou l'erreur
`refresh_action is Nil`, fermer puis rouvrir cet onglet après la mise à jour.

## Inspecter les positions

### Salles et couloirs — études des raccords

Ouvrir une de ces scènes dans Godot, puis **F6** :

| Salles fermées | Couloirs ouverts dans leur axe |
| --- | --- |
| `scenes/1x1CellRoom.tscn` | `scenes/1x2Corridor.tscn` — nord/sud |
| `scenes/2x2CellRoom.tscn` | `scenes/2x1Corridor.tscn` — ouest/est |
| `scenes/3x3CellRoom.tscn` | `scenes/1x3Corridor.tscn` — nord/sud |
| | `scenes/3x1Corridor.tscn` — ouest/est |

L'ancienne `SingleCellRoom.tscn` a été renommée **2x2CellRoom**. Une case logique
contribue deux rangées de petites dalles de largeurs variées. Tous les cas
partagent les mêmes coins, murs et variantes : douze dalles dans trois formats,
dont six fissures différentes, et quatre dessins de brique dans deux longueurs.
Le sol conserve ses formats et fissures variés, avec des surfaces plus lisses,
plus unies et sans gravure centrale. La palette de l'ensemble est assombrie et
désaturée d'après le concept. Les pierres horizontales gardent leur épaisseur ; les deux
rangées de façade passent en continu sous les coins et les chapeaux, à joints
décalés. Les côtés utilisent des contours noirs renforcés et une matière reprise
d'après les coins, sans grosse face sombre répétée sous chaque pierre.
Le placement par paires superposées est remplacé par un remplissage entre les
extrémités des coins, partagé avec les couloirs.

**Point de retour avant palette : `2584f57`.** Les neuf nouvelles images et
leurs prompts ImageGen sont répertoriés dans
`assets/dungeon/modular-study/calm-palette-generation.json`. Tous les sprites
modulaires utilisent une modulation blanche ; les couleurs et l'assombrissement
des supports sont peints dans les PNG. Les captures précédentes sont conservées
dans `artifacts/palette-before/`. La nouvelle palette reste à apprécier visuellement.

Les images conservent leur alpha natif et leurs proportions. Aucun sprite
ne contient une salle complète.

**Nouvelle étude des raccords :** ouvrir `scenes/3x3RoomFourCorridors.tscn`,
puis **F6**. Par défaut, la salle 3×3 a quatre couloirs centrés, ouverts au bout,
de longueur logique **3 à gauche/droite et 4 en haut/bas** pour examiner la
continuité. `vertical_corridor_length=4` ajoute une case aux branches verticales ;
zéro reprend la longueur commune (défaut du script : 2).
`connections` active chaque direction (N1/E2/S4/W8,
défaut15) ; `corridor_length` va de 1 à 3. Leur modification reconstruit le rendu.
Les arêtes exposées et les angles sont déduits des cases occupées.

**Comparaison 5×5 :** ouvrir `scenes/5x5RoomFourCorridors.tscn`, puis **F6**.
Même assemblage et mêmes longueurs de couloir que la 3×3 ; seule la ressource
de plan change. Les douze coins exposent notamment les raccords avec des
portions droites plus longues. Captures :

```powershell
godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomFourCorridors
```

Voir `artifacts/5x5RoomFourCorridors.png`, `-2x.png` et
`5x5RoomFourCorridors-corners-comparison.png` pour les douze coins à ×4.
Cette étude reste à valider visuellement.

**Quatre couloirs horizontaux aux coins :** ouvrir
`scenes/3x3RoomCornerCorridors.tscn`, puis **F6**. La salle 3×3 utilise les mêmes
scripts, avec `horizontal_attachment_rows=[0,2]`, `connections=10` et longueur3.
Deux passages partent vers la gauche et deux vers la droite. La liste vide
garde le placement central des autres scènes.

```powershell
godot --path . --script tools/capture_room_corridors.gd -- --scene=3x3RoomCornerCorridors
```

Voir `artifacts/3x3RoomCornerCorridors.png`, sa version `-2x.png` et
`3x3RoomCornerCorridors-corners-comparison.png`. Les deux murs intérieurs opposés
utilisent maintenant un **séparateur commun**, avec un seul dessus large et une
terminaison maçonnée complète vers la salle. Ses deux pierres de dessus et ses
deux assises sont réunies dans le même sprite ; la façade descend verticalement,
avec un bord fermé aligné du dessus au pied. La façade droite s'arrête à son bord
de connexion. Les anciens bouts plats ont été rejetés pour leur effet de
« rideau », puis les bouts à face oblique pour leur perspective. La règle détecte une bande vide d'une case
dans le contour et remplace les anciens coins et chapeaux superposés. Les deux
nez sont capturés à ×4. Les nouveaux sprites gardent leur alpha natif ; aucune
découpe ou superposition de bouts peints ne fabrique la jonction.
L'approbation visuelle de cette nouvelle version reste à recueillir.

**Même disposition en 5×5 :** ouvrir `scenes/5x5RoomCornerCorridors.tscn`, puis
**F6**. Les quatre couloirs horizontaux de longueur 3 se raccordent aux rangées
0 et 4, avec les mêmes sprites et le même assemblage partagé. Capturer avec
`godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomCornerCorridors`.
Voir `artifacts/5x5RoomCornerCorridors.png`, `-2x.png` et
`5x5RoomCornerCorridors-corners-comparison.png`. Étude à valider visuellement.

**Couloirs verticaux aux coins de la 5×5 :** ouvrir
`scenes/5x5RoomVerticalCornerCorridors.tscn`, puis **F6**. Deux couloirs partent
vers le haut et deux vers le bas, aux colonnes 0 et 4, longueur 3, bouts ouverts.
Le réglage partagé est `vertical_attachment_columns=[0,4]`, `connections=5`.
Capturer avec `godot --path . --script tools/capture_room_corridors.gd -- --scene=5x5RoomVerticalCornerCorridors`.
Voir `artifacts/5x5RoomVerticalCornerCorridors.png`, `-2x.png` et
`5x5RoomVerticalCornerCorridors-corners-comparison.png`. Les raccords restent
à valider visuellement.

Les angles en L dédiés remplacent les carrés rejetés. Les murs droits utilisent
les mêmes échelles, espacements et assises que les sept petites scènes. Les
couloirs latéraux prolongent les rangées de la salle sans recouvrir ses dalles.
Les petites entretoises entre les angles sont supprimées. Les courts retours
utilisent `paired-cap-square-v7.png`, une assise complète à quatre pierres
et deux coudes. Leurs deux centres verticaux sont désormais recalés ensemble
sur les ports logiques ; les extrémités utilisent le même transform uniforme.
Les angles individuels compatibles utilisent `cap-elbows-square-v7.png`.
Les côtés utilisent les deux paires de `cap-tight-v13.png`, les deux paires
compactes de `cap-compact-pairs-v24.png` et `wall-tight-v22/v23.png`.
Les paires compactes corrigent les carrés isolés de la2×2 ; la largeur commune
des raccords aux coins fermés est fixe à101 unités source. Le kit choisit ces
modules selon la longueur disponible, sans condition sur le nom de scène.
Prompts ImageGen, source et captures : `compact-pairs-generation.json`.
Les longueurs complémentaires remplacent les extrémités trop noires de
v17/v18. Les coins fermés viennent de cap-square-v3 ; les chapeaux droits
gardent cap-muted-v11. La v16 avait été écartée pour sa couleur et sa largeur.
Les salles et passages isolés ou raccordés partagent la composition des longueurs
à largeur fixe : remplir un mur plus long ne change plus la largeur des pierres.
Le dallage reste inchangé.
Les extrémités des coins prolongent la pierre bleue jusqu'au bord extérieur.
Les essais qui comblaient le biseau avec une plaque noire sont écartés.
Prompts, variantes et ports : `assets/dungeon/modular-study/square-corners-generation.json`.
La capture `artifacts/5x5RoomVerticalCornerCorridors-north-span-2.5x.png`
montre les deux extrémités du mur au-dessus de leurs assises.
Les façades commencent désormais à 96 unités source au nord et 105 au sud,
sous le pied peint des chapeaux, pour conserver la première brique entière.
Les captures `artifacts/3x3CellRoom-west-4x.png` et
`artifacts/3x3CellRoom-southwest-4x.png` montrent les deux raccords signalés.
Prompts, régions et variantes écartées :
`assets/dungeon/modular-study/port-width-generation.json`.
La correction des contours et du chevauchement est consignée dans
`assets/dungeon/modular-study/tight-joints-generation.json`.
Le rendu reste à apprécier visuellement ; il ne valide pas des plans arbitraires.
Les bras natifs des angles ajoutent une transition à la longueur des modules
droits ; le calage d'une future grille de construction reste à définir.
Il n'y a pas encore d'éditeur joueur ni de rendu complet pour plans arbitraires.

Captures : `godot --path . --script tools/capture_room_corridors.gd`.
Voir `artifacts/3x3RoomFourCorridors.png`, sa version `-2x.png` et ses quatre
jonctions `-{north,south,west,east}-4x.png`.
Les détails `-west-floor-4x.png`, `-corridor-wall-foot-4x.png` et
`-corner-style-4x.png` ciblent les trois problèmes signalés.
`godot --path . --script tools/capture_module_connections.gd` produit aussi :

- `junction-perspective-comparison.png` : carrés rejetés / angles en L ;
- `junction-continuity-comparison.png` : entretoises et angles gris / retours actuels ;
- `junction-profile-comparison.png` : marches et débords / calage des profils ;
- `wall-profile-shared-comparison.png` : couloir 2×1 / couloir raccordé, à ×4 ;
- `junction-native-parts-comparison.png` : retour inférieur avant/après, à ×4 ;
- `vertical-material-comparison.png` : matière des murs verticaux avant/après, à ×4 ;
- `junction-all-returns.png` : les quatre retours courts en entier, à ×4 ;
- `junction-ports-west-upper-return-comparison.png` et `junction-ports-west-lower-return-comparison.png` : largeur/alignement avant et après ;
- `junction-ports-north-comparison.png` et `junction-ports-south-comparison.png` : coins et branches verticales avant et après ;
- `connection-masks-comparison.png` : les 16 combinaisons de directions ;
- `connection-lengths-comparison.png` : longueurs 1, 2 et 3 ;
- `connections/rebuild-roundtrip.png` : fermeture et réouverture sur la même instance.

```powershell
godot --path . --script tools/capture_modular_room.gd
```

Cette commande capture uniquement le rendu, sans sondes ni assertions :

- `artifacts/cell-rooms-comparison.png` : les trois salles à la même échelle ;
- `artifacts/corridors-comparison.png` : les quatre couloirs ;
- `artifacts/<NomDeScene>-2x.png` : vue agrandie ;
- `artifacts/<NomDeScene>-{west,east,north,south}-4x.png` : détails des raccords.

Ces études restent à apprécier visuellement et se lancent séparément avec **F6**.
PNG et prompts : `assets/dungeon/modular-study/`.

### Étude visuelle de la référence

Ouvrir `scenes/ReferenceCalibration.tscn`, puis **F6**, pour voir la portion de
salle en cours de recalage. Cette étude n'est pas encore approuvée. Elle utilise
des sprites complets à transparence native et ne remplace pas la carte F5.
Les captures sont dans `artifacts/reference-calibration.png`,
`reference-calibration-2x.png` et `reference-calibration-comparison.png`.
L'arche et les pierres environnantes forment désormais un module de maçonnerie
commun ; le vantail séparé se place derrière ses embrasures. Les pieds avancent
sur les dalles. `door-masonry-comparison.png` montre l'original, l'état précédent
rejeté et le rendu actuel ; `door-integration-opening.png` masque uniquement le
vantail. La capture ciblée contrôle l'ouverture, l'ordre de rendu, l'appui des
pieds sur le sol et le chargement des PNG :
`godot --path . --script tools/capture_reference_calibration.gd`.
La porte a été resserrée avec son arche ; `door-proportions-comparison.png`
montre l'original, la version trop large et le rendu actuel. Cette correction
concerne l'étude F6. Le contrôle de proportions complète la comparaison visuelle.
Le bois et les ferrures du battant ont ensuite été repeints pour harmoniser
leur traitement avec les pierres : voir `artifacts/door-style-comparison.png`.

### Sondes de la carte

Après F5, **F3** affiche **644 sondes** et rend **858 éléments** inspectables.

- Clic : origine, emprise, Z, PNG source, région d'atlas et UV locales.
- Filtres : sols, murs, piliers, entrée, cœur, lumières et effets.
- **R / Actualiser** recalcule ; **F3 / Échap** masque le diagnostic.
- **Exporter JSON** écrit `user://dungeon-probes.json` et affiche son chemin.

Les cadres représentent les sprites complets ; la sélection tient compte de
leur alpha. Les sondes vérifient des positions fixes et ne remplacent pas
l'inspection visuelle des raccords.

## Images et assemblage

`assets/dungeon/alpha-kit/` contient huit PNG utilisés et leur provenance dans
`generation.json`. `scripts/alpha_kit.gd` définit 27 sprites complets avec leurs
marges transparentes et leurs ancrages. La torche utilise son PNG partagé dans
`assets/dungeon/torches/`. `walls.png` est un brouillon inutilisé.

**Règle du projet : aucun détourage programmatique**, même préparé hors moteur.
Générer les variantes nécessaires avec leur véritable alpha, conserver leurs
proportions et assembler les images entières. Aucun masque de silhouette ni
shader de détourage n'est utilisé dans la scène principale.

Les corps des murs et leurs bords extérieurs sont des sprites indépendants.
Les bords s'arrêtent aux angles et façades ; les pierres du corps reprennent
au pied des piliers. Les motifs des colonnes sont placés sur leur face verticale.

| Fichier | Rôle |
| --- | --- |
| `assets/layouts/six_rooms.tres` | Plan fixe, grille et entrée |
| `scripts/alpha_kit.gd` | Catalogue de sprites entiers |
| `scripts/six_room_view.gd` | Assemblage, recouvrements, lumières et actualisation |
| `scripts/stone_variation.gd` | Choix de variantes et teintes reproductibles |
| `scenes/DungeonHeart.tscn` | Cœur transparent et lumière, instance préservée |
| `scenes/DungeonTorch.tscn` | Torche transparente et ancrage |
| `scripts/probe_fixtures.gd` | Positions attendues des sondes |
| `scripts/dungeon_probes.gd` | Inspection, sélection alpha et rapports |
| `scripts/probe_overlay.gd` | Interface F3 |
| `GAME_DESIGN.md` | Valeurs implémentées et limites |

## Vérifier

```powershell
./tools/test-mobile.ps1 -All
./tools/test-mobile.ps1 -All -Capture
```

La suite contrôle la transparence des sources, les régions d'atlas, les
proportions, le plan, les sondes, les variantes, l'actualisation dans un éditeur
isolé et le cadrage dans quatre formats. Des défauts temporaires sont injectés
pour vérifier les diagnostics.

`-Capture` ajoute les contrôles de pixels GPU et les captures réelles :

- `artifacts/dungeon-2d.png` : carte complète ;
- `six-room-details.png` et `vertical-wall-details.png` : détails ;
- `alpha-joins-2x.png` : raccords et murs latéraux à ×2 ;
- `wall-projection-comparison.png` : entrée et salle haute à la même échelle ;
- `entrance-seams-detail.png` et `heart-detail.png` : entrée et cœur à ×2 ;
- `stone-variation-before-after.png` : comparaison des variations ;
- `dungeon-probes.png`, `probe-wall-detail.png`, `probe-failure-example.png`
  et `dungeon-probes.json` : diagnostic et défaut volontaire ;
- `alpha-six_rooms-report.json`, `entry-seams-report.json`,
  `alpha-heart-report.json` : composition alpha GPU ;
- `reference-comparison.png` : étude historique de l'entrée, pas une comparaison
  de toute la nouvelle scène.

Les contrôles GPU comparent 599 points de carte, 3828 d'entrée et 2809 du cœur
à la composition attendue des sprites actuels. Ils ne prouvent pas à eux seuls
la fidélité artistique ; inspecter aussi les captures normales et à ×2.

Rendu GL Compatibility, vérifié avec Godot **4.7.2**. Utiliser `-Godot <chemin>`
ou `GODOT_BIN` si nécessaire. Les captures demandent une session graphique.

## Périmètre

La carte reste fixe, sans animation, interaction, sauvegarde ni génération.
Les autres dispositions et portes latérales nécessitent des variantes adaptées.
L'optimisation mémoire, les exports et les contrôles tactiles sur téléphone
restent à réaliser ; en portrait la carte entière est affichée à petite échelle.

`assets/dungeon/perspective/reference-atlas.png` conserve la référence artistique.
L'étude `PerspectiveRoom.tscn` garde son ancien assemblage de calibration ;
ce pipeline de découpe n'est plus utilisé par la scène principale.
Le prototype 3D reste dans Git au tag **v1.0.0**.
