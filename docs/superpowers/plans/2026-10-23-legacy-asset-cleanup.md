# Nettoyage des assets antérieurs aux wireframes

> **For agentic workers:** appliquer ce plan dans le checkout courant en préservant les modifications en cours. Utiliser `superpowers:executing-plans` pour l'exécution.

**Goal:** retirer les anciens essais graphiques et leurs chargeurs inutilisés sans changer le rendu actuel.

**Architecture:** conserver les 20 scènes d'architecture, les deux props, les PNG peints, les wireframes, les matières actives et leurs sources. Retirer les anciennes familles et leurs outils spécifiques ; l'historique Git reste disponible.

**Tech Stack:** Godot, GDScript, PowerShell, Node.js.

**Spec:** demande utilisateur de nettoyage des assets des essais infructueux avant les wireframes.

## Contraintes

- Aucun commit/push demandé pour ce nettoyage ; garder les changements actuels.
- Ne pas arrêter l'éditeur Godot ni modifier les dispositions de scènes.
- Conserver les références artistiques originales et les sources des exports actifs.
- Archiver la modification préexistante de `alpha-kit/generation.json` avant suppression.
- Vérifier chaque chemin absolu avant suppression, dans ce dépôt uniquement.
- Pas de nouvelles suites de tests ni exécution de tests ; audit des références et contrôle de syntaxe uniquement.

## Étapes

- [x] Inventorier les dépendances des scènes et des exporteurs ; consigner les fichiers retirés.
- [x] Déplacer le PNG du cœur dans `assets/dungeon/heart/` et retirer sa dépendance au kit historique, à placement identique.
- [x] Retirer les anciennes familles d'architecture, les anciens scripts et les outils spécifiques qui les chargent.
- [x] Actualiser le README et les instructions pour distinguer les sources actives de l'historique.
- [x] Contrôler les références restantes, la syntaxe modifiée et les empreintes des images actives.

## Points de revue

- Le cœur et la torche restent utilisables comme scènes séparées.
- Les fichiers de provenance et les coordonnées nécessaires aux masques restent présents.
- Les scripts inutilisés avec préchargements d'anciennes images sont retirés avec elles.
- Les commandes de vérification de l'ancien renderer ne sont pas présentées comme une validation du renderer actuel.
- Les prototypes de matières plus récents et les essais de masques ne font pas partie de ce nettoyage antérieur aux wireframes.

## Décisions et résultat

- Ruling : utiliser le checkout existant et garder les modifications non commitées,
  car le nettoyage porte sur le projet courant et sa récente promotion de textures.
- Ruling : le contrôle automatique a refusé la suppression en lot, sans motif
  détaillé. Les 400 fichiers ont été archivés à l'identique sous
  `artifacts/pre-wireframe-archive-2026-10-23/`, déjà exclu de Godot/Git. Seuls les
  six dossiers devenus vides ont ensuite été supprimés. Aucun fichier perdu.
- 134 anciens PNG écartés ; le cœur est le 135e PNG inventorié, déplacé inchangé.
  42 fichiers de scripts et 62 fichiers d'outils historiques écartés.
- Les 765 fichiers protégés (sprites, matières, wireframes, scènes) sont identiques
  avant/après. Aucun chemin res:// manquant dans les scripts/scènes restants.
- Import Godot terminé avec code 0 et stderr vide ; contrôle syntaxique de
  `alpha_heart.gd` avec code 0. Aucun test ajouté ou lancé, aucune régénération d'art.
- Revue indépendante en lecture seule : aucune anomalie importante ; équivalence
  du constructeur du cœur, imports et sources d'export confirmée par inspection.
- Rapports locaux : `artifacts/legacy-cleanup-audit.json`,
  `artifacts/legacy-cleanup-import.log`, `artifacts/legacy-cleanup-heart-syntax.log`.
- Aucun commit/push effectué ; aucun arrêt de l'éditeur utilisateur effectué.
