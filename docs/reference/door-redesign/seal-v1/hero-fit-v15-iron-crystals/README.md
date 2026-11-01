# Porte en métal, pierre et cristaux — intégrée le 1er novembre 2026

L’utilisateur trouve la porte décalée par rapport à l’interface et choisit « métal, pierre et avec les cristaux ». La proposition du 31 octobre remplace le bois bordeaux par du fer bleuté noirci et un groupe de cristaux violets enchâssés dans les ferrures. Le 1er novembre, « ok applique cette porte au jeu » autorise son intégration : `selection.json` est désormais la sélection du générateur partagé et les atlas du jeu sont régénérés.

`source/face-source.png` est la sortie native du générateur ImageGen intégré, copie de `exec-6edb400d-7bf4-4337-bc41-4b1482a7956f.png`. `source/prompt.txt` contient la consigne exacte. Cible : source v13 du battant ; références : header-c-center et capture native detail-standing v13. Aucun dessin manuel par script. La projection déterministe réutilise le récepteur lisse, la caméra, le découpage indépendant des montants et les UV validés.

La nouvelle image sert seulement de matériau au battant. La maçonnerie existante reste celle du kit, pour conserver la palette des murs. Les pixels voisins du battant peuvent varier dans la frange de filtrage et le recouvrement de 2 pixels des parties de porte ; la vérification exclut une frange de 3 pixels comme le précédent contrôle de remplacement du battant. Géométrie, cadres, supports et contacts aux murs sont identiques. Le pixel de contact (512,1138) reste dans le trou noir de la serrure. `proposal-preservation.json` conserve la preuve historique avant installation ; `preservation.json` décrit la dernière génération de revue sans mutation des atlas, indépendamment de leur version installée.

Reproduction de la comparaison depuis la racine, Node avec sharp disponible :

```powershell
node tools/prepare_crystal_door_review.cjs
godot --path . --script res://tools/capture_crystal_door_review.gd
```

`isometric_seal_texture.render` et `isometric_seal_door.paint` acceptent une source de battant facultative ; sans cet argument, leur sélection de production est maintenant v15. La revue impose explicitement l’ancienne source v13 pour ses vues « avant », afin de conserver une comparaison reproductible après installation.

Reproduction du kit installé et des captures utilisant les ressources de production :

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import --quit
godot --path . --script res://tools/capture_integrated_compact_door.gd -- --output=res://artifacts/crystal-door-integration/native
```

La vérification d’intégration (`tools/verify_crystal_door_integration.cjs`) compare l’atlas avec les 16 parties fermées approuvées. Son état de référence a été enregistré avec `--record` avant installation ; cette commande refuse d’écraser cet état. Les 16 écarts initiaux deviennent 361 contrôles réussis, sans échec. Les 155 autres régions, dont les 12 parties des cadres ouverts, les métadonnées des 171 sprites et les 37 fichiers de héros contrôlés restent identiques. Les PNG du kit perdent 2 307 octets ; l’allocation RGBA reste de 13 631 488 octets (13 Mio). Rapport conservé dans `integration.json`.

Validation native après import : ouverture/réparation/suppression des portes 84 contrôles, badges 87, traversée 863, comportement Vulpin 367, tous réussis avec stderr vide. La capture de production vérifie aussi 32 contacts de crochetage et 64 poses centrales de passage dans les quatre directions. Les captures de porte fermée, crochetage et passage ont été inspectées ; `runtime/` en conserve trois exemples. Logs complets dans `artifacts/crystal-door-integration/`.

Les cristaux restent un relief peint sur le battant, sans nouveau volume 3D. Aucun accès aux sauvegardes du joueur, APK, commit ou push. Cette validation native ne remplace pas un test sur téléphone physique.
