[CmdletBinding()]
param(
    [string]$SdkPath = "$env:LOCALAPPDATA\Android\Sdk",
    [switch]$AcceptLicenses
)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$cache = Join-Path $root 'artifacts/android/sdk-downloads'
$manager = Join-Path $SdkPath 'cmdline-tools/19.0/bin/sdkmanager.bat'
if (-not $env:JAVA_HOME) {
    $env:JAVA_HOME = Split-Path (Split-Path (Get-Command java -ErrorAction Stop).Source -Parent) -Parent
}
if (-not (Test-Path $manager)) {
    $destination = Join-Path $SdkPath 'cmdline-tools/19.0'
    if (Test-Path $destination) { throw "Incomplete tools at $destination; inspect manually before retrying." }
    New-Item -ItemType Directory -Force -Path $cache | Out-Null
    [xml]$repository = (Invoke-WebRequest 'https://dl.google.com/android/repository/repository2-1.xml').Content
    $package = @($repository.SelectNodes("//*[local-name()='remotePackage']") | Where-Object {
        $_.path -eq 'cmdline-tools;19.0' -and $_.channelRef.ref -eq 'channel-0'
    })
    if ($package.Count -ne 1) { throw 'Cannot identify stable Android command-line tools.' }
    $archive = @($package[0].archives.archive | Where-Object { $_.'host-os' -eq 'windows' })
    if ($archive.Count -ne 1) { throw 'Cannot identify Windows SDK archive.' }
    $filename = [string]$archive[0].complete.url
    if ($filename -notmatch '^commandlinetools-win-[0-9]+_latest\.zip$') { throw 'Unexpected SDK archive name.' }
    $zip = Join-Path $cache $filename
    Invoke-WebRequest ("https://dl.google.com/android/repository/" + $filename) -OutFile $zip
    if ((Get-FileHash $zip -Algorithm SHA1).Hash -ne [string]$archive[0].complete.checksum) {
        throw 'SDK archive checksum does not match official repository metadata.'
    }
    $staging = Join-Path $cache ([guid]::NewGuid().ToString())
    Expand-Archive -LiteralPath $zip -DestinationPath $staging
    New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
    $source = [IO.Path]::GetFullPath((Join-Path $staging 'cmdline-tools'))
    $target = [IO.Path]::GetFullPath($destination)
    if (-not $source.StartsWith([IO.Path]::GetFullPath($cache) + [IO.Path]::DirectorySeparatorChar) -or
        -not $target.StartsWith([IO.Path]::GetFullPath($SdkPath).TrimEnd('\') + [IO.Path]::DirectorySeparatorChar)) {
        throw 'SDK staging paths escaped their expected roots.'
    }
    Move-Item -LiteralPath $source -Destination $target
}
if ($AcceptLicenses) {
    1..100 | ForEach-Object { 'y' } | & $manager "--sdk_root=$SdkPath" --licenses
    if ($LASTEXITCODE -ne 0) { throw "SDK license acceptance failed ($LASTEXITCODE)." }
}
& $manager "--sdk_root=$SdkPath" 'platform-tools' 'build-tools;35.0.1' 'platforms;android-35'
if ($LASTEXITCODE -ne 0) { throw "SDK installation failed ($LASTEXITCODE)." }
foreach ($file in @('platform-tools/adb.exe', 'build-tools/35.0.1/apksigner.bat', 'build-tools/35.0.1/zipalign.exe', 'platforms/android-35/android.jar')) {
    if (-not (Test-Path (Join-Path $SdkPath $file))) { throw "SDK installation incomplete: $file missing." }
}
Write-Host "Android SDK ready: $SdkPath"
