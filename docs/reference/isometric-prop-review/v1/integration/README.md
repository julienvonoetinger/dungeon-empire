# Six décors intégrés dans Godot

La sélection « Tous », puis l’autorisation « ok vas-y », sont appliquées.
Les six sources originales sont conservées. Les sprites sont préparés hors
du jeu, ajoutés à l’atlas commun et placés dans la même projection 2:1.

## Voir le résultat

- `scenes/DungeonDecorations.tscn` : les six décors réunis, zoom fixe 0,75 et
  déplacement libre comme les autres scènes.
- [Capture à l’échelle mobile](gallery-mobile.png).
- [Exemples autour du cœur](DungeonPreview-heart-room.png).
- [MobileReference](MobileReference-native.png) : cristaux, idole et cierges.
- [Mur arrière et mur devant la stèle](wall-order-negative-coordinates.png).

`DungeonPreview` et `SixRoomPreview` présentent les six objets dans la salle du
cœur. Ces placements sont écrits dans les scènes, pas distribués aléatoirement.
Les autres scènes gardent leur composition ; le catalogue est accessible partout.

## Placer un décor

Sur le nœud `Dungeon`, `decoration_positions` associe un centre au sol (coordonnées
logiques, y compris fractionnaires) à un identifiant :

| Identifiant | Décor |
| --- | --- |
| `prop-crystals` | Cristaux corrompus |
| `prop-idol` | Idole de pierre |
| `prop-stele` | Stèle rituelle |
| `prop-basin` | Vasque d’offrandes |
| `prop-grimoire` | Grimoire scellé |
| `prop-candles` | Cierges rituels |

Exemple : `Vector2(0.65, 0.65): "prop-crystals"`. Le bouton **Actualiser le rendu**
reconstruit l’aperçu. Les setters rafraîchissent la scène ; après une modification
en place d’un dictionnaire par script, appeler `refresh_preview()`.

`decorations_enabled` masque les décors, leurs ombres et leurs lumières.
`decoration_lights_enabled` contrôle la petite lumière des cierges, indépendamment
des torches. Les autres accents violets sont peints dans les sprites, sans
lumière dynamique supplémentaire.

Un placement sans sol, sur une case de porte/escalier, ou chevauchant le support
d’un mur, du cœur ou d’un autre décor est ignoré avec un avertissement. Les
positions sont triées pour garder une priorité stable si deux décors se recouvrent.
Cette vérification organise le rendu ; elle n’ajoute pas de collisions de gameplay.

## Géométrie, sources et ombres

Les illustrations restent dans leur vue sélectionnée. Pas de rotation à l’écran,
miroir, déformation indépendante des axes, nouvelle génération ou retouche.
L’alpha natif est conservé, seules les marges entièrement transparentes sont
recadrées ; la taille est réduite uniformément.

Les contours inférieurs mesurés sur les sources déterminent les points d’appui.
Ils sont convertis en coordonnées au sol avec l’inverse de la projection commune.
Les [guides](guides/) montrent ce contact et l’enveloppe utilisée pour le tri.
Ce sont des volumes approximatifs de placement, pas une reconstruction 3D exacte
des sculptures. La vue peinte reste celle que l’utilisateur a sélectionnée.

Chaque objet reçoit une petite ombre de contact et un court prolongement orienté
suivant la lumière ambiante peinte. Ces images sont préparées à l’avance, limitées
au sol receveur et dessinées avant les objets et les murs. Elles ne simulent pas
les ombres de chaque torche. La lumière des cierges utilise le système local
existant, sans nouvelle animation ni occlusion dynamique de la lumière.

## Taille et vérification

- Atlas : **120 régions, 1024×2048, 1 566 183 octets PNG, 8 Mio RGBA**.
- Ajout : **62 070 octets PNG**, aucune augmentation de la mémoire de l’atlas.
- Les six décors sont stockés à 75 % de leur taille logique ; les ombres à 50 %.
- Les **108 anciennes régions** gardent leurs pixels RGBA et leurs métadonnées
  hors coordonnées de rangement. Les **12 références sélectionnées** gardent
  leurs empreintes exactes.
- 13 captures ciblées, puis 70 captures d’exécution sur 24 scènes : code de
  sortie 0. Les six avertissements ciblés correspondent aux placements invalides
  volontairement montrés. L’exécution des scènes normales ne produit pas de stderr.
- 17 captures d’éditeur sur cinq scènes : sortie 0. La seconde passe conserve
  1 519 octets de diagnostics natifs de fenêtre/ressources à la fermeture.
  Une erreur de résolution d’un ancien outil apparue à la première passe ne se
  reproduit ni en analyse syntaxique isolée ni dans la seconde passe ; premiers
  journaux conservés. Aucun ancien outil ni cache utilisateur n’a été effacé.
- Export de ressources : 53 dépendances, 24 scènes, ZIP de 1 324 453 octets.
  Import/export en dossier séparé et démarrage du paquet réussis. Ce n’est ni
  un APK ni une mesure de performance sur téléphone.
- Revue indépendante ciblée : aucun défaut concret signalé.

L’export réutilise le remplacement atomique existant pour écrire les variantes
de murs/sols : les écritures directes étaient refusées sur des PNG ouverts sous
Windows. Cette correction ne change aucun pixel des anciennes régions.

Reproduction : `node tools/export_isometric_painted_kit.cjs`, import Godot,
`tools/capture_isometric_ritual_props.gd`, puis
`node tools/prepare_isometric_ritual_integration.cjs`. Les captures générales
emploient `tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-prop-review/v1/integration`.
Les sources et planches sélectionnées restent figées dans le dossier parent.
Aucun test automatisé, commit ou push effectué.
