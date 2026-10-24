# Décors lumineux — proposition visuelle du 24 octobre 2026

L'utilisateur a accepté de commencer par une torche murale orange et un cristal
violet enchâssé. Cette étude présente leur apparence dans Godot à la distance de
jeu. L'apparence attend encore son retour ; aucune promotion dans le kit actif.

## À regarder

- `comparison.png` : recadrages Godot sans agrandissement, sprites seuls puis
  avec lumière locale. Le halo doux déjà peint dans le sprite reste présent dans
  les deux vues ; seule la lumière sur les surfaces voisines change.
- `captures/with-local-light.png` : salle complète, caméra fixe à 0,75.
- `LightReview.tscn` : scène indépendante, Espace active/désactive les lumières.
  `docs/` est exclu de l'import Godot : ouvrir le fichier par son chemin explicite
  ou lancer la commande ci-dessous. Le script décode les PNG préparés directement.

| Élément | PNG préparé | Poids PNG | Sujet affiché à 0,75 |
| --- | --- | --- | --- |
| Torche | 73 × 109 px | 7 897 octets | environ 66 px de haut |
| Cristal | 75 × 68 px | 5 363 octets | environ 41 px de haut |

Les dimensions comprennent la marge transparente de l'image source. Le poids
total des deux PNG est de 13 260 octets (~13 Kio), hors texture de lumière.
Ce chiffre est un poids de fichier, pas une mesure de mémoire GPU.

## Fabrication et placement

Les deux originaux `source/*.png` proviennent de l'outil intégré image_gen, avec
alpha natif. La maquette `mobile-optimization/source/mockup.png` est la référence.
`generation.json` conserve les deux prompts exacts et les chemins de génération.
Les originaux sont conservés sans retouche.

`prepare_mobile_light_review.cjs` réduit l'image entière en conservant son alpha.
Le seuil alpha 128 sert seulement à mesurer le sujet pour choisir sa taille :
aucun pixel n'est supprimé, recoloré ou déformé. `prepared.json` conserve tailles,
ancrages, positions d'émission, réglages de lumière et empreintes SHA256.

Les objets sont montrés sur la façade d'un mur horizontal. La torche possède une
plaque de fixation en fer ; le cristal est entouré d'un petit logement en pierre
ébréchée. Leur intégration et leur taille sont des propositions à juger dans la
capture, sans validation implicite des autres orientations.

Le script de revue utilise le rendu architectural commun et son ordre physique
de dessin. Les sprites préparés sont placés à échelle 1, sans rotation ni
déformation. Le point d'attache est projeté sur la façade existante. La lumière
est un PointLight2D additif par source, avec un petit dégradé radial préparé hors
ligne. Rayon source : 190 px pour la torche, 140 pour le cristal ; énergie :
2,4 et 1,6. Les sprites lumineux eux-mêmes ne reçoivent pas ce second éclairage.

## Reproduire

Avec Node et Sharp disponibles :

```powershell
node tools/prepare_mobile_light_review.cjs
& $godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_light_review.gd
node tools/prepare_mobile_light_review.cjs --boards
```

Pour parcourir directement la proposition :

```powershell
& $godot --path . res://docs/reference/mobile-light-review/LightReview.tscn
```

La capture a terminé avec le code 0 et un stderr vide. Les deux vues et leur
comparaison ont été inspectées visuellement. Pas de tests automatisés ajoutés ou
exécutés, ni de profilage sur téléphone. Les lumières sont statiques et sans
ombres portées dans cette étude ; l'occlusion lumineuse pour des salles voisines
et les autres orientations restent à traiter avant une intégration générale.

Le kit, l'atlas, la scène principale et les scènes de production restent dans
leur état antérieur. Aucun commit ou push pour cette proposition.
