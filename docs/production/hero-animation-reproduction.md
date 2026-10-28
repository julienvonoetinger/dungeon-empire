# Reproduire et contrôler les sprites des héros

Ces commandes concernent les [recettes Vulpin actuelles](../reference/vulpin-review/README.md).
Les lancer depuis la racine du dépôt, dans PowerShell. **Rendre ou préparer une
action remplace ses sorties de revue et parfois ses ressources natives.** Pour
une nouvelle recherche, copier la recette dans un nouveau dossier, adapter ses
sorties et conserver la version précédente. Les commandes de contrôle et de
relecture ne régénèrent pas les images.

## Outils et vérification des sources

Environnement utilisé : Blender 5.2.1 LTS, Godot 4.7.2, Node 24.22.1,
Sharp 0.35.5 et libvips 8.18.7. Les
chemins des exécutables sont locaux ; les ajuster sur une autre machine.
Blender utilise son Python intégré. Sharp sert à la préparation, pas au rendu.

```powershell
$repo = (Get-Location).Path
$blender = 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe'
$godot = 'C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$node = 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe'
$env:NODE_PATH = 'C:/Users/A/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules'
& $blender --version
& $godot --version
& $node -e "console.log(process.version, require('sharp').versions)"
& $node tools/audit_hero_pipeline.cjs
if ($LASTEXITCODE -ne 0) { throw 'Sources absentes ou modifiées : examiner le rapport' }
```

L'audit est en lecture seule par défaut. Il vérifie les fichiers recensés par
taille/SHA256 et les liens des trois guides plus la provenance. Le manifeste
est un instantané de conservation, **pas un test de naturel ou de collision**.
Après une modification volontaire vérifiée, mettre à jour l'index et le
manifeste avec `--record`, puis relancer sans option. Ne pas utiliser `--record`
pour faire disparaître un écart inexpliqué. Les fichiers de rapport évoluent
eux aussi lorsqu'un contrôle est relancé.

## Refaire une action

Choisir une ligne de ce tableau. `prepare.cjs` est propre à chaque dossier.

| Dossier sous `docs/reference/vulpin-review/` | Script de pose | Blender sauvegardé | Complément avant préparation |
| --- | --- | --- | --- |
| `v16-meshy-walk` | `render_walk.py` | `vulpin-walk-poses.blend` | Copier ensuite les quatre feuilles dans `assets/previews/vulpin-walk`; conserver le `frames.tres` existant |
| `v17-meshy-run` | `render_run.py` | `vulpin-run-poses.blend` | Aucun |
| `v19-hurt-recoil` | `render_hurt.py` | `vulpin-hurt-poses.blend` | Aucun ; la région neutre est aussi utilisée par le repos |
| `v20-door-lockpick` | `render_lockpick.py` | `vulpin-lockpick-poses.blend` | `verify_masonry_clearance.py` |
| `v21-chest-open` | `render_chest_open.py` | `vulpin-chest-open-poses.blend` | Aucun ; garder le coffre entrouvert dans le stage |
| `v22-chest-lockpick` | `render_chest_lockpick.py` | `vulpin-chest-lockpick-poses.blend` | `calibrate_chests.cjs`, puis `verify_chest_clearance.py` |
| `v24-meshy-dead` | **`render_fall.py`** | `vulpin-fall-poses.blend` | Les 24 anciennes feuilles natives doivent encore correspondre à `previous-sprite-hashes.json` |

Exemple complet pour le crochetage de coffre :

```powershell
$action = Join-Path $repo 'docs/reference/vulpin-review/v22-chest-lockpick'
& $blender --background --python-exit-code 1 --python (Join-Path $action 'render_chest_lockpick.py')
if ($LASTEXITCODE -ne 0) { throw 'Échec des poses ou rendus' }
& $blender --background --python-exit-code 1 --python (Join-Path $action 'verify_saved_poses.py')
if ($LASTEXITCODE -ne 0) { throw 'Échec de relecture Blender' }
& $node (Join-Path $action 'calibrate_chests.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Échec de calibration' }
& $blender --background --python-exit-code 1 --python (Join-Path $action 'verify_chest_clearance.py')
if ($LASTEXITCODE -ne 0) { throw 'Collision avec les limites du coffre' }
& $node (Join-Path $action 'prepare.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Échec de préparation des sprites' }
```

Pour la porte, remplacer la calibration de coffre par
`verify_masonry_clearance.py` après le rendu/rechargement. Pour les autres
actions, garder rendu → relecture → préparation. Pour v16 uniquement,
après `prepare.cjs` :

```powershell
foreach ($view in 'se','sw','nw','ne') {
    Copy-Item -LiteralPath (Join-Path $repo "docs/reference/vulpin-review/v16-meshy-walk/sprites/walk-$view.png") -Destination (Join-Path $repo "assets/previews/vulpin-walk/walk-$view.png")
}
```

Le repos n'a pas de script de rendu : sa ressource pointe vers les régions
neutres des feuilles de dégâts. La dernière pose de chute sert déjà aux clips
`dead-*`, sans nouveaux PNG.

Les options de rendu vont après `--` : v16/v17/v19/v20/v22 proposent
`--pilot` pour SE et `--back-only` pour les vues arrière ; v19/v20/v22 ont aussi
`--peak-only`. v21 propose `--pilot`, `--ends-only` et `--no-render`.
v24 `--pilot` rend SE/NW aux poses 3,6,9, et `--final-only` la pose 9.
Les modes partiels écrivent dans les mêmes dossiers : ne pas préparer un atlas
à partir d'un mélange de nouveaux pilotes et de vieux maîtres. Après validation
du pilote, exécuter un rendu complet avant `prepare.cjs`.

Les `.blend` contiennent les ressources intégrées et les clés `CONSTANT`.
Leurs numéros d'images représentent des poses ; les durées runtime viennent
des métadonnées. Le résultat numérique de relecture doit rester sous la
tolérance du script. Un rendu Cycles refait avec un autre matériel ou une
autre version de bibliothèque n'est pas garanti byte-identique : conserver
les PNG de référence avant de comparer ou de régénérer les hashes.

## Vérification native sans toucher à une partie

Lancer l'import en arrière-plan, puis le script de capture. Le chemin de projet
est entouré de guillemets pour les emplacements contenant des espaces.
Les logs restent dans `artifacts/hero-pipeline-check`, exclu de Git.

```powershell
$logDir = Join-Path $repo 'artifacts/hero-pipeline-check'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$import = Start-Process -FilePath $godot -WindowStyle Hidden -Wait -PassThru -ArgumentList @('--headless','--editor','--path',('"' + $repo + '"'),'--import') -RedirectStandardOutput (Join-Path $logDir 'import.out.log') -RedirectStandardError (Join-Path $logDir 'import.err.log')
if ($import.ExitCode -ne 0) { throw 'Échec import Godot' }
$capture = Start-Process -FilePath $godot -WindowStyle Hidden -Wait -PassThru -ArgumentList @('--path',('"' + $repo + '"'),'--script','res://tools/capture_vulpin_chest_lockpick_preview.gd','--resolution','1280x900','--max-fps','60','--quit-after','600') -RedirectStandardOutput (Join-Path $logDir 'capture.out.log') -RedirectStandardError (Join-Path $logDir 'capture.err.log')
Get-Content (Join-Path $logDir 'import.err.log'),(Join-Path $logDir 'capture.err.log')
Get-Content (Join-Path $repo 'docs/reference/vulpin-review/v22-chest-lockpick/native-scene/validation.json')
if ($capture.ExitCode -ne 0) { throw 'Échec capture Godot' }
```

Vérifier ensemble code de sortie, stderr, message de fin et JSON sans échec.
Le timeout `--quit-after` ne prouve pas que le contrôle a fini : une erreur
de script peut laisser l'application attendre puis sortir sans validation.
Les captures ont besoin du renderer ; ne pas leur ajouter `--headless`.

| Action | Script Godot | Rapports / captures |
| --- | --- | --- |
| Marche | `tools/capture_vulpin_walk_preview.gd` | v16 `native-corridors/` |
| Course | même script, ajouter `-- --run` aux arguments | v17 `native-corridors/` |
| Dégâts | `tools/capture_vulpin_hurt_preview.gd` | v19 `native-scene/` |
| Porte | `tools/capture_vulpin_lockpick_preview.gd` | v20 `native-scene/` |
| Coffre déverrouillé | `tools/capture_vulpin_chest_open_preview.gd` | v21 `native-scene/` |
| Coffre verrouillé | `tools/capture_vulpin_chest_lockpick_preview.gd` | v22 `native-scene/` |
| Repos | `docs/reference/vulpin-review/v23-static-idle/capture.gd` | v23, trois PNG ; pas de JSON de tests |
| Chute / mort | `tools/capture_vulpin_death_preview.gd` | v24 `native-scene/` |

Après les captures des interactions ou de la mort, leur
`prepare_native_preview.cjs` reconstruit les WebP de revue depuis les PNG.
Les scripts de capture règlent eux-mêmes les tailles des vues. Ouvrir aussi la
scène avec F6 pour regarder les contacts en vue normale et, si proposé,
fantôme. Les modes fantômes et guides ne sont que des outils d'inspection.

## Conservation et transfert à une autre machine

Le manifeste couvre les sources courantes, les recettes, `.blend`, rapports,
ressources natives et dépendances directes recensées. Il ne remplace pas une
sauvegarde du dépôt complet : conserver également les atlases du donjon, ses
scripts, les références artistiques et l'historique utiles. Les maîtres PNG et
captures intermédiaires sont régénérables avec les recettes.

Les scripts courants lisent le GLB archivé. v24 résout également les anciennes
listes de hashes par leur chemin sous `assets/previews`, ce qui permet de
déplacer le dépôt. Des rapports historiques et scripts exploratoires ont
encore des chemins absolus ; ils restent des preuves, pas les commandes
conseillées ici. Les recettes supposent la profondeur actuelle des dossiers :
les déplacer implique d'adapter leurs chemins de sortie.

Ne pas relancer un export Android pour vérifier cette documentation. Un APK,
un commit et un push restent des actions distinctes à effectuer sur demande.
