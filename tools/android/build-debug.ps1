[CmdletBinding()]
param(
    [string]$Godot = 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$output = Join-Path $root 'artifacts/android'
$apk = Join-Path $output 'dungeon-empire-debug.apk'
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw "Godot executable missing: $Godot" }
& (Join-Path $PSScriptRoot 'audit-payload.ps1')
New-Item -ItemType Directory -Force -Path $output | Out-Null

# Export scans/imports resources itself. Keep its large log out of the terminal.
$log = Join-Path $output 'export.log'
$errorLog = Join-Path $output 'export.stderr.log'
$started = [DateTime]::UtcNow
$arguments = @('--headless', '--path', ('"' + $root + '"'), '--export-debug', '"Android Debug"', ('"' + $apk + '"'))
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput $log -RedirectStandardError $errorLog
$code = $process.ExitCode
$errors = Select-String -LiteralPath $log,$errorLog -Pattern 'SCRIPT ERROR:|ERROR:'
if ($code -ne 0 -or $errors -or -not (Test-Path $apk) -or (Get-Item $apk).LastWriteTimeUtc -lt $started) {
    Write-Host "Export failed or reported errors. Inspect $log and $errorLog"
    Get-Content -LiteralPath $errorLog -Tail 20 | ForEach-Object { Write-Host $_ }
    throw "Android export did not pass validation (exit $code)."
}
Write-Host "APK: $apk"
Write-Host "Export log: $log"
Write-Host "Stderr log: $errorLog"
& (Join-Path $PSScriptRoot 'audit-payload.ps1') -ApkPath $apk
