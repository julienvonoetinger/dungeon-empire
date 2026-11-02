Salle au trésor · Orientation du couloir

Ouvrir index.html. Nord 1 est le cas de référence. Les boutons comparent les
huit emplacements du passage dans Godot, avant/après à caméra identique.

La composition tourne sur la grille vers l’unique cellule de couloir
adjacente. Un atlas contient quatre sprites de la réserve. Chaque orientation
utilise les peintures avant ou arrière des coffres du kit. Les deux passages
d’un même côté partagent le sprite, avec un léger décalage latéral pour
dégager le seuil. Le tas d’or reste à l’opposé de l’accès. La caméra, les
ombres peintes et les murs utilisent toujours le même repère. Les murs de
premier plan peuvent masquer une partie de la réserve.

Depuis la racine du dépôt, avec Node, sharp et Godot installés :
  node docs/reference/treasury-review/v11-couloir/prepare.cjs
  godot --path . --script docs/reference/treasury-review/v11-couloir/capture.gd

La première commande reconstruit les quatre vues enregistrées dans
reserve-atlas.png et atlas.json. La seconde vérifie les 256 configurations
du périmètre, puis capture les huit entrées dans vues/. sources.json indique
l’origine du tas de pièces et des accessoires. Étude visuelle isolée.
