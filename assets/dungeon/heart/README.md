# Cœur du donjon

`heart.png` est le sprite complet à alpha natif utilisé par
`scenes/DungeonHeart.tscn` via `scripts/alpha_heart.gd`.

Il a été déplacé depuis `assets/dungeon/alpha-kit/heart.png` lors du nettoyage du
23 octobre 2026, sans modifier ses pixels ni ses réglages d'import.
SHA-256 : `8322d1472022c2949c3a73626a8fbb9e7909e08e2e798f6fd22327795567e43c`.

Le sprite conserve le cadre entier 1269 × 1239, la mesure du corps
(295,322,680,724), la largeur affichée de 220 et la position (-110,-147).
Le rectangle du corps sert uniquement à l'ancrage et à l'échelle uniforme ;
la texture entière est affichée. La lumière du sol reste définie dans la scène.

`reference.png` est une copie inchangée de la maquette originale approuvée par
l'utilisateur. Elle sert de référence artistique et n'est pas découpée au runtime.

La provenance historique est conservée dans
`docs/cleanup/alpha-kit-generation-before-cleanup.json`.
Le cœur reste un prop séparé, absent du SixRoomPreview actuel.
