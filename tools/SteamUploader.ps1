$script:OmhUploaderToolsRoot = $PSScriptRoot
function Get-SteamUploaderPath {
    param([string]$Root)
    if ($env:OMH_STEAM_UPLOADER) {
        if (-not (Test-Path -LiteralPath $env:OMH_STEAM_UPLOADER -PathType Leaf)) { throw 'OMH_STEAM_UPLOADER does not name an executable.' }
        return [IO.Path]::GetFullPath($env:OMH_STEAM_UPLOADER)
    }
    foreach ($searchRoot in @($Root, $script:OmhUploaderToolsRoot)) {
        $folder = [IO.Path]::GetFullPath($searchRoot)
        while ($folder) {
            $candidate = Join-Path $folder '.tools\steam-uploader\SteamUploader.exe'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
            $folder = Split-Path -Parent $folder
        }
    }
    throw 'The compatible SteamUploader build is missing. See tools/steam-uploader/README.md.'
}

function ConvertFrom-SteamUploadVdf {
    param([string]$Text, [string]$PreviewFile)
    $lines = @($Text.Trim() -split '\r?\n')
    if ($lines.Count -lt 5 -or $lines[0] -ne '"workshopitem"' -or $lines[1] -ne '{' -or $lines[-1] -ne '}') { throw 'Invalid upload descriptor.' }
    $fields = @{}
    foreach ($line in $lines[2..($lines.Count - 2)]) {
        $match = [regex]::Match($line, '^\s*"([a-z]+)"\s+"([^"\x00-\x1f\x7f]*)"\s*$')
        if (-not $match.Success -or $fields.ContainsKey($match.Groups[1].Value)) { throw 'Invalid or duplicate upload field.' }
        $fields[$match.Groups[1].Value] = $match.Groups[2].Value
    }
    if ($fields.appid -ne '108600' -or $fields.publishedfileid -notmatch '^(0|[1-9]\d{5,19})$') { throw 'Invalid Project Zomboid Workshop target.' }
    $manifest = [ordered]@{ appid = 108600 }
    if ($fields.publishedfileid -ne '0') { $manifest.workshopid = [uint64]$fields.publishedfileid }
    $map = @{contentfolder='content'; previewfile='preview'; title='title'; description='description'; visibility='visibility'}
    foreach ($key in $fields.Keys) {
        if ($map.ContainsKey($key)) {
            $value = $fields[$key]
            if ($key -eq 'visibility') {
                if ($value -notmatch '^[0-3]$') { throw 'Invalid visibility.' }
                $value = [int]$value
            }
            $manifest[$map[$key]] = $value
        } elseif ($key -notin @('appid','publishedfileid','changenote')) { throw "Unsupported upload field: $key" }
    }
    if ($PreviewFile) { $manifest.preview = [IO.Path]::GetFullPath($PreviewFile) }
    if ($fields.publishedfileid -ne '0' -and ($manifest.Contains('description') -or $manifest.Contains('title'))) { throw 'Existing-item uploads must preserve the Workshop title and description.' }
    return [pscustomobject]@{ Manifest = $manifest; Note = $fields.changenote; ItemId = $fields.publishedfileid }
}

function Assert-SteamUploaderResult {
    param([int]$ExitCode, [string]$Output, [string]$ItemId, [switch]$DryRun)
    if ($ExitCode -ne 0) { throw "SteamUploader failed with exit code $ExitCode. The upload is not confirmed." }
    if ($DryRun) {
        if ($Output -notmatch '(?m)^OMH_PREFLIGHT_OK\r?$' -or $Output -match '(?m)^OMH_UPLOAD_CONFIRMED:') { throw 'SteamUploader did not confirm a dry run.' }
        return
    }
    $matches = [regex]::Matches($Output, '(?m)^OMH_UPLOAD_CONFIRMED:([1-9]\d{5,19})\r?$')
    if ($matches.Count -ne 1 -or $matches[0].Groups[1].Value -cne $ItemId) { throw 'Steam did not confirm the intended Workshop item. Inspect the log before retrying.' }
    if ($Output -match '(?im)^(Upload failed:|Error |Error:|thread .+panicked|.*timed out)') { throw 'Upload output contains a failure; inspect the log before retrying.' }
}

function Invoke-SteamUploaderProcess {
    param([string]$Executable, [string[]]$Arguments, [string]$WorkingDirectory, [int]$TimeoutSeconds = 1860)
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $quoted = foreach ($argument in $Arguments) {
        if ($argument -match '["\r\n]') { throw 'Unsupported command argument.' }
        '"' + $argument + '"'
    }
    $info.Arguments = $quoted -join ' '
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $info.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    $started = $false
    try {
        if (-not $process.Start()) { throw 'Could not start SteamUploader.' }
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $clock = [Diagnostics.Stopwatch]::StartNew()
        $nextNotice = 10
        while (-not $process.WaitForExit(100)) {
            if ($clock.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
                $process.Kill(); $process.WaitForExit()
                return [pscustomobject]@{ ExitCode = 124; Output = $stdout.Result + $stderr.Result + "`nUpload failed: uploader timed out. Inspect Steam before retrying." }
            }
            if ($clock.Elapsed.TotalSeconds -ge $nextNotice) { Write-Host 'Waiting for SteamUploader...'; $nextNotice += 10 }
        }
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $stdout.Result + $stderr.Result }
    } finally {
        if ($started -and -not $process.HasExited) { $process.Kill() }
        $process.Dispose()
    }
}

function Invoke-SteamUploaderUpload {
    param([string]$ManifestPath, [string]$LogPath, [string]$PreviewFile = '', [switch]$DryRun,
        [ValidateSet('Content','Preview','Leaderboard')][string]$UploadKind = 'Content', [string]$ReleaseVersion = '')
    $parsed = ConvertFrom-SteamUploadVdf ([IO.File]::ReadAllText($ManifestPath)) $PreviewFile
    $executable = Get-SteamUploaderPath (Split-Path -Parent $ManifestPath)
    $runFolder = Join-Path (Split-Path -Parent $LogPath) ('uploader-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $runFolder -Force | Out-Null
    $jsonPath = Join-Path $runFolder 'mod-manifest.json'
    $notePath = Join-Path $runFolder 'change-note.bbcode'
    $receiptPath = [IO.Path]::ChangeExtension($LogPath, '.result.json')
    $record = [ordered]@{status='pending'; itemId=$parsed.ItemId; startedUtc=[DateTime]::UtcNow.ToString('o'); manifest=$jsonPath; log=$LogPath; dryRun=[bool]$DryRun}
    $record.uploadKind = $UploadKind
    $record.releaseVersion = $ReleaseVersion
    $record.executableSha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash
    try {
        $probe = Invoke-SteamUploaderProcess $executable @('--omh-protocol-version') $runFolder 15
        if ($probe.ExitCode -ne 0 -or $probe.Output.Trim() -cne 'OMH_STEAM_UPLOADER_PROTOCOL=1') { throw 'This SteamUploader build lacks the required metadata and confirmation safeguards.' }
        if (-not $DryRun -and -not (Get-Process -Name steam -ErrorAction SilentlyContinue)) { throw 'Open Steam and sign in to the Workshop owner account, then retry. Steam will stay running.' }
        if ($parsed.Manifest.Contains('preview')) {
            $preview = $parsed.Manifest.preview
            $bytes = [IO.File]::ReadAllBytes($preview)
            if ($bytes.Length -eq 0 -or $bytes.Length -ge 1MB) { throw 'Workshop preview must be smaller than 1 MiB.' }
            $extension = [IO.Path]::GetExtension($preview)
            $copy = Join-Path $runFolder ('preview' + $extension)
            [IO.File]::WriteAllBytes($copy, $bytes)
            $parsed.Manifest.preview = $copy
            $record.previewSha256 = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        }
        [IO.File]::WriteAllText($jsonPath, ($parsed.Manifest | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
        $record.manifestSha256 = (Get-FileHash -LiteralPath $jsonPath -Algorithm SHA256).Hash
        $arguments = @('upload', '--manifest-path', $jsonPath)
        if ($null -ne $parsed.Note) {
            [IO.File]::WriteAllText($notePath, $parsed.Note, [Text.UTF8Encoding]::new($false))
            $record.changeNoteSha256 = (Get-FileHash -LiteralPath $notePath -Algorithm SHA256).Hash
            $arguments += @('--patchnote', $notePath)
        }
        if ($DryRun) { $arguments += '--dry-run' }
        [IO.File]::WriteAllText($receiptPath, ($record | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
        Write-Host $(if ($DryRun) { 'Checking upload without contacting Steam...' } else { 'Uploading through the running Steam client...' })
        $result = Invoke-SteamUploaderProcess $executable $arguments $runFolder
        [IO.File]::WriteAllText($LogPath, $result.Output, [Text.UTF8Encoding]::new($false))
        $record.exitCode = $result.ExitCode
        if ($parsed.ItemId -eq '0' -and -not $DryRun) {
            $returned = [IO.File]::ReadAllText($jsonPath) | ConvertFrom-Json
            if ([string]$returned.workshopid -match '^[1-9]\d{5,19}$') {
                $parsed.ItemId = [string]$returned.workshopid
                $vdf = [IO.File]::ReadAllText($ManifestPath).Replace('"publishedfileid" "0"', ('"publishedfileid" "' + $parsed.ItemId + '"'))
                [IO.File]::WriteAllText($ManifestPath, $vdf, [Text.UTF8Encoding]::new($false))
                $record.itemId = $parsed.ItemId
            }
        }
        Assert-SteamUploaderResult $result.ExitCode $result.Output $parsed.ItemId -DryRun:$DryRun
        $record.status = if ($DryRun) { 'preflight' } else { 'confirmed' }
        $record.completedUtc = [DateTime]::UtcNow.ToString('o')
        Write-Host "Uploader evidence: $receiptPath"
    } catch {
        $record.status = 'unconfirmed'
        $record.error = $_.Exception.Message
        if (-not (Test-Path -LiteralPath $LogPath)) { [IO.File]::WriteAllText($LogPath, $record.error, [Text.UTF8Encoding]::new($false)) }
        throw
    } finally {
        [IO.File]::WriteAllText($receiptPath, ($record | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    }
}
