LITHIDE — PRISES DU MARTEAU ET DU BOUCLIER
1 novembre 2026 — correction de la pose fixe, en attente de retour visuel.

La v2 a été rejetée pour le placement des accessoires. Elle conservait la pose
en A, des mains ouvertes et des axes d'accessoires verticaux approximatifs.
Un test d'attachement à un os ne prouvait pas une prise correcte : le marteau
traversait l'avant-bras et l'épaule. Le bouclier croisait aussi l'armure.

La v3 pose les bras à longueur constante, avec les coudes fléchis. Rotation des
paumes et fermeture des doigts via les os existants. Le manche passe entre les
doigts et le pouce ; le bouclier est tenu par son attache dorée arrière native.
Le contrôle rapproché a révélé cette attache, initialement mal identifiée :
aucune poignée supplémentaire n'est conservée. Le pouce droit a été recourbé
autour du bois après inspection d'un premier essai qui le faisait traverser.

Correction suivante demandée par l'utilisateur : rotation du marteau de -90°
autour de son manche, au point de prise. L'axe des faces de frappe passe de X
(gauche/droite) à -Y (avant/arrière). Pose des mains, bouclier et échelle inchangés.
before-hammer-turn.png conserve l'ancien aperçu. Le validateur contrôle l'axe
réel du marteau rechargé, le manche vertical et l'absence de déplacement de prise.

Modèles, topologie, UV, textures et proportions des accessoires inchangés.
Marteau 1.04 et bouclier 1.16 pour un personnage de hauteur 1.70. Fixations
rigides aux poignets Bone_023 et Bone_019. Points de prise en equipment-fit.json.
Le script conserve les rotations détaillées des doigts. Les originaux GLB et
leurs hashes restent dans ../source. Aucun ajout d'objet au jeu.

Livrables : paladin-equipped-review.blend, six vues complètes à même échelle,
gros plans hammer-grip.png et shield-grip.png, deux vues du bouclier seul,
rapports, scripts et journaux. Textures intégrées dans le .blend. Les vues
isométriques ont une élévation de 30 degrés ; face/dos sont orthographiques.

Reproduction depuis la racine du dépôt, Blender 5.2.1 LTS, processus séparés :
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v2-meshy-inspection/inspect_models.py
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v2-meshy-inspection/assemble_preview.py
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v3-equipment-grips/fit_equipment.py
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v3-equipment-grips/inspect_grips.py
  blender --background --python-exit-code 1 --python docs/reference/lithide-review/v3-equipment-grips/verify_fit.py

Le vérificateur recharge les deux scènes. Il teste les intersections des arêtes
des accessoires avec les triangles du corps et réciproquement, en excluant la
main qui tient chaque objet (contact attendu). V2 : marteau 403 intersections,
bouclier 75 ; v3 : aucune intersection détectée hors des mains. Attache stable
lors d'une rotation de poignet de 8 degrés et restauration contrôlée ; neuf
images embarquées et hashes des GLB archivés vérifiés.

Limites : contrôle d'une pose fixe, pas de toute une animation. La méthode
géométrique ne prouve pas l'absence d'un volume complètement inclus dans un autre,
ni une prise parfaite ; les contacts des mains sont inspectés dans les rendus.
Les cadrages de détail coupent volontairement le reste du personnage. Aucune
validation de marche/combat, aucun sprite de production, aucune modification
du jeu, sauvegarde joueur, APK, commit ou push. docs/.gdignore exclut ces sources.
