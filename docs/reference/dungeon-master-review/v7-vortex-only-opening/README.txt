Vortex seul au debut — 4 novembre 2026

v6 conservait une gorge noire de rayon 0.17 des l'ouverture. L'utilisateur
demande que le cercle noir apparaisse seulement avec l'oeil.
BlackCore est maintenant invisible jusqu'a 3 secondes, puis son rayon
augmente de zero a 0.62 sur 3-8 secondes, avec la meme progression douce
que son emergence. Un seul noyau ; iris et arcs gardent leur chronologie.
Le bouton Regard ne revele pas la pupille pendant l'ouverture.

Six echecs de regression reproduits sur v6. Verification native finale :
aucun echec, stderr vide ; controles de visibilite, croissance continue,
pause, retour arriere et trois formats. Captures aux trois angles.
Le retour GPU a t=7 differe de six canaux de 1/255 au dernier passage
(neuf au diagnostic initial) : tolerance explicite
de 1 au maximum sur moins de 0.01 % des octets, pas une egalite bit a bit.
Animation de 24 secondes encodee depuis 360 captures natives (15 fps).
Prototype isole, aucune modification de l'introduction ni des sauvegardes.
