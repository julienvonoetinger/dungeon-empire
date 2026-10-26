# Interface mobile noir et or — 25 octobre 2026

L'utilisateur a demandé l'intégration de la proposition
`docs/reference/interface-review/v1/index.html`, en donnant la priorité au mobile.
Le HUD natif de `scenes/game/DungeonGame.tscn` remplace l'ancien panneau latéral.

## Implémentation

- `game_hud.gd` : ressources, phase, catalogue repliable, pose et sélection,
  visiteur, accueil, pause, bilan/défaite et confirmations.
- `ui/hud_theme.gd` : thème noir/or, panneaux extensibles et commandes tactiles.
- `ui/hud_catalog.gd` : onze outils existants en trois familles, niveaux affichés.
- `ui/hud_selection.gd` : coût réel/raison du refus, collecte, absorption et
  transferts bornés avec choix du coffre et pas de 1/25/max.
- `game_session.gd` : un indicateur d'ouverture du catalogue suspend uniquement
  le compte à rebours. Règles, sauvegardes et gardes économiques conservées.
- `game_input.gd` : protection tactile du HUD, routage Échap/Retour Android.
  Le comportement Android s'appuie sur `SceneTree.quit_on_go_back`, désactivé
  pendant cette scène puis restauré à sa sortie, et `Window.go_back_requested`
  ([documentation Godot](https://docs.godotengine.org/en/stable/classes/class_scenetree.html#class-scenetree-property-quit-on-go-back)).

19 petits SVG, **12 419 octets source**, sont préparés par
`tools/prepare_game_hud_assets.cjs`. Les icônes proviennent de la proposition
HTML ; les quatre surfaces utilisent des marges extensibles. Aucun nouvel asset
de donjon ni atlas modifié. Ce chiffre est la taille des sources SVG, pas une
mesure mémoire GPU ni la taille d'un APK.

L'échelle du HUD est indépendante de la caméra. Les cibles font au moins
48×48 unités, les actions principales 56 de haut. La densité et les zones sûres
mobiles viennent de DisplayServer. Les dialogues et contextes trop hauts défilent.
Le jeu reste destiné au paysage ; la taille physique réelle dépend encore des
informations fournies par le téléphone et doit être contrôlée sur appareil.

## Vérifications effectuées

Import Godot et lancement de DungeonGame en mode headless, slot `--review-session`
isolé : codes de sortie 0, stderr vide pour l'import et le démarrage de 12 images.
Les sorties finales sont conservées dans `artifacts/hud-import.*.log` et
`artifacts/hud-startup.*.log`. Aucun contrôle de l'écran, aucune interruption de
l'éditeur/jeu existant et aucune commande d'écriture de la sauvegarde du joueur.

`tools/capture_game_hud_layout.gd` recueille les rectangles des contrôles Godot
de **42 présentations statiques** : accueil, préparation, catalogue, pose,
pose refusée, coffre, transfert, transfert avec corps/butin, raid, pause,
confirmation, bilan, défaite et sauvegarde illisible, à
**740×360**, **844×390** et **1280×720**. Il désactive le processus de simulation
et emploie des fixtures en mémoire, sans appeler les commandes du joueur ni
sauvegarder. Résultat : `artifacts/hud-layout.json`, code 0 et stderr vide.
Ce relevé mesure la disposition ; il ne valide pas une partie jouée ni le rendu GPU.

La barre de pose mesure 76 unités de haut à 740×360. Aucune commande recensée
n'a une taille nominale inférieure à 48×48. Les éléments situés hors de la zone
visible d'un panneau défilant restent accessibles par défilement.

Une revue indépendante du code a identifié le recouvrement partiel du recentrage
par le transfert : corrigé en masquant ce bouton si les panneaux se croisent.
La revue a aussi relevé la perte de précision avec seulement ±25 : ajout de ±1.
Les panneaux contextuels avec butin/corps sont désormais limités en hauteur et
défilants. Les nouvelles géométries ont été relevées après ces corrections.

## Limites

Pas de tests automatisés du gameplay, conformément à l'instruction du dépôt.
Pas de validation tactile réelle, de profilage téléphone/APK, ni d'inspection
visuelle du nouveau HUD dans une fenêtre Godot : l'utilisateur utilise son
ordinateur et a interdit la prise de contrôle. La validation interactive complète
du raid et de l'économie reste celle indiquée dans le relevé précédent.

Pour voir le rendu natif : ouvrir **DungeonGame.tscn**, puis **F6**. Le réglage de
scène principale local dans `project.godot` n'a pas été modifié. Aucun commit/push.
