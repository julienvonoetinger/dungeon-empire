MAITRE D'ENERGIE — LE VORTEX PUIS L'OEIL
4 novembre 2026

Demande utilisateur : commencer par un vortex et faire sortir l'oeil de celui-ci.
Cette mise en scene remplace l'apparition simultanee de v4-native-prototype.

0-3 secondes : apparition du tourbillon seul. Un entonnoir concave et une petite
gorge obscure donnent de la profondeur ; aucun element de l'oeil n'est visible.
3-8 secondes : le noyau et l'iris emergent du fond. Le groupe EyeEmergence
avance de z=-0.85 a z=+0.55 et passe progressivement de 10 a 100 % d'echelle.
5.5-9 secondes : les arcs de l'oeil se dessinent, puis le regard se stabilise.
Le vortex reste derriere, plus discret. Dissipation en fin de cycle (22-24 s).
Le bouton Regard ne saute pas l'ouverture du vortex.

Scene : scenes/previews/EnergyMasterPreview.tscn. Toujours un prototype separe
du sanctuaire et du jeu. Les controles de lecture et de vue sont conserves.

Validation native : les quatre controles d'ordre d'apparition echouaient sur
la version precedente ; ils passent sur celle-ci. Deplacement et croissance
de l'oeil, pause/reprise, recherche deterministe, changement visuel anime et
trois formats d'ecran verifies. Les comparaisons GPU attendent deux images
de rendu pour laisser se stabiliser le redimensionnement du SubViewport et
les transformations du groupe ; l'horloge d'animation reste explicite.
Zero echec final ; captures 2.5 / 5.5 / 9 secondes inspectees.

animation.webp : captures natives a 15 images/s, cycle de 24 secondes avec
rotation active. La fenetre interactive anime a la cadence de rendu.
prepare.cjs reproduit l'encodage depuis artifacts/energy-master/frames.
Les limites de v4 restent valables : pas de vraie lentille gravitationnelle,
integration au decor, son ou evaluation sur telephone.
