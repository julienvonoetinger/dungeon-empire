# Correction de l'aperçu éditeur — 24 octobre 2026

`reported-broken.png` est la capture fournie par l'utilisateur. Après réorganisation
de l'atlas, l'aperçu montrait des portions de sprites décalées et d'anciens décors.
Un nouveau processus de rendu produisait déjà la bonne scène avant le correctif.

## Cause dans le chargement

Le script ne lisait le catalogue qu'à `_ready()` et utilisait `load()` sur les
AtlasTexture `.tres`. L'éditeur persistant pouvait conserver leurs anciens
rectangles pendant que l'image de l'atlas était réimportée, ou conserver une
ancienne dépendance PNG avec les nouveaux rectangles. Le catalogue conservé
en mémoire pouvait aussi rester ancien. Cette combinaison explique les découpes
incohérentes ; la géométrie et le packing sur disque donnaient un rendu correct.

Les modes de [ResourceLoader](https://docs.godotengine.org/en/stable/classes/class_resourceloader.html#enum-resourceloader-cachemode)
réutilisent normalement les dépendances en cache. Remplacer seulement la
ressource AtlasTexture ne garantit pas de relire son image PNG externe.

## Correctif

- Bouton **Actualiser le rendu** dans l'inspecteur du nœud racine MobileReference.
- Relecture du catalogue et remplacement en cache des `.tres` utilisés et de
  chaque PNG d'atlas externe, une seule fois par chemin à chaque actualisation.
- Rechargement automatique après les événements de réimport/rechargement de
  [EditorFileSystem](https://docs.godotengine.org/en/stable/classes/class_editorfilesystem.html).
  Une modification du catalogue ou d'un atlas détectée au scan déclenche aussi
  l'actualisation ; elle attend la fin du scan et des imports.
- Le bouton active également la surveillance pour une scène restée ouverte
  pendant le rechargement du script. Les réglages de l'inspecteur et la caméra
  sont conservés. Le cache normal reste utilisé pendant le jeu.

Le correctif ne repeint aucun sprite et ne génère aucune image dans Godot.

## Captures et limites

`tools/capture_mobile_reference.gd` produit les captures habituelles en mode jeu.
Avec l'option Godot `--editor`, il écrit dans ce dossier après avoir attendu la
fin des imports. Il conserve les neuf vues, et indique `editor hint: true` dans
le journal. `proposed-256.png` a été inspecté visuellement et possède le même
SHA-256 que son équivalent en mode jeu :

`edcef32b5be77e5474d4cc5b4dbc9159ece4e73ff7ed8a794cffbb1b117ebae1`

Import et captures en mode jeu : sortie 0, stderr vide. Capture sous le contexte
éditeur : sortie 0, images produites correctement, mais ce processus personnalisé
émet des avertissements de destruction de ressources natives à la fermeture et
`current_window is null` dans le dialogue de progression de l'éditeur. Ces logs
ne constituent pas un arrêt sans erreur ; voir `artifacts/mobile-preview-editor.*`.
L'état en mémoire de l'éditeur de l'utilisateur n'a pas été inspecté directement.
Le bouton est disponible pour rafraîchir son instance déjà ouverte.

Aucun test automatisé ajouté ou exécuté. Aucune modification de la géométrie,
des atlas, du style du pilier ou des autres scènes pour cette correction.
