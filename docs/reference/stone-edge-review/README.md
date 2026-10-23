# Adoucir les pierres : revue du coin supérieur gauche

Comparaison conservée avant intégration. L'utilisateur a choisi **B** le
23 octobre 2026 (« ok pour B »).

- **A — précédente** : copie exacte du PNG avant intégration de B.
- **B — adoucie** : coins émoussés, arêtes presque régulières et reflets continus.
- **C — plus irrégulière** : arrondi plus prononcé et petites ondulations des arêtes.

`comparison.png` montre les cases et un gros plan. `details.png` contient les gros
plans seuls. `b-soft-overlay.png` et `c-worn-overlay.png` superposent le wireframe
magenta d'origine aux propositions.

Les textures, couleurs de base, coordonnées de matière, cadrage, projection et
masque alpha de la case sont conservés. Seule la finition visible des pierres
est redessinée par la méthode de masques hors jeu déjà autorisée. Les joints
internes peuvent donc s'écarter volontairement des traits droits d'origine.
Le modèle n'est pas régénéré par imagegen et aucune nouvelle matière n'est créée.

Reproduction avec Node.js et `sharp` :

```powershell
node tools/prepare_stone_edge_review.cjs
```

Les paramètres et empreintes sont dans `recipe.json`. Le rayon est mesuré dans
le cadre de référence 304×352 ; le rendu PNG est à ×4. Les faces étroites et le
sol reçoivent un adoucissement proportionnellement réduit. L'angle intérieur du
retour reste sur le gabarit pour respecter l'occultation des faces.

Le générateur lit désormais `a-current.png` et les fichiers figés de `source/`.
Il ne lit plus le sprite actif comme base A : une réexportation ne doit pas
modifier la référence approuvée. Les fichiers de texture communs restent les
crops approuvés identifiés dans `source/materials.json`.
Leurs empreintes sont contrôlées avant toute écriture. Si une matière a changé,
la reproduction s'arrête ; elle ne remplace pas silencieusement B. Le PNG B
reproduit doit également conserver l'empreinte de l'image approuvée.

La recette de production est `assets/dungeon/shared-materials/stone-finish.json` ;
le compositeur utilise `tools/stone_edge_finish.cjs`. Les fragments périodiques du
sol sont finis comme une pierre entière. Les coupes internes aux raccords de murs
ne reçoivent pas de nouveau biseau. Voir `../PAINTED_GODOT.md` pour l'intégration
et sa revue visuelle ; cette planche seule ne valide pas tous les assemblages.
