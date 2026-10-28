function Get-ReleaseMenuEntries {
    return @(
        @{ Key = '1'; Label = 'Install locally (backup and verify local mods + Workshop staging)'; Action = 'Install'; CheckOnly = $false },
        @{ Key = '2'; Label = 'Mirror to GitHub (branch, release tag and draft PR)'; Action = 'Mirror'; CheckOnly = $false },
        @{ Key = '3'; Label = 'Publish mod to Steam Workshop'; Action = 'Publish'; CheckOnly = $false },
        @{ Key = '4'; Label = 'Check local install readiness (no changes)'; Action = 'Check'; CheckOnly = $true },
        @{ Key = '5'; Label = 'Check Workshop upload readiness (no upload)'; Action = 'Publish'; CheckOnly = $true }
    )
}

function Invoke-ReleaseMenuSelection {
    param([hashtable]$Entry, [scriptblock]$RunAction)
    try {
        $result = & $RunAction $Entry.Action ([bool]$Entry.CheckOnly)
        if ($result -eq 0) { Write-Host 'Action finished.' -ForegroundColor Green }
        else { Write-Host "Action stopped (exit code $result). Review the message above." -ForegroundColor Yellow }
    } catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    $null = Read-Host 'Press Enter to return to the menu'
}

function Show-ReleaseMenu {
    param([scriptblock]$GetInfo, [scriptblock]$RunAction, [array]$Extras = @())
    while ($true) {
        $info = & $GetInfo
        Write-Host "`n$($info.Title) - v$($info.Version)" -ForegroundColor Cyan
        Write-Host "Branch: $($info.Branch) | Workshop item: $($info.WorkshopId)"
        if ($info.Notice) { Write-Host $info.Notice -ForegroundColor Yellow }
        $entries = @(Get-ReleaseMenuEntries)
        foreach ($entry in $entries) { Write-Host "  $($entry.Key)  $($entry.Label)" }
        if ($Extras.Count) { Write-Host '  6  Project-specific tools' }
        Write-Host '  0  Exit'
        $choice = (Read-Host 'Choose an option').Trim()
        if ($choice -eq '0') { return }
        if ($choice -eq '6' -and $Extras.Count) {
            Write-Host "`n$($info.Title) - Project-specific tools" -ForegroundColor Cyan
            for ($i = 0; $i -lt $Extras.Count; $i++) { Write-Host "  $($i + 1)  $($Extras[$i].Label)" }
            Write-Host '  0  Back'
            $extraChoice = (Read-Host 'Choose an option').Trim()
            if ($extraChoice -eq '0') { continue }
            $index = 0
            if ([int]::TryParse($extraChoice, [ref]$index) -and $index -ge 1 -and $index -le $Extras.Count) {
                Invoke-ReleaseMenuSelection $Extras[$index - 1] $RunAction
            } else { Write-Host 'Choose one of the listed options.' -ForegroundColor Yellow }
            continue
        }
        $selected = @($entries | Where-Object { $_.Key -eq $choice })
        if ($selected.Count -ne 1) { Write-Host 'Choose one of the listed options.' -ForegroundColor Yellow; continue }
        Invoke-ReleaseMenuSelection $selected[0] $RunAction
    }
}
