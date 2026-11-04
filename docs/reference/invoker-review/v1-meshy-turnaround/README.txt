INVOCATEUR OCULIN - QUATRE VUES POUR MESHY
4 novembre 2026

Ancien Oculin distinct du personnage de base : manteau rituel violet use,
bordures geometriques dorees, medaillon en forme d'oeil, tunique sombre,
ceinture de corde et tabard fendu. Morphologie courte et massive conservee,
un oeil violet, deux cornes claires, peau minerale, mains et pieds nus.
Pose neutre, mains vides. Aucun accessoire tenu ni dieu genere dans ce pack.

Les quatre fichiers du dossier meshy/character sont les vues individuelles :
01-front.png : face
02-left.png : profil gauche, personnage tourne vers la gauche de l'image
03-back.png : dos
04-right.png : profil droit, personnage tourne vers la droite de l'image

Generation avec ImageGen integre, alpha natif. Les fichiers livres conservent
les octets des sources : pas de miroir, retouche procedurale, decoupe du corps
ou deformation pour aligner artificiellement les vues. four-views.png est
uniquement une planche de lecture; utiliser les quatre images individuelles.

References archivees : source/species-reference.png (personnage existant),
source/elder-reference.webp (ancien du storyboard). Les prompts exacts sont
source/prompt-front.txt, prompt-left.txt, prompt-back.txt, prompt-right.txt.
provenance.json conserve les sorties natives et validation.json les hashes,
dimensions, limites visibles et ecarts de cadrage mesures.

Reproduction du conditionnement sans API :
  $env:NODE_PATH = "$PWD/artifacts/sanctuary-textured/deps/node_modules"
  node docs/reference/invoker-review/v1-meshy-turnaround/prepare.cjs

Ces vues sont des illustrations coherentes, pas des rendus calibres d'un meme
maillage. Le resultat de reconstruction, les couches du manteau et le rig
devront etre examines sur le modele 3D. Aucun modele n'a ete genere ou envoye
a Meshy dans cette etape. Aucun changement du jeu, APK, commit ou push.
