[CmdletBinding()]
param(
    [switch]$PrintSelection,
    [string]$ApkPath
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$selected = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
[void]$selected.Add('res://Main.tscn')
[void]$selected.Add('res://scripts/Main.gd')
$scripts = @(Get-Item (Join-Path $root 'scripts/Main.gd'))
foreach ($directory in @('game', 'hud', 'mobile', 'world')) {
    $scripts += Get-ChildItem (Join-Path $root "scripts/$directory") -Filter *.gd -Recurse |
        Where-Object { $_.Name -ne 'render_lab.gd' }
}
foreach ($script in $scripts) {
    [void]$selected.Add('res://' + $script.FullName.Substring($root.Length + 1).Replace('\', '/'))
    # Conservative literal inventory includes load/preload, tables and path constants.
    foreach ($match in [regex]::Matches((Get-Content $script.FullName -Raw), '["''](res://[^"''\r\n]+)["'']')) {
        $path = $match.Groups[1].Value
        if ($path -in @('res://assets/models/traps/', 'res://assets/models/core_fragments/fragment_%d.res')) { continue }
        if ($path.Contains('%') -or $path.EndsWith('/')) { throw "Review new constructed resource path: $path" }
        [void]$selected.Add($path)
    }
}
# Constructed paths in core_anomaly.gd and meshy_stone_trap.gd.
foreach ($index in 0..6) { [void]$selected.Add("res://assets/models/core_fragments/fragment_$index.res") }
foreach ($family in @('spike', 'snare', 'void')) {
    foreach ($state in @('armed', 'sprung', 'broken')) {
        [void]$selected.Add("res://assets/models/traps/paver_v3/${family}_${state}.glb")
    }
}
$paths = @($selected | Sort-Object)
if ($PrintSelection) {
    'export_files=PackedStringArray(' + (($paths | ForEach-Object { '"' + $_ + '"' }) -join ', ') + ')'
    return
}
$preset = Get-Content (Join-Path $root 'export_presets.cfg') -Raw
if ($preset -notmatch '(?m)^export_filter="resources"\r?$') { throw 'Expected selective resources export.' }
$line = [regex]::Match($preset, '(?m)^export_files=PackedStringArray\((.*)\)\r?$')
if (-not $line.Success) { throw 'Missing explicit export resource list.' }
$configured = @([regex]::Matches($line.Groups[1].Value, '"([^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value })
$missing = @($paths | Where-Object { $_ -notin $configured })
$absent = @($configured | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_.Substring(6)) -PathType Leaf) })
if ($missing.Count -or $absent.Count) {
    foreach ($path in $missing) { Write-Host "Not selected: $path" }
    foreach ($path in $absent) { Write-Host "Source missing (finish asset generation first): $path" }
    throw 'Payload roots need review. -PrintSelection prints current suggested roots; no files are modified.'
}
$bytes = ($configured | ForEach-Object { (Get-Item -LiteralPath (Join-Path $root $_.Substring(6))).Length } | Measure-Object -Sum).Sum
Write-Host ('Static audit: {0} selected roots, {1:N1} MiB source; imported dependencies and APK compression are additional.' -f $configured.Count, ($bytes / 1MB))
Write-Host 'Literal runtime references, seven Core fragments and nine paver trap states are selected. Godot resolves their transitive dependencies during export.'
Write-Host 'This static audit does not prove runtime loading. Keep constructed-path coverage current when scripts change.'
if (-not $ApkPath) { return }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ApkPath).Path)
try {
    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in $zip.Entries) { [void]$names.Add($entry.FullName) }
    $missingPacked = @()
    foreach ($path in $configured) {
        $entry = 'assets/' + $path.Substring(6)
        if (-not ($names.Contains($entry) -or $names.Contains($entry + '.import') -or $names.Contains($entry + '.remap'))) {
            $missingPacked += $path
        }
    }
    $forbidden = @($zip.Entries | Where-Object { $_.FullName -match '^assets/(art/|art_bible/|tools/|tests/|docs/|artifacts/|\.godot/editor/)' })
    if ($missingPacked.Count -or $forbidden.Count) {
        $missingPacked | Select-Object -First 12 | ForEach-Object { Write-Host "APK root missing: $_" }
        $forbidden | Select-Object -First 12 | ForEach-Object { Write-Host "Unexpected APK entry: $($_.FullName)" }
        throw 'APK payload audit failed.'
    }
    Write-Host ('APK: {0:N1} MiB; all selected roots have export entries.' -f ((Get-Item -LiteralPath $ApkPath).Length / 1MB))
    $zip.Entries | Sort-Object CompressedLength -Descending | Select-Object -First 8 |
        ForEach-Object { Write-Host ('{0:N1} MiB compressed: {1}' -f ($_.CompressedLength / 1MB), $_.FullName) }
} finally {
    $zip.Dispose()
}
