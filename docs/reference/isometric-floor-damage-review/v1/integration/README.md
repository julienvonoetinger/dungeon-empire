# Quatre décors de dalles B intégrés

L’utilisateur a accepté les quatre propositions avec « ok ajoutes les ».
[selection.json](../selection.json) fige les neuf fichiers de référence.

Les variantes A (fissures courtes), B (fracture ramifiée), C (veine violette) et
D (racines dans le joint avec un petit cristal) sont intégrées dans le catalogue
commun. [Comparaison des quatre décors](prepared-comparison.png),
[avant/après en scène](scene-comparison.png), [capture MobileReference](reference-seed17.png).

Les pierres peintes dans les sources approuvées sont adaptées aux rectangles
existants des assemblages B. La géométrie, la palette de fond et les raccords du
sol restent ceux du kit. Il s’agit d’une adaptation aux petites pierres réelles,
pas d’une copie complète des concepts. Aucune source artistique n’a été régénérée.

## Préparation et placement

`tools/isometric_floor_damage.cjs` prépare quatre petits sprites avec leur fond de
pierre, chacun réservé à son assemblage B. Les pixels et marges sont documentés
dans `prepared.json`. La variante D prolonge les mêmes coordonnées de texture
sur un joint intérieur pour conserver sa racine et son cristal. Le fond du joint
est calibré sur la pierre pour éviter de doubler l’assombrissement du mortier.

Les pixels modifiés restent à au moins .10 case du périmètre. Le masque du décor
s’arrête à l’intérieur du sol, avec une transition .06–.085 ; il ne recouvre jamais
les pixels semi-transparents du contour original. Le recadrage garde deux pixels
de couleur inchangée pour le filtrage. Ce masque corrige un défaut découvert lors
de la relecture : un simple recadrage rectangulaire répétait l’alpha du bord.

`dungeon_floor_damage.gd` choisit une fois à la reconstruction, à partir des
coordonnées logiques et de la graine. La corruption est plus rare que les
fissures. Les huit voisins immédiats ne portent pas d’autre accent sélectionné.
Les cases spéciales et l’emprise XY du véritable socle du cœur sont exclues.

Les vingt scènes de disposition activent `floor_damage`. Le script et les anciens
plans de revue restent désactivés par défaut. `floor_damage_seed=17` et
`floor_corruption` sont disponibles dans l’inspecteur. Le décor est dessiné juste
après sa dalle B correspondante, avant les ombres et tous les objets. Pas de
nouveau traitement par frame ni de pixels créés par Godot.

## Vérifications

- 104 régions antérieures identiques en RGBA et métadonnées hors rangement.
  Neuf empreintes de sélection inchangées ; quatre sprites préparés retrouvés dans l’atlas.
- Recomposition réelle sol + décor : alpha identique, écart RGB maximal1/255
  dû à l’arrondi de composition. Aucun décor sur un pixel translucide du contour.
  107 424 pixels de périmètre vérifiés inchangés ; 6 565 pixels de couleur modifiés.
- Onze captures ciblées : échantillons des quatre variantes, grille à coordonnées
  négatives, changement et restauration de graine, désactivation, et scènes.
  Restaurer17 reproduit les images à l’identique ; l’ordre du dictionnaire ne
  change pas le choix. Dalles propres et placements des autres éléments identiques.
- SixRoomPreview : 38 accents sur256 cases (A13, B16, C4, D5). MobileReference :
  deux accents avec la graine17. La répartition reste une proposition artistique
  dont le rendu intégré est présenté à l’utilisateur.
- Import, 68 captures runtime/23 scènes, import/export isolés et démarrage du paquet :
  sortie0, stderr vide. Éditeur : 19 captures/cinq scènes, sortie0, avec1520 octets
  de diagnostics natifs de fenêtre et de libération des ressources.
- Relecture indépendante ciblée : correction de l’alpha et conservation de la
  racine D vérifiées ; aucune autre anomalie concrète restante. Les valeurs des
  masques D ont aussi été corrigées dans la provenance, sans modifier les pixels.

L’atlas contient **108 régions**, **1024×2048**, **1 504 113 octets PNG**, **8 Mio RGBA**.
L’ajout représente41 098 octets PNG et aucune augmentation de mémoire RGBA.
Le paquet de ressources fait **1 271 254 octets**, avec52 dépendances pour23 scènes.
Ce paquet n’est pas un APK ; aucun profilage sur téléphone n’a été effectué.

Reproduction : exporter avec `tools/export_isometric_painted_kit.cjs`, importer
dans Godot, capturer avec `tools/capture_isometric_floor_damage.gd` et
`tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-floor-damage-review/v1/integration`,
puis préparer les planches avec `tools/prepare_isometric_floor_damage_integration.cjs`.
`pixel-validation.json` et `validation.json` contiennent les observations finales.
`before/` conserve l’état précédent. `prepared-inspection.png` et `source-mapping.png`
sont des diagnostics intermédiaires ; les planches finales sont celles liées plus haut.

Aucun test automatisé ajouté/exécuté, aucun commit ou push.
