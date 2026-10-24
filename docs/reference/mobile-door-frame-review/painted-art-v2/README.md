# Sommet en arche et ferrures en retrait

**Apparence validée par l'utilisateur : « Ok », le 24 octobre 2026.**
`selection.json` conserve les empreintes des sources, recettes et images validées.

Cette proposition répond aux deux corrections de l'utilisateur : raccourcir les
ferrures pour dégager du bois sur les côtés, et peindre un vrai sommet arrondi
avec son bord usé, au lieu de couper le haut d'une texture rectangulaire.

## Images

- `before-after.png` : v1 à gauche, proposition corrigée à droite, taille de jeu.
- `paint-and-guide.png` : rendu et superposition magenta du contour validé.
- `four-directions.png` : nord, est, sud et ouest, poignée sur les deux faces.
- `source/door-artwork.png` : peinture ImageGen finale avec transparence native.
- `source/door-intermediate.png` : première retouche, ferrures encore trop larges.

Les deux prompts ImageGen et les références sont conservés dans `generation.json`.
La silhouette de référence provient directement du bois du wireframe v8.

## Application dans le cadre

La peinture source a déjà un sommet arqué. Pour conserver son bord peint sur le
contour exact du jeu, la préparation ajuste chaque ligne horizontale de l'image
au profil validé. Elle conserve la source originale et interpole les couleurs
avec leur alpha. Le seuil alpha de 8 sert seulement à mesurer les extrémités,
pas à effacer ou rendre opaques les pixels. Le détail est dans `source/fit.json`.

Le résultat est projeté sur les deux faces du vantail par le workflow de masques
hors du jeu. Luminosité et saturation du matériau : .82/.82. Les chants gardent
un bois calme. Les arches, le mur lisse en retrait et leurs textures restent ceux
de la revue v8. Les ferrures sont des détails peints, pas des joints de géométrie.

```powershell
node tools/prepare_mobile_door_art_template.cjs
# Les sources ImageGen existantes sont conservées ; elles ne sont pas régénérées.
node tools/prepare_mobile_door_arch_artwork.cjs
node tools/prepare_mobile_nested_door_review.cjs --art-v2
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_nested_door_review.gd -- --art-v2
node tools/prepare_mobile_nested_door_review.cjs --boards --art-v2
```

## État

28 parties et 12 captures Godot, code 0, stderr vide. Alpha du vantail et guides
identiques à v8 ; les 24 parties de pierre gardent aussi leurs empreintes.
Zéro trou intérieur ou pixel extérieur excédentaire dans les rapports d'export.
Les captures et guides ont été inspectés. Détails dans `export-report.json`.

Apparence validée puis **intégrée au kit actif** après le « Vas-y » de
l'utilisateur. Le [bilan d’intégration](../integration/) enregistre les sorties
de production. Les images et `selection.json` ci-dessus restent le relevé figé
de l'approbation, antérieur à la migration. Aucun test automatisé ajouté ou
exécuté, aucun profilage mobile.
