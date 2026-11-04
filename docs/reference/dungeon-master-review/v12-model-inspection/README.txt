OEIL ET VOLUTE MESHY — INSPECTION ET ASSEMBLAGE STATIQUE
4 novembre 2026

Fichiers utilisateur archives a l'identique dans ../source :
eye-original.glb : 12396216 octets
volute-original.glb : 12490860 octets
provenance.json conserve les chemins d'origine et SHA256. Aucun changement
aux GLB des Downloads ou aux originaux archives.

Blender 5.2.1 en processus background dedie. Pas de modification d'une
session Blender ouverte, du jeu, de l'introduction ou du prototype Godot.
Chaque modele : un maillage, un materiau, une couche UV et trois textures
2048x2048 embarquees (couleur, normale, metal/roughness).
Oeil : 10283 sommets / 10282 triangles.
Volute : 9380 sommets / 10244 triangles.
Aucun squelette, aucune animation, aucune shape key dans ces deux GLB.
L'iris et la pupille ne sont pas des objets mobiles separes du corps de l'oeil.

Rendus individuels : eye-*.png / volute-*.png ; sources de travail packees :
eye-inspection.blend et volute-inspection.blend.
master-assembly.blend propose un placement avec deux racines independantes :
Eye_Control et Volute_Control. Seules des transformations d'objets sont
appliquees, sans fusion, repeinture, changement des UV ou deformation.
La volute est agrandie uniformement a 2.4 et placee autour du noyau.
Valeurs exactes, essais de placement et limites dans assembly.json.
Les trois vues assembly-*.png montrent cet assemblage statique.

Verification : empreintes geometrie/UV identiques avant/apres et au rechargement
du blend, six images packees presentes, hashes des GLB inchanges. Aucun
candidat d'intersection de surfaces BVH a la pose retenue. Ce controle ne
valide pas une animation, les volumes contenus ni toutes les auto-collisions.
Le rendu utilise les materiaux originaux et un eclairage de studio neutre.
La lueur, la brume, la preparation des parties mobiles et l'animation restent
a faire. La rigidite de l'oeil necessitera un travail de deformation pour
l'ouverture ; la volute peut deja etre pilotee independamment comme objet.

Scripts : prepare.py (archive), inspect.py (inspection/rendus), assemble.py
(placement), verify.py (rechargement). Rendus frontaux des deux objets,
oeil en vue oblique et assemblage de face/en oblique examines visuellement.
Processus : exit 0. inspect.py emet un avertissement de deprecation pour
World.use_nodes dans Blender 6.0, sans erreur de rendu. Assemblage/verification
sans erreur. Aucune validation sur telephone, aucun upload Meshy, rig,
export APK, commit ou push.
