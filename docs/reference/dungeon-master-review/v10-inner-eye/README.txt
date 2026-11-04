OEIL DANS LE CERCLE NOIR — 4 novembre 2026

L'utilisateur signale l'absence d'oeil a l'interieur du cercle.
v9 utilisait la sphere noire comme pupille de l'ensemble du vortex.
Cette version ajoute un oeil d'energie distinct dans cette zone noire :
iris peint, petite pupille et deux contours en amande. L'ouverture de
l'iris laisse voir la sphere noire existante : aucune seconde sphere.

InnerEye partage la croissance sur place de EyeEmergence. Son apparition
est progressive entre 3.5 et 7.5 secondes, donc absente au debut.
Les trois surfaces epousent la sphere de rayon 0.62 avec un ecart de 0.006,
pour rester dans sa silhouette sous les vues obliques. Pas de deformation
de sommet sur ces trois surfaces ; UV de la texture peinte animees.
Les grands contours externes sont attenues pour privilegier l'oeil central.
Texture v8 inchangee, aucune generation d'image supplementaire.

Validation native : controles existants passent, aucun stderr ; unicite
du noyau, ouverture sans noyau, croissance fixe/concentrique, recherche,
pause/reprise, trois formats et captures de transition conserves.
Retour GPU a t=7 identique. Rendu frontal et oblique inspecte visuellement.
360 captures natives, 24 secondes, 15 fps dans animation.webp.
Sources et logs dans source/. prepare.cjs encode les captures natives.
Prototype isole, sans integration au decor/jeu, saves, APK, commit ou push.
