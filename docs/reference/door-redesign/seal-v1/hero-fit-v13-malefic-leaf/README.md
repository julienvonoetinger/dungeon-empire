# Battant maléfique — ferrures unifiées

Le 28 octobre 2026, l’utilisateur trouve le battant v12 trop plat et demande de retrouver son aspect menaçant. Après un premier sceau séparé des gonds, il demande de réunir les gonds et la croix métallique en une armature proche d’un « # ». La source finale présente deux traverses reliées aux deux gonds, deux montants pointus, un sceau violet et une vraie serrure noire. Cette proposition est intégrée pour inspection ; son apparence finale reste à valider par l’utilisateur.

## Sources et invariants

- `source/face-source.png` : sortie native ImageGen, 1024 × 1536 RGBA. Copie sans modification de `exec-ac003acf-8656-40e1-b9f2-306c2b22bb50.png` ; générateur intégré, pas de CLI.
- `source/unified-frame-prompt.txt` : consigne finale exacte. La seule entrée était `source/cross-separate-hinges.png`, première proposition conservée, avec sa propre consigne `source/prompt.txt`.
- Première génération : v12 comme cible, v7 comme référence stylistique. Ancienne image menaçante : `../painted-v7-clean-leaf/source/face-source.png`. Le style ne rétablit pas ses anciennes dimensions.
- `selection.json` conserve toutes les sources v12 de géométrie, pierre, palette, gonds et projection. Seul `leafPainting` change. `tools/isometric_seal_texture.cjs` l’applique exclusivement aux faces `leaf*` du récepteur lisse. Les ferrures ne sont pas ajoutées au wireframe.
- Géométrie v11/v12 exacte, hauteur 1.16, passage .96 × .63, raccords inchangés. UV uniforme existant, source de contact (512,1138), serrure Z=.32. Le pixel de contact final est (1,0,0,253). Aucun déplacement du héros ni modification de ses animations.
- La pierre vient toujours de la source v12 : d’éventuelles variations de pierre dans la nouvelle illustration ImageGen ne sont jamais utilisées.

## Vérification

`validation.json` compare le kit à son état v12 enregistré avant modification dans `before.json`. Les 159 identifiants et toutes les métadonnées/positions d’atlas sont identiques. Les 151 sprites autres que les huit parties des portes fermées sont identiques pixel à pixel, y compris les huit cadres ouverts. Les quatre silhouettes complètes sont inchangées ; hors récepteur du battant et voisinage de filtrage de 3 pixels, les rendus sont identiques. Les 37 ressources PNG/TRES/JSON des héros sont inchangées.

Kit PNG : 2 094 094 → 2 107 174 octets (+13 080). Allocation RGBA : 13 631 488 octets inchangés. Aucune nouvelle page de texture.

Import et captures Godot : code 0, stderr vide. `native-sizing/validation.json` : quatre orientations, 32 contacts de crochetage, 64 poses de passage, zéro échec. Captures rapprochées et vues orientées inspectées. Les preuves v12 restent intactes.

## Reproduction

Depuis la racine, avec Node et le module `sharp` disponibles :

```powershell
node tools/prepare_ritual_door_leaf.cjs
node tools/export_isometric_painted_kit.cjs
node tools/verify_door_leaf_refresh.cjs
godot --headless --editor --path . --import
godot --path . --script res://tools/capture_integrated_compact_door.gd --rendering-method gl_compatibility -- --output=res://docs/reference/door-redesign/seal-v1/hero-fit-v13-malefic-leaf/native-sizing
```

Le mode `--record` du vérificateur n’est destiné qu’à l’enregistrement initial du kit v12 ; il refuse d’écraser la référence existante. Ne pas le relancer pour accepter une régression.

Limites : captures sur ordinateur, pas de validation sur téléphone. Les gonds sont peints ; les portes ouvertes gardent un cadre sans battant, sans animation de pivot. Aucune modification de sauvegarde joueur, des règles, des sprites du héros, ni création d’APK. Pas de commit ou push dans cette étape.
