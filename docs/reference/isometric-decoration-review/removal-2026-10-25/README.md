# Retrait des anciennes fissures — 25 octobre 2026

À la demande de l'utilisateur, les anciens motifs `corner-split`,
`vertical-hairline`, `edge-fork` et `crack-corrupt` ne sont plus adoptés par
l'exporteur ni sélectionnés dans les scènes actives. Douze régions ont été
retirées de l'atlas, soit quatre motifs sur le sol et les deux faces de mur.

Le décor `chip-worn` est conservé dans ses trois projections. Ses emplacements
restent identiques : les anciens emplacements de fissures sont simplement vides,
sans les remplacer par davantage d'éclats. Les nouveaux murs A/C/F et leurs
racines/cristaux restent inchangés.

Les dix-huit anciennes copies préparées ont été supprimées de
`isometric-review/painted-v1/sprites/`, y compris les six copies déjà obsolètes
des premiers motifs courts/ramifiés. `deleted-files.json` enregistre leurs noms
et empreintes : 13 375 octets. Les sources et revues de validation historiques
restent archivées ; elles ne font pas partie du paquet du jeu.

`verify.cjs` confirme douze retraits exactement, les 103 régions restantes
identiques en RGBA et métadonnées hors emplacement d'atlas, ainsi que l'absence
des fichiers supprimés. Les scripts runtime et catalogues ne référencent plus
aucun ancien motif de fissure.

Atlas actuel : 103 régions, 1024×2048, 1 424 918 octets PNG, 8 Mio RGBA.
Le format alloué ne diminue pas : la suppression ne suffit pas à revenir à
1024×1024. Les fichiers PNG conservés et les dessins approuvés ne sont pas refaits.

Import et 68 captures runtime des 23 scènes : sortie 0, stderr vide.
MobileReference a été inspectée visuellement. Export de ressources :
50 dépendances, ZIP 1 182 540 octets ; import de la copie propre, export et
démarrage isolé OpenGL : sortie 0, stderr vide. Aucune nouvelle capture éditeur,
suite de tests, mesure sur téléphone, commit ou push.

`before/` préserve le catalogue/l'atlas antérieurs et les deux scripts modifiés.
`captures/` et `validation.json` contiennent les preuves de ce retrait.
