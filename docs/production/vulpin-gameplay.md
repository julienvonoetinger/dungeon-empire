# Vulpin dans les raids jouables

Intégration du 28 octobre 2026. Le réglage `testing/vulpin_only=true` filtrait
correctement les classes, mais `isometric_game_view.gd` affichait encore le pion
de `game_marker.gd`. Rusk est un nom de Vulpin, pas une autre classe de héros.

Le renderer instancie désormais `vulpin_actor.gd` pour `kind=thief`. Les autres
classes conservent leur rendu provisoire si le filtre est désactivé. Les PNG et
SpriteFrames approuvés dans `assets/previews/vulpin-*` sont réutilisés directement.
Aucune image n'a été régénérée ou dupliquée. Caméra, ancrage et échelle .85 restent
ceux des scènes d'inspection ; la mort utilise son ancrage spécifique de 384 px.

| État du raid | Présentation |
| --- | --- |
| Attente, déplacement terminé | Repos fixe |
| Déplacement interpolé | Marche, 15 poses/s |
| Entrée / sortie par l'escalier | Hauteur des cinq marches, descente puis exploration / remontée puis départ |
| Fuite ou saut de piège | Course, 16 poses/s ; translation du saut existante |
| Piège blessant non mortel | Recul de 720 ms sur place avant de repartir ; durée comprise dans les 3 s de l'entrave |
| `lockpicking` sur porte / coffre | Boucle de crochetage correspondante |
| `collecting_gold` | Geste d'ouverture/collecte, puis maintien de la dernière pose |
| `dying` | Chute de 550 ms, puis maintien pendant le reste du délai existant |
| Corps après raid | Dernière pose fixe, orientation conservée |

Le temps vient exclusivement de `RaidDirector.elapsed_seconds` et des compteurs
d'action. Pas d'autoplay indépendant : pause et ×2 affectent ensemble déplacement
et poses. Le même acteur est conservé quand une porte ou un coffre s'ouvre et
provoque une reconstruction du décor. Les gestes ne déverrouillent rien par eux-
mêmes et ne ferment jamais un coffre déjà entrouvert.

La réaction aux pièges utilise `GameTypes.VULPIN_HURT_HOLD` (.72 s), égal à la
durée du clip approuvé. Un impact non mortel enregistre `hurt_started_at` dans
la simulation et porte `move_cd` au maximum entre son délai existant et .72.
Le rendu lit cet instant, y compris si l'impact arrive au premier sous-pas du ×2
ou si l'acteur est recréé. Cela évite le départ pendant le recul, sans ajouter
.72 aux trois secondes de l'entrave. Pièges épuisés/déjà déclenchés, néant et
coups mortels ne reçoivent pas cette attente supplémentaire.

Le défaut a été reproduit avec les sondes : départ 17 ms après les pointes en
×1, 33 ms en ×2. Après correction, `verify_vulpin_trap_reaction.gd` passe 29
contrôles sans interface et 39 avec le rendu natif (pause, pointes/entrave,
vitesse, position fixe du sprite, durée du clip et priorité de la mort).
`tests/scenarios/trap-recoil.json` reproduit le raid complet sans interface.
Les sept scénarios de sondes et les contrôles existants Vulpin (367) et pièges
(160) passent ; stderr vide. Captures et traces : `artifacts/vulpin-trap-reaction`.

Les contacts porte/coffre utilisent les repères des scènes de contrôle, avec
180 ms d'approche. Les déplacements suivants repartent du point de contact.
Les supports physiques des poses marche/course/repos et crochetage servent au
tri avec les deux montants et la couronne indépendants des portes. La réaction
aux dégâts et la chute ont encore des supports approximatifs, pas un test de
collision de tous les pixels. La cadence de marche ne garantit pas l'absence de
glissement des pieds à la vitesse actuelle de la simulation, laissée inchangée.

Cas dense : si aucune face du coffre ne dispose d'un espace libre (coffres
adjacents dans un couloir), la position est contrainte par l'enveloppe de toutes
les poses à sa case praticable. Cela empêche le Vulpin de traverser le mur ; le
contact mains/serrure est alors approximatif. Aucun changement de construction
ou de déplacement logique n'a été introduit pour masquer ce cas.

Les corps ajoutent deux champs facultatifs `kind` et `facing` à leur sauvegarde.
Les anciens corps à trois champs sont toujours acceptés et conservent leur
marqueur historique, faute d'information sur leur classe. Tests sans accès aux
sauvegardes joueur.

## Traversée des escaliers

`stair_traversal.gd` reprend les cinq hauteurs de la géométrie de production
(`tools/isometric_kit_geometry.cjs`, source
`docs/reference/entrance-stairs-open-south-wireframe.json`). La direction de
l'entrée désigne le côté bas ouvert. Les pieds, le support de tri et l'ombre
de contact suivent le même relief dans les quatre orientations. Les petits
raccords entre hauteurs sont lissés sur .05 case autour de chaque contremarche.
Le volume global des marches ne masque plus un personnage qui marche dessus ;
les murs conservent leur tri physique.

Le raid commence par `entering` / `enter_t` pendant `TURN_TIME` (.48 s), du haut
de l'escalier à son centre, avant la première décision d'exploration. Le premier
pas ordinaire termine la descente. Au retour, `exit_arrival_t` laisse finir le
pas jusqu'au centre ; `exiting` / `exit_t` terminent la remontée. Le fondu ne
concerne que les .1064 case finales près du haut. Une porte directement après
l'escalier peut retenir le héros en position de crochetage : sa remontée repart
de ce contact, sans saut au centre. Pause et ×2 utilisent le temps du raid.

Les sprites de marche/course existants sont conservés. Il s'agit d'un placement
sur le relief, sans nouvelle animation anatomique d'escalade ni garantie de
contact indépendant de chaque pied. Aucun changement de sauvegarde.

Régression : cinq erreurs initiales reproduites ; la revue a ensuite reproduit
un saut de 89.6 pixels après un crochetage raté juste devant l'entrée, dans les
quatre orientations. `tools/verify_vulpin_stairs.gd` passe désormais 1787 contrôles
natifs (captures dans `artifacts/vulpin-stairs`). Le scénario
`tests/scenarios/stair-traversal.json` vérifie sans interface les phases, la pause,
les positions et le départ seulement après la remontée. Les six scénarios de
sondes passent, ainsi que 367 contrôles Vulpin et 12 contrôles de retraite.

```powershell
./tools/run-probes.ps1 -Scenario tests/scenarios/stair-traversal.json -Report artifacts/vulpin-stairs/probes.json
& $godot --path . --script res://tools/verify_vulpin_stairs.gd
```

## Reproduire les contrôles

`tools/prepare_vulpin_gameplay.gd` extrait les repères approuvés et les supports
dans `assets/heroes/vulpin/registration.tres`. Ce Resource préchargé assure que
les exports suivent les dépendances sans lire de JSON ni de document de revue
à l'exécution. Les sources sont celles des trois `registration.json` d'interaction
et de `hero-fit-v11-compact/passage-validation.json`.

```powershell
& $godot --headless --path . --script res://tools/prepare_vulpin_gameplay.gd
& $godot --path . --script res://tools/verify_vulpin_gameplay.gd
./tools/run-probes.ps1 -Report artifacts/vulpin-gameplay/probes.json
```

La régression initiale échouait parce qu'un raid réel créait un pion au lieu du
sprite. Contrôle final : 367 assertions natives, zéro échec ; le raid seed 21
traverse marche, crochetage, repos, dégâts, collecte et course. Captures des
quatre orientations, contacts, passages, mort et mobile dans
`artifacts/vulpin-gameplay`. Revue indépendante : le cas des coffres serrés a été
reproduit dans un raid réel et corrigé avec un test rouge puis vert.

Les cinq scénarios de sondes restent verts, ainsi que pièges (160), portes
ouvertes (84), suivi de l'œil (34) et API de sondes (63). Les tests œil/portes
attendent une image GPU : une tentative headless a expiré ; leurs relances avec
rendu graphique sont passées sans erreur. Import natif sans erreur. Aucun APK
construit, aucun profilage ou validation sur téléphone physique dans cette passe.
