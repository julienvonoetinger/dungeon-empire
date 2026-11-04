INVOCATEUR — CORRECTION DE LA PRISE DU BATON
4 novembre 2026

Defaut utilisateur : dans v3, le baton etait a cote des doigts. Le controle
zero intersection ne suffisait pas a verifier une prise. v3 reste historique.

La correction reconstruit le repere anatomique de la main avec la direction
du majeur et celle du pouce. Paume tournee vers le manche, pouce vers le haut,
avant-bras aligne en rotation axiale avec la paume. Les trois chaines des doigts
se replient autour de l'axe du manche ; le pouce est oppose de l'autre cote.
Les longueurs des phalanges sont conservees. La base du doigt inferieur est
legerement ecartee radialement pour degager sa chair du manche.

Le baton est positionne a (0.462, -0.358, 0.955), echelle uniforme 0.98. Sa prise
est mesuree depuis la geometrie reelle. Une enveloppe fermee autour du cuir,
parentee au poignet avec le baton, fournit une contrainte OUTSIDE sur la main.
Subdivision SIMPLE niveau 2 pour echantillonner cette correction sans lisser
les coutures du GLB. Aucun changement du maillage de base, UV, poids d'origine,
squelette au repos, materiaux ni des six textures embarquees : preserve.py
compare les deux sources Blender et le resultat par empreintes.

Validation :
- l'ancien montage echoue aux controles d'enveloppement des trois doigts et
  d'opposition du pouce (before-validation.json) ;
- les pointes des trois doigts passent au-dela de l'axe par rapport a la paume,
  devant le manche, tandis que le pouce s'oppose derriere ;
- chaque doigt presente une distance minimale au manche inferieure a 0.008
  unite (mesures finales environ 0.0049 a 0.0052), une marge de contact visuel ;
- zero croisement arete/surface du baton avec le corps entier, main comprise ;
- baton et enveloppe suivent la rotation de 0.1 radian du poignet puis retour ;
- sources GLB et donnees originales conservees, six textures embarquees.
Les captures de face, exterieure, interieure et dessus ont ete inspectees.
La vue du dessus utilise une coupe de camera pour retirer la tete du baton :
elle est diagnostique seulement, pas un maillage ouvert ni un rendu de jeu.

Fichier retenu : invoker-equipped.blend. Apercu : overview.png.
Recette : executer equip.py, puis verify.py et preserve.py avec Blender en
arriere-plan et --python-exit-code 1. verify.py -- --old reproduit l'echec v3.
Les sources se trouvent dans ../source et ../v3-meshy-inspection/combined-source.blend.

Pose statique uniquement. Ce controle ne prouve pas toutes les auto-collisions,
les volumes contenus ni la qualite d'une animation future. Aucun changement
de jeu, scene d'introduction, sauvegarde ou export APK. Pas de commit/push.
