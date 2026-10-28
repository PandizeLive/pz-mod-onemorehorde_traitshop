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

function ConvertTo-SteamArgument {
    param([string]$Value)

    if ($Value.Contains("`r") -or $Value.Contains("`n")) {
        Stop-Publisher 'Steam credentials may not contain line breaks.'
    }

    return '"' + $Value.Replace('"', '\"') + '"'
}

function ConvertFrom-SecureValue {
    param([Security.SecureString]$SecureValue)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Read-GuardCode {
    $secureCode = Read-Host 'Steam Guard code (input hidden)' -AsSecureString
    $code = ConvertFrom-SecureValue $secureCode
    if ([string]::IsNullOrWhiteSpace($code)) {
        Stop-Publisher 'A Steam Guard code is required for this publishing workflow.'
    }
    if ($code -notmatch '^[A-Za-z0-9]{5,10}$') {
        Stop-Publisher 'The Steam Guard code must contain 5-10 letters or numbers.'
    }

    return $code
}

function Get-PublisherCredential {
    if ($ResetCredentials -and (Test-Path -LiteralPath $credentialPath)) {
        Remove-Item -LiteralPath $credentialPath -Force
    }

    if (Test-Path -LiteralPath $credentialPath -PathType Leaf) {
        try {
            return Import-Clixml -LiteralPath $credentialPath
        } catch {
            Stop-Publisher "The saved Steam credential could not be decrypted. Rerun with -ResetCredentials. $($_.Exception.Message)"
        }
    }

    Write-Host 'First-time SteamCMD publisher setup.' -ForegroundColor Cyan
    Write-Host 'The password will be encrypted with Windows DPAPI for this Windows account.'
    $username = (Read-Host 'Steam username').Trim()
    if ([string]::IsNullOrWhiteSpace($username)) {
        Stop-Publisher 'Steam username cannot be blank.'
    }
    $password = Read-Host 'Steam password (input hidden)' -AsSecureString
    if ($password.Length -eq 0) {
        Stop-Publisher 'Steam password cannot be blank.'
    }
    $credential = [Management.Automation.PSCredential]::new($username, $password)
    New-Item -ItemType Directory -Path $publisherRoot -Force | Out-Null
    $credential | Export-Clixml -LiteralPath $credentialPath -Force
    return $credential
}

function Get-SteamPath {
    $candidates = @()
    try {
        $steamRegistry = Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction Stop
        if ($steamRegistry.SteamExe) {
            $candidates += $steamRegistry.SteamExe.Replace('/', '\')
        }
    } catch {
    }
    $candidates += 'C:\Program Files (x86)\Steam\steam.exe'
    $candidates += 'C:\Program Files\Steam\steam.exe'

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    Stop-Publisher 'Steam.exe could not be located.'
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

function Stop-SteamClient {
    param([string]$SteamPath)

    if (-not (Get-Process -Name 'steam' -ErrorAction SilentlyContinue)) {
        return $false
    }

    Write-Host 'Closing Steam cleanly...' -ForegroundColor Cyan
    Start-Process -FilePath $SteamPath -ArgumentList '-shutdown' -WindowStyle Hidden | Out-Null
    $deadline = [DateTime]::UtcNow.AddSeconds(45)
    while ((Get-Process -Name 'steam' -ErrorAction SilentlyContinue) -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    if (Get-Process -Name 'steam' -ErrorAction SilentlyContinue) {
        Stop-Publisher 'Steam did not close within 45 seconds. Close it manually and rerun the publisher.'
    }

    return $true
}

function Invoke-SteamCmdUpload {
    param(
        [Management.Automation.PSCredential]$Credential,
        [string]$GuardCode,
        [string]$LogPath
    )

    $plainPassword = ConvertFrom-SecureValue $Credential.Password
    try {
        if ([string]::IsNullOrEmpty($plainPassword)) {
            Stop-Publisher 'The stored Steam password is blank. Rerun with -ResetCredentials.'
        }
        $startInfo = [Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $steamCmdPath
        $startInfo.WorkingDirectory = Split-Path -Parent $steamCmdPath
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.Arguments = @(
            '+login',
            (ConvertTo-SteamArgument $Credential.UserName),
            (ConvertTo-SteamArgument $plainPassword),
            (ConvertTo-SteamArgument $GuardCode),
            '+workshop_build_item',
            (ConvertTo-SteamArgument $vdfPath),
            '+quit'
        ) -join ' '

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        if (-not $process.Start()) {
            Stop-Publisher 'SteamCMD did not start.'
        }
        $startInfo.Arguments = ''

        Write-Host 'Uploading Workshop content...' -ForegroundColor Cyan
        $outputLines = [Collections.Generic.List[string]]::new()
        $stdoutComplete = $false
        $stderrComplete = $false
        $stdoutTask = $process.StandardOutput.ReadLineAsync()
        $stderrTask = $process.StandardError.ReadLineAsync()
        $nextHeartbeat = [DateTime]::UtcNow.AddSeconds(15)

        while (-not ($stdoutComplete -and $stderrComplete)) {
            $receivedOutput = $false
            if (-not $stdoutComplete -and $stdoutTask.IsCompleted) {
                $line = $stdoutTask.GetAwaiter().GetResult()
                if ($null -eq $line) {
                    $stdoutComplete = $true
                } else {
                    $safeLine = $line.Replace($plainPassword, '[REDACTED]').Replace($GuardCode, '[REDACTED]')
                    $outputLines.Add($safeLine)
                    $safeLine | Write-Host
                    $stdoutTask = $process.StandardOutput.ReadLineAsync()
                    $receivedOutput = $true
                }
            }
            if (-not $stderrComplete -and $stderrTask.IsCompleted) {
                $line = $stderrTask.GetAwaiter().GetResult()
                if ($null -eq $line) {
                    $stderrComplete = $true
                } else {
                    $safeLine = $line.Replace($plainPassword, '[REDACTED]').Replace($GuardCode, '[REDACTED]')
                    $outputLines.Add($safeLine)
                    $safeLine | Write-Host
                    $stderrTask = $process.StandardError.ReadLineAsync()
                    $receivedOutput = $true
                }
            }
            if ($receivedOutput) {
                $nextHeartbeat = [DateTime]::UtcNow.AddSeconds(15)
            } elseif (-not $process.HasExited -and [DateTime]::UtcNow -ge $nextHeartbeat) {
                Write-Host 'SteamCMD is still working...' -ForegroundColor DarkGray
                $nextHeartbeat = [DateTime]::UtcNow.AddSeconds(15)
            }
            if (-not ($stdoutComplete -and $stderrComplete)) {
                Start-Sleep -Milliseconds 50
            }
        }

        $process.WaitForExit()
        $safeOutput = [string]::Join([Environment]::NewLine, $outputLines)
        $safeOutput | Set-Content -LiteralPath $LogPath -Encoding UTF8

        if ($process.ExitCode -ne 0) {
            Stop-Publisher "SteamCMD failed with exit code $($process.ExitCode). See $LogPath"
        }
        if ($safeOutput -match '(?i)ERROR!|Login Failure|FAILED \(') {
            Stop-Publisher "SteamCMD reported a failure. See $LogPath"
        }
        $publishedFileSuccess = $safeOutput -match '(?i)Success\.\s+Published File Id'
        $committedUpdateSuccess = $safeOutput -match '(?i)Committing update\.\.\.\s*Success\.'
        if (-not ($publishedFileSuccess -or $committedUpdateSuccess)) {
            Stop-Publisher "SteamCMD did not confirm a successful Workshop publication. See $LogPath"
        }
    } finally {
        $plainPassword = $null
        [GC]::Collect()
    }
}
