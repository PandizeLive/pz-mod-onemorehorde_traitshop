[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Info', 'Check', 'Install', 'Mirror', 'Publish', 'Preview')]
    [string]$Action = 'Menu',
    [switch]$ValidateOnly,
    [string]$UserDataRoot = (Join-Path $env:USERPROFILE 'Zomboid')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
$repository = Split-Path -Parent $PSScriptRoot
$shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Invoke-OmhAction {
    param([string]$SelectedAction, [bool]$CheckOnly)
    $arguments = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File')
    switch ($SelectedAction) {
        'Check' { $arguments += @((Join-Path $PSScriptRoot 'Install-OMH.ps1'), '-ValidateOnly', '-UserDataRoot', $UserDataRoot) }
        'Install' {
            $arguments += @((Join-Path $PSScriptRoot 'Install-OMH.ps1'), '-UserDataRoot', $UserDataRoot)
            if ($CheckOnly) { $arguments += '-ValidateOnly' }
        }
        'Mirror' {
            $arguments += (Join-Path $PSScriptRoot 'Mirror-OMH.ps1')
            if ($CheckOnly) { $arguments += '-ValidateOnly' }
        }
        'Publish' {
            $arguments += (Join-Path $PSScriptRoot 'Publish-OMHWorkshop.ps1')
            if ($CheckOnly) { $arguments += '-PreflightOnly' }
        }
        'Preview' {
            $arguments += @((Join-Path $PSScriptRoot 'Publish-OMHWorkshop.ps1'), '-UpdatePreview')
            if ($CheckOnly) { $arguments += '-PreflightOnly' }
        }
        default { throw "Unknown action: $SelectedAction" }
    }
    & $shell @arguments | Out-Host
    return $LASTEXITCODE
}

try {
    if ($Action -eq 'Info') {
        Get-OmhRelease $repository | ConvertTo-Json
        exit 0
    }
    if ($Action -ne 'Menu') { exit (Invoke-OmhAction $Action ([bool]$ValidateOnly)) }
    if ($ValidateOnly) { throw 'Specify an action with -ValidateOnly.' }
    while ($true) {
        $release = Get-OmhRelease $repository
        Write-Host "`nOMH: TRAIT SHOP - v$($release.Version)" -ForegroundColor Cyan
        Write-Host "Branch: $($release.Branch) | Workshop item: $(Get-OmhWorkshopId $repository) (0 = not created)"
        Write-Host '  1  Install locally (backup and verify local mods + Workshop staging)'
        Write-Host '  2  Mirror to GitHub (branch, immutable release tag, draft PR)'
        Write-Host '  3  Publish to Steam Workshop (first item is private)'
        Write-Host '  4  Check local install readiness (no changes)'
        Write-Host '  5  Check Workshop upload manifest (no network or upload)'
        Write-Host '  6  Update Workshop page preview to GIF (preview only)'
        Write-Host '  0  Exit'
        $choice = (Read-Host 'Choose an option').Trim()
        if ($choice -eq '0') { exit 0 }
        $selected = switch ($choice) {
            '1' { 'Install' }
            '2' { 'Mirror' }
            '3' { 'Publish' }
            '4' { 'Check' }
            '5' { 'Publish' }
            '6' { 'Preview' }
            default { $null }
        }
        if (-not $selected) { Write-Host 'Enter a number from 0 to 6.'; continue }
        $result = Invoke-OmhAction $selected ($choice -eq '5')
        if ($result -eq 0) { Write-Host 'Action finished.' -ForegroundColor Green }
        else { Write-Host "Action stopped (exit code $result)." -ForegroundColor Yellow }
        $null = Read-Host 'Press Enter to return to the menu'
    }
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
