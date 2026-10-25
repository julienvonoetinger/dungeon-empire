# Décors intégrés au kit isométrique

Les quatre motifs approuvés sont repris sans retouche ni nouvelle génération :
fissure courte v2, fracture ramifiée, pierre ébréchée v2 et corruption discrète.
Chaque motif possède sa projection pour le sol et les deux faces de mur visibles.

## Utilisation

F5 ouvre MobileReference avec les décors. Les 20 scènes utilisant le renderer de
salles les activent explicitement. Les props isolés et EntranceVariants restent
nus ; les scripts et anciennes revues ont un défaut désactivé.

Sur le nœud Dungeon :

- **Surface Details** : active/désactive les détails séparés.
- **Surface Detail Seed** : change la répartition, valeur initiale 17.

La sélection utilise les coordonnées logiques, l'orientation et la graine, jamais
l'ordre de parcours ou un tirage à chaque image. Elle s'effectue seulement lors
d'une reconstruction. Les candidats voisins se départagent par priorité stable :
huit voisins pour le sol, les deux voisins longitudinaux pour un mur. Les seuils
de candidature sont 25 % au sol et 40 % aux murs ; l'espacement réduit ensuite
ces proportions. Le choix du motif est pondéré 40/30/25/5 %, la corruption étant
la plus rare. Ce ne sont pas des quotas garantis dans chaque petite salle.

Les portes, escaliers, cases touchant le socle du cœur et segments portant une
torche sont exclus. Les mêmes PNG sont réutilisés sans rotation à l'écran,
agrandissement ou déplacement dans leur plan. Les joints en creux restent masqués
comme dans les images approuvées. Le dessin apparaît immédiatement après son
support : détails au sol, puis ombres, puis volumes triés et leurs détails.
Tous les détails reçoivent les lumières de leur surface et ne créent pas de lumière.

## Images et mesures

- `reference-bare.png` / `reference-decorated.png` : même caméra de jeu .75,
  option désactivée/activée, huit décors avec la graine 17.
- `reference-seed-43.png` : quatre décors avec une autre graine.
- `reference-restored.png` : retour à 17, image identique par SHA256.
- `captures/` : 68 captures en jeu pour les 23 scènes.
- `editor-captures/` : aperçus de cinq scènes dans le contexte éditeur.
- `observations.json` : placements observés dans les quatre vues de référence.
- `before/` : catalogue, atlas, scripts modifiés et empreintes avant intégration.
- `validation.json` : métriques, préservation et résultats des commandes.

Le catalogue compte **47 régions**, toujours **1024×1024**, **583 101 octets PNG**
et **4 Mio RGBA sans mipmaps**. L'ajout coûte 12 379 octets PNG. Les 35 anciennes
régions conservent leurs pixels RGBA et leurs métadonnées hors rectangle d'atlas.
Les 35 fichiers figés par la sélection artistique sont inchangés. Le petit atlas
de revue 256×256 est conservé comme référence, mais n'est pas chargé en jeu.

Import et captures en jeu : sorties 0, stderr vide. La capture éditeur sort à 0
mais conserve les diagnostics natifs de fenêtre/progression et de ressources à
l'arrêt. Export de ressources : **489 337 octets**, 46 fichiers source pour
23 scènes. Import de la copie, export et démarrage isolé : sorties 0, stderr vide.
Il ne s'agit pas d'un APK ; aucun profilage téléphone ni test automatisé effectué.

## Reproduction

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_isometric_decoration_integration.gd
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-decoration-review/v1/integration
node tools/prepare_mobile_export.cjs
```

`tools/isometric_approved_decorations.cjs` vérifie les empreintes de la sélection,
puis fournit les PNG préparés à l'exporteur. Il ne lance pas le peintre de revue.
`scripts/dungeon_surface_details.gd` choisit les hôtes et motifs. Le renderer
commun les place dans le même atlas et respecte l'ordre de leurs supports.

L'approbation des images d'origine est conservée. Cette répartition automatique
est une nouvelle intégration à examiner en jeu ; aucun commit ou push effectué.
