# Vertical slice mobile 2.5D

## Objectif

Transformer le prototype actuel en une vertical slice Android jouable sur un
vrai téléphone, lisible au premier regard et fidèle à l'intention visuelle des
maquettes. Le donjon reste rendu en vraie 3D, mais sa présentation se comporte
comme un jeu isométrique 2D : caméra cadrée, silhouettes nettes, interactions
tactiles prévisibles et interface entièrement pensée pour le paysage mobile.

La boucle livrée est complète : préparer le donjon, construire, observer un
raid, recevoir une récompense, faire progresser le Core, débloquer un nouvel
outil, puis préparer le raid suivant.

## Décision visuelle

La vertical slice utilise une approche 2.5D.

- La grille, les murs, les pièges, les portes, le Core et les héros restent des
  objets 3D. Les règles, le pathfinding et les modèles existants sont conservés.
- La caméra est orthographique et utilise des angles isométriques prédéfinis.
  Le joueur ne dispose pas d'une rotation libre.
- Le cadrage, les matériaux, les ombres, les couleurs et les marqueurs donnent
  une lecture proche d'une illustration 2D.
- Le HUD, les portraits, les icônes, les jauges, les retours de placement et
  les écrans de résultat sont des éléments 2D en espace écran.
- Des imposteurs ou effets 2D peuvent remplacer ponctuellement un effet 3D
  coûteux, mais ils ne deviennent pas la représentation principale du donjon.

Cette direction évite de produire une variante d'image pour chaque orientation,
état et animation de chaque objet. Elle permet aussi de réutiliser les modèles
et comportements déjà présents sans sacrifier l'apparence des maquettes.

## Plateforme cible

- Android en orientation paysage.
- Référence de mise en page : 1280 x 720, extensible aux écrans plus larges et
  aux zones sûres des appareils à encoche ou découpe caméra.
- Cibles tactiles d'au moins 48 pixels logiques, espacées pour éviter les
  activations accidentelles.
- 30 images par seconde stables sur un appareil Android milieu de gamme comme
  seuil d'acceptation. Le mode 60 images par seconde reste optionnel.
- Souris et clavier continuent de fonctionner dans l'éditeur pour accélérer les
  tests, mais aucune action nécessaire au jeu ne dépend d'un périphérique PC.

La chaîne Android locale n'est pas encore configurée : Java est disponible,
mais aucun SDK Android, `adb` ou preset d'export Godot n'a été détecté. Leur
installation et la création du preset font partie de la livraison Android.

## Boucle utilisateur

### Préparation

Le joueur arrive directement sur son donjon. La barre supérieure montre l'or,
l'intégrité du Core, le niveau du Core et le délai avant le raid. Un objectif
court indique la prochaine action obligatoire, par exemple placer le Core,
creuser depuis son influence, construire du stockage ou ouvrir l'entrée.

Le bouton de construction ouvre un plateau inférieur. Choisir un outil ne
modifie pas immédiatement la simulation : cela active un mode de placement.

### Placement

1. Le joueur choisit un outil dans une catégorie courte : structure, piège ou
   entretien.
2. Il touche une case. Le jeu affiche un aperçu fantôme, son coût et un retour
   vert ou rouge expliquant la validité du placement.
3. Il confirme avec un bouton dédié ou annule. Seule la confirmation appelle la
   mutation correspondante dans `DungeonSim`.

Un second toucher sur une autre case déplace l'aperçu. Les portes et éléments
orientés montrent leur orientation calculée ; un bouton de rotation n'apparaît
que pour un objet qui accepte réellement plusieurs orientations.

### Raid

Au début du raid, la construction est verrouillée et le HUD passe en mode
observation. La caméra cadre l'entrée du héros puis le suit avec une transition
douce, sans empêcher le joueur de déplacer ou de zoomer la vue.

Le héros possède un portrait, une classe, une jauge de vie et un marqueur de
sol contrasté. Les activations importantes produisent un retour court en espace
écran : piège déclenché, porte attaquée, or volé, Core touché ou fuite.

Le joueur peut recentrer la caméra sur le héros ou sur le Core. Il ne dirige pas
le héros et ne construit pas pendant le raid.

### Résultat

La fin du raid ouvre un écran compact au-dessus du donjon. Il présente le sort
du héros, l'or perdu ou gagné, les dégâts du Core, les pièges consommés, l'XP du
Core obtenue et le prochain déblocage. La progression de niveau s'anime une
seule fois. Le bouton Continuer revient à la préparation et rend les réparations
et la construction disponibles.

## Navigation tactile et caméra

- Un toucher bref sélectionne une case ou un contrôle.
- Un glissement à un doigt au-delà d'un seuil déplace la caméra et annule le
  toucher de sélection associé.
- Un pincement à deux doigts règle le zoom.
- Deux boutons tournent la caméra par pas de 90 degrés entre des angles connus.
- Un bouton contextuel recentre sur le héros pendant un raid et sur le Core
  pendant la préparation.
- Le zoom est borné afin que les cases restent manipulables et que le donjon ne
  devienne jamais un amas illisible.
- Les gestes commencés sur le HUD sont consommés par le HUD et ne déplacent pas
  la caméra.

Les événements souris et tactiles sont traduits en intentions communes
(`tap`, `pan`, `pinch`, `rotate`, `focus`). La logique de jeu ne dépend pas du
type d'événement d'entrée brut.

## Lisibilité du donjon

### Caméra et occlusion

La caméra conserve un pitch et une distance stables par profil. Les murs situés
entre la caméra et la zone d'intérêt deviennent masqués ou semi-transparents.
La zone d'intérêt est la case sélectionnée en construction, le héros en raid ou
le Core lorsqu'aucune autre cible n'est active.

Le cutaway ne modifie ni collisions, ni pathfinding, ni état de simulation. Il
affecte uniquement les instances visuelles concernées et utilise une transition
courte pour éviter les clignotements.

### Hiérarchie visuelle

- Le sol et les murs utilisent des valeurs sobres afin de laisser ressortir les
  éléments interactifs.
- Chaque famille de piège possède une silhouette et une couleur d'accent
  distinctes. L'état chargé, consommé ou endommagé ne repose jamais uniquement
  sur une différence de couleur.
- Le Core est le point focal permanent grâce à son échelle, son halo borné et
  son contraste, sans éclairer tout le niveau en violet.
- Les héros sont légèrement exagérés en taille apparente et complétés par un
  anneau de classe, une ombre de contact et une jauge en espace écran.
- Les marqueurs de développement, le texte de debug et les instructions PC ne
  sont pas affichés dans la version jouable.

## HUD mobile

Le HUD est une scène Godot composée de contrôles standards, pas un ensemble de
textes dessinés directement par `Main._draw()`.

Il contient :

- une barre supérieure compacte pour l'or, l'intégrité, le niveau du Core et le
  prochain raid ;
- un objectif contextuel d'une ligne maximum ;
- une barre inférieure de modes en préparation ;
- un plateau de construction défilable horizontalement ;
- les contrôles de confirmation, annulation et rotation du placement ;
- les contrôles de suivi et de vitesse autorisés pendant le raid ;
- l'écran de résultat et de progression.

La disposition utilise les marges sûres fournies par Android. Aucun texte utile
n'est placé sous un bord arrondi, une encoche ou une barre système. Les libellés
longs sont abrégés dans la barre et restent disponibles dans le panneau de
détail de l'outil.

## Progression du Core

L'intégrité du Core et son niveau sont deux valeurs distinctes. L'intégrité est
la vie actuelle attaquée par les héros. Le niveau est une progression durable
du profil, sauvegardée entre les sessions et conservée lors de la création d'un
nouveau donjon.

### Récompense de raid

Un résultat structuré est produit exactement une fois par raid. La première
table d'équilibrage utilise les statistiques déjà suivies :

- 20 XP si le Core survit au raid ;
- 25 XP si le héros est éliminé ;
- 10 XP si aucun or n'est emporté ;
- 5 XP par piège déclenché, limité à trois pièges ;
- 10 XP si le Core ne subit aucun dégât.

Le joueur reçoit également 30 pièces d'or si le Core survit, 25 supplémentaires
si le héros est éliminé et 15 supplémentaires si aucun or n'est emporté. Les
valeurs sont regroupées dans une table de configuration afin de permettre un
rééquilibrage sans modifier le flux de résultat.

Les récompenses sont identifiées par l'index du raid. Réouvrir l'écran de
résultat ou recharger une sauvegarde ne peut pas les appliquer deux fois.

### Niveaux de la vertical slice

| Niveau | XP cumulé | Déblocage principal |
| --- | ---: | --- |
| 1 | 0 | excavation, stockage, pointes, porte, réparation et absorption |
| 2 | 60 | piège ralentissant |
| 3 | 150 | faille du vide |
| 4 | 280 | porte arcanique |

Un outil verrouillé reste visible dans le plateau pour annoncer la progression,
mais il est désactivé et indique le niveau requis. `DungeonSim` refuse également
son utilisation si un appel contourne le HUD.

## Sauvegarde locale

Une sauvegarde versionnée dans `user://` conserve :

- le niveau, l'XP et les déblocages du Core ;
- l'index du dernier raid récompensé ;
- la grille, l'or, l'intégrité du Core et les structures ;
- les charges des pièges et l'état des portes ;
- l'index du prochain raid et les connaissances persistantes des héros.

La sauvegarde est écrite après une construction confirmée, après une réparation
et après validation de l'écran de résultat. Un raid actif n'est pas sérialisé à
mi-chemin : l'application reprend le dernier point de préparation cohérent.
Une version inconnue ou un fichier corrompu ne bloque pas le démarrage ; il est
écarté avec un message journalisé et un nouveau profil est proposé.

## Architecture proposée

### Responsabilités existantes

- `DungeonSim` reste propriétaire de la grille, de l'économie et des mutations
  de construction.
- `RaidDirector` reste propriétaire du héros et du déroulement du raid.
- `DungeonWorld` reste la façade de présentation 3D et de picking.
- `Main` devient uniquement le conducteur qui relie les services, les modes et
  les signaux.

### Nouveaux composants

```text
Main
├── MobileHud
├── MobileInputRouter
├── MobileCameraController
├── BuildPlacementController
├── CoreProgression
├── SaveService
├── DungeonSim
├── RaidDirector
└── DungeonWorld
```

- `MobileHud` possède les contrôles 2D et émet des intentions, sans modifier la
  simulation directement.
- `MobileInputRouter` transforme souris et tactile en intentions communes et
  arbitre le conflit entre toucher, déplacement et pincement.
- `MobileCameraController` gère cadrages, zoom, rotations discrètes, suivi et
  recentrage.
- `BuildPlacementController` possède la sélection d'outil, l'aperçu, la
  validation et la confirmation. Il appelle `DungeonSim` uniquement à la fin.
- `CoreProgression` calcule les récompenses, les seuils et les outils autorisés.
  Sa logique est indépendante de l'interface et testable sans rendu.
- `SaveService` sérialise un instantané versionné et utilise une écriture
  temporaire avant remplacement du fichier valide.

`RaidDirector` remplace le rapport uniquement textuel par un objet de résultat
structuré, tout en pouvant encore produire la phrase de debug existante. Il
émet un signal `raid_finished(result)` consommé par la progression et le HUD.

Les extractions depuis `Main` et `DungeonWorld` sont limitées au comportement
touché par cette vertical slice. Les règles de raid existantes ne sont pas
réécrites.

## Images et modèles

Les modèles existants sont utilisés en priorité. La génération directe d'images
sert aux portraits, fonds d'écran de résultat, textures d'effets et éventuels
éléments décoratifs du HUD. Une famille d'assets est générée et validée comme un
ensemble afin de garder perspective, palette et langage de formes cohérents.

Meshy n'est utilisé que si un modèle 3D nécessaire manque réellement. Le
pipeline reste en dry-run par défaut et aucune commande payante n'est lancée
sans accord explicite. Une image générée peut servir de référence Meshy, mais
les sorties doivent passer par la validation GLB existante avant intégration.

## Budget de rendu mobile

- Conserver le renderer de compatibilité pour Android.
- Limiter les lumières locales actives et les ombres dynamiques aux éléments
  importants ; les marqueurs, particules et halos ne projettent pas d'ombre.
- Réutiliser matériaux et meshes plutôt que dupliquer les ressources par case.
- Réduire ou désactiver les effets écran coûteux dans le profil mobile.
- Borner les particules et les retours de combat simultanés.
- Utiliser une résolution interne ajustable sans modifier la taille logique du
  HUD ou des cibles tactiles.

Les optimisations sont guidées par une capture de performances sur appareil.
Un changement visuel important n'est pas accepté uniquement sur la base du
temps mesuré dans l'éditeur Windows.

## Gestion des erreurs et états limites

- Une perte de focus ou une interruption Android annule le geste tactile en
  cours et ne confirme jamais un placement.
- Une orientation portrait accidentelle conserve une image sûre ou demande de
  revenir en paysage ; elle ne réorganise pas le jeu en plein raid.
- Un redimensionnement, une marge sûre ou un ratio extrême ne superpose pas le
  HUD à la zone centrale manipulable.
- Un outil devenu invalide entre l'aperçu et la confirmation est refusé avec le
  nouveau motif de validation et sans dépenser d'or.
- Un écran de résultat ne peut être ouvert qu'avec un résultat complet et ne
  distribue jamais deux fois une récompense.
- Une sauvegarde échouée laisse le dernier fichier valide intact.

## Vérification

### Tests automatisés

- Les tests de simulation et de raid existants restent verts.
- Des tests unitaires couvrent les seuils de mouvement tactile, les bornes de
  zoom et les rotations discrètes.
- Le placement vérifie aperçu sans mutation, confirmation unique, annulation,
  coût insuffisant, case invalide et outil verrouillé.
- La progression vérifie chaque composant de récompense, les passages de niveau,
  les déblocages et l'idempotence par index de raid.
- La sauvegarde vérifie aller-retour, migration de version, fichier corrompu et
  reprise au dernier point de préparation.
- Les dimensions 1280 x 720, 1600 x 720 et 960 x 540 sont capturées afin de
  détecter les chevauchements du HUD et les textes coupés.

### Validation sur téléphone

1. Produire un APK de debug installable.
2. Installer et démarrer l'APK via `adb` sur un appareil Android réel.
3. Placer le Core, creuser, construire du stockage et ouvrir l'entrée sans
   souris ni clavier.
4. Placer, déplacer, annuler et confirmer un piège uniquement au toucher.
5. Déplacer, zoomer, tourner et recentrer la caméra pendant la préparation et
   le raid.
6. Terminer un raid, recevoir une seule récompense et constater la progression
   ou le déblocage correspondant.
7. Fermer complètement l'application, la relancer et retrouver le dernier état
   cohérent.
8. Observer au moins un raid complet sans chute durable sous 30 images par
   seconde ni surchauffe anormale sur l'appareil de référence.

## Hors périmètre

- Refaire tout le catalogue d'assets en 2D.
- Ajouter une boutique, des achats intégrés, de la publicité ou des services en
  ligne.
- Concevoir la campagne complète ou plus de quatre niveaux de Core.
- Ajouter de nouvelles classes de héros, de nouveaux pièges ou modifier leur IA
  au-delà des données nécessaires au résultat de raid.
- Produire immédiatement des modèles Meshy pour tous les assets manquants.
- Garantir la compatibilité iOS dans cette première livraison.

## Ordre de livraison

1. Introduire le résultat de raid structuré, la progression et leurs tests.
2. Ajouter la sauvegarde versionnée et les points de reprise cohérents.
3. Extraire l'entrée et la caméra mobiles avec émulation souris.
4. Construire le HUD responsive et le flux de placement confirmé.
5. Appliquer le cadrage 2.5D, le cutaway des murs et les marqueurs de lisibilité.
6. Intégrer l'écran de résultat et les déblocages dans la boucle complète.
7. Générer seulement les images finales identifiées comme manquantes.
8. Configurer Android, produire l'APK et profiler la vertical slice sur appareil.

## Critères de réussite

La vertical slice est réussie lorsqu'un nouveau joueur peut accomplir la boucle
préparation, raid, résultat et progression sur téléphone sans clavier, sans
texte de debug, sans confusion entre le décor et les objets interactifs, et
sans perdre son progrès après avoir fermé l'application. Le rendu doit évoquer
les maquettes 2D tout en conservant la flexibilité et les assets du monde 3D.
