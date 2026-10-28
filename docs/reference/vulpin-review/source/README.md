# Modèle source du Vulpin

`Meshy_AI_Character_output.glb` est une copie byte-identique du fichier fourni
par l'utilisateur, initialement dans `C:/Users/A/Downloads/`. Elle a été
archivée ici le 28 octobre 2026 pour ne plus dépendre de ce dossier temporaire.

- Taille : **15 644 004 octets**.
- SHA256 : `035f4d448e60fefd99b5eb9c8a7f2ddd55405802dcc060018d0c9595d848e2b4`.
- Maillage : `output_unwrapped`, 10 321 triangles, 13 590 sommets exportés.
- Armature : `SmartRigArmature`, 57 os avec poids.
- Peinture et textures intégrées au GLB ; aucune animation ni morph de visage.

Ne pas écraser cet original en enregistrant une pose. Les fichiers `.blend`
par action et les scripts de pose sont les dérivés modifiables. Le `.gdignore`
du dossier parent exclut cette source des imports Godot. Seuls les PNG et
ressources de `assets/previews/` sont utilisés par les scènes de revue.

Les recettes actuelles v15, v16, v17, v19, v20, v21, v22 et `v24/render_fall.py`
lisent cette copie avec un chemin relatif. Les scripts abandonnés conservent
leurs anciennes références et ne doivent pas servir de point de départ.

Voir le [guide de production](../../../production/hero-animation-pipeline.md)
et les [instructions de reproduction](../../../production/hero-animation-reproduction.md).
