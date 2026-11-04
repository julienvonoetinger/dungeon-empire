MAITRE D'ENERGIE — REFERENCES MESHY
4 novembre 2026

Demande : passer a un modele 3D a animer, puis generer les images pour Meshy.
Livraison : quatre vues du noyau-oeil (face/gauche/dos/droite) et une volute
separee. Le noyau est un volume violet ferme, un seul iris frontal et une
pupille noire, encadre par des plis d'energie. Dos sans oeil. La volute est
un objet distinct pour pouvoir preparer des mouvements independants.
Pas de chair, corps humanoide, metal ou decoration ajoutee.

Source artistique : ../v3-vortex-eye/source/vortex-eye.png, adaptee en volumes
lisibles pour reconstruction. Face generee d'abord, profils/dos derives de
cette identite. La volute reprend la maquette et la nouvelle face.
Toutes les generations utilisent l'outil ImageGen integre, transparence native.
Prompts exacts dans source/prompt-*.txt. Sorties originales dans source/*.png.
provenance.json enregistre chemins natifs, SHA256, dimensions et bornes alpha.

prepare.cjs verifie les sources natives au premier passage puis les hashes
archives pour permettre une reproduction sans cache machine. Il copie les
PNG a l'identique dans meshy/, sans miroir, coupe, peinture ni deformation.
four-views.png est seulement une planche de consultation : images completes
reduites uniformement avec libelles, ne pas la soumettre comme vue Meshy.
Les instructions utilisateur sont dans INSTRUCTIONS.txt et dans le ZIP.

Reproduction :
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node docs/reference/dungeon-master-review/v11-meshy-eye/prepare.cjs

Validation : cinq PNG de 1254x1254, marges transparentes, volumes opaques,
aucune silhouette coupee sur les bords, copies identiques aux natifs.
Ecarts de cadrage mesures pour les quatre vues : haut 4 px, bas 6 px.
Les profils restent des illustrations approximees, pas des vues geometriquement
calibrees. Reconstruction, topologie et separation des parties mobiles a verifier
sur les GLB. La brume et l'eclairage ne sont pas inclus comme objets solides.

Aucun appel de generation Meshy, upload, rig, changement du jeu ou de l'apercu
natif, aucune sauvegarde, APK, commit ou push. Sources exclues par docs/.gdignore.
