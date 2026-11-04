MAITRE D'ENERGIE — MATIERE PEINTE ET VOLUTES
4 novembre 2026

Demande : rapprocher le rendu anime de la maquette v3-vortex-eye avant
integration au sanctuaire. Chronologie v7 conservee : vortex seul 0-3 s,
un seul noyau emerge 3-8 s, silhouette de l'oeil 5.5-9 s.

Le shader procedural seul produisait des bandes roses trop regulieres.
Le rendu actif utilise maintenant energy_master_painted.gdshader : texture
native peinte sur l'entonnoir concave, les trois surfaces d'iris et les
rubans courbes. Coordonnees polaires animees par clock_time, modulation
douce du rayon et du relief ; aucune horloge TIME. Sphere noire physique,
six volutes distinctes en profondeur et contours en amande plus larges.
Le petit trou geometrique du vortex a ete reduit de 0.12 a 0.015 pour
eviter de suggerer une pupille avant l'emergence.

Texture creee par ImageGen integre avec la maquette v3 comme reference.
Prompt exact : prompt.txt. PNG original copie sans retouche de pixels ni
modification de son alpha dans :
assets/previews/energy-master/painted-energy.png
1254x1254 RGBA, 1504418 octets.
SHA256 ec4cc1ce897eda4ae011c1a3d44c3b0abbbafb18691c5f5ec4a791e978aadbfb
Source native : C:/Users/A/.codex/generated_images/01a1a181-6ee9-7241-b413-6580736dc500/exec-346b38e5-96db-4fc9-b852-b5cb600b4c58.png
Alpha : 792463 pixels transparents, 779568 partiels, 485 opaques.
Le fichier de projet contient exactement les octets du natif.

Validation : import et rendu natif Godot 4.7.2, aucun echec, stderr vide.
Unicite/absence initiale du noyau, croissance et mouvement continus,
pause/reprise, recherche, formats 1280x720/390x844/844x390 ; vues a +/-38 deg.
Retour GPU a t=7 : un canal different de 1/255, sous tolerance documentee.
Native screenshots inspectes en paysage, portrait et vue oblique.
Animation : 360 captures a 15 images/s, 24 secondes, rotation active.
prepare.cjs encode les captures artifacts/energy-master/frames en WebP.
Les sources utilisees et les logs sont archives dans source/ ; before/
preserve le prototype procedural precedent. comparison.png : v7 a gauche,
nouvelle version a droite, cadrage natif identique.

Limites : adaptation animee de la maquette, pas une reproduction exacte.
Art a valider par l'utilisateur. Materiaux translucides sur surfaces 3D,
pas une simulation volumetrique ou gravitationnelle. Pas de son, evaluation
telephone, integration a l'introduction, modification de sauvegarde, APK,
commit ou push. L'ancien shader procedural est conserve sans modification.
