# Deux arches séparées — wireframe à valider

**Proposition rejetée : l'espace doit contenir un mur lisse.** Voir la
[révision 6](../wireframe-v6/) ; ne pas conserver le vide proposé ici.

Dernière correction : « Non il faut un espace entre les 2 arches ».
La grande arche reste inchangée. La petite arche retrouve sa largeur de la v3,
en conservant un espace entre elles et en supprimant la rangée de briques qui
occupait cet espace. La v4, où les arches se touchaient, est rejetée.

## Proposition représentée

- Grande arche blanche : rayons 5/12 et 7/12, source mobile originale.
- Petite arche cyan : rayons .27 et .35, sept voussoirs et ses propres montants.
- Écart entre les deux : 5/12 − .35 = .066667 case.
- Bois ocre : rayon/demi-largeur .26, inchangé depuis la v3.
- Départ commun des arcs : H = 1.88/6 ; profondeur pierre : 1/6.

Le dessin propose un espace ouvert, y compris sur les côtés, sans volume de
remplissage ni joints entre les arches. Les arêtes désormais visibles dans cet
espace sont projetées et occultées avec les mêmes règles que le kit.
Cette interprétation visuelle reste à valider avant toute peinture.

`wireframe.png` / `wireframe.svg` montrent la face et la perspective du jeu.
`perspective.png` isole cette dernière. `geometry.json` conserve les paramètres,
volumes, lignes et empreintes des sources.

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs --legacy-open-gap
```

La génération produit uniquement ces documents de revue, sans modifier le kit
actif, ses matériaux ou les scènes Godot.
