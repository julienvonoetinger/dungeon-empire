# Décors maléfiques — propositions du 25 octobre 2026

Direction choisie par l’utilisateur : cristaux, idoles et objets rituels.
L’utilisateur rappelle explicitement que les décors doivent respecter la 2D
isométrique du donjon. Sa réponse « Tous » sélectionne les six apparences
présentées. La [sélection enregistrée](selection.json) conserve leurs empreintes
et celles des planches. La préparation géométrique et l’intégration dans Godot
restent à faire.

Les statuts de `generation.json` et `validation.json` décrivent l’étape antérieure
à cette sélection et sont conservés tels quels. `selection.json` fait référence
pour l’approbation des apparences ; elle ne valide pas encore leur calage exact.

## Comparaison

- [Planche de comparaison](comparison.png) : chaque proposition agrandie à 1,6×,
  puis à sa taille de jeu proposée, sur les vraies dalles B du kit.
- [Vue à petite taille](mobile-scale.png) : les six silhouettes côte à côte.
- [Sources originales](source/) : PNG ImageGen copiés sans modification.
- [Prompts et provenance](generation.json) : prompt commun, consigne de chaque
  objet, références et chemins des résultats de l’outil intégré ImageGen.
- [Vérifications](validation.json) : dimensions, empreintes SHA256 et limites.

| Repère | Objet | Hauteur proposée à l’écran |
| --- | --- | --- |
| A | Cristaux corrompus | 62 px |
| B | Idole de pierre | 76 px |
| C | Stèle rituelle | 84 px |
| D | Vasque d’offrandes | 49 px |
| E | Grimoire scellé | 56 px |
| F | Cierges rituels | 67 px |

Les tailles sont des propositions, mesurées sur le sujet opaque. Les vues
servent à juger la silhouette et les accents lisibles à petite taille : cristal,
yeux, rune, liquide, couverture et flammes. Les petits reliefs restent secondaires.
La vasque générée présente un tourbillon plus marqué que la consigne initiale ;
l’apparence montrée fait partie des six décors retenus.

## Projection et préparation

La cible est la projection commune du kit :

`screen = 256 * ((x-y)/2, (x+y)/4 - sqrt(3/8)*z)`

Le zoom fixe de 0,75 donne un losange logique de 192×96 pixels. Le repère rose
des grandes vues suit exactement ce rapport 2:1. Les verticales restent droites,
sans convergence. Le cadrage des sources a été demandé en vue orthographique
à 30° d’élévation ; l’ancienne maquette sert seulement de référence de style.

Le repère vérifie la grille du montage, pas la géométrie exacte des objets
générés. Avant leur adoption, il reste à vérifier et caler les supports rigides
sur les volumes de cette projection, définir leurs empreintes et leurs points
d’ancrage, puis préparer l’ordre d’affichage et les ombres de contact. Une source
incompatible devra être adaptée explicitement ; ne pas écraser sa largeur ou
faire pivoter le sprite à l’écran pour simuler une autre face.

Ces planches sont des montages de revue, pas des captures Godot. Elles n’ajoutent
ni ombre au sol ni lumière à la scène. Les points de contact sont provisoires.
La composition conserve l’alpha natif, recadre seulement les marges entièrement
transparentes et redimensionne uniformément. Le seuil alpha 128 sert uniquement
à mesurer la taille du sujet ; aucun pixel n’est effacé avec ce seuil.

Reproduction : `node tools/prepare_isometric_prop_review.cjs` avec Sharp disponible.
Le script vérifie les six copies contre leurs originaux et huit empreintes des
fichiers actifs. Le kit reste à 108 régions, atlas 1024×2048 / 8 MiB RGBA.
Aucune modification des scènes, du rendu, de la caméra ou de l’atlas ; aucune
importation/exportation Godot, aucun test automatisé, commit ou push pour cette
revue.
