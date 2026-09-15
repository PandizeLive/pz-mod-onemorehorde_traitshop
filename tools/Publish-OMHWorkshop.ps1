[CmdletBinding()]
param([switch]$PreflightOnly, [switch]$ResetCredentials)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
. (Join-Path $PSScriptRoot 'OMH-SteamHelpers.ps1')
$repoRoot = Split-Path -Parent $PSScriptRoot
$contentFolder = Join-Path $repoRoot 'Contents'
$changeLogPath = Join-Path $repoRoot 'WORKSHOP_CHANGELOG.txt'
$workshopMetadataPath = Join-Path $repoRoot 'workshop.txt'
$publisherRoot = Join-Path $env:LOCALAPPDATA 'OMH\TraitShopPublisher'
$credentialPath = Join-Path $publisherRoot 'steam-credential.xml'
$logFolder = Join-Path $publisherRoot 'Logs'
$vdfPath = Join-Path $publisherRoot 'traitshop-upload.vdf'
$pendingPath = Join-Path $publisherRoot 'creation-pending.json'
$steamCmdPath = Find-OmhSharedPath $repoRoot '.tools\steamcmd\steamcmd.exe'
$workshopAppId = '108600'

function New-WorkshopVdf {
    param([string]$ContentFolder, [string]$ChangeNote, [string]$ItemId, [string]$Description)
    if ($ItemId -eq '3777891317' -or $ItemId -notmatch '^\d+$') { throw 'Invalid Trait Shop Workshop target.' }
    $fields = [ordered]@{
        appid = $workshopAppId
        publishedfileid = $ItemId
        contentfolder = $ContentFolder
        changenote = $ChangeNote
    }
    if ($ItemId -eq '0') {
        $fields.title = 'OMH: Trait Shop'
        $fields.description = $Description
        $fields.visibility = '2'
    }
    $lines = @('"workshopitem"', '{')
    foreach ($key in $fields.Keys) { $lines += '    "' + $key + '" "' + (ConvertTo-VdfValue $fields[$key]) + '"' }
    $lines += '}'
    return $lines -join "`r`n"
}

function Save-CreatedWorkshopId {
    param([string]$ManifestPath)
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw
    $ids = [regex]::Matches($manifest, '"publishedfileid"\s+"([1-9]\d{5,19})"')
    if ($ids.Count -ne 1 -or $ids[0].Groups[1].Value -eq '3777891317') { throw 'Steam did not return a valid new Trait Shop ID; preserve the pending marker and inspect the upload log.' }
    $id = $ids[0].Groups[1].Value
    $metadata = Get-Content -LiteralPath $workshopMetadataPath -Raw
    if ([regex]::Matches($metadata, '(?m)^id=0\r?$').Count -ne 1) { throw 'Workshop metadata changed during creation. Do not retry creation.' }
    [IO.File]::WriteAllText($workshopMetadataPath, ([regex]::Replace($metadata, '(?m)^id=0\r?$', "id=$id")), [Text.UTF8Encoding]::new($false))
    Write-Host "Created private Workshop item $id. Recorded it in workshop.txt; commit this identity before the next mirror/upload."
    return $id
}

try {
    $release = Get-OmhRelease $repoRoot
    Assert-OmhTaggedContent $release
    $config = Get-OmhRemoteConfig $release
    $workshopId = Get-OmhWorkshopId $repoRoot
    $changeLog = Get-WorkshopChangeNote $release.Version
    $description = ((Get-Content -LiteralPath $workshopMetadataPath -Encoding UTF8 |
        Where-Object { $_.StartsWith('description=') } | ForEach-Object { $_.Substring(12) }) -join ' ').Trim()
    if ($workshopId -eq '0' -and -not $description.Contains('DISCLAIMER: This mod was made in tandem with ChatGPT')) {
        throw 'The first Workshop description must include the required disclaimer.'
    }
    $manifest = New-WorkshopVdf $contentFolder $changeLog.Steam $workshopId $description
    Write-Host "OMH: TRAIT SHOP publisher - v$($release.Version) - Workshop ID $workshopId"
    Write-Host $changeLog.Source
    Write-Host $manifest
    if ($PreflightOnly) {
        Write-Host 'Manifest preflight passed. No network calls, credentials, files, or external processes changed.'
        Write-Host 'Actual publication additionally requires committed release tooling and a verified GitHub mirror.'
        exit 0
    }
    if ($workshopId -eq '0' -and (Test-Path -LiteralPath $pendingPath)) {
        if ((Test-Path -LiteralPath $vdfPath) -and (Get-Content -LiteralPath $vdfPath -Raw) -match '"publishedfileid"\s+"[1-9]\d{5,19}"') {
            $null = Save-CreatedWorkshopId $vdfPath
        }
        throw "An earlier creation attempt needs review. Do not create another item. Inspect $pendingPath and the preserved VDF/logs, then commit the recovered workshop.txt ID."
    }
    if (-not $steamCmdPath) { throw 'SteamCMD not found. Install it under the shared .tools/steamcmd folder.' }
    $criticalPaths = @('Contents', 'tools', 'OMH.cmd', 'workshop.txt', 'WORKSHOP_CHANGELOG.txt')
    if (Invoke-OmhReleaseGit $release (@('status', '--porcelain', '--untracked-files=all', '--') + $criticalPaths)) {
        throw 'Commit release content, identity, changelog and tooling before publishing.'
    }
    Assert-OmhOrigin $release $config
    $ghPath = Find-OmhSharedPath $repoRoot '.tools\gh.exe'
    if (-not $ghPath) { $ghPath = (Get-Command gh.exe -ErrorAction Stop).Source }
    $ghConfig = Find-OmhSharedPath $repoRoot '.gh-codex'
    if ($ghConfig) { $env:GH_CONFIG_DIR = $ghConfig }
    $gitAuth = @('-c', 'credential.helper=', '-c', ('credential.helper=!"' + $ghPath.Replace('\', '/') + '" auth git-credential'))
    Assert-OmhRemoteMirror $release $config $gitAuth
    Assert-ProjectZomboidClosed
    $confirmationWord = if ($workshopId -eq '0') { 'CREATE' } else { 'PUBLISH' }
    $label = if ($workshopId -eq '0') { 'create a NEW PRIVATE Trait Shop Workshop item' } else { "update Trait Shop item $workshopId (preserving description, cover and visibility)" }
    if ((Read-Host "Type $confirmationWord to $label").Trim() -cne $confirmationWord) { throw 'Publication cancelled.' }
    New-Item -ItemType Directory -Path $publisherRoot, $logFolder -Force | Out-Null
    [IO.File]::WriteAllText($vdfPath, $manifest, [Text.UTF8Encoding]::new($false))
    $credential = Get-PublisherCredential
    $steamPath = Get-SteamPath
    $guardCode = Read-GuardCode
    $steamWasRunning = Stop-SteamClient $steamPath
    try {
        Assert-OmhTaggedContent $release
        if ($workshopId -eq '0') {
            [IO.File]::WriteAllText($pendingPath, (@{ repository = $repoRoot; version = $release.Version; manifest = $vdfPath; startedUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
        }
        $logPath = Join-Path $logFolder ("traitshop-v$($release.Version)-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Invoke-SteamCmdUpload $credential $guardCode $logPath
        if ($workshopId -eq '0') {
            $workshopId = Save-CreatedWorkshopId $vdfPath
            Remove-Item -LiteralPath $pendingPath -ErrorAction Stop
        }
        Write-Host "Upload confirmed: https://steamcommunity.com/sharedfiles/filedetails/?id=$workshopId"
        Write-Host "Log: $logPath"
    } finally {
        if ($steamWasRunning) { Start-Process -FilePath $steamPath -WindowStyle Hidden | Out-Null }
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
