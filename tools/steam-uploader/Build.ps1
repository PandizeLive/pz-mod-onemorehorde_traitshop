[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$WorkspaceRoot, [string]$CargoExecutable = 'cargo')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($WorkspaceRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Workspace does not exist.' }
$build = Join-Path $root ('.tools/steam-uploader-build-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $build 'source'
New-Item -ItemType Directory -Path $build -Force | Out-Null
& git clone --branch v0.3.0 --single-branch https://github.com/SimKDT/Steam-Uploader-rs.git $source
if ($LASTEXITCODE -ne 0) { throw 'Clone failed.' }
$head = & git -C $source rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $head -ne '73c6db2702114cafe3ab67e2843c2a1ba16feacb') { throw 'Unexpected upstream revision.' }
& git -C $source apply (Join-Path $PSScriptRoot 'compatibility.patch')
if ($LASTEXITCODE -ne 0) { throw 'Patch failed.' }
& $CargoExecutable build --locked --release --manifest-path (Join-Path $source 'Cargo.toml')
if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
$metadata = & $CargoExecutable metadata --locked --format-version 1 --manifest-path (Join-Path $source 'Cargo.toml') | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Dependency discovery failed.' }
$sdk = @($metadata.packages | Where-Object { $_.name -eq 'steamworks-sys' -and $_.version -eq '0.13.0' })
if ($sdk.Count -ne 1) { throw 'Unexpected Steamworks SDK dependency.' }
$dll = Join-Path (Split-Path -Parent $sdk[0].manifest_path) 'lib/steam/redistributable_bin/win64/steam_api64.dll'
$destination = Join-Path $root '.tools/steam-uploader'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $destination 'steam_api64.dll')
Copy-Item -LiteralPath (Join-Path $source 'target/release/SteamUploader.exe') -Destination (Join-Path $destination 'SteamUploader.exe')
$protocol = & (Join-Path $destination 'SteamUploader.exe') --omh-protocol-version
if ($LASTEXITCODE -ne 0 -or $protocol -ne 'OMH_STEAM_UPLOADER_PROTOCOL=1') { throw 'Built executable failed the protocol check.' }
Write-Host "Built $destination. Run tools/Test-SteamUploader.ps1 before publishing. No Steam upload performed."
