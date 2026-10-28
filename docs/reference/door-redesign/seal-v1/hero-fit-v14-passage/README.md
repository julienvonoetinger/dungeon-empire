# Traversée de porte — montants indépendants

## Cause reproduite

Le 28 octobre 2026, l’utilisateur signale une mauvaise superposition pendant le passage. Les anciennes couches `leaf` et `arch` désignaient le bas et le haut de toute la porte, pas le battant et la pierre. Chacune réunissait les deux montants dans une boîte englobant le passage vide. Le héros ne pouvait donc pas être placé devant un montant et derrière l’autre. Les précédents contrôles de volume prouvaient que le modèle tenait dans l’ouverture, pas que la composition de sprites respectait cette profondeur.

`before-check.json` conserve les 24 échecs de partition et `before/validation.json` les quatre défauts de montants indépendants dans le rendu Godot. Les images avant/après utilisent la même texture v13.

## Correction

`tools/isometric_seal_door.cjs` répartit les pixels du rendu final en trois supports de pierre et un battant séparé quand la porte est fermée :

- montant gauche : identifiant historique `-leaf` conservé pour les raccords muraux ;
- haut de l’arche : `-arch`, au-dessus de Z=.92, conservé pour le badge ;
- montant droit : `-jamb-right` ;
- battant seul : `-panel`, absent de la porte ouverte.

Le wireframe complet et la texture ne changent pas. Les faces ne sont découpées que pour calculer les boîtes de tri ; aucune nouvelle surface visible n’est créée. Les pixels originaux sont répartis selon la face XYZ qui les possède, avec un chevauchement opaque de 2 pixels aux frontières pour éviter les lignes de filtrage. Les guides de couches montrent le découpage de rendu, pas un nouveau design de pierre.

Le catalogue fournit `companions` au support principal et `door_part` pour l’inspection. Le rendu mobile savait déjà ajouter les compagnons et les trier ; le jeu, ses badges et la scène de crochetage réutilisent ce chemin. Les cadres ouverts ont trois parties, les portes fermées quatre. Pas de modification du héros ni de la logique de déplacement.

## Validation

- `partition-validation.json` : géométrie identique à v11/v12, rendu complet fermé identique pixel à pixel à v13, assemblage des parties sans jointure (tolérance d’arrondi 1/255), aucun support bas englobant les deux côtés du passage.
- `after/validation.json` : 863 contrôles sans échec ; 49 positions traversées × quatre directions, 16 poses marche/course au centre. Vérifie les relations de profondeur non ambiguës des volumes projetés, plus montant éloigné < héros < montant proche au centre et couronne au-dessus.
- `open-door-validation.json` : 84 contrôles sans échec dans le vrai jeu. Deux axes, ouverture ordinaire/magique, reconstruction de l’état sauvegardable en mémoire, destruction, réparation, suppression ; inclut explicitement l’insertion de l’acteur entre les montants dans l’ordre statique mis en cache du jeu.
- `badge-validation.json` : 87 contrôles sans échec, badge unique et position conservée.
- `lockpick/validation.json` : 32 contacts, huit poses, quatre orientations et quatre tailles de fenêtre ; pause, pas à pas, vitesse et repères vérifiés.
- `preservation.json` : 143 sprites hors portes et leurs métadonnées inchangés ; 37 ressources des héros inchangées. 171 entrées au lieu de 159. Kit PNG 2 107 174 → 2 096 585 octets ; allocation RGBA identique, 13 MiB. Davantage de parties n’implique pas une nouvelle page d’atlas.

Import et exécutions Godot : codes 0 et stderr vides. Vues centrales et étapes d’entrée/sortie inspectées. Revue indépendante du générateur, des compagnons et des consommateurs : aucun défaut actionnable identifié. Le contrôle du tri propre au jeu a été ajouté après cette revue et exécuté avec succès.

Ces tests ne prouvent pas un ordre exact par pixel pour toute configuration future, ni une collision 3D continue. La scène conserve les sprites 2D. Aucun essai téléphone, APK, sauvegarde joueur, commit ou push.

## Reproduction

Depuis la racine, avec Node/Sharp et Godot disponibles :

```powershell
node tools/verify_door_passage_parts.cjs
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --script res://tools/capture_door_passage.gd --rendering-method gl_compatibility
godot --path . --script res://tools/verify_open_doors.gd --rendering-method gl_compatibility
godot --path . --script res://tools/verify_door_badges.gd --rendering-method gl_compatibility
godot --path . --script res://tools/capture_vulpin_lockpick_preview.gd --rendering-method gl_compatibility -- --output=res://docs/reference/door-redesign/seal-v1/hero-fit-v14-passage/lockpick
node tools/prepare_door_passage_review.cjs
```

Les PNG de traversée sont des masters régénérables ignorés ; les 98 images WebP sans perte et rapports sont conservés. Les captures `before` ont été faites avant correction ; ne pas réutiliser `--before` sur le code corrigé pour réécrire cette preuve. Les anciennes revues v12/v13 restent des instantanés historiques, avec leur ancien découpage.
