Batrafian — inspection et équipement statique
1 novembre 2026

Entrées
Les quatre GLB originaux sont archivés dans ../source, avec provenance et SHA256.
Blender 5.2.1 LTS, processus indépendant en arrière-plan. Aucun fichier de jeu
ou scène Blender ouverte par l'utilisateur n'est modifié.

Inspection
Corps : 26 os, 13 176 sommets, 10 350 triangles. Aucun sommet sans poids.
Les 25 os pondérés non racine déforment le modèle et retrouvent la pose d'origine
après une rotation de contrôle. Textures intégrées, aucun clip d'animation.
Arc : 10 244 triangles ; carquois : 10 049 ; flèche : 9 797.
Ces modèles servent à produire des sprites, pas à charger ces géométries sur mobile.

Montage proposé
Arc main gauche, lié à Bone_023 ; carquois dans le dos, lié au torse Bone_003.
Les bras utilisent les chaînes gauches025→024→023 et droites021→020→019.
Pas de copie des numéros d'os du Paladin. Avant du modèle : -Y ; vertical : Z.
Les passants du carquois sont tournés vers le corps. Sa position est réglée
après contrôle des intersections (première proposition : 122 contacts de surface).
Les accessoires sont redimensionnés uniformément : arc1.25, carquois.92 avant
inclinaison, flèche.79, pour un corps de hauteur1.70. Maillages/peintures conservés.
La flèche reste indépendante et masquée dans la pose de repos, prête à recevoir
ultérieurement un attachement main/corde ou un comportement de projectile.

Limites
Cette étape est une proposition d'équipement statique, pas une animation validée.
Le rig comporte un os distal commun aux doigts de chaque main, aucun contrôle
individuel des doigts. La prise actuelle est approximative ; un rig de main plus
fin sera utile pour serrer l'arc et tenir l'encoche pendant le tir.
L'arc et sa corde sont des objets rigides. Leur flexion et la tension de corde
restent à préparer pour l'attaque. Le carquois et ses flèches forment un seul mesh.
Les vérifications de surface excluent la zone de prise de l'arc. Elles ne prouvent
ni l'absence de volumes entièrement contenus, ni la qualité des futures poses.
Pas d'intégration runtime, d'animation, de modification de sauvegarde ou d'APK.

Rendus et vérifications
Six vues du même modèle : face, dos et quatre directions isométriques à30°.
Cadrage orthographique commun, PNG alpha768px, Cycles32, Standard/None.
batrafian-equipped-review.blend conserve les12 images intégrées et les attaches.
inspection.json consigne géométrie, poids, noms/positions des os et essais.
equipment-fit.json consigne les paramètres du montage.
saved-scene-validation.json résume le rechargement, les sources et attaches.

Reproduction depuis la racine du dépôt (PowerShell)
$blender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$review = 'docs/reference/batrafian-review/v2-meshy-inspection'
& $blender --background --python-exit-code 1 --python "$review/inspect_models.py"
& $blender --background --python-exit-code 1 --python "$review/assemble_preview.py"
& $blender --background --python-exit-code 1 --python "$review/verify_saved.py"
Vérifier chaque code de sortie avant de poursuivre. -- --pilot après le script
d'assemblage rend seulement SW et dos ; refaire la série complète avant validation.
