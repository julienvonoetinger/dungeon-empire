# Retrait des derniers décors de dégâts — 25 octobre 2026

Le motif signalé par l'utilisateur est l'éclat `chip-worn` conservé lors du
retrait précédent. Ses versions sol et deux faces de mur sont maintenant
retirées de l'atlas et de la génération active. Les trois copies préparées
sont supprimées (4 526 octets). Les sources artistiques et validations
historiques restent archivées.

Le placement des anciens décors et ses options d'inspecteur ont été supprimés.
Les fonctions de coordonnées et de classement encore utilisées par les nouveaux
murs sont conservées. La répartition des variantes A/C/F, leurs zones calmes et
les racines/cristaux F ne changent pas.

`pixel-validation.json` compare l'atlas au snapshot `before/` : seules les trois
régions attendues disparaissent ; les 100 autres gardent leurs pixels et leurs
métadonnées, hormis les coordonnées de rangement. `verify.cjs` reproduit cette
vérification d'intégrité. Aucune nouvelle peinture ni modification des supports.

Atlas : **100 régions**, **1024×2048**, **1 420 533 octets PNG / 8 Mio RGBA**.
Paquet de ressources : **1 176 007 octets**, **50 dépendances / 23 scènes**.
Import, 68 captures runtime, import/export isolés et démarrage du paquet : sortie
0, stderr vide. `validation.json` et les journaux consignent les résultats.
L'aperçu MobileReference a été inspecté visuellement.

[Voir le rendu Godot](captures/MobileReference-native.png).

Pas de nouvelle capture éditeur, suite de tests, APK/profilage téléphone,
commit ou push. Les preuves précédentes restent des snapshots historiques.
