# Sources actuelles des animations du Vulpin

État du 28 octobre 2026. Commencer par le
[guide réutilisable pour les héros](../../production/hero-animation-pipeline.md)
et les [commandes de reproduction](../../production/hero-animation-reproduction.md).
L'[original Meshy](source/README.md) est archivé avec les recettes. Le
[manifeste](pipeline-manifest.json) permet de détecter une source manquante ou
modifiée. Ces scènes ne remplacent pas encore les héros de la simulation.

## Recettes à reprendre

Chaque dossier animé contient `poses.json`, `prepare.cjs`,
`verify_saved_poses.py`, un `.blend` avec les poses fixes et les rapports.
Le repos réutilise les textures neutres, sans nouveau rendu.

| État | Source actuelle | Poses par direction et cadence native | Scène Godot |
| --- | --- | --- | --- |
| Repos | [v23](v23-static-idle/), région neutre de v19 | 1 fixe | [VulpinIdle](../../../scenes/VulpinIdle.tscn) |
| Marche | [v16 render_walk.py](v16-meshy-walk/render_walk.py) | 8, 15 poses/s effectives ; boucle 0.5333 s | [VulpinWalk](../../../scenes/VulpinWalk.tscn) |
| Course | [v17 render_run.py](v17-meshy-run/render_run.py) | 8, 16 poses/s ; boucle 0.5 s | [VulpinRun](../../../scenes/VulpinRun.tscn) |
| Dégâts | [v19 render_hurt.py](v19-hurt-recoil/render_hurt.py) | 8, 720 ms sans boucle, retour au neutre | [VulpinHurt](../../../scenes/VulpinHurt.tscn) |
| Crocheter une porte | [v26 render_lockpick.py](v26-lower-lock-review/render_lockpick.py) | 8, 8 poses/s ; boucle 1 s ; serrure Z=.32 | [VulpinLockpick](../../../scenes/VulpinLockpick.tscn) |
| Prendre dans un coffre déverrouillé | [v21 render_chest_open.py](v21-chest-open/render_chest_open.py) | 8, 1.08 s sans boucle ; coffre toujours entrouvert | [VulpinChestOpen](../../../scenes/VulpinChestOpen.tscn) |
| Crocheter un coffre verrouillé | [v22 render_chest_lockpick.py](v22-chest-lockpick/render_chest_lockpick.py) | 8, 8 poses/s ; boucle 1 s, coffre toujours fermé | [VulpinChestLockpick](../../../scenes/VulpinChestLockpick.tscn) |
| Chute puis mort | [v24 render_fall.py](v24-meshy-dead/render_fall.py) | 10, 550 ms sans boucle ; mort fixe = pose 9 | [VulpinDeath](../../../scenes/VulpinDeath.tscn) |

Les assets natifs sont dans [assets/previews](../../../assets/previews/), dossiers
`vulpin-idle`, `vulpin-walk`, `vulpin-run`, `vulpin-hurt`, `vulpin-lockpick`,
`vulpin-chest-open`, `vulpin-chest-lockpick` et **`vulpin-death`**.
Ils contiennent `frames.tres` et `SOURCE.txt` ; les interactions et la chute
ajoutent `registration.json`. Ne pas confondre `v24-meshy-dead` avec le nom du
dossier runtime `vulpin-death`.

La marche est le cas particulier de cadence : ressources et anciens WebP
restent à 10 poses/s ; `base_playback_rate=1.5` dans la scène native donne le
nouveau ×1 utilisateur. Les autres multiplicateurs sont relatifs à cette base.
Le repos prend la région 0 des feuilles de dégâts ; la séquence dégâts joue
les régions `1,2,3,4,5,6,7,0`. Ne pas remplacer le repos par la première région
jouée de l'animation dégâts.

## Sources de placement et preuves

- [Inspection du GLB](v15-meshy-inspection/inspection.json) et os de repos.
- [Géométrie compacte de porte intégrée](../door-redesign/seal-v1/hero-fit-v12-integrated/geometry.json).
- [Passage et séparation porte/héros](../../../tools/verify_compact_door_passage.py).
- [Mesures des serrures de coffre](v22-chest-lockpick/calibrate_chests.cjs),
  [contacts](v22-chest-lockpick/chest-contacts.json) et
  [séparation par hauteur](v22-chest-lockpick/verify_chest_clearance.py).
- [Relecture des dix poses de chute et des bras finaux](v24-meshy-dead/verify_saved_poses.py).
- Les rapports natifs actuels sont dans `native-corridors/validation.json`
  pour v16/v17 et `native-scene/validation.json` pour v19/v26/v21/v22/v24.
  Pour v23, `capture.gd` et les trois PNG constituent le contrôle natif.
- Chaque scène s'ouvre avec F6 ; elle n'instancie pas de partie ni de sauvegarde.
  Les [outils de capture](../../../tools/) vérifient les comportements natifs.

## Coût des textures actuelles

| Action | PNG des feuilles ou atlas | RGBA décodé |
| --- | ---: | ---: |
| Marche | 1 087 233 octets | 8 MiB |
| Course | 1 138 660 octets | 8 MiB |
| Dégâts et repos partagé | 1 235 647 octets | 8 MiB |
| Crochetage porte | 894 106 octets | 8 MiB |
| Coffre déverrouillé | 1 102 311 octets | 8 MiB |
| Crochetage coffre | 847 196 octets | 8 MiB |
| Chute et mort partagée | 1 435 199 octets | 5 386 240 octets, environ 5.14 MiB |

Ces valeurs concernent les textures de revue, pas un budget mobile final.
Le coût RGBA est celui de toutes les pages concernées décodées, hors copies
CPU et moteur. Ne pas multiplier les chiffres des anciens mannequins pour
estimer le coût des nouveaux héros peints. La chute illustre un empaquetage
plus compact qui pourrait être appliqué aux autres actions après validation.

## Historique à ne pas confondre avec les sources actuelles

| Versions | Rôle et limite |
| --- | --- |
| v1, v2 | Propositions initiales, armes abandonnées |
| v3, v4 | Identité sans armes et intentions de poses ; pas de cycles animés calibrés |
| v5 | Images de marche générées incohérentes entre elles ; essai non retenu |
| v6 à v10 | Mannequin articulé et étude de poids ; ancien APK de test v8, ancienne mort statique v10 |
| v11, v12 | Peinture sur proxy puis morceaux attachés aux os ; rejetés pour qualité, pieds et clipping |
| v13 | Essai de sprites entiers générés ; aucune marche complète exploitable |
| v20, v25 | Anciennes poses de porte ; v25 à serrure haute masque les mains. Remplacées par v26 avec porte compacte |
| v14 | Vues de référence envoyables à Meshy, pas des rendus d'un modèle unique |
| v15 | Inspection du vrai modèle fourni, pas une animation |
| v18 | Dégâts trop brusques ressemblant à un éternuement ; remplacés par v19 |
| v24 `render_dead.py`, `render_side_pilot.py`, `pose.json` | Première recherche de cadavre sur le côté, remplacée par `render_fall.py` et `poses.json` |

Les dossiers de revue sont exclus des imports Godot par `.gdignore`, **pas
nécessairement de Git**. Les sources et cette documentation sont locales tant
qu'elles n'ont pas fait l'objet d'un commit et d'un push. Vérifier `git status`
et `git check-ignore` avant une sauvegarde ; ne pas supprimer l'historique en
supposant que tous ses fichiers sont régénérables.
