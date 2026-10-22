param(
    [switch]$All,
    [string]$Godot,
    [switch]$Capture
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$artifactRoot = Join-Path $projectRoot 'artifacts'
New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

if (-not $Godot) { $Godot = $env:GODOT_BIN }
if (-not $Godot) {
    foreach ($commandName in @('godot', 'godot4')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { $Godot = $command.Source; break }
    }
}
if (-not $Godot) {
    $Godot = 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    throw 'Godot introuvable : utilisez -Godot <chemin.exe> ou GODOT_BIN.'
}

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$EngineArguments, [string]$CheckProject = $projectRoot)
    $stdout = Join-Path $artifactRoot "$Name.out.log"
    $stderr = Join-Path $artifactRoot "$Name.err.log"
    $arguments = @('--path', ('"{0}"' -f $CheckProject)) + $EngineArguments
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(60000)) {
        Stop-Process -Id $process.Id
        throw "$Name : délai de 60 secondes dépassé."
    }
    $process.Refresh()
    $output = Get-Content -LiteralPath $stdout -Raw
    $errors = Get-Content -LiteralPath $stderr -Raw
    Write-Output $output
    if ($errors) { Write-Output $errors }
    if ($process.ExitCode -ne 0 -or $errors -match '(?m)(SCRIPT ERROR|ERROR):') {
        throw "$Name a échoué (code $($process.ExitCode)). Voir $artifactRoot."
    }
}

# -All keeps the established repository entry point; the old gameplay suite was
# retired with v1.0.0. Both default and -All run the entire current scene check.
Invoke-GodotCheck 'import' @('--headless', '--editor', '--import')
Invoke-GodotCheck 'verify-scene' @('--headless', '--script', 'res://tools/verify_scene.gd')
Invoke-GodotCheck 'verify-six-rooms' @('--headless', '--script', 'res://tools/verify_six_rooms.gd')
# The single-cell art study is now reviewed through capture_modular_room.gd.
# Its old assertions describe a rejected composition and are no longer run.
Invoke-GodotCheck 'verify-alpha-assets' @('--headless', '--script', 'res://tools/verify_alpha_assets.gd')
Invoke-GodotCheck 'verify-wall-layers' @('--headless', '--script', 'res://tools/verify_wall_layers.gd')
Invoke-GodotCheck 'verify-entry-seams' @('--headless', '--script', 'res://tools/verify_entry_seams.gd')
Invoke-GodotCheck 'verify-torches' @('--headless', '--script', 'res://tools/verify_torches.gd')
Invoke-GodotCheck 'verify-heart' @('--headless', '--script', 'res://tools/verify_heart.gd')
Invoke-GodotCheck 'verify-variations' @('--headless', '--script', 'res://tools/verify_variations.gd')
Invoke-GodotCheck 'verify-probes' @('--headless', '--script', 'res://tools/verify_probes.gd')
Invoke-GodotCheck 'main-scene' @('--headless', '--quit-after', '3')
# Exercise real @tool processing without changing the user's open editor tabs.
# A normal editor main loop also releases its UI resources cleanly at shutdown.
$editorCheckRoot = Join-Path $artifactRoot 'editor-refresh-project'
foreach ($relativePath in @(
    'project.godot', 'scenes/SixRoomPreview.tscn',
    'scenes/DungeonHeart.tscn', 'assets/dungeon/heart/reference.png',
    'scripts/six_room_preview.gd', 'scripts/six_room_view.gd',
    'scripts/stone_variation.gd',
    'scripts/alpha_kit.gd', 'scripts/alpha_heart.gd', 'scenes/DungeonTorch.tscn',
    'assets/dungeon/torches/torch-violet-v1.png', 'assets/dungeon/torches/torch-violet-v1.png.import',
    'scripts/probe_fixtures.gd', 'scripts/dungeon_probes.gd', 'scripts/probe_overlay.gd',
    'scripts/reference_pieces.gd', 'scripts/dungeon_layout.gd',
    'assets/layouts/six_rooms.tres', 'assets/dungeon/perspective/reference-atlas.png',
    'tools/verify_editor_refresh.gd', 'tools/fixtures/EditorRefreshCheck.tscn'
)) {
    $destination = Join-Path $editorCheckRoot $relativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot $relativePath) -Destination $destination -Force
}
foreach ($asset in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/dungeon/alpha-kit') -File) {
    $destination = Join-Path $editorCheckRoot ('assets/dungeon/alpha-kit/' + $asset.Name)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath $asset.FullName -Destination $destination -Force
}
Invoke-GodotCheck 'editor-refresh-import' @('--headless', '--editor', '--import') $editorCheckRoot
Invoke-GodotCheck 'editor-refresh' @('--headless', '--editor', 'res://tools/fixtures/EditorRefreshCheck.tscn', '--', '--verify-editor-refresh') $editorCheckRoot
if ($Capture) {
    Invoke-GodotCheck 'modular-rooms' @('--script', 'res://tools/capture_modular_room.gd')
    Invoke-GodotCheck 'room-corridors' @('--script', 'res://tools/capture_room_corridors.gd')
    Invoke-GodotCheck 'module-connections' @('--script', 'res://tools/capture_module_connections.gd')
    Invoke-GodotCheck 'capture' @('--script', 'res://tools/capture_scene.gd')
    Invoke-GodotCheck 'verify-reference' @('--script', 'res://tools/verify_reference.gd')
    Invoke-GodotCheck 'compare-reference' @('--script', 'res://tools/capture_reference_comparison.gd')
    Invoke-GodotCheck 'verify-six-rooms-gpu' @('--script', 'res://tools/verify_six_rooms.gd', '--', '--gpu')
    Invoke-GodotCheck 'verify-entry-seams-gpu' @('--script', 'res://tools/verify_entry_seams.gd', '--', '--gpu')
    Invoke-GodotCheck 'verify-heart-gpu' @('--script', 'res://tools/verify_heart.gd', '--', '--gpu')
    Invoke-GodotCheck 'six-room-details' @('--script', 'res://tools/capture_six_room_details.gd')
    Invoke-GodotCheck 'entrance-seams-detail' @('--script', 'res://tools/capture_entry_seams.gd')
    Invoke-GodotCheck 'vertical-wall-details' @('--script', 'res://tools/capture_vertical_walls.gd')
    Invoke-GodotCheck 'alpha-joins-detail' @('--script', 'res://tools/capture_alpha_joins.gd')
    Invoke-GodotCheck 'wall-projection-comparison' @('--script', 'res://tools/capture_wall_projection.gd')
    Invoke-GodotCheck 'stone-variation-comparison' @('--script', 'res://tools/capture_stone_variation.gd')
    Invoke-GodotCheck 'probe-capture' @('--script', 'res://tools/capture_probes.gd')
}
