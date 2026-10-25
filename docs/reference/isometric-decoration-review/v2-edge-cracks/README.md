# Fissures liées aux bords des pierres — proposition du 25 octobre 2026

L'utilisateur trouve les fissures intégrées trop grossières. Il précise ensuite
que les essais plus fins répètent tous une diagonale gauche-droite : ses références
montrent des cassures courtes qui partent des bords et des coins d'une pierre.

Cette proposition comporte trois silhouettes différentes : **coin fendu**,
**cassure verticale depuis le haut**, **fissure latérale depuis un côté**. Les
dessins sont nouveaux ; les murs, sols, sculptures, lumière et projection restent
ceux du kit actif. La proposition n'est pas intégrée au catalogue de production.

## Voir

- `comparison.png` : actuelle puis trois propositions, sol et deux murs à .75,
  avec le même détail de mur agrandi ×3, explicitement indiqué.
- `gameplay-comparison.png` : extraits non redimensionnés de deux captures Godot,
  mêmes hôtes, mêmes lumière et caméra, avant/après.
- `captures/current.png` / `captures/proposed.png` : vues entières 1280×720.
- `Cracks.tscn` : revue isolée ; Espace alterne les dessins actuels et proposés.

La scène remplace seulement les trois familles de fissures, sur les hôtes déjà
sélectionnés par la répartition active. L'éclat `chip-worn` reste inchangé.
Le motif corrompu est remplacé par le tracé latéral sans violet dans cette étude
de formes ; aucune nouvelle variante corrompue n'est proposée ici.

## Images et préparation

Créées avec **ImageGen intégré**, alpha natif. `generation.json` garde tous les
prompts et rôles des images ; `source-files.json` relie les sorties originales
aux copies du projet. `references/` conserve les deux images fournies par
l'utilisateur. `drafts/` conserve les premiers essais diagonaux écartés après
sa précision. La version verticale extrêmement fine n'est pas utilisée : elle
disparaissait à l'échelle du jeu. La source courante est
`source/vertical-hairline-readable.png` ; son ouverture haute est coupée par
le bord physique de la pierre, comme les autres traits qui commencent dans un joint.

`prepare_isometric_edge_cracks_review.cjs` reprend la projection et
l'échantillonnage du peintre v1 figé, dans un nouvel outil. Les sources sont
réduites uniformément dans leur plan, puis projetées. Elles se raccordent aux
bords d'une pierre centrale réelle, avec masquage de la pierre voisine et du
mortier. Les coins et positions XYZ du kit ne changent pas.

Le seuil alpha 128 sert uniquement à mesurer l'encombrement pour l'échelle. Les
pixels natifs sont échantillonnés sans extraction par couleur ni seuil d'alpha.
Seuls les masques de visibilité, de pierre et de mortier coupent le dessin.
Après projection, le cadre retire les pixels exactement transparents en gardant
deux pixels de marge. Aucun axe n'est comprimé indépendamment et aucune rotation
en espace écran n'est utilisée.

Neuf PNG préparés, atlas de revue 256×256 / 3 388 octets PNG. La faible résolution
est celle du kit ; les dessins restent volontairement discrets. Préférence
artistique et lisibilité restent à valider par l'utilisateur.

## Reproduire

```powershell
node tools/prepare_isometric_edge_cracks_review.cjs
godot --path . --rendering-method gl_compatibility --script res://tools/capture_isometric_edge_cracks_review.gd
node tools/prepare_isometric_edge_cracks_boards.cjs
```

Deux captures terminées, sortie 0, stderr vide. Planche et comparaison de jeu
inspectées. `validation.json` enregistre les empreintes courantes et la
préservation de la production/sélection v1. Aucun test automatisé, import/export
de production, commit ou push dans cette étude.
