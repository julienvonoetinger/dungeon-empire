L'OEIL GRANDIT SUR PLACE — 4 novembre 2026

L'utilisateur prefere une croissance de l'oeil a sa sortie du vortex.
Rendu peint v8 conserve sans retouche de texture ou de shader.
Le noyau et le groupe de l'iris restent maintenant en (0,0,0.55).
Leur echelle commune passe doucement de zero a un entre 3 et 8 secondes.
Le vortex apparait seul avant 3 secondes, sans sphere noire visible.
L'orbite conserve egalement sa profondeur fixe. Le fond de l'entonnoir
est maintenu exactement au centre de la pupille, y compris pendant ses
petites rotations et sous les vues obliques. Aucun mouvement de sortie.
Le libelle de l'apercu indique maintenant "L'oeil grandit".

Trois regressions de centre/profondeur reproduites sur v8 avant correction.
Verification native finale sans echec, stderr vide : centre immobile et
commun a la pupille/iris/vortex sur 300 intervalles, croissance continue,
absence initiale du noyau, un seul noyau, pause/reprise et trois formats.
Retour GPU a t=7 : un canal different de 1/255, tolerance inchangee.
Captures de transition et animation native 24 secondes/360 images a 15 fps.
Sources et logs archives dans source/ ; prepare.cjs reproduit le WebP.

Prototype isole uniquement. Aucun changement au decor, au jeu, aux saves,
ni nouvelle generation d'image. Pas de commit/push ou APK.
