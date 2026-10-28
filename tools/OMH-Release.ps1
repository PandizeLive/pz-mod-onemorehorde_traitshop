[CmdletBinding()]
param(
    [ValidateSet('Menu', 'Info', 'Check', 'Install', 'Mirror', 'Publish', 'Preview')]
    [string]$Action = 'Menu',
    [switch]$ValidateOnly,
    [string]$UserDataRoot = (Join-Path $env:USERPROFILE 'Zomboid')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
. (Join-Path $PSScriptRoot 'ReleaseMenu.ps1')
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
    Show-ReleaseMenu -GetInfo {
        $release = Get-OmhRelease $repository
        @{ Title = 'OMH: TRAIT SHOP'; Version = $release.Version; Branch = $release.Branch; WorkshopId = (Get-OmhWorkshopId $repository) }
    } -RunAction {
        param($selected, $checkOnly)
        Invoke-OmhAction $selected $checkOnly
    } -Extras @(
        @{ Label = 'Update Workshop page preview to GIF (preview only)'; Action = 'Preview'; CheckOnly = $false },
        @{ Label = 'Check Workshop preview update (no upload)'; Action = 'Preview'; CheckOnly = $true }
    )
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
