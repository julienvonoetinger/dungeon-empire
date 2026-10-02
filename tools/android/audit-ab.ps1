$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$archives = @()
try {
    foreach ($backend in @('opengl', 'vulkan')) {
        $path = Join-Path $root "artifacts/android/dungeon-empire-$backend-probe.apk"
        $zip = [IO.Compression.ZipFile]::OpenRead($path)
        $archives += $zip
        $reader = [IO.BinaryReader]::new($zip.GetEntry('assets/_cl_').Open())
        $arguments = @()
        try {
            $count = $reader.ReadInt32()
            for ($i = 0; $i -lt $count; $i++) {
                $arguments += [Text.Encoding]::UTF8.GetString($reader.ReadBytes($reader.ReadInt32()))
            }
        } finally { $reader.Dispose() }
        $method = $arguments[[Array]::IndexOf($arguments, '--rendering-method') + 1]
        $driver = $arguments[[Array]::IndexOf($arguments, '--rendering-driver') + 1]
        $expectedMethod = if ($backend -eq 'opengl') { 'gl_compatibility' } else { 'mobile' }
        $expectedDriver = if ($backend -eq 'opengl') { 'opengl3' } else { 'vulkan' }
        if ($method -ne $expectedMethod -or $driver -ne $expectedDriver) {
            throw "Incorrect renderer command line in $backend APK"
        }
        Write-Host "$backend APK: method=$method driver=$driver"
    }
    $count = 0
    foreach ($entry in $archives[0].Entries) {
        if (-not $entry.FullName.StartsWith('assets/') -or $entry.FullName -eq 'assets/_cl_') { continue }
        $other = $archives[1].GetEntry($entry.FullName)
        if ($null -eq $other) { throw "Missing counterpart: $($entry.FullName)" }
        $hashes = @()
        foreach ($item in @($entry, $other)) {
            $stream = $item.Open()
            $hash = [Security.Cryptography.SHA256]::Create()
            try { $hashes += [Convert]::ToBase64String($hash.ComputeHash($stream)) }
            finally { $hash.Dispose(); $stream.Dispose() }
        }
        if ($hashes[0] -ne $hashes[1]) { throw "Game resource differs: $($entry.FullName)" }
        $count++
    }
    $otherCount = @($archives[1].Entries | Where-Object { $_.FullName.StartsWith('assets/') -and $_.FullName -ne 'assets/_cl_' }).Count
    if ($otherCount -ne $count) { throw 'Resource counts differ' }
    Write-Host "$count game resource entries identical by SHA-256; renderer arguments verified."
} finally {
    foreach ($zip in $archives) { $zip.Dispose() }
}
