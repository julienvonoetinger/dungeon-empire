# Fissures et usure — première série isométrique

Quatre motifs séparés : fissure courte, fracture ramifiée, pierre ébréchée et
fissure corrompue discrète. Chaque dessin possède une projection pour le sol et
pour les deux faces de mur visibles : **12 sprites transparents**. Apparence
validée par l'utilisateur le 24 octobre 2026 (« Ok »). `selection.json` conserve
les empreintes des images retenues. Les décors sont maintenant intégrés au kit
commun : voir [l'intégration](integration/README.md). Les JSON de préparation et
de validation gardent leur état historique antérieur à cette approbation.

## Voir le résultat

- `variants.png` compare chaque motif sur le sol et les murs à la taille de jeu
  (.75), avec des détails ×2 explicitement indiqués. Ce sont des compositions
  hors ligne des mêmes sprites préparés et des surfaces existantes.
- `scene-comparison.png` compare deux captures Godot .75 sans redimensionnement.
- `captures/mixed.png` est la scène complète avec une répartition espacée ; les
  quatre captures nommées par motif isolent chaque apparence.
- `Decorations.tscn` est la scène de revue locale : lancer par son chemin explicite
  ci-dessous. Espace affiche/masque les détails ; déplacement à la souris ou au
  doigt, zoom fixe .75. `docs/.gdignore` évite d'importer les sources volumineuses.

```powershell
godot --path . res://docs/reference/isometric-decoration-review/v1/Decorations.tscn
```

## Sources et préparation

Génération avec **ImageGen intégré**, fond alpha natif. Prompts exacts et rôle
des références : `generation.json`, puis `refinement.json` pour les deux
retouches. `source/` conserve les quatre originaux et les versions v2 de
`crack-short` (cassure plus lisible) et `chip-worn` (éclat moins saillant).
Les sprites courants, sources sélectionnées, empreintes et transformations sont
décrits dans `prepared.json`. `first-pass/` conserve la première capture et recette.

Les fichiers de référence étaient `wall-h-0.png` et `floor.png` du kit peint,
utilisés pour la palette et le style. Aucune architecture n'a été régénérée.
Chaque source est réduite uniformément dans son plan, puis projetée avec la
caméra isométrique approuvée ; la forme ne subit pas de rotation à l'écran.
Le seuil alpha 128 sert uniquement à mesurer l'encombrement du sujet pour son
échelle. Tous les pixels alpha natifs restent échantillonnés. Les seuls masques
sont la visibilité géométrique de la surface et les joints en creux des murs.

Dans la scène, chaque détail est dessiné immédiatement après son support.
Il reçoit les mêmes lumières. Les volumes au premier plan et l'ombre du cœur
restent au-dessus. La corruption ne crée pas de nouvelle source lumineuse.

## Poids et portée

Atlas de revue **256×256**, **12 874 octets PNG**, **256 Kio RGBA**. Les douze
images mesurent de 37 à 72 pixels de large et de 32 à 57 pixels de haut, avant
le zoom .75. Le catalogue de production reste à 35 régions / 4 Mio : cet atlas
de décors n'y est pas encore ajouté. Les assets, scripts et captures sélectionnés
pour l'ombre v6 sont inchangés par empreinte.

Cette étape fournit les images et une scène de comparaison, avec des placements
de démonstration fixes. Elle ne fournit pas encore un éditeur de décor, un
placement aléatoire ou une migration de toutes les scènes de production.

## Reproduction

```powershell
node tools/prepare_isometric_decoration_review.cjs
godot --path . --rendering-method gl_compatibility --script res://tools/capture_isometric_decoration_review.gd
node tools/prepare_isometric_decoration_boards.cjs
```

Six captures, sortie 0 et stderr vide. Inspection des deux planches et de la
scène complète. Une revue indépendante ciblée n'a trouvé aucun défaut concret
de projection, d'ordre d'affichage ou de masquage. La lisibilité et l'apparence
restent des préférences à valider par l'utilisateur. Aucun test automatisé,
export de production, profilage sur téléphone, commit ou push à cette étape.
