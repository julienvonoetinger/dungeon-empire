# Images peintes — revue du catalogue isolé

## À regarder

- [Sélection de pièces](overview.png) et [superposition magenta](overview-overlay.png).
- Toutes les cases : [planche 1](cells-1.png), [planche 2](cells-2.png), [planche 3](cells-3.png).
- [Sol, pilier, quatre escaliers et quatre portes](specials.png).
- [Même planche avec le wireframe](specials-overlay.png).

Les PNG individuels transparents sont dans
[`assets/dungeon/painted-cells/`](../../../assets/dungeon/painted-cells/).
Le [catalogue](../../../assets/dungeon/painted-cells/catalog.json) résout les
146 identifiants des guides vers 57 images distinctes. Une image n'est pas une
variante approuvée tant que sa revue artistique n'a pas été faite.

## Géométrie et matériaux

- Cases carrées 1×1, épaisseur 1/6, hauteur 1.88/6, deux assises égales.
- Projection `(x − .18z, y − .9z)` ; jamais de miroir du dessin projeté.
- Même pas de 1024 px et même ancrage ×4 sur toute la famille.
- Cases/escaliers : 1216×1408, ancrage (96,352).
- Portes : 1216×1568, ancrage (96,512).
- Sol : 1056×1056, ancrage (16,16) ; pilier : 384×576, ancrage (96,352).
- Quatre matières de mur, quatre de sol, un bois et un métal communs.
- Traits magenta superposés à la même origine et à la même échelle.

Le fond sombre des planches sert à la présentation. Les images individuelles
gardent leur alpha. Les accents violets font partie de l'image préparée.

## Contrôle et reproduction

Depuis la racine, avec Node.js et sharp :

```powershell
node tools/prepare_shared_stone_materials.cjs
node tools/export_painted_image_catalog.cjs
```

Le [rapport global](validation.json) enregistre les empreintes des sources,
les segments copiés, la comparaison alpha et les éventuels trous de peinture.
L'export actuel conserve tous les traits des 57 images : **0 différence d'alpha,
0 pixel intérieur non peint et 0 pixel opaque excédentaire**. Les 146 alias
pointent vers des images existantes. Les trois planches de cases et celles des
pièces spéciales ont été inspectées, avec détails agrandis de porte et d'escalier.
Chaque image a son `-report.json`, son `-regions.svg` de construction et sa
superposition `-overlay.png`. Les masques des portes viennent aussi de la
visibilité des volumes 3D : une seule zone de traits peut contenir plusieurs
matières lorsque des solides se touchent sans trait d'intersection.

Les [règles de matière](../MATERIAL_WORKFLOW.md) précisent les sources et les
décisions utilisateur. Les prompts bois/métal et les sorties originales sont
référencés dans `assets/dungeon/shared-materials/generation.json`.

## Portée

Ces images montrent les pièces isolées, avec leurs extrémités visibles. Les
tests de coordonnées et d'alpha ne constituent pas une validation artistique,
ni une preuve des raccords dans un donjon assemblé. Les textures wireframe et
les scènes Godot ne sont pas remplacées par cet export.
