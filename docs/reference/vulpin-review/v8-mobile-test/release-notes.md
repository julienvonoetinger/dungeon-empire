Application Android de test du mannequin animé Vulpin.

- Installation séparée : **Vulpin — animations**, identifiant `org.dungeonempire.vulpinreview`. Aucune session de jeu ni sauvegarde du donjon n'est chargée.
- Neuf états, chacun dans quatre orientations : attente, marche, course, dégâts, crochetage de porte/coffre, ramassage, chute et mort.
- Trois profils : 128 équilibré (par défaut), 96 léger et 160 référence.
- Pause, reprise, rejeu, ralenti 0,5×, détail ×2 et déplacement de la vue au doigt.
- Paysage et portrait, avec contrôles adaptés aux petits écrans.

Il s'agit du mannequin sans textures finales. Les gestes restent des propositions. La vitesse de la démonstration correspond aux foulées du mannequin ; aucune règle ou vitesse du jeu principal n'est modifiée. Les pistes de marche/course recommencent après quatre cycles.

L'APK de test inclut le moteur Godot pour ARM 32 et 64 bits, le décor et les trois profils. Son poids total n'est pas le poids du héros seul. Android 7.0 / API 24 minimum. Signature de test.

Validation sur PC : import et export réussis ; signature v2/v3 vérifiée ; 578 contrôles sans échec sur les ressources exactes extraites de l'APK, dont les neuf états/quatre vues/trois profils, arrêt final, pause, contrôles tactiles et six tailles d'écran. Orientation Android fullUser vérifiée. Aucun essai physique sur téléphone ni profilage mobile effectué.

Construit depuis l'espace de travail du 27 octobre 2026, y compris les sources de revue non encore commitées. Le tag désigne le commit de base ; les archives de sources automatiques de GitHub ne reproduisent pas exactement ce binaire.

SHA-256 : `f67a7a75416a3752243a8389e9d7e1581907b0ba45d813f28e6994bb58b09bd3`
