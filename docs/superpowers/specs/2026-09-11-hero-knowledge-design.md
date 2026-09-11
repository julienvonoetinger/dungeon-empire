# Mémoire des héros et priorités du Vulpin

## Objectif

Rendre les raids successifs plus intelligents : les héros qui ressortent
vivants transmettent les informations qu'ils ont effectivement découvertes,
tandis que le Vulpin reste un voleur centré sur les coffres.

## Règles de jeu

### Vulpin / Voleur

- Son objectif est exclusivement le trésor : il cible les coffres connus,
  puis explore lorsqu'aucun coffre connu n'est atteignable.
- Il ne déclenche jamais une attaque contre le Cœur. S'il entre sur une case
  du Cœur pendant son exploration, il la mémorise puis continue son objectif
  de vol ou cherche la sortie.
- Lorsqu'il ne connaît ni coffre atteignable ni nouvelle zone utile à
  explorer, il passe en fuite et rejoint l'entrée.
- Lorsqu'il vide ou pille un coffre, il joue son animation de collecte puis
  quitte le donjon, conformément au comportement existant.
- Il est vulnérable aux pièges : leurs dégâts et leur danger perçu sont plus
  élevés pour lui que pour un Paladin.
- Il peut crocheter une porte intacte. Le crochetage ouvre le passage sans
  utiliser l'attaque de force prévue pour les autres classes.
- Il peut sauter au-dessus d'un unique piège connu et intact grâce à son
  agilité. Il ne peut pas enchaîner des sauts : s'il existe un second piège
  sur sa case d'atterrissage, celui-ci se déclenche normalement.
- Le saut ne s'applique qu'à un piège signalé par sa carte personnelle ou la
  mémoire transmise par un survivant. Après le saut, une courte récupération
  empêche le Vulpin de traverser une suite d'obstacles sans risque.

### Lithide / Paladin

- Son objectif est exclusivement le Cœur : il ignore les coffres et ne
  détourne jamais sa route pour de l'or.
- Il continue à explorer jusqu'à connaître une route vers le Cœur, puis le
  frappe selon sa règle d'attaque existante.
- Lorsqu'il ressort vivant, il partage néanmoins toute information perçue,
  notamment les positions des pièges et des coffres. Ces données peuvent donc
  être exploitées par de futurs voleurs ou autres héros.
- Il encaisse mieux les pièges physiques que le Vulpin.
- Il peut forcer une porte, mais avec une efficacité inférieure à celle du
  crochetage d'un Vulpin ; les portes restent donc un obstacle stratégique
  plus important pour lui.
- Lorsqu'il force une porte, il joue son animation d'attaque. Les dégâts de
  porte sont appliqués au moment de l'impact de cette animation, et non au
  début de son interaction.

### Mémoire transmise

- Chaque raid conserve une `carte de royaume` par donjon, distincte de la
  carte personnelle du héros en raid.
- Seules les informations réellement perçues sont transmissibles : position
  du Cœur, coffres, pièges détectés, portes et cases explorées.
- La mémoire est transmise uniquement lorsqu'un héros finit la raid vivant :
  sortie par l'entrée ou portail vers la ville. Un héros tué, absorbé par le
  vide ou détruit avant son départ ne transmet rien.
- Le héros suivant démarre avec une copie de cette mémoire, puis enrichit sa
  propre carte pendant le raid. Les décisions continuent d'utiliser la carte
  personnelle afin que chaque raid reste isolé pendant son déroulement.
- La mémoire est partagée entre toutes les espèces et classes : un Vulpin
  ayant vu un piège peut donc aider indirectement un futur Paladin, et un
  Paladin ayant repéré un coffre peut guider indirectement un futur Vulpin.

### Obsolescence

- Toute modification du joueur sur une case invalide cette case dans la
  mémoire de royaume : excavation, construction, porte, piège, stockage ou
  réparation qui change son état connu.
- Les héros peuvent redécouvrir une case invalidée normalement.
- Une information restée valide ne révèle pas la quantité exacte d'or : elle
  indique seulement qu'un coffre a été vu. Le coffre vide est ensuite marqué
  comme tel par le héros qui le constate.

## Architecture proposée

`RaidDirector` possède une carte persistante `kingdom_knowledge` pour le
donjon actif. À la création d'un héros, elle est copiée dans `hero["known"]`.
À la sortie vivante, les entrées perçues sont fusionnées dans la carte
persistante. Les opérations de construction existantes invalidant une case
retirent sa clé de `kingdom_knowledge`.

La logique d'objectif du Vulpin conserve `vault` comme cible principale. La
résolution de case ignore explicitement le Cœur pour les héros de type
`thief`; elle ne peut donc pas déclencher `_hero_reaches_core`.

## Tests d'acceptation

1. Un Vulpin qui atteint le Cœur ne réduit jamais son intégrité.
2. Un Vulpin sans coffre connu finit par fuir plutôt que d'attaquer le Cœur.
3. Après la sortie vivante d'un héros, le héros suivant possède les cases
   découvertes de son prédécesseur, dont un piège, un coffre et le Cœur.
4. La mort ou l'absorption par le vide ne transmet aucune nouvelle information.
5. Modifier une case connue retire uniquement cette information de la mémoire
   partagée ; les autres découvertes restent disponibles.
6. Un Vulpin subit davantage les pièges mais peut crocheter une porte ; un
   Paladin résiste mieux aux pièges mais force une porte moins efficacement.
7. Un Vulpin saute uniquement un piège connu et intact ; un second piège
   directement après le premier se déclenche à l'atterrissage.
8. Un Paladin forçant une porte joue l'animation d'attaque et n'inflige ses
   dégâts de porte qu'à l'impact du clip.
9. `GAME_DESIGN.md` décrit ces règles comme comportement de référence.
