BATRAFIAN — VUES POUR MESHY
1novembre2026

Quatre vues du ranger grenouille à partir du concept approuvé du21octobre :
face, profil gauche, dos, profil droit. Pose A avec mains libres, corps sans
arc ni carquois. Arc, carquois et flèche complète disposent chacun de leur PNG
séparé. La flèche a été ajoutée à la demande de l'utilisateur pour permettre
son utilisation indépendante pendant le tir et comme projectile.
Les profils sont des vues de reconstruction, pas les futures vues de jeu
isométriques. Le cadrage isométrique sera réalisé sur le modèle3D final.

Génération via ImageGen intégré, alpha natif. Tous les prompts exacts et les
chemins d'origine sont dans prompts.json/provenance.json ; le prompt de la
flèche est dans source/arrow-prompt.txt. Deux corrections :
profil gauche davantage de côté (torse/main) et dos de sacoche sans répéter
le fermoir avant. Les premières versions restent dans source/*-initial.png.

prepare.cjs copie les PNG sans retouche et vérifie alpha, marges, dimensions,
poids et SHA256. Il conserve les écarts réels de cadrage dans validation.json.
Les vues sont des illustrations indépendantes : leur cohérence visuelle ne
garantit pas une reconstruction ou un rig parfait. Le modèle reste à générer
dans Meshy par l'utilisateur. Pas de modifications du jeu ou d'animations.

REPRODUCTION DU PACK, DEPUIS LA RACINE DU DEPOT
Node avec sharp accessible via NODE_PATH :
  node docs/reference/batrafian-review/v1-meshy-turnaround/prepare.cjs
Puis PowerShell :
  Compress-Archive -Path docs/reference/batrafian-review/v1-meshy-turnaround/meshy/* -DestinationPath docs/reference/batrafian-review/v1-meshy-turnaround/batrafian-ranger-meshy-pack.zip -Force

Le ZIP contient les sept PNG et les instructions. La page index.html permet
de comparer les quatre angles et d'ouvrir chaque fichier. docs/.gdignore
exclut les sources et cette revue des exports du jeu.
