# Proposition d’interface mobile — noir et or

Le style noir et or, proche de la maquette d’origine, et la priorité mobile sont
des choix explicites de l’utilisateur. La disposition présentée ici est une
proposition à examiner ; elle n’est pas encore intégrée au HUD Godot.

## Navigation proposée

- Ressources et état du cœur en haut, phase de jeu au centre, pause et recentrage
  à droite. Le terrain reste visible entre les commandes.
- Deux actions principales en bas : **Bâtir** et **Lancer le raid**.
- Le catalogue inférieur regroupe les onze outils actuels dans Terrain,
  Défenses et Trésors. Les prix et niveaux viennent des scripts de jeu existants.
- Choisir un outil replie le catalogue et affiche une barre de pose avec prix,
  annulation et confirmation. Les opérations restent explicites au toucher.
- Pendant le raid, les commandes de construction laissent place à l’état du
  visiteur. Pause et bilan utilisent le même langage visuel.

Toutes les commandes du jeu dans cette proposition mesurent au moins 48 × 48
pixels CSS. Les actions principales mesurent 56 pixels de haut au format mobile.
Les marges tiennent compte des zones sûres exposées par le navigateur. Le dessin
privilégie le paysage, conformément à la référence ; le portrait n’est pas un
format produit validé. La taille physique devra être vérifiée sur téléphone lors
du portage dans Godot, sans simplement réduire une interface de bureau.

## Voir et reproduire

Ouvrir `index.html` dans un navigateur. Les boutons sous le donjon permettent de
voir Donjon, Catalogue, Pose, Raid et Bilan. Les boutons du HUD sont également
cliquables pour explorer l’enchaînement. Les valeurs sont illustratives ; il n’y a
ni simulation, ni modification de sauvegarde, ni placement réel dans cette page.

`render.cjs` produit onze captures dans `captures/` : 844 × 390, 740 × 360 et
1280 × 720. Il utilise Playwright et une nouvelle instance de Chrome **sans
fenêtre**, sans profil utilisateur et sans connexion aux applications ouvertes.
Le chemin du navigateur peut être fourni via `UI_REVIEW_BROWSER`.

```powershell
$env:NODE_PATH = 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe' 'docs/reference/interface-review/v1/render.cjs'
```

Le rendu a terminé avec onze captures, aucune erreur JavaScript, aucun débordement
de page et aucune commande visible sous 48 × 48 pixels. Les captures des vues
principales ont été inspectées. Ce sont des vérifications de la maquette locale,
pas une validation tactile sur appareil, ni des tests automatisés du jeu.

## Sources et limites

- Fond inchangé : `docs/reference/isometric-prop-review/v1/integration/DungeonPreview-heart-room.png`,
  capture Godot existante. Il est ajusté au cadre HTML pour illustrer l’interface ;
  cela ne définit aucun nouveau zoom ou réglage de caméra pour le jeu.
- Référence de style : `docs/reference/mobile-optimization/source/mockup.png`.
- Habillage et pictogrammes : CSS et SVG dans le fichier HTML, sans nouvelle
  dépendance ou texture de production.
- Les détails des coffres/transferts, l’ancrage initial du cœur, les erreurs de
  pose, les confirmations de réinitialisation et les états de défaite restent à
  décliner dans le portage. Leurs règles et protections existantes doivent être
  préservées ; cette proposition ne modifie pas l’économie ou la boucle de jeu.

Aucun script, scène, atlas, réglage de caméra ou sauvegarde de production n’a été
modifié pour cette proposition. Aucune prise de contrôle de l’écran, aucun commit
ou push.
