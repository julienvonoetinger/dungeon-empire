# Android Debug

Run PowerShell from the worktree root. Requires Godot 4.7.2 with matching Android
export templates, a JDK, and Android SDK tools. Normal APK template export is
used: no Gradle, NDK or CMake. The preset is arm64-only, package
`org.dungeonempire.prototype`; landscape is inherited from `project.godot`.

```powershell
./tools/android/setup-sdk.ps1 -AcceptLicenses
./tools/android/build-debug.ps1
```

Setup uses command-line tools 19.0 (avoiding incompatible latest CLI shims),
downloads verified archives from Google's SDK repository and installs
platform-tools, build-tools 35.0.1 and platform android-35. `-AcceptLicenses`
accepts the SDK licenses; omit it for interactive review. Existing packages
are retained. Default SDK: `C:\Users\A\AppData\Local\Android\Sdk`.

Godot Editor Settings > Export > Android must point to that SDK, the installed
JDK and a local debug keystore. This machine's Steam editor already has those
paths configured and uses JDK 25. `build-debug.ps1 -Godot <exe>` selects another
editor, which needs its own settings and matching templates. No signing keys
or passwords belong in the preset. JDK 17 is the documented Godot baseline if
another machine encounters Java incompatibility.

Output: `artifacts/android/dungeon-empire-debug.apk`; logs:
`artifacts/android/export.log` and `artifacts/android/export.stderr.log`.
The build fails on nonzero exit, script/export errors or stale/missing output.
Rebuild after the rest of the mobile changes land.

Enable `rendering/textures/vram_compression/import_etc2_astc=true` and finish
source imports before building, even for Compatibility rendering. The debug
APK build and signature verification passed on 2026-09-28. Phone validation
is pending: `adb devices -l` found no connected device.

## Payload

The preset exports selected resources and their Godot dependencies, not every
imported art variant. Explicit roots retain runtime scripts, all referenced
hero models (including priest/saurian), UI/font/Core art, production textures,
seven constructed Core fragment paths and nine `paver_v3` trap states.
The certificate bundle and font license are included as plain files.

```powershell
./tools/android/audit-payload.ps1
./tools/android/audit-payload.ps1 -PrintSelection
./tools/android/audit-payload.ps1 -ApkPath artifacts/android/dungeon-empire-debug.apk
```

These commands never start Godot or import/export. The build wrapper runs the
source audit before exporting and the ZIP audit afterward. Review new path
construction manually; the literal scan is conservative, not a GDScript parser.
`-PrintSelection` prints suggested roots for updating the preset. Source sizes
are not APK size estimates; Godot adds imported dependencies and compression.
The ZIP audit checks root/remap entries, not successful runtime loading.

Audit on 2026-09-28 selected 141 roots (730 MiB source, before dependencies).
The initial 896.5 MiB APK was reduced to approximately 196.6 MiB (206 MB) by
budgeting 193 exported textures: 1024 pixels for color/UI/environment textures,
512 for metallic/roughness maps, with ETC2 compression. Original source images
are unchanged. The package is arm64-only and requests no permissions.
The obsolete mobile tool icon paths were removed.
The preset supplies the existing Core sprite as its launcher icon.

Import settings are recorded in `tools/android/mobile-texture-budget-manifest.json`.
`tools/mobile_texture_budget.gd -- --verify` checks dimensions and ETC2 outputs.
The command atlas and Core sprite have mipmaps because they also appear in 3D;
portraits are UI-only. To budget newly exported textures, run the script without
`--verify` after a first APK export, reimport, then export again. This edits only
Godot import configuration, not original bitmaps.

## Desktop Verification

```powershell
./tools/test-mobile.ps1 -All
```

`tools/capture_mobile.gd` produces management, building, raid and result captures
at 1280x720, 1560x720 and 960x540. Run Godot with
`--rendering-method gl_compatibility --script res://tools/capture_mobile.gd` to
exercise the Android renderer on desktop. Desktop default rendering remains
Forward+ for the legacy test scenes.

Android caps the frame rate at 30 and the 3D resolution scale at 0.75; the 2D HUD
stays at native resolution. The mobile scene uses 2x MSAA, bounded shadowless
lights, automatic mesh LODs, cutaway walls and 2D Core/prop sprites. These are
budgets, not proof of sustained device performance. Native desktop render
counters on the starter scene were approximately 343 draws/658k primitives
in management and 196 draws/556k primitives in a followed raid.

## Real Phone

Enable USB debugging and authorize this computer. Select the phone's serial:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices -l
$serial = '<phone serial>'
& $adb -s $serial install -r artifacts/android/dungeon-empire-debug.apk
& $adb -s $serial shell am start -n org.dungeonempire.prototype/com.godot.game.GodotAppLauncher
& $adb -s $serial logcat -s godot AndroidRuntime
```

Do not uninstall to resolve a signature mismatch: that loses local saves.
Use the same debug key or investigate before replacing the app.

Check landscape and safe areas; Core placement, digging, storage and entrance;
tap/drag/pinch/rotate/focus; trap preview/cancel/confirm; a complete raid and
one-time rewards/unlocks; force-close/relaunch save recovery; sustained 30 FPS
through a raid. Record device model, Android version, APK hash, results and
performance observations. An APK build alone does not validate phone behavior.

References: [Godot Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html),
[Android SDK tools](https://developer.android.com/tools/sdkmanager).
