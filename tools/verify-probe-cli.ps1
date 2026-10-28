param([string]$Godot = 'C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$scratch = Join-Path $repo ('artifacts/probes/cli-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
$script:checks = 0
$script:failures = @()
function Assert-Case([bool]$Condition,[string]$Label) {
    $script:checks++
    if (-not $Condition) { $script:failures += $Label; Write-Host "FAIL: $Label" }
}
function Write-Fixture([string]$Name,$Data) {
    $path = Join-Path $scratch $Name
    [IO.File]::WriteAllText($path,($Data | ConvertTo-Json -Depth 15),[Text.UTF8Encoding]::new($false))
    return $path
}
function Invoke-Wrapper([string]$InputFile,[string]$OutputFile) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-probes.ps1') -Godot $Godot -Scenario $InputFile -Report $OutputFile | Out-Null
    return $LASTEXITCODE
}
$good = @{name='CLI check';initial='prepared';steps=@(@{action='assert';probe='economy';field='gold';op='eq';value=245})}
$goodPath = Write-Fixture 'good.json' $good
$report = Join-Path $scratch 'out.json'
Assert-Case ((Invoke-Wrapper $goodPath $report) -eq 0) 'success exits zero'
Assert-Case ((Get-Content $report -Raw | ConvertFrom-Json).ok) 'success report is positive'
$first = (Get-FileHash $report).Hash
Assert-Case ((Invoke-Wrapper $goodPath $report) -eq 0) 'replay succeeds'
Assert-Case ((Get-FileHash $report).Hash -eq $first) 'replay report byte identical'
$bad = @{name='wrong gold';steps=@(@{action='assert';probe='economy';field='gold';op='eq';value=999})}
$badPath = Write-Fixture 'failure.json' $bad
Assert-Case ((Invoke-Wrapper $badPath $report) -eq 1) 'failed assertion exits one'
$result = Get-Content $report -Raw | ConvertFrom-Json
Assert-Case (-not $result.ok -and $result.runs[0].failures[0].probe -eq 'economy') 'failure identifies probe'
$timeout = Write-Fixture 'timeout.json' @{name='timeout';steps=@(@{action='wait';probe='raid';field='active';op='eq';value=$true;timeout=0.05})}
Assert-Case ((Invoke-Wrapper $timeout $report) -eq 1) 'timeout exits one'
$invalid = Write-Fixture 'invalid.json' @{version=$true;name='bad version';steps=@(@{action='checkpoint';label='x'})}
Assert-Case ((Invoke-Wrapper $invalid $report) -eq 2) 'schema error exits two'
Assert-Case (-not (Get-Content $report -Raw | ConvertFrom-Json).ok) 'schema error cannot pass'
$before = (Get-FileHash $goodPath).Hash
$stdout = Join-Path $scratch 'native.out.log'
$stderr = Join-Path $scratch 'native.err.log'
$nativeArgs = '--headless --path "{0}" --script res://tools/run_probes.gd -- --scenario "{1}" --report "{1}"' -f $repo,$goodPath
$native = Start-Process -FilePath $Godot -ArgumentList $nativeArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
Assert-Case ($native.ExitCode -eq 2) 'native conflicting report exits two'
Assert-Case ((Get-FileHash $goodPath).Hash -eq $before) 'native error cannot overwrite input'
Assert-Case ((Get-Item $stderr).Length -eq 0) 'native validation has no script errors'
$singleSuite = Join-Path $scratch 'suite'
New-Item -ItemType Directory -Path $singleSuite | Out-Null
Copy-Item -LiteralPath $goodPath -Destination (Join-Path $singleSuite 'good.json')
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'run-probes.ps1') -Godot $Godot -Suite ($singleSuite + '/') -Report $report | Out-Null
Assert-Case ($LASTEXITCODE -eq 0) 'trailing suite separator is quoted correctly'
Assert-Case ((Get-Content $report -Raw | ConvertFrom-Json).ok) 'trailing separator produces requested report'
$summary = @{checks=$script:checks;failures=$script:failures;scratch=$scratch}
$summary | ConvertTo-Json -Depth 5
$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $repo 'artifacts/probes/cli-verification.json') -Encoding UTF8
if ($script:failures.Count) { exit 1 }
exit 0
