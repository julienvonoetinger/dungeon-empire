# Ombre agrandie — 24 octobre 2026

L'utilisateur précise que le défaut est simplement la taille de l'ombre.
Cette précision remplace la piste de modification du matériau du diagnostic v3.
Le cœur, sa texture, sa géométrie et son placement restent exactement identiques.

L'empreinte complète de l'ombre est agrandie de **50 % sur ses deux axes** autour
de l'ancrage [0,0,0]. La direction, les opacités et les proportions sont conservées ;
la douceur des bords suit la même échelle. Il s'agit d'un élargissement artistique
sur le sol, pas d'une nouvelle géométrie physique du socle.

Seul `heart-shadow.png` change parmi les PNG préparés. Son cadre passe de 233×134
à **349×202**, son poids à **8 604 octets**. Ses limites de réception suivent
l'agrandissement ; le renderer existant exige toujours une surface de sol complète
dans les layouts. L'aperçu isolé DungeonHeart garde son exception sans layout.

L'atlas reste à **27 régions, 1024×1024, 4 Mio RGBA** ; PNG **533 290 octets**.
Import et 68 captures runtime / 23 scènes : sortie 0, stderr vide. L'éditeur
produit 21 captures / cinq scènes, sortie 0 avec ses diagnostics natifs connus.
Export isolé : 45 dépendances, paquet de **454 207 octets** ; import, export et
ouverture sortent à 0 avec stderr vide. Pas de tests automatisés ni profilage mobile.

`before/` conserve l'ancien générateur, les empreintes, le catalogue et les captures.
`comparison.png` juxtapose les captures Godot à caméra identique, à l'échelle du
jeu puis agrandies ×2. Reproduction après export/capture :

```powershell
node tools/prepare_isometric_large_shadow_review.cjs
```

La nouvelle taille est intégrée et présentée pour retour visuel ; ne pas confondre
la réussite technique avec une approbation artistique. Aucun commit ni push.
