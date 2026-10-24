# Nettoyage des assets

## Fichiers volumineux retirés — 24 octobre 2026

L'utilisateur a demandé de supprimer les anciens fichiers inutiles après la
migration mobile. **19 117 fichiers, 7 160 979 645 octets (6,669 Gio)** ont été
supprimés : les deux anciens catalogues haute résolution et leurs imports,
les deux scripts de sélection inutilisés, et 17 anciens caches/copies d'essais.

- `assets/dungeon/painted-connected/` et `painted-cells/` sont retirés.
- Les caches sous `artifacts/stone-context-cache/`, les variantes retirées,
  copies avant correction et l'archive locale pré-wireframes sont retirés.
- Aucune nouvelle copie d'archive volumineuse n'est créée.
- L'inventaire `2026-10-24-retired-large-assets.json` donne chaque chemin,
  taille, SHA256 et catégorie. Son statut indique si la suppression est terminée.
- Les fichiers suivis sont récupérables au commit
  `6a6fcaa7cea2cbf201807e8bcc3a96dd7b7a2501`. Pour l'archive pré-wireframes,
  consulter l'inventaire précédent et le commit
  `ddb80ce0c69e02f4c6d2eed7b941d19bb65081d4`. Les caches ignorés ne sont pas
  tous des fichiers Git ; les recettes et sources choisies restent disponibles.
- `alpha-kit-generation-before-cleanup.json` conserve la modification non
  commitée identifiée lors du nettoyage précédent.

### Sources conservées

Le kit mobile, les 21 scènes, le cœur, les torches, les matières, les wireframes,
les références originales et les revues sélectionnées restent en place.
L'inventaire enregistre 553 empreintes de dépendances et de sources préservées.
Le compositeur utilise toujours `nw-material-review-v2/validation.json` ; cette
source et le dessus sculpté du pilier sont conservés.

Les chiffres avant/après du kit sont figés dans
`docs/reference/mobile-kit/legacy-catalog-inventory.json` : l'export mobile
ne relit plus les anciens répertoires supprimés. Les commandes historiques
peuvent mentionner leurs anciennes sorties ; elles ne sont pas le pipeline actif.

Le cache de l'éditeur `.godot/`, l'historique `.git/`, les pièces jointes,
les preuves actuelles du kit mobile et les projets de diagnostic de l'éditeur
ne sont pas nettoyés par cette opération. Il ne s'agit pas d'une réécriture de
l'historique Git ; sa taille locale et distante ne diminue pas automatiquement.
Aucun commit/push ni test automatisé n'est demandé pour ce nettoyage.

### Résultat du contrôle après suppression

- Statut de l'inventaire : `deleted` ; 19 117 fichiers retirés, dont 5 923
  fichiers précédemment suivis par Git et 13 194 fichiers de caches/copies locaux.
- Les 553 fichiers préservés ont conservé exactement leurs empreintes SHA256.
- Reconstruction complète avec `node tools/export_mobile_kit.cjs` : sortie 0,
  23 sprites, atlas 1024×2048 de 635 387 octets, identique à l'atlas précédent.
- Les 40 dépendances déclarées des scènes mobiles sont toujours présentes.
- Aucun ancien dossier supprimé n'a été recréé par l'export mobile.
- `git diff --check` : sortie 0. Aucune suite de tests automatisés exécutée.

## Historique : nettoyage des anciens essais — 23 octobre 2026

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
l'exclure du scan et de l'import Godot. Cette copie n'était pas partagée par Git. Elle a été supprimée le 24 octobre
à la demande de nettoyage des fichiers volumineux ; voir l'inventaire ci-dessus.

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
