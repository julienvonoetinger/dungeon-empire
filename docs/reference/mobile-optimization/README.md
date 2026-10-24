# Direction mobile — 24 octobre 2026

Ce document conserve les décisions de la conversation. Il ne décrit pas une
migration déjà effectuée : le catalogue A/B/C/D2 du commit 6a6fcaa7 reste actif.

Dernière proposition : [dessus de pilier sculpté avec sa pierre](../pillar-cap-review/README.md).
Les médaillons A/B/C précédents sont conservés comme comparaisons historiques ;
l'utilisateur a rejeté leur lisibilité à distance et leur aspect collé.

Si l'aperçu éditeur montre des découpes décalées après un export, sélectionner
le nœud racine **MobileReference** et cliquer **Actualiser le rendu** dans
l'inspecteur. Le script recharge le catalogue, les régions et l'atlas ensemble,
puis surveille les réimports. Voir la [correction de l'aperçu](editor-preview/README.md).

## Décisions de l'utilisateur

- Optimiser pour un jeu mobile, à une distance de lecture comparable à la
  [maquette](source/mockup.png). Aucun zoom utilisateur.
- Déplacement libre de la vue au doigt, confirmé explicitement. La caméra
  ne suit pas automatiquement le héros.
- Garder une échelle de lecture constante, indépendamment de la taille du
  donjon. L'ajustement actuel pour afficher toute la carte n'est pas le cadrage
  souhaité pour le jeu.
- Simplifier les surfaces pour qu'elles soient lisibles à cette distance et
  utiliser des images de résolution inférieure. La résolution exacte reste à
  déterminer à partir du cadrage retenu.
- Une base de pierre commune et des décors transparents séparés (fissures,
  corruption, etc.) remplaceraient les familles complètes de variantes peintes.
  Cette nouvelle direction autorise la superposition de sprites préparés.
- Des [piliers nettement définis](source/pillar.png), comme dans la maquette,
  doivent servir de jonction aux coins. Les murs se terminent contre les piliers,
  ce qui évite d'exiger une peinture continue autour de chaque coin.
- Les dalles actuelles sont trop grandes relativement aux briques des murs.
  Retrouver le rapport de tailles de la maquette. L'ancienne approbation de la
  taille C à deux rangées n'est plus une contrainte pour la prochaine proposition.
  Conserver les surfaces calmes et les coins arrondis du sol.

## Éléments à préserver

Grille logique carrée 1×1, projection commune, épaisseur cohérente, deux assises
de murs, passages d'une ou plusieurs cases et lisibilité du passage. Un joint de
texture devenu inutile ne dispense pas de placer précisément murs et piliers.
Les décors sont des sprites préexportés avec une perspective et une visibilité
appropriées ; aucun calcul de texture ou déformation de perspective en jeu.

## Prototype de référence proposé

Une petite scène de référence avec sol, murs horizontaux/verticaux, un angle avec
pilier et quelques décors. Calibrer d'abord les proportions et la taille à l'écran,
puis comparer les résolutions et organiser les atlas. Ne pas identifier une dalle
décorative de la maquette à une case logique sans référence d'échelle.

Le projet utilise une fenêtre de référence 1280×720. Le cadrage actuel dans
`scripts/six_room_preview.gd` fait entrer toutes les limites de la scène à l'écran.
La taille du personnage n'est pas encore fixée dans le jeu. Le cadrage de référence
et le nouveau rapport dalle/brique doivent donc être proposés visuellement ;
aucune valeur précise n'est encore approuvée. Le prototype décrit ci-dessous
permet de les comparer. Les anciennes scènes conservent leur catalogue actif.

## Provenance

Copies inchangées des deux images fournies le 24 octobre :

- `source/mockup.png` : codex-clipboard-6aa07da3-9508-42b3-b349-9c4153c33891.png.
- `source/pillar.png` : codex-clipboard-d7a13f31-4dda-4fee-8115-30cb9a8f8512.png.

## Prototype réalisé après le « ok »

Ouvrir `scenes/MobileReference.tscn` dans Godot puis F6. Glisser la vue au doigt
ou avec le bouton gauche de la souris. Aucun zoom. Les boutons changent la
résolution source (128/256), l'ancien/nouveau sol, les Décors murs et les
Décors piliers séparément. Le sélecteur propose **Dessus creusé** et les anciens
médaillons A/B/C ; Recentrer remet
la caméra à son point de départ. La configuration locale de scène principale
pointe actuellement vers MobileReference ; les anciennes scènes restent disponibles.

Choix de départ de l'assistant, à valider visuellement :

- Fenêtre de référence 1280×720 ; 192 pixels affichés par case, caméra 0,75.
- Salle de 3×2 cases, extensions de trois cases à droite et quatre vers le bas.
  Les extensions débordent du cadrage initial pour permettre le déplacement libre.
- Trois rangées de dalles, largeur entière 0,32–0,35 case, hauteur 1/3 ;
  environ 61–67 × 64 pixels à ce cadrage. Les grandes dalles C étaient proches
  de 96×96. Les briques supérieures du prototype font 1/3 case hors terminaison.
- Pilier nu de 0,24 case de large contre 1/6 pour le mur, deux assises, avec
  un décor séparé sur le dessus. Sa hauteur est celle du mur +0,035 case.
- Une apparence de pierre calme commune ; moindre contraste de matière,
  sans changer les sources approuvées. Sol calme et coins arrondis conservés.
- Un dessus complet avec grand losange creusé, avec pierre de fond et bordure
  raccordée à la base. Les trois anciens médaillons A/B/C restent accessibles
  pour comparaison. Les anciens petits décors muraux sont désactivés par défaut.

### Images et fichiers

- [Vue Godot 256](captures/proposed-256.png), [vue 128](captures/proposed-128.png)
  et [commandes](captures/controls.png).
- [Comparaison du sol](floor-comparison.png) et
  [comparaison des résolutions](resolution-comparison.png) : extraits sans
  redimensionnement des captures 1280×720. Le comparatif du sol utilise les
  nouveaux murs des DEUX côtés, et change uniquement le sol.
- `assets/dungeon/mobile-reference/` : catalogue isolé et AtlasTexture préparées.
- `recipe.json` : sources, empreintes, paramètres et rapports du compositeur.
- `guides/`, `sprites/`, `overlays/` : pièces isolées et références magenta.

Le petit catalogue contient 14 images logiques : un sol, huit murs (deux axes ×
quatre terminaisons contre un pilier), un pilier nu, un dessus sculpté et trois
anciens décors gardés pour comparaison. Les quatre murs
par axe ont UNE apparence commune ; leurs longueurs aux extrémités diffèrent.
Les murs se terminent réellement à la limite du pilier. Aucun joint peint ne
traverse une frontière de case à recoller au coin. Les fragments périodiques du
sol sont peints comme des dalles entières avant découpe, comme dans le kit actif.

| Densité source | Atlas | PNG sur disque | RGBA brut sans mipmaps |
|---|---|---|---|
| 128 px/case | 512×256 | 83275 octets, soit 81,3 Kio | 512 Kio |
| 256 px/case | 1024×512 | 253634 octets, soit 247,7 Kio | 2 Mio |

Ce sont les dimensions du prototype de 14 pièces, pas une estimation du futur
kit complet. Les deux densités sont conservées pour comparaison ; la version
256 est affichée par défaut et apparaît plus nette au cadrage choisi. Aucune
résolution n'est encore validée par l'utilisateur. Aucun profilage mobile.

### Reproduction

Avec Node et Sharp déjà disponibles dans l'environnement du projet :

1. `node tools/prepare_mobile_reference.cjs` : export des deux atlas, des
   ressources, des guides, des PNG de revue et de la recette.
2. Import Godot du projet (`--headless --editor --import`).
3. Godot avec un rendu réel : `--script res://tools/capture_mobile_reference.gd`.
4. `node tools/prepare_mobile_reference_review.cjs` : les deux comparatifs.
5. `node tools/prepare_pillar_cap_review.cjs` : avant/après du dessus sculpté,
   extraits Godot à taille réelle puis mêmes pixels agrandis.

La revue historique des médaillons reste reproductible par
`node tools/prepare_mobile_decoration_review.cjs`, à partir de ses captures figées.

Le prototype ne remplace ni le générateur connecté, ni les portes/escaliers,
ni les anciennes scènes. Il ne démontre pas la compatibilité de toutes les
configurations du futur kit. L'ajout de colonnes crée une nouvelle géométrie
proposée : les anciens wireframes ne la valident pas automatiquement.

Aucun test automatisé ajouté ou exécuté. Import et captures servent à produire
la proposition visuelle. Le glissement tactile est implémenté mais n'a pas été
essayé sur un téléphone ; aucune performance mobile n'est annoncée.

## Correction de superposition des piliers

Le premier prototype dessinait tous les murs à z_index=1 et tous les piliers à
z_index=2. Cette priorité masquait à tort les murs qui passent devant un pilier,
notamment sous le pilier supérieur gauche signalé par l'utilisateur.

Les murs et les piliers partagent maintenant une couche et sont ordonnés par la
profondeur de leur support au sol, suivant la direction commune (0,18 ; 0,9).
Un mur sortant vers le sud/est est dessiné après le pilier situé derrière lui ;
un mur arrivant du nord/ouest est dessiné avant le pilier qui le masque.
Les ornements sont dessinés juste après leur mur et peuvent ainsi être occultés
par un élément placé devant. Les PNG et la géométrie n'ont pas changé pour cette
correction. Ne jamais remettre une priorité globale « tous les piliers devant ».

[Avant/après du coin supérieur gauche](join-review/top-corner.png).
La capture initiale est conservée dans `join-review/before.png`. Les captures
courantes et comparatifs du sol/résolution ont été refaits après correction.
Import Godot et captures de revue après correction : sortie 0, journaux stderr vides.
Les jonctions visibles de cette scène ont été examinées ; le tri n'est pas une
preuve de compatibilité avec des volumes arbitraires ou les futures portes.

## Historique : séparation du premier losange — 24 octobre 2026

Le losange gris était initialement peint dans le sprite de pilier. Il a été
séparé en PNG transparent indépendant, `ornament-pillar`, dans le même atlas.
Les premiers losanges violets des murs étaient déjà des détails séparés.
Ces trois anciens dessins sont maintenant remplacés dans le prototype par les
propositions peintes décrites ci-dessous ; leur apparence a été rejetée.

- [Les trois couches](details-review/layers.png) : base, détail, assemblage.
- [Scène avec piliers nus](captures/without-pillar-details.png).
- Dans F6, bouton **Décors piliers** pour comparer sans modifier le cadrage.
  Propriété `pillar_details` également disponible dans l'inspecteur.
- L'ancien losange mesurait 44×46 pixels à la densité 256 et utilisait son
  ancre préparée. Chaque décor suit son pilier dans le tri de profondeur,
  pour que les murs au premier plan puissent encore le masquer.
- 13 sprites logiques, atlas toujours 1024×512 à la densité 256, 2 Mio RGBA brut.
  PNG : 199146 octets ; la dimension de l'atlas n'a pas augmenté.
- Avant séparation conservé dans `details-review/pillar-before-separation.png`.

Ceci illustre l'ajout de détails sur une base réutilisée. La proposition ne
contient pas encore de nouvelle bibliothèque de fissures, racines ou autres
ornements. Cinq captures Godot produites, sortie 0 et stderr vide ; aucune suite
de tests automatisée exécutée lors de cette étape historique.

## Historique : premiers décors peints séparés

L'utilisateur confirme la conservation des murs, sols et piliers nus et demande
des décors plus travaillés. Trois images ont été générées depuis la maquette :
A pierre sculptée, B sceau ancien, C sceau corrompu violet. Les biseaux, creux et
éclats sont peints dans les petits décors, jamais dans les bases réutilisables.

Voir la [comparaison](../mobile-decoration-review/comparison.png), les
[sources et instructions](../mobile-decoration-review/README.md) et les
[couches séparées](details-review/layers.png). Aucun des trois dessins n'est
retenu par l'utilisateur : leur rendu à distance et l'effet collé ont été rejetés.
A était le choix initial de cette revue. Les anciens sprites de losanges sont conservés dans sprites/
comme historique, et ne font plus partie des atlas actifs du prototype.

Les deux commandes de décors désactivées montrent les [bases nues](captures/bare-bases.png).
Ce stade comportait 13 sprites. Import et huit
captures avaient terminé sans erreur signalée dans stderr. Les trois propositions ont
été examinées à la taille de jeu ; pas de test automatisé ni de mesure sur mobile.

## Dessus sculpté — proposition actuelle

Le patch `pillar-top-carved` contient le grand creux et la pierre qui l'entoure.
Sa bordure reprend exactement celle du pilier nu. Il utilise la même ancre au
sol et reste dans le tri de profondeur de son support. L'export est préparé hors
ligne ; Godot superpose simplement ce dessus aux mêmes bases.

La [revue dédiée](../pillar-cap-review/README.md) décrit la source générée, le
raccord, les dimensions et la reproduction. Les audits aux densités 128 et 256
constatent zéro différence d'alpha et zéro changement RGB hors du dessus, avec
une référence passée dans le même compositeur. Neuf captures Godot et l'import
ont terminé avec sortie 0 et stderr vide. Aucun test automatisé ni profilage mobile.
