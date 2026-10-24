# Petite arche intérieure — wireframe à valider

**Historique remplacé par [la révision 4](../wireframe-v4/).** L'utilisateur a
signalé que la rangée de briques intermédiaire donnait une troisième arche.
Ne pas utiliser cette rangée dans la prochaine proposition.

La demande du 24 octobre 2026 conserve l'arche principale et ajoute une seconde
arche, plus petite, pour encadrer le bois. La pierre remplit aussi l'espace
au-dessus de la porte. Les propositions qui réduisaient l'arche principale
(v1) ou ajoutaient seulement des montants latéraux (v2) sont rejetées.

## Lecture

- `wireframe.png` / `wireframe.svg` : vue de face et perspective du jeu.
- `perspective.png` : vue du couloir seule.
- Blanc : arche principale existante, géométrie conservée.
- Cyan : petite arche et maçonnerie ajoutée, sur les côtés et au-dessus.
- Ocre : porte en bois réduite, avec un sommet arrondi plus bas.
- Gris : murs du couloir et repères de sol.

La vue de face explique la structure. La vue du couloir utilise la projection
du kit `(x - .18z, y - .9z)` et masque les arêtes cachées par les volumes.
Les murs gardent leurs deux assises. Le trait sur le sommet des murs ne crée
pas une troisième assise. Le plan du bois reste en retrait de la façade pierre.

## Proportions proposées, en cases

| Élément | Dimensions |
| --- | --- |
| Arche principale | Rayons 5/12 et 7/12, inchangés |
| Petite arche | Rayon intérieur .27, extérieur .35 |
| Bois | Demi-largeur/rayon .26 |
| Départ des arcs | H = 1.88/6, commun aux deux arches |
| Profondeur pierre | 1/6, inchangée |
| Retrait du bois derrière la façade | .025 |

La maçonnerie ajoutée remplit la couronne entre les rayons .35 et 5/12 ainsi
que les montants latéraux. La petite arche en pierre occupe .27 à .35.
Le bois a donc un sommet plus bas : H + .26 au lieu de H + 5/12. La hauteur
totale de l'arche principale reste H + 7/12. Les chiffres sont une proposition
de dessin ; l'utilisateur n'a pas encore validé ces proportions.

Les 56 volumes de l'arche principale proviennent du même JSON source et de la
même expansion radiale que l'export mobile existant. Ils ne sont pas redessinés
à partir d'une image. `geometry.json` conserve les volumes, lignes, paramètres
et empreintes des sources pour reprendre cette proposition après validation.

## Reproduction

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs --legacy-three-rings
```

Ce script génère uniquement les documents de cette revue. Aucun matériau,
sprite du kit, scène Godot ou catalogue actif n'est modifié. Les autres
orientations et la peinture attendent la validation du wireframe.
