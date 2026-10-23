# Nettoyage des anciens essais — 23 octobre 2026

À la demande de l'utilisateur, les essais d'architecture antérieurs aux wireframes
ont été retirés du projet actif : anciens atlas et découpes, prototypes modulaires,
trois coins rejetés et leurs renderers/outils exclusifs.

## Résultat

- 400 fichiers écartés du projet actif, dont 134 PNG d'essais retirés.
- Le 135e PNG inventorié est le cœur, déplacé à l'identique dans
  `assets/dungeon/heart/heart.png` avec ses paramètres d'import.
- Environ 107,4 Mio de fichiers retirés des anciens emplacements, sans libération
  équivalente d'espace disque : la copie locale est conservée.
- Les scènes d'architecture, les sprites actuels, la géométrie wireframe, les
  matières actives et les maquettes utilisateur sont conservés.
- Les anciens `verify_*` et `test-mobile.ps1` dépendaient de l'ancien renderer.
  Ils ne sont plus des commandes actives. Aucune suite de tests de remplacement
  n'a été créée ou exécutée pour ce nettoyage.

## Récupération

La suppression permanente en lot a été refusée par le contrôle automatique de
l'outil. Un archivage réversible a été effectué à la place. Les fichiers se trouvent
localement dans `artifacts/pre-wireframe-archive-2026-10-23/`, avec leurs chemins
d'origine. Le dossier `artifacts` est ignoré par Git et contient `.gdignore` pour
l'exclure du scan et de l'import Godot. Cette copie n'est donc pas partagée par Git.

`2026-10-23-pre-wireframe.json` contient les chemins, tailles, empreintes et le
commit Git qui permet de récupérer les fichiers historiques suivis. Pour consulter
un fichier historique sans rétablir tout l'ancien kit :

```text
git show ddb80ce0c69e02f4c6d2eed7b941d19bb65081d4:chemin/du/fichier
```

La modification préexistante de `alpha-kit/generation.json` est conservée sans
changement dans `alpha-kit-generation-before-cleanup.json`, en plus de la copie
locale. Les autres changements en cours de l'utilisateur sont conservés.

## Sources encore nécessaires

`docs/reference/nw-material-review-v2/validation.json` alimente le compositeur
actuel : ses coordonnées et identifiants de matière ne doivent pas être supprimés.
Les essais de masques et les propositions de textures postérieures aux wireframes
ne font pas partie de ce nettoyage. Le dossier `perspective` ne contient plus
qu'une maquette originale et sa documentation, sans renderer associé.
