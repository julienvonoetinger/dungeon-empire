LITHIDE — INSPECTION DES GLB ET ASSEMBLAGE PROVISOIRE
1 novembre 2026

ASSEMBLAGE REJETÉ pour le placement des accessoires. Inspection des sources
toujours valable ; nouvelle pose équipée dans ../v3-equipment-grips.

Les trois GLB fournis par l'utilisateur sont archivés sans modification dans
../source, avec leurs SHA256. Le modèle Meshy et sa peinture font désormais
autorité pour les futurs sprites ; les images v1 restent des intentions.

Résultats d'import (Blender 5.2.1 LTS) :
- Paladin : 14 680 sommets importés, 10 410 triangles, 50 os, aucun sommet
  sans poids. Les 49 os pondérés hors racine ont été tournés individuellement
  de 5 degrés puis restaurés, avec contrôle du déplacement et de la restauration.
- Marteau : 9 917 triangles. Bouclier : 9 743 triangles. Accessoires rigides.
- Trois textures embarquées par modèle, aucun clip d'animation fourni.

L'avant du personnage est -Y, Z est vertical. Les noms d'os ont été relevés
sur ce modèle : ne pas copier ceux du Vulpin. Voir inspection.json et
equipment-fit.json pour les chaînes, têtes/queues et premiers points de fixation.

Le paladin mesure 1,70 unité ; les accessoires importés mesurent environ1,90.
Dans l'assemblage de revue, le marteau est ramené uniformément à1,04 unité et
le bouclier à1,16. Marteau à la main droite (X négatif, Bone_023), bouclier à
la main gauche (X positif, Bone_019). Pas de déformation des accessoires ni de
retouche de leurs textures. Les prises et intersections restent à affiner
avec les poses : le personnage conserve ici sa pose neutre, doigts ouverts.

paladin-equipped-review.blend est le dérivé modifiable avec textures intégrées.
equipped-front.png et equipped-se/sw/nw/ne.png montrent l'assemblage statique.
Les quatre vues diagonales utilisent une élévation orthographique de30 degrés
comme la grille2:1 du jeu, à la même échelle entre vues. Ce cadrage de revue
n'est pas encore la registration/ancre des sprites de production.

Reproduction depuis la racine du dépôt, dans un Blender en arrière-plan :
blender --background --python-exit-code 1 --python docs/reference/lithide-review/v2-meshy-inspection/inspect_models.py
blender --background --python-exit-code 1 --python docs/reference/lithide-review/v2-meshy-inspection/assemble_preview.py
blender --background --python-exit-code 1 --python docs/reference/lithide-review/v2-meshy-inspection/verify_saved.py

Le premier script reconstruit inspection.blend (intermédiaire ignoré par Git).
Le second sauvegarde le modèle équipé ; le troisième le rouvre, contrôle les
attaches, leurs mouvements/restaurations, les textures embarquées et les hashes.
Les scripts ne doivent être exécutés que dans un processus Blender dédié :
ils chargent une scène vierge ou remplacent la scène du processus.

Les rendus du corps, des deux accessoires et de l'assemblage de face/isométrique
ont été inspectés. Les sondes de déformation prouvent la connexion des poids,
pas le naturel des mouvements ni l'absence de collisions sur toute leur plage.
Aucune animation, intégration Godot, modification de sauvegarde ou compilation
APK dans cette étape. Le workflow complet pour les poses et sprites reste dans
docs/production/hero-animation-pipeline.md.
