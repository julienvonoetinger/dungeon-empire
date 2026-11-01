MYCEAN — VUES POUR MESHY
1 novembre2026

Quatre vues du mage champignon à partir du concept approuvé du21octobre :
face, profil gauche, dos, profil droit. Pose A avec mains libres ; grand chapeau
violet à taches cyan, visage crème, tenue verte/violette en feuilles, bottes,
harnais et unique sacoche droite. Deux petits champignons à l'épaule arrière
droite. Bâton fongique torsadé généré comme objet séparé : sa tige se prolonge
directement dans les lamelles et le chapeau bleu-violet, sans champignon ajouté.
Les profils servent à reconstruire le volume ; la caméra isométrique du jeu
sera appliquée au modèle3D final, pas imposée aux références de reconstruction.

Génération via ImageGen intégré, alpha natif. Front fondé sur la planche des
quatre héros et mycean-scene.png, puis profils/dos guidés par la face et le
profil gauche. Dos interprété depuis les indications du concept, pas un modèle
existant. Prompts exacts : prompts.json et source/*-prompt.txt. Provenance,
fichiers natifs et SHA256 : provenance.json. Chaque PNG final est une copie
exacte de la sortie native ; aucun détourage, redimensionnement ou miroir scripté.

Corrections conservées : left-initial.png montrait trop la paume et le X du
torse ; le profil corrigé les montre de côté, avec un seul pied proche visible.
back-initial.png répétait un rabat de sacoche au dos ; le dos retenu montre son
panneau arrière et son passant. La face et le profil droit gardent le fermoir.
L'utilisateur rejette ensuite le premier bâton, qui portait un petit champignon
dans une fourche. staff-initial.png conserve cet essai ; staff.png est la nouvelle
croissance continue, bois torsadé devenant tige puis lamelles du chapeau. Poignée
et pied conservés. Prompt de correction : source/staff-integrated-prompt.txt.

prepare.cjs copie les cinq PNG vers meshy/ puis vérifie SHA256, alpha natif,
marges, absence de silhouette solide tronquée, dimensions et poids. Il vérifie
les sources avec leurs hashes archivés, sans dépendre du cache Codex local.
Résultat : cinq1254x1254,4,491,473octets PNG. Écart réel des hauts de silhouettes
14px, des semelles10px sur les quatre vues, enregistré dans validation.json.
Ces mesures ne prouvent pas une géométrie3D calibrée ; variations de peinture
et de formes possibles. Reconstruction/rigging Meshy non testés.

LIVRAISON
meshy/character/01-front.png,02-left.png,03-back.png,04-right.png : même corps.
meshy/equipment/staff.png : génération d'objet séparée, pas une vue du corps.
meshy/README.txt : consignes d'import.
mycean-mage-meshy-pack.zip : ces cinq PNG et les consignes uniquement.
index.html : comparaison des quatre angles, bâton et téléchargements individuels.

REPRODUCTION DU PACK (PowerShell, racine du dépôt)
$env:NODE_PATH='C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' docs/reference/mycean-review/v1-meshy-turnaround/prepare.cjs
Compress-Archive -Path docs/reference/mycean-review/v1-meshy-turnaround/meshy/* -DestinationPath docs/reference/mycean-review/v1-meshy-turnaround/mycean-mage-meshy-pack.zip -Force

docs/.gdignore exclut sources/revue/pack des exports. Pas de changement du jeu,
de nouveau modèle3D, d'animation, d'APK, de commit ni de push pendant cette étape.
Les recommandations officielles consultées sont liées dans le README du pack.
