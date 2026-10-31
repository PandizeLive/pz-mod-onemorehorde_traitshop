. (Join-Path $PSScriptRoot 'SteamUploader.ps1')

function Stop-Publisher {
    param([string]$Message)

    throw $Message
}

function ConvertTo-VdfValue {
    param([string]$Value)

    if ($Value -match '[\x00-\x1f\x7f"]') {
        Stop-Publisher 'VDF scalar values may not contain control characters or double quotes.'
    }

    # SteamCMD reads this KeyValues file without backslash escape processing.
    return $Value
}

function Get-WorkshopChangeNote {
    param([string]$Version)

    $source = (Get-Content -Raw -LiteralPath $changeLogPath -Encoding UTF8).Trim()
    if ([string]::IsNullOrWhiteSpace($source)) {
        Stop-Publisher 'WORKSHOP_CHANGELOG.txt is blank.'
    }
    if ($source.Contains('\n')) {
        Stop-Publisher 'WORKSHOP_CHANGELOG.txt contains a literal \n sequence. Use real line breaks.'
    }

    $lines = @($source -split "`r?`n")
    $nonBlankLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $versionHeaders = @($nonBlankLines | Where-Object { $_.Trim() -match '^v\d+(?:\.\d+){2,4}$' })
    if ($versionHeaders.Count -ne 1) {
        Stop-Publisher "WORKSHOP_CHANGELOG.txt must contain exactly one version heading; found $($versionHeaders.Count)."
    }
    if ($nonBlankLines[0].Trim() -ne "v$Version") {
        Stop-Publisher "WORKSHOP_CHANGELOG.txt starts with '$($nonBlankLines[0].Trim())'; expected 'v$Version'."
    }

    $steamParts = [Collections.Generic.List[string]]::new()
    $steamParts.Add("[h1]v$Version[/h1]")
    $listOpen = $false
    $sectionSeen = $false
    $sectionCount = 0
    $bulletCount = 0

    for ($index = 1; $index -lt $lines.Count; $index++) {
        $line = $lines[$index].Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            if ($listOpen) {
                $steamParts.Add('[/list]')
                $listOpen = $false
            }
            continue
        }

        if ($line.StartsWith('- ')) {
            if (-not $sectionSeen) {
                Stop-Publisher "WORKSHOP_CHANGELOG.txt has a bullet before its first category: '$line'."
            }
            $bullet = $line.Substring(2).Trim()
            if ([string]::IsNullOrWhiteSpace($bullet)) {
                Stop-Publisher 'WORKSHOP_CHANGELOG.txt contains an empty bullet.'
            }
            if (-not $listOpen) {
                $steamParts.Add('[list]')
                $listOpen = $true
            }
            $steamParts.Add("[*]$bullet")
            $bulletCount++
            continue
        }

        if ($listOpen) {
            $steamParts.Add('[/list]')
            $listOpen = $false
        }
        if ($line -match '^v\d+(?:\.\d+){2,4}$') {
            Stop-Publisher "WORKSHOP_CHANGELOG.txt contains an additional version heading: '$line'."
        }
        $steamParts.Add("[h2]$line[/h2]")
        $sectionSeen = $true
        $sectionCount++
    }

    if ($listOpen) {
        $steamParts.Add('[/list]')
    }
    if ($sectionCount -eq 0 -or $bulletCount -eq 0) {
        Stop-Publisher 'WORKSHOP_CHANGELOG.txt must contain at least one category and one bullet.'
    }

    $steamChangeNote = [string]::Join('', $steamParts).Replace('"', "'")
    if ($steamChangeNote.Contains("`r") -or $steamChangeNote.Contains("`n") -or $steamChangeNote.Contains('\n')) {
        Stop-Publisher 'Internal safety check failed: the generated Steam change note contains newline escapes.'
    }

    return [PSCustomObject]@{
        Source = $source
        Steam = $steamChangeNote
    }
}

function Assert-ProjectZomboidClosed {
    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match '^ProjectZomboid' -or
            ($_.ProcessName -eq 'java' -and $_.Path -and $_.Path -match 'ProjectZomboid[\\/].*java\.exe$')
    })
    if ($running.Count -gt 0) {
        Stop-Publisher 'Project Zomboid is running. Save and exit the game normally, then run the publisher again.'
    }
}
