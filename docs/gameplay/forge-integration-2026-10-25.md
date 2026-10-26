# Forge et roche excavée — intégration du 25 octobre 2026

L'utilisateur a demandé l'implémentation de la maquette v9. Sa sélection est
enregistrée dans `docs/reference/interface-review/v9-rock-cutout/selection.json`.
Les anciennes notes et captures de proposition sont conservées telles quelles.

## Résultat natif

- Forge en pierre bleue et corruption violette, avec icônes peintes et marges
  intérieures. Colonne outils de 136 unités, observation de 56, panneaux de 244
  maximum. Un SubViewport séparé réserve réellement le reste de l'écran au monde.
- Catalogue défilant, choix d'outil puis repli ; troisième raccourci remplacé
  par le dernier outil choisi. Les cartes passent sur une colonne sous 234 unités.
- Pose directe et répétée sur roche/sol approprié ; glisser-déposer depuis la
  palette, cible relevée de 52 unités. Déplacer la vue ne pose rien. Le cœur et
  les remplacements conservent une confirmation. Prix, niveaux et règles restent
  ceux de la simulation existante.
- Annulation des 32 dernières constructions au maximum, uniquement pendant cette
  session de préparation. Historique effacé au raid, redémarrage, collecte,
  absorption et transfert ; aucune modification du format de sauvegarde.
- Découpe réelle de la roche autour de l'union des cases, marge de 0,90 case,
  sommet à hauteur des murs (0,3133333333333333), sol brut à z=0 et tranches
  visibles. Les trois maillages sont recalculés quand les cases excavées changent,
  pas à chaque image ni lors du déplacement de caméra.

Les matières gardent les pixels approuvés ; leur distribution dans le shader
est une adaptation économique au GPU, pas une reproduction pixel pour pixel du
composite Canvas2D. La couverture est bornée à la carte actuelle de 16×16 et sa
marge de caméra. Aucun streaming de monde infini ni performance mobile mesurée.

Treize PNG sont adoptés par `tools/prepare_native_forge.cjs` : douze copies
identiques, plus le panneau pierre réduit uniformément à 64×64 pour ses bordures
extensibles natives de 11 pixels. Provenance : `assets/ui/forge/provenance.json`.
Les atlas du donjon et sources approuvées ne sont pas repeints pour cette UI.
Les anciens symboles utilitaires sont conservés ; les décors n'acquièrent pas
de nouvelle économie de placement.

La police MSDF du thème évite le flou dû au changement d'échelle du HUD
([documentation Godot sur les polices et l'échelle](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-property-scale)).

## Vérifications effectuées

Import Godot 4.7.2 : sortie 0, stderr vide. Dernières sorties dans
`artifacts/forge-import.stdout.log` et `.stderr.log`.

`tools/capture_forge_integration.gd` instancie la vraie scène et produit
**55 présentations natives, plus une extension de salle**, à 740×360, 844×390,
1280×720, 390×844 et 320×568. Outils, observation, catalogue, contexte, transfert
avec butin/corps, menu, raid, bilan en pause, remplacement, défaite et erreur de
sauvegarde sont couverts. Simulation arrêtée, fixtures en mémoire, aucun appel
aux commandes joueur ou à l'écriture d'une sauvegarde. Ces captures représentent
des états d'interface, pas 55 parties jouées.

Résultats : `docs/reference/interface-review/implementation/captures/` et
`presentation.json`. Exécution GPU Compatibility sur RTX 4090 ; code de sortie
dans `artifacts/forge-capture.exit.txt`, stdout/stderr voisins. Ce rendu bureau
ne constitue pas un profil de téléphone. Les captures ont permis de corriger
le texte flou, les noms longs du catalogue, les actions contextuelles sur écran
étroit et l'accès au bouton de raid sans long texte d'aide dans le menu.

Une partie **manuelle isolée**, lancée avec `-- --forge-review`, a vérifié :

| Action à la souris | Observation |
| --- | --- |
| Ancrer le cœur | Confirmation explicite, salle initiale et découpe visibles |
| Creuser deux cases successives | 320 → 315 → 310 or, sans confirmation intermédiaire |
| Annuler | 315 or, seconde case et contour restaurés |
| Déplacer la vue avec un outil actif | Carte déplacée, 315 or inchangés |
| Glisser Pointes depuis la palette sur le sol | Une pose, 315 → 280 or |
| Relâcher une palette sur l'interface | Aucune pose, 280 or inchangés |
| Choisir Coffre dans Trésors | Catalogue replié, raccourci Coffre actif |
| Voir puis Pause | Colonne réduite puis menu, monde dans sa zone réservée |

Fenêtre de contrôle fermée après vérification ; sauvegarde dédiée
`user://forge_review_v1.save`, pas celle du joueur. Log manuel sans stderr.
Les dernières corrections de police et de disposition ont ensuite été capturées
dans le moteur ; cette interaction n'a pas été rejouée intégralement après elles.

## Revue et limites

Une revue indépendante du code a signalé trois problèmes concrets, corrigés :

1. Le menu de pause pouvait remplacer le texte du bilan, de la défaite ou de
   l'erreur de sauvegarde après perte de focus. Les branches sont séparées.
2. Une annulation native de contact pouvait être traitée comme un relâchement.
   Elle annule désormais immédiatement les pointeurs et la pose.
3. La pose par palette contrôlait uniquement la cible relevée. Le relâchement
   réel doit maintenant aussi être dans la zone du monde.

Les captures couvrent les branches modales corrigées. Le code des gardes tactiles
a été relu ; **pas de validation physique multitouch**, d'encoche/DPI sur téléphone,
de profil mémoire/GPU mobile ou d'export APK. La boucle complète du raid, la
reprise après fermeture forcée et toutes les permutations de transferts/annulation
ne sont pas certifiées par cette vérification ciblée.

Aucun test automatisé ajouté ou exécuté, conformément aux instructions du dépôt.
Aucun commit ni push. Les fichiers déjà modifiés avant cette intégration restent
en place. Les chemins des outils de capture de coffres et vortex suivent désormais
`PlayArea/World/Dungeon` ; leurs anciennes captures approuvées sont conservées.

## Voir le résultat

Ouvrir `scenes/game/DungeonGame.tscn` et lancer F6. **Voir** replie les outils,
**Catalogue** permet de changer d'outil, et la trésorerie ouvre l'état du domaine.
Le slot `--forge-review` reste disponible pour une vérification indépendante.

- [Vue mobile avec outils](../reference/interface-review/implementation/captures/844-tools.png)
- [Mode observation](../reference/interface-review/implementation/captures/844-observe.png)
- [Extension et découpe](../reference/interface-review/implementation/captures/extended.png)
- [Catalogue portrait](../reference/interface-review/implementation/captures/390-catalog.png)

## Correction des boutons compacts

Après retour utilisateur, les boutons rapides conservent une hauteur de 52 unités
(48 sur les formats de moins de 390 unités de haut). Ils mesuraient 168–169 à
1280×720, car ils absorbaient toute la hauteur disponible. Un espace vide assure
maintenant cette extension, entre le statut et les commandes du bas.

Le bloc or/cœur avait 35 unités disponibles pour un contenu de 41. Sa hauteur
dépend désormais du contenu et de deux marges de 11 unités : 63 au total avec
la police actuelle. Le texte du cœur reste à l'intérieur du cadre.

Reproduction et correction : `tools/capture_forge_compact_hud.gd`, 12 captures
avant et 12 après en 1280×720, 844×390, 740×360 et 320×568 ; modes outils,
catalogue et observation. Import et captures : sortie 0, stderr vide. Aucune
commande de gameplay, lecture de sauvegarde joueur ou génération d'images.
Les captures initiales d'intégration ci-dessus restent des instantanés historiques.

[Rendu compact corrigé](../reference/interface-review/compact-hud/after/1280-tools.png)

## Marges et icônes harmonisées

Le retour suivant demande plus de padding et de vraies icônes de ressources.
Les blocs utilisent désormais les mêmes colonnes : icône de 30 unités, espace
de 8, puis texte, avec 14 unités de marge horizontale et 12 verticalement.
Les boutons d'outil et de catalogue gardent 58 unités de hauteur. Le bloc de
ressources affiche une pièce d'or et un cœur violet, avec des valeurs alignées.

Le coffre de catalogue avait aussi beaucoup plus de transparence dans son PNG
que la porte. Des régions AtlasTexture générées par `prepare_native_forge.cjs`
uniformisent leur cadrage à l'affichage. Les PNG sont conservés ; seul un petit
SVG de santé est ajouté au style vectoriel existant.

Pour garder ces marges sur les petits écrans, les ressources et les outils sont
dans une zone défilante ; le statut, Annuler et Voir restent en bas. Les 16 vues
de `interface-review/spacing-hud/` montrent quatre formats, le haut et le bas du
défilement, le catalogue et l'observation. Capture et import : sortie 0, stderr
vide. Aucun accès à la sauvegarde joueur ni test automatisé. Le comportement
tactile du défilement et du glisser-déposer reste à vérifier sur téléphone.

[Rendu avec marges et icônes alignées](../reference/interface-review/spacing-hud/1280-tools.png)

## Catalogue direct, timer et jauges — 26 octobre

Les quatre familles Terrain, Portes, Pièges et Trésors remplacent la palette de
raccourcis. Une famille ouvre sa liste de variantes, puis le choix replie la
liste et conserve la pose répétée. Les cartes sont ramenées de 124 à 72 unités,
avec icône et texte centrés verticalement. Une grille provisoire trop serrée a
été rejetée : les familles gardent des lignes de 58 unités avec leurs marges,
et défilent sur les petits écrans. La largeur du monde reste inchangée.

Le timer reste au-dessus de tous les menus, avec 12 unités de marge. Le compteur
ne change pas de règles : il indique clairement la suspension pendant une
construction, le temps écoulé pendant le raid et les prérequis absents. Or/vie
forment un second bloc autonome ; ils restent dans les sous-menus et ne sont
plus répétés dans le texte du domaine. Les espaces transparents montrent le
matériau rocheux existant dans les mêmes coordonnées mondiales.

Les chiffres au-dessus des coffres/pièges sont remplacés par les couronnes de
l'ancienne version mobile. Le centre des coffres montre des pièces, leur anneau
doré mesure le remplissage. Les pièges gardent leur icône et des segments cuivrés
pour leurs charges. Les jauges passent devant les murs, tandis que les objets
conservent leur profondeur. Les valeurs exactes restent dans la sélection.

Voir [le relevé natif et ses limites](../reference/interface-review/catalogue-direct/README.md).
Les sauvegardes joueur, règles de simulation et textures peintes sont préservées.
