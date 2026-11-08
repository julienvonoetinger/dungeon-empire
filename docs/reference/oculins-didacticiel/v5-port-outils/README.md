# Port des outils dans le donjon

La v5 reprend les trois marches de `../v4-marche`. Le mineur et le menuisier tiennent leur outil près du buste et la lame de la pioche suit le sens du passage. Le scientifique marche les mains libres. La recette retire le diapason et son empreinte dans la paume, puis abaisse le bras le long du corps sur les seize poses. Elle conserve les quatre caméras et le point d’appui au sol de la v4.

## Reproduction

Depuis la racine du dépôt, sous PowerShell avec Blender 5.2 et Python avec Pillow disponibles :

```powershell
$recipe = 'docs/reference/oculins-didacticiel/v5-port-outils'
$renders = 'artifacts/port-outils'
foreach ($role in 'mineur','menuisier','scientifique') {
    blender -b --factory-startup --python-exit-code 1 --python "$recipe/carry.py" -- $role $renders --render --optix
    if ($LASTEXITCODE) { throw "Échec du rendu de $role" }
}
python "$recipe/pack.py" $renders
godot --headless --import
godot --headless --script res://tools/verify_artisan_clearance.gd
```

Le rendu CPU s’obtient en retirant `--optix`. Chaque image complète de 384 px est réduite à 256 px. Le contrôle Blender vérifie la pose du bras et la continuité de la boucle. Pour les deux personnages équipés, il vérifie aussi la prise en main et les intersections outil/personnage. Pour chaque pose, les triangles entiers de l’outil sont regroupés par hauteur. Le fichier `tool-bounds.json` associe ces volumes aux empreintes SHA-256 des planches. Le scientifique a une liste de volumes d’outil vide à chaque pose. Le contrôle Godot les vérifie pendant l’entrée, le rassemblement et la sortie avec les trois emplacements de porte du couloir.
