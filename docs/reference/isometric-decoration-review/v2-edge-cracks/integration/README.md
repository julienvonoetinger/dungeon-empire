# Variantes de fissures intégrées — 25 octobre 2026

L'utilisateur a accepté les trois nouvelles formes, puis demandé d'intégrer
toutes les variantes. Les décors disponibles sont **coin fendu, fissure verticale,
fissure latérale, éclat usé et corruption violette**, chacun préparé pour le sol
et les deux faces de mur. Les six anciennes fissures ordinaires sont remplacées ;
les essais rejetés restent dans les références.

Les neuf PNG de la nouvelle sélection sont adoptés sans repeinture ni changement
de taille, d'alpha ou de raccord. `../selection.json` fige les 27 fichiers de la
revue ; les 35 fichiers de l'ancienne sélection restent également inchangés.
La corruption violette conserve son apparence précédemment acceptée.

## Répartition

La densité, les hôtes, les exclusions et la graine restent ceux de l'intégration
précédente. Seul le choix du motif change : coin 25 %, verticale 25 %, latérale
20 %, éclat 25 %, corruption 5 %. Ce sont des poids de sélection parmi les
décors éligibles, pas des pourcentages de couverture du donjon.

Les sols restent sous les ombres et les objets ; les détails des murs sont
dessinés immédiatement après leur support. Aucun travail ajouté par frame,
aucune rotation de sprite, aucune nouvelle texture de base.

## Résultat et vérification

- `reference-decorated.png` : capture Godot de la scène de référence.
- `reference-seed-43.png` : autre répartition ; `reference-restored.png` est
  identique par SHA256 à la première après retour à la graine 17.
- `six-room-native.png` et `captures/` : scènes plus vastes et kit complet.
- `editor-confirm/editor-captures/` : seconde capture des cinq aperçus éditeur.
- `pixel-validation.json` : pixels, métadonnées et fichiers sélectionnés.
- `validation.json` : commandes et limites de la vérification.

Le kit compte **50 régions**, dont **15 décors**, dans le même atlas **1024×1024** :
**580 419 octets PNG**, **4 Mio RGBA**. Les 41 régions conservées ont les mêmes
pixels et métadonnées (hors position dans l'atlas). Les neuf nouvelles régions
correspondent exactement à l'atlas approuvé ; leurs PNG préparés sont copiés
octet pour octet. Les cinq motifs apparaissent dans les captures ciblées.

Import, 68 captures en jeu / 23 scènes, cinq captures ciblées, import de la copie,
export et démarrage isolé : sorties 0, stderr vide. ZIP de ressources :
**486 487 octets**, 46 dépendances pour 23 scènes. Aucun APK ou profilage téléphone.

L'éditeur produit 21 captures / cinq scènes et sort à 0. Le premier passage a
émis un diagnostic de résolution de `layout` dans l'ancien outil historique
`capture_approved_heart.gd`. Il ne réapparaît pas au second passage complet, sans
modifier cet outil. Les diagnostics natifs de fenêtre et de ressources à l'arrêt
restent présents (1399 octets au second passage) : stderr éditeur n'est pas vide.

## Reproduction

```powershell
node tools/export_isometric_painted_kit.cjs
godot --headless --editor --path . --import
godot --path . --rendering-method gl_compatibility --script res://tools/capture_isometric_edge_cracks_integration.gd
godot --path . --rendering-method gl_compatibility --script res://tools/capture_mobile_kit.gd -- --output-root=res://docs/reference/isometric-decoration-review/v2-edge-cracks/integration
node tools/prepare_mobile_export.cjs
```

Ne pas relancer les anciens générateurs de revue dans leurs dossiers figés.
Pas de test automatisé ajouté, de commit ou de push dans cette intégration.
