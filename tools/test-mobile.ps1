[CmdletBinding()]
param(
    [string]$Godot = 'C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe',
    [switch]$All
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$logs = Join-Path $root 'artifacts/tests'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$pattern = if ($All) { '*.gd' } else { 'mobile_*_test.gd' }
$tests = Get-ChildItem -LiteralPath (Join-Path $root 'tests') -Filter $pattern
$failures = @()
foreach ($test in $tests) {
    $stdout = Join-Path $logs ($test.BaseName + '.out.log')
    $stderr = Join-Path $logs ($test.BaseName + '.err.log')
    $arguments = @('--headless', '--path', ('"' + $root + '"'), '--script', ('res://tests/' + $test.Name), '--quit-after', '600')
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(120000)) {
        Stop-Process -Id $process.Id
        $failures += $test.Name
        Write-Host "TIMEOUT $($test.Name)"
        continue
    }
    $process.Refresh()
    $errors = Select-String -LiteralPath $stdout,$stderr -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:'
    if ($process.ExitCode -ne 0 -or $errors) {
        $failures += $test.Name
        Write-Host "FAIL $($test.Name)"
        $errors | ForEach-Object { Write-Host $_.Line }
    } else {
        Write-Host "PASS $($test.Name)"
    }
}
Write-Host "$($tests.Count - $failures.Count)/$($tests.Count) passed; logs: $logs"
if ($failures.Count) { throw ('Failed tests: ' + ($failures -join ', ')) }
