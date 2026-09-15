[CmdletBinding()]
param([switch]$ValidateOnly, [string]$UserDataRoot = (Join-Path $env:USERPROFILE 'Zomboid'))

$ErrorActionPreference = 'Stop'
$omhRepoRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
$omhRelease = Get-OmhRelease -RepositoryPath $omhRepoRoot
$omhVersion = $omhRelease.Version
$omhTag = $omhRelease.Tag
$omhPackages = @('OneMoreHorde_TraitShop')
$omhLocalRoot = [IO.Path]::GetFullPath((Join-Path $UserDataRoot 'mods'))
$omhStagingRoot = [IO.Path]::GetFullPath((Join-Path $UserDataRoot 'Workshop\OneMoreHorde_TraitShop\Contents\mods'))
$omhBackupRoot = [IO.Path]::GetFullPath((Join-Path $UserDataRoot ('OMH-TraitShop-local-backups\before-v' + $omhVersion + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-ffff'))))
$omhDestinations = @(
    @{ Root = $omhLocalRoot; BackupRoot = (Join-Path $omhBackupRoot 'local') },
    @{ Root = $omhStagingRoot; BackupRoot = (Join-Path $omhBackupRoot 'staging') }
)

function Get-OmhFileHash {
    param([string]$Path)
    $stream = [IO.File]::OpenRead($Path)
    $sha = $null
    try {
        $sha = [Security.Cryptography.SHA256]::Create()
        return [BitConverter]::ToString($sha.ComputeHash($stream))
    } finally {
        $stream.Dispose()
        if ($sha) { $sha.Dispose() }
    }
}

function Assert-OmhPackagePath {
    param([string]$Path, [string]$Root, [string]$Package)
    $resolved = [IO.Path]::GetFullPath($Path)
    $expected = [IO.Path]::GetFullPath((Join-Path $Root $Package))
    if ($Package -notin $omhPackages -or $resolved -ne $expected -or (Split-Path -Parent $resolved) -ne $Root) {
        throw "Unexpected package target: $resolved"
    }
    $candidate = $resolved
    while ($candidate) {
        if ((Test-Path -LiteralPath $candidate) -and
                ((Get-Item -LiteralPath $candidate).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Install target is a link: $candidate"
        }
        $candidate = Split-Path -Parent $candidate
    }
}

try {
    Assert-OmhTaggedContent $omhRelease
    $omhInstallTargets = @()
    foreach ($package in $omhPackages) {
        $source = Join-Path $omhRepoRoot "Contents\mods\$package"
        Assert-OmhPackagePath -Path $source -Root (Join-Path $omhRepoRoot 'Contents\mods') -Package $package
        if (Get-ChildItem -LiteralPath $source -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw "Source package contains a link: $package" }
        foreach ($destination in $omhDestinations) {
            $target = Join-Path $destination.Root $package
            $backup = Join-Path $destination.BackupRoot $package
            Assert-OmhPackagePath -Path $target -Root $destination.Root -Package $package
            Assert-OmhPackagePath -Path $backup -Root $destination.BackupRoot -Package $package
            $omhInstallTargets += @{
                Package = $package; Root = $destination.Root; Path = $target
                BackupRoot = $destination.BackupRoot; Backup = $backup
            }
        }
    }
    if ($ValidateOnly) {
        Write-Host "Local installer validation passed for $omhTag (local mods and local Workshop staging)."
        exit 0
    }
    if (Get-Process -Name ProjectZomboid64,ProjectZomboid32,java -ErrorAction SilentlyContinue |
            Where-Object { $_.ProcessName -like 'ProjectZomboid*' -or ($_.Path -and $_.Path -match 'ProjectZomboid[\\/].*java\.exe$') }) {
        throw 'Save and quit Project Zomboid before installing. No files were copied.'
    }
    New-Item -ItemType Directory -Path $omhBackupRoot | Out-Null
    foreach ($destination in $omhDestinations) {
        New-Item -ItemType Directory -Force -Path $destination.Root | Out-Null
        New-Item -ItemType Directory -Path $destination.BackupRoot | Out-Null
    }
    $omhStartedTargets = @()
    try {
        foreach ($installTarget in $omhInstallTargets) {
            $package = $installTarget.Package
            $target = $installTarget.Path
            $backup = $installTarget.Backup
            Assert-OmhPackagePath -Path $target -Root $installTarget.Root -Package $package
            Assert-OmhPackagePath -Path $backup -Root $installTarget.BackupRoot -Package $package
            if (Test-Path -LiteralPath $target) { Move-Item -LiteralPath $target -Destination $backup }
            $omhStartedTargets += $installTarget
            Copy-Item -LiteralPath (Join-Path $omhRepoRoot "Contents\mods\$package") -Destination $target -Recurse
            $sourceRoot = Join-Path $omhRepoRoot "Contents\mods\$package"
            foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -File -Recurse) {
                $relative = $file.FullName.Substring($sourceRoot.Length + 1)
                $copied = Join-Path $target $relative
                if ((Get-OmhFileHash -Path $file.FullName) -ne (Get-OmhFileHash -Path $copied)) {
                    throw "Copy verification failed: $relative"
                }
            }
        }
    } catch {
        foreach ($installTarget in $omhStartedTargets) {
            $package = $installTarget.Package
            $target = $installTarget.Path
            $backup = $installTarget.Backup
            Assert-OmhPackagePath -Path $target -Root $installTarget.Root -Package $package
            Assert-OmhPackagePath -Path $backup -Root $installTarget.BackupRoot -Package $package
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            if (Test-Path -LiteralPath $backup) { Move-Item -LiteralPath $backup -Destination $target }
        }
        throw
    }
    Write-Host "Installed OMH: Trait Shop v$omhVersion into local mods and local Workshop staging. File hashes match the tagged source."
    Write-Host "Previous packages: $omhBackupRoot"
    Write-Host 'Launch normally through Steam with your existing -debug option. Local staging takes priority over subscribed copies.'
    Write-Host 'Steam subscriptions and launch options were not changed. No Workshop upload or GitHub mirror was performed.'
    Write-Host 'At the main menu, ask Codex to verify the loaded version before gameplay testing.'
    Write-Host 'Use OMH.cmd for mirroring and publication after testing.'
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
