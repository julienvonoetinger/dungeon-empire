INVOCATEUR ET BATON MESHY — INSPECTION ET PROPOSITION STATIQUE
4 novembre 2026

Les deux GLB fournis par l'utilisateur sont copies sans modification dans
../source, avec leurs chemins d'origine, tailles et SHA256 dans provenance.json.
Travail dans un Blender 5.2.1 separe en arriere-plan. Aucun changement du jeu.

Personnage : 19 550 sommets, 10 216 triangles, 61 os, aucun sommet du corps
non pondere, aucun clip d'animation ni shape key. Les 59 os non racine ponderes
testes repondent a une rotation de cinq degres et retrouvent leur etat initial.
Le petit maillage de controle cree par l'importateur pour afficher le rig est
exclu des mesures et du cadrage du personnage. Taille du personnage : 1,70 unite.
Baton : 12 275 sommets, 10 330 triangles, pas de squelette. Six images 2048x2048
sont embarquees au total : couleur, normale et metal/rugosite par modele.

La proposition equipee conserve les maillages, UV, poids et materiaux d'origine.
Seuls les os du bras et des doigts gauches sont poses. Chaine propre a ce modele :
Bone_022 bras, Bone_021 avant-bras, Bone_020 poignet ; ne pas copier les numeros
du Mycean. Le baton est parent du point de vue fonctionnel au poignet (objet
enfant de l'armature, parent_type=BONE, parent_bone=Bone_020), echelle uniforme
0,98, position monde (0,435, -0,23, 0,955). Les doigts longs sont poses par leurs
chaines 036-033, 040-037 et 044-041. Pas de correction des poids ou repeinture.

Validation de la pose sauvegardee : zero croisement arete/surface entre le
baton et le corps entier, main comprise. Distance minimale de la zone de prise
au corps : 0,0070 unite ; ce n'est pas une contrainte physique de prehension.
Le baton reste a 0,0222 unite au-dessus du sol. Son attache suit une rotation
du poignet de 0,1 radian avec erreur relative maximale 1,2e-7. Hashes originaux
intacts. Rapport complet : equipment-validation.json.

La prise et la pose restent une proposition visuelle. Ces verifications ne
valident pas toutes les auto-collisions, volumes contenus, deformations du
manteau ni animations futures. Aucun mouvement de marche ou rituel produit.

Fichiers utiles :
equipped-overview.png : face, trois-quarts isometrique, dos isometrique.
grip.png : detail de la prise ; front.png et iso-*.png : modele non equipe.
invoker-equipped.blend : montage avec les six textures embarquees.
invoker-inspection.blend : personnage importe dans sa pose d'origine.
combined-source.blend : deux sources importees avant la pose.

Reproduction, depuis la racine du depot, avec Blender en arriere-plan :
  blender --background --python-exit-code 1 --python docs/reference/invoker-review/v3-meshy-inspection/inspect.py
  blender --background --python-exit-code 1 --python docs/reference/invoker-review/v3-meshy-inspection/staff_probe.py
  blender --background --python-exit-code 1 --python docs/reference/invoker-review/v3-meshy-inspection/equip.py
  blender --background --python-exit-code 1 --python docs/reference/invoker-review/v3-meshy-inspection/verify_equipped.py

L'essai historique equip-contact-rejected.py utilisait une enveloppe de contact
et une subdivision : cela ne resolvait pas la mauvaise position initiale du
manche. Il est abandonne. Le montage retenu replace le manche dans l'ouverture
de la main sans ces modificateurs. find_grip.py conserve l'exploration des
translations ; ne pas confondre cette exploration avec le montage selectionne.
Sources et revues exclues des exports du jeu par docs/.gdignore.
