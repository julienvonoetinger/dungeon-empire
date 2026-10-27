# Dallage adapté aux pièges et recalage de la projection

Le retour utilisateur vise deux défauts : des pièges semblant collés sur le sol,
puis des pierres coupées arbitrairement par leur logement central. La correction
est intégrée dans le catalogue utilisé par le jeu et `scenes/DungeonTraps.tscn`.

## Correction

Le générateur précédent réduisait uniformément les peintures puis les coupait
dans un losange isométrique. Cela ne corrigeait pas leur projection source. Le
rectangle des Pointes mesuré dans la peinture avait notamment un rapport proche
de 1,74:1, contre 2:1 pour le sol. La couche du sol conservait aussi du dessin
en relief alors qu’une seconde copie était rendue comme mécanisme.

- Le nouveau dallage comporte **huit pierres complètes** disposées autour du
  carré central : quatre bordures et quatre angles. Même matière, même plan z=0
  que les dalles voisines. Il ne s’agit pas d’un socle surélevé. Les coordonnées
  et le wireframe sont conservés dans `receiver-geometry.json` et
  `receiver-wireframe.svg`.
- Le logement reste `.22..78`, encadré par les pierres dans `.10..90`. La bande
  extérieure de `.06` est conservée à l’identique pour les raccords avec le
  dallage B. Le reste du dallage autour du piège est volontairement redessiné.
- Les supports peints sont enregistrés dans le plan du sol. Les neuf logements
  de Pointes restent aux mêmes positions dans les trois états ; leurs pyramides
  sont projetées séparément, avec les couleurs des facettes de la peinture
  sélectionnée. Les mâchoires d’Entrave passent par une surface texturée 2,5D
  avec composante de hauteur séparée : cela ne reconstitue pas leur volume caché.
- Les illustrations sources restent intactes. Aucune nouvelle génération
  d’image. La nouvelle apparence est une adaptation d’intégration, pas une
  approbation artistique automatique. La validation reste celle de l’utilisateur.

## Vérification et preuves

- `catalogue/overview.png` : capture native des neuf exemples fixes.
- `native/ready-spike.png`, `ready-snare.png`, `ready-void.png` : intégration dans
  une pièce avec les autres dalles. Les états déclenché/épuisé et les passages
  du repère de héros sont également conservés dans ce dossier.
- `before/` conserve les sprites et l’ancienne préparation ; `study/` contient
  les vues de travail hors moteur. Ne pas confondre ces montages avec les
  captures natives.
- Import et deux captures Godot : sortie 0, stderr vide. Le scénario natif des
  pièges compte 11 contrôles enregistrés, tous réussis : changement d’état,
  reconstruction, pause, réparation, charge par défaut, coup fatal, reprise,
  horloge réelle et suppression. Les images de superposition avec le repère de
  héros ont été inspectées ; ce n’est pas un oracle de profondeur par pixel.
- `verify_painted_traps.cjs` vérifie les huit pierres sans recouvrement ni trou
  dans leur anneau, les sources immuables, 136 régions non concernées, les deux
  autres pages d’atlas et 220 428 pixels extérieurs inchangés. Les 2 600 pixels
  centraux du sol des Pointes sont identiques entre états, contre 5 200
  différences pour les deux comparaisons de l’ancien sol. La bordure des marques
  lumineuses est exclue de ce dernier contrôle pour respecter le filtrage.
- Toujours 15 régions de pièges dans une page 512×1024, soit 2 MiB RGBA. Le PNG
  passe de 200 743 à 185 182 octets. Les trois glyphes du HUD ont été régénérés
  à partir de ces mêmes sprites.

Pas de modification de règles, charges, effets, caméra ou format de sauvegarde,
ni d’accès à une sauvegarde joueur. Pas de profilage sur téléphone ni de revue
de campagne complète. Aucun commit ou push effectué pour cette correction.
