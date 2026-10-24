# Deux arches jointives — wireframe à valider

**Proposition rejetée.** L'utilisateur précise qu'il faut un espace entre les
deux arches. Voir [wireframe-v5/](../wireframe-v5/) pour la correction proposée.

Correction demandée : supprimer les briques entre les deux arches, car la
révision 3 donnait l'impression de trois arches.

La révision 4 supprime le contour intermédiaire de rayon .35 et la rangée
supplémentaire. La petite arche cyan rejoint directement le bord intérieur
de l'arche principale blanche. Les montants ont également une seule largeur,
sans bande latérale intermédiaire. Le bois conserve les proportions de la v3.

- Arche principale : rayons 5/12 et 7/12, géométrie originale conservée.
- Petite arche : rayons .27 et 5/12, sept voussoirs.
- Bois : demi-largeur/rayon .26 ; sommet H + .26.
- H = 1.88/6 ; profondeur pierre = 1/6 ; projection du kit inchangée.

`wireframe.png` et `wireframe.svg` montrent la vue de face et la perspective
du jeu. `perspective.png` isole cette dernière. `geometry.json` conserve les
paramètres, volumes et lignes. L'ancienne v3 reste disponible pour comparaison.

```powershell
node tools/prepare_mobile_nested_arch_wireframe.cjs --legacy-joined
```

Cette correction reste une proposition en lignes pour validation visuelle.
Aucune texture, scène Godot ou ressource du kit actif n'est modifiée.
