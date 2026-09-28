# Mobile Texture Budget

`tools/mobile_texture_budget.gd` uses ConfigFile to update only texture imports
whose generated files occur in the current APK. It never writes source images.
Run it after a first APK when adding new texture dependencies, then import and
rebuild. Settings apply to this mobile branch's desktop imports too.

```powershell
$godot = 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
# Pipe output so PowerShell waits for the GUI executable.
& $godot --headless --path . --script tools/mobile_texture_budget.gd | Out-Host
& $godot --headless --path . --import | Out-Host
& $godot --headless --path . --script tools/mobile_texture_budget.gd -- --verify | Out-Host
./tools/android/build-debug.ps1
```

Preserve every `.import` file listed in `mobile-texture-budget-manifest.json`
when cleaning import churn. The manifest records each intentional setting's
original and final values. It accumulates changes across runs.

- Model, floor/wall and generated mobile UI imports: `process/size_limit=1024`.
- Metallic/roughness filenames: `process/size_limit=512`.
- Existing smaller caps remain smaller.
- `compress/mode=2`, `compress/high_quality=false`: VRAM compression with ETC2.
- Model/world mipmaps enabled, including `command-atlas-v1.png` and
  `core-monument-v1.png`, which also appear as world props. Portrait atlas
  mipmaps remain disabled.

Verification loads every recorded texture, checks its dimensions and settings,
and checks its ETC2 artifact exists. The initial budget covered 193 textures,
reducing the debug APK from 896.5 MiB to 195.9 MiB. Phone visual/performance
validation remains necessary; the source bitmaps retain their full resolution.
