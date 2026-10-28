param(
    [string]$Scenario,
    [string]$Suite = 'tests/scenarios',
    [Nullable[int]]$Seed = $null,
    [ValidateRange(1,100)][int]$Runs = 1,
    [string]$Report = 'artifacts/probes/report.json',
    [string]$Godot = $env:GODOT
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Godot) {
    $command = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $Godot = $command.Source }
    elseif (Test-Path -LiteralPath 'C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe') {
        $Godot = 'C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
    } else { throw 'Provide -Godot or set GODOT to the Godot executable.' }
}
function Resolve-TaskPath([string]$Path) {
    if ($Path.Contains('://')) { throw 'Use filesystem paths in this PowerShell wrapper.' }
    if ([IO.Path]::IsPathRooted($Path)) { return [IO.Path]::GetFullPath($Path) }
    return [IO.Path]::GetFullPath((Join-Path $repo $Path))
}
$reportFile = Resolve-TaskPath $Report
if ([IO.Path]::GetExtension($reportFile) -ne '.json') { throw 'Report must have a .json extension.' }
$inputPath = Resolve-TaskPath $(if ($Scenario) { $Scenario } else { $Suite })
if ($reportFile -eq $inputPath -or (-not $Scenario -and (Split-Path -Parent $reportFile) -eq $inputPath)) {
    throw 'Keep reports outside the input scenario/suite.'
}
$logDirectory = Join-Path $repo 'artifacts/probes/logs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $reportFile) | Out-Null
$runId = [Guid]::NewGuid().ToString('N')
$temporaryReport = Join-Path $logDirectory ($runId + '.json')
$stdout = Join-Path $logDirectory ($runId + '.out.log')
$stderr = Join-Path $logDirectory ($runId + '.err.log')
$arguments = @('--headless','--path',$repo,'--script','res://tools/run_probes.gd','--',
    $(if ($Scenario) { '--scenario' } else { '--suite' }),$inputPath,
    '--runs',[string]$Runs,'--report',$temporaryReport)
if ($null -ne $Seed) { $arguments += @('--seed',[string]$Seed) }
# Start-Process takes a command-line string on Windows; quote path arguments.
# Quotes cannot occur in Windows filenames; there is no intervening shell.
$quoted = ($arguments | ForEach-Object { '"' + ($_ -replace '(\\+)$', '$1$1') + '"' }) -join ' '
$process = Start-Process -FilePath $Godot -ArgumentList $quoted -WorkingDirectory $repo -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle # Keep the native handle so ExitCode survives WaitForExit on Windows PowerShell.
# A broken script must not leave automation waiting forever.
if (-not $process.WaitForExit(300000)) {
    $process.Kill()
    $process.WaitForExit()
    $exitCode = 2
    $engineError = 'Godot exceeded the five-minute watchdog.'
} else {
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $engineError = Get-Content -LiteralPath $stderr -Raw
}
Get-Content -LiteralPath $stdout
if ($engineError -or -not (Test-Path -LiteralPath $temporaryReport)) {
    # Godot can exit zero after a script runtime error. Never call that a pass.
    $exitCode = 2
    @{ version=1; ok=$false; status='error'; error="Godot failed: $engineError"; stdout=$stdout; stderr=$stderr } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportFile -Encoding UTF8
    Write-Host "Runner error; inspect $stderr"
} else {
    $result = Get-Content -LiteralPath $temporaryReport -Raw | ConvertFrom-Json
    # The structured result is authoritative even if the GUI process wrapper
    # loses the native exit status. Never let a failed scenario exit zero.
    if ($result.status -eq 'failed' -and -not $result.ok) { $exitCode = 1 }
    elseif ($result.status -eq 'error' -and -not $result.ok) { $exitCode = 2 }
    elseif ($result.status -ne 'passed' -or -not $result.ok -or $null -eq $exitCode -or $exitCode -ne 0) { $exitCode = 2 }
    Move-Item -LiteralPath $temporaryReport -Destination $reportFile -Force
}
Write-Host "Report: $reportFile"
exit $exitCode
