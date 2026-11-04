Nettoyage des assets après validation de l’introduction V1 — 4 novembre 2026

420 fichiers archivés (assets, scènes, scripts, shaders et métadonnées Godot),
76 453 689 octets. Les assets actifs passent de 277 821 852 à 201 874 938
octets : 75 946 914 octets retirés des dossiers assets, environ 27 %.
Les 1 178 assets restants ont été comparés par SHA256 : aucun n’a changé.

Lot retiré des ressources actives :
- Anciens essais de Maître : énergie œil-vortex et modèle œil + volute.
- Première peinture détaillée du sanctuaire, remplacée par le style validé.
- Ancienne cinématique illustrée de l’invocation et ses effets spécifiques.
- Premier escalier abandonné au profit de stairwell-v2.
- Anciennes variantes du prologue et premières images du rituel.

Préservé :
- Toute l’introduction V1, ses vingt images de prologue, Wraith animé,
  invocateur, procession, décor actuel, escalier V2 et dialogues.
- Les modèles originaux, scènes Blender, rendus maîtres et recettes sous docs.
- Les aperçus des héros et leurs sprites, y compris les dossiers previews
  réellement utilisés par le jeu (Wraith, Vulpin notamment).
- Le wireframe et les étapes de fabrication du sanctuaire encore utilisées
  par les recettes. SanctuaryTextured fournit notamment leurs ombres.
- Les doublons conservés dans l’inventaire : une copie identique peut avoir
  un chemin utilisé par un aperçu ou une recette. Pas de dédoublonnage aveugle.

Archive et inventaire :
- superseded-introduction.zip : chemins d’origine et octets exacts.
- manifest.json : taille, SHA256 et motif pour chaque fichier.
- inventory.json : inventaires avant/après, tailles, SHA256 et doublons.
docs/.gdignore exclut ce dossier de l’import Godot et des exports.
Il s’agit d’un rangement hors des ressources actives, pas d’une réduction
équivalente de l’espace disque : l’archive conserve les anciens fichiers.
Les références historiques dans la documentation restent des références aux
anciens chemins ; restaurer l’archive pour rouvrir ces essais.

Restauration depuis la racine du dépôt :
    python tools/archive_intro_experiments.py --restore
Puis relancer l’import Godot. La commande vérifie tous les fichiers avant
d’écrire et refuse d’écraser un fichier modifié. Aucun effacement récursif.
Le mode par défaut est un audit sans modification ; --apply crée et vérifie
l’archive avant de retirer les fichiers sélectionnés et refuse de la remplacer.

Vérifications effectuées après nettoyage :
- Import Godot réussi, stderr vide.
- Chargement des 67 scènes restantes et des 20 images de prologue : zéro échec.
- Vérifications natives des dialogues et de la transition : zéro échec.
- Contrôle SHA256 de l’archive et de ses 420 membres.
- Test isolé de restauration, protection contre écrasement et sortie du dépôt.
- Revue indépendante : aucune référence active par chemin ou UID vers le lot,
  aucun problème signalé. Les outils génériques d’énumération des scènes et
  le test des dix chapitres ont été examinés pour les références dynamiques.
Logs et captures : artifacts/sanctuary-procession/cleanup-*.

Pas de modification des sauvegardes, d’APK, de commit ou de push.
