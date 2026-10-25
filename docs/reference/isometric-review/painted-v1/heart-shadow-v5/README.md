# Ombre directionnelle — 24 octobre 2026

L'utilisateur rejette l'agrandissement dans toutes les directions de v4. Le socle
conserve son apparence ; son ombre doit être portée d'un seul côté.

La projection est maintenant `ground = [x-z*Lx/Lz, y-z*Ly/Lz, 0]` avec
`L = [-2.1,-1.2,1]`. Ce choix suppose une lumière ambiante en haut à gauche et
donne une ombre vers le bas à droite à l'écran. Tous les échantillons de lumière
gardent ce sens. Les points à z=0 ne bougent pas : aucune dilatation de l'empreinte
du socle. Le contact est de nouveau fin (.7 pixel source), le bord porté diffus
(1.2 pixel source). Les opacités .32/.38 et le sprite du cœur restent inchangés.

L'effet reste statique, sans réaction aux torches. Le vortex lumineux ne projette
pas d'ombre. Le renderer existant place le PNG au-dessus des sols, sous les
volumes, et l'omet dans les layouts si sa zone de réception sort du sol ou traverse
une case spéciale. L'aperçu isolé DungeonHeart conserve son exception sans sol.

Seul `heart-shadow.png` change parmi les PNG préparés : **251×170**, **7 496
octets**. L'atlas garde 27 régions, 1024×1024, 4 Mio RGBA ; PNG **550 518 octets**.
Le dossier `before/` conserve v4, son générateur, ses empreintes et ses captures.

Après export et captures, reproduire le comparatif Godot avec :

```powershell
node tools/prepare_isometric_large_shadow_review.cjs --directional
```

La direction est intégrée et montrée pour retour visuel. Les import/captures et
résultats d'export sont consignés dans `validation.json`. Aucune approbation
artistique n'est déduite des contrôles techniques. Pas de tests automatisés,
profilage mobile, commit ou push.

Import et 68 captures runtime / 23 scènes : sortie 0, stderr vide. Les 21 captures
éditeur / cinq scènes sortent à 0 avec les diagnostics natifs de progression et
ressources à l'arrêt connus. Paquet isolé : 45 dépendances, **453 767 octets** ;
import, export et ouverture sortent à 0 avec stderr vide.
