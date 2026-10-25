# Murs A/C/F intégrés — 25 octobre 2026

L'utilisateur a demandé « ok implémente ces murs », puis a signalé des coloris
trop tranchés. Les neuf propositions sont intégrées dans les vingt scènes de
disposition, avec la palette commune du mur nu. Les sources sélectionnées restent
intactes ; les sprites sont des adaptations sur les supports isométriques.

- A1–A3 : maçonneries différentes ; C1–C3 : reliefs peu profonds avec géométrie.
- F1–F3 : couche facultative avec son fond de pierre, dessinée après un mur nu.
  Elle ne se combine pas aux reliefs et conserve les accents violets. La couper
  laisse le même mur nu ; cela ne sélectionne pas un nouveau relief.
- Les deux orientations et les quatre profils de pilier donnent 72 régions :
  48 structures et 24 couches F. Hauteur, extrémités et supports de base conservés.
- Répartition déterministe par coordonnées/graine, accents espacés, murs sobres
  près des torches et des portes/escaliers. Des murs nus conservent les anciens
  décors de fissures. Ceux-ci ne traversent pas les nouveaux joints/reliefs.
- Inspecteur : `wall_variants`, `wall_variant_seed` (17), `wall_corruption`.
  Les plans et scènes de revue non activés gardent le rendu précédent.

## Correction des coloris

Les dessins sources avaient des luminosités différentes : médiane des façades
A1 49, C1 46, C3 59,7 contre 39,6 pour le mur de base. Le premier rendu reproduisait
ces écarts. `isometric_wall_palette.cjs` harmonise hors ligne la distribution de
luminosité et la teinte de chaque plan avec le mur existant. Les accents violets
sont conservés ; aucun détourage ni changement des sources/alphas n'est effectué
par cet étalonnage. Les faces sont toujours projetées et masquées géométriquement
par l'exporteur, comme le reste du kit.

`palette-v2/comparison.png` compare exactement le même couloir avant/après.
`palette-v2/before/` conserve les premières captures, le catalogue, l'atlas et le
générateur. La palette initiale est rejetée ; ne pas la réintégrer.

## Vérifications et taille

`prepared-comparison.png` présente les deux orientations et leurs guides vifs.
Les captures `variant-*-native/close.png` montrent tous les profils dans Godot.
`reference-seed17.png` est le rendu courant de MobileReference. Les autres
captures sont dans `captures/` et `editor-captures/`.

- 43 anciennes régions : RGBA et métadonnées hors coordonnées d'atlas identiques.
- 13 références de sélection inchangées ; 72 profils gardent hauteur/extrémités.
- Rétablir la graine 17 produit exactement la même image. SixRoomPreview utilise
  les neuf motifs. Désactiver la corruption retire ses couches sans nouveau relief.
- Import, 24 captures ciblées, 68 captures runtime/23 scènes : sortie 0, stderr vide.
- 19 captures éditeur/5 scènes : sortie 0 ; 1 520 octets de diagnostics natifs
  de fenêtre/progression et ressources à l'arrêt, comme avant. Stderr non vide.
- 115 régions, atlas 1024×2048, 1 430 732 octets PNG, 8 Mio RGBA sans mipmaps.
  Les nouveaux profils ont une densité .75 ; le cadre logique reste inchangé.
- Export de ressources : 50 dépendances/23 scènes, ZIP 1 192 581 octets.
  Import de la copie propre, export et démarrage isolé OpenGL : sortie 0, stderr vide.
- Revue indépendante de code/pixels/captures : aucun défaut concret relevé.

Ce n'est pas un APK ni un profilage sur téléphone. Aucun nouveau test automatisé,
commit ou push. L'appréciation artistique du résultat appartient à l'utilisateur.

Reproduire : `export_isometric_painted_kit.cjs`, import Godot,
`capture_isometric_wall_variants.gd`, puis `prepare_isometric_wall_variants_review.cjs`.
Utiliser `capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-wall-variation-review/v2-subvariants/integration`
pour conserver les anciennes captures de validation.
