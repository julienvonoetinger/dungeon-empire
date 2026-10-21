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
    param([string]$Name, [string[]]$EngineArguments)
    $stdout = Join-Path $artifactRoot "$Name.out.log"
    $stderr = Join-Path $artifactRoot "$Name.err.log"
    $arguments = @('--path', ('"{0}"' -f $projectRoot)) + $EngineArguments
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
Invoke-GodotCheck 'main-scene' @('--headless', '--quit-after', '3')
if ($Capture) {
    Invoke-GodotCheck 'capture' @('--script', 'res://tools/capture_scene.gd')
}
