# Généralisation des raccords approuvés — 23 octobre 2026

L'utilisateur a validé le comparatif horizontal / vertical. Conserver la gamme
stylisée, la finition B et toute la géométrie. Le problème vient de la peinture
indépendante des fragments, puis du filtrage de leurs limites alpha.

## Travail

1. Construire un voisinage géométrique local à l'export. Les pierres traversant
   une limite sont peintes entières, avec une identité, une texture et un reflet
   stables. Aucun dessin de salle entière dans les assets de production.
2. Exporter les PNG par case, avec une garde de filtrage de deux pixels de
   référence uniquement dans le volume opaque commun. Dédupliquer les images
   identiques. Conserver les ancrages, le pas 256 et l'échelle 0,25.
3. Sélectionner ces images selon le voisinage logique dans le script partagé.
   Préparer aussi les raccords des quatre portes et quatre escaliers.
4. Réimporter et examiner les scènes existantes à taille normale et agrandie.
   Documenter l'export et ses limites ; conserver le comparatif approuvé.

## Contraintes de revue

- Un changement d'alpha individuel est attendu dans la garde intérieure ; il
  ne doit pas élargir la silhouette de l'assemblage.
- RGB, biseaux et accents doivent être stables par pierre entière, sans dépendre
  de l'ordre des régions ni du nom de la scène.
- Examiner les angles, piliers, extrémités ouvertes, portes et escaliers, pas
  uniquement les deux exemples approuvés.
- Pas de tests ajoutés ou lancés : seuls exports, audits de sources et captures
  de rendu. Pas de commit/push demandé à cette étape.

## Journal

- Diagnostic et prototype déjà examinés : voir `wall-join-review-plan.md` et
  `wall-join-review/`. Implémentation poursuivie dans le checkout actuel.

- Export connecté étendu aux 1 296 voisinages ordinaires (dont 161 sans structure),
  aux orientations spéciales et aux configurations locales des scènes existantes.
  Catalogue de chemins chargés à la demande, sol partagé et placement conservé.
- Visibilité des matières de portes corrigée aux frontières coplanaires ; la
  déduplication inclut désormais la visibilité et le repère du bois.
- Revue indépendante des sources : aucun défaut bloquant confirmé. Le reviewer
  a examiné les captures de murs nord/ouest/sud ; pas de conclusion exhaustive
  sur les futurs assemblages ni sur un export de jeu empaqueté.
- Import et capture des 20 scènes terminés sans erreur. La revue visuelle a
  toutefois repéré des traits d'escalier sur l'arche de ReferenceCalibration.
  Correction commune : découper les traits aux frontières projetées des faces
  puis supprimer les segments occultés par le volume voisin. Export spécial et
  nouvelle capture terminés sans erreur. L'arche de la capture finale ne porte
  plus les traits des marches cachées.

- Catalogue final : 737 structures, 1 sol, 1 444 clés dont 161 sans structure.
  Empreintes des sources/PNG conformes au catalogue, aucun PNG actif inutilisé.
  208 PNG intermédiaires et leurs imports archivés dans
  `artifacts/whole-stone-retired/` puis retirés du dossier actif.
- Captures finales après correction : les sept scènes de pièces spéciales ont
  été reprises à 1×/2×. Les détails des murs et de l'arche sont conservés dans
  `wall-join-review/godot-final-{details,arch}.png`. Documentation synchronisée.
  Aucun test ajouté/lancé, aucun commit/push effectué.
