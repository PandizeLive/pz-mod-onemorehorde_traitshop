param([string]$PreviewFile = (Join-Path (Split-Path -Parent $PSScriptRoot) 'preview.gif'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'SteamUploader.ps1')
$fixtureParent = Join-Path (Split-Path -Parent $PSScriptRoot) 'diagnostics'
$fixture = Join-Path $fixtureParent ('uploader-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture 'Contents') -Force | Out-Null
$vdfPath = Join-Path $fixture 'upload.vdf'
$utf8 = [Text.UTF8Encoding]::new($false)
function Reject([scriptblock]$Action) {
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Expected rejection.' }
}
try {
    [IO.File]::WriteAllText((Join-Path $fixture 'Contents/file.txt'), 'fixture', $utf8)
    $text = @('"workshopitem"','{','    "appid" "108600"','    "publishedfileid" "9912345678"',
        ('    "contentfolder" "' + (Join-Path $fixture 'Contents') + '"'), '    "changenote" "[h1]Fixture[/h1]"','}') -join "`n"
    [IO.File]::WriteAllText($vdfPath, $text, $utf8)
    $parsed = ConvertFrom-SteamUploadVdf $text $PreviewFile
    foreach ($field in @('title','description','tags','visibility')) { if ($parsed.Manifest.Contains($field)) { throw "Metadata unexpectedly supplied: $field" } }
    Reject { ConvertFrom-SteamUploadVdf ($text.Replace('}', '    "tags" "Build 42"' + "`n}")) '' }
    Reject { ConvertFrom-SteamUploadVdf ($text.Replace('}', '    "description" "replacement"' + "`n}")) '' }
    Reject { ConvertFrom-SteamUploadVdf ($text.Replace('108600', '480')) '' }
    Reject { ConvertFrom-SteamUploadVdf ($text.Replace('}', '    "publishedfileid" "9987654321"' + "`n}")) '' }
    $steamBefore = @(Microsoft.PowerShell.Management\Get-Process -Name steam -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    $log = Join-Path $fixture 'dryrun.log'
    Invoke-SteamUploaderUpload $vdfPath $log $PreviewFile -DryRun
    $receipt = Get-Content ([IO.Path]::ChangeExtension($log, '.result.json')) -Raw | ConvertFrom-Json
    if ($receipt.status -ne 'preflight') { throw 'Dry run marked successful.' }
    $manifest = Get-Content $receipt.manifest -Raw | ConvertFrom-Json
    foreach ($field in @('title','description','tags','visibility')) { if ($manifest.PSObject.Properties.Name -contains $field) { throw 'Dry-run manifest changes metadata.' } }
    if ((Get-FileHash $manifest.preview).Hash -ne (Get-FileHash $PreviewFile).Hash) { throw 'Preview bytes changed.' }
    if (Get-ChildItem $fixture -Filter steam_appid.txt -Recurse) { throw 'Dry run created an app ID file.' }
    $steamAfter = @(Microsoft.PowerShell.Management\Get-Process -Name steam -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    if (($steamBefore -join ',') -ne ($steamAfter -join ',')) { throw 'Steam process changed during dry run.' }
    $exe = Get-SteamUploaderPath $fixture
    [IO.File]::WriteAllText($receipt.manifest, '{"appid":108600,"workshopid":9912345678,"preview":"missing.gif"}', $utf8)
    $invalid = Invoke-SteamUploaderProcess $exe @('upload','--manifest-path',$receipt.manifest,'--dry-run') $fixture
    if ($invalid.ExitCode -eq 0 -or $invalid.Output -match 'OMH_UPLOAD_CONFIRMED') { throw 'Real executable accepted a missing preview.' }
    $shell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $timed = Invoke-SteamUploaderProcess $shell @('-NoProfile','-Command','Start-Sleep -Seconds 5') $fixture 1
    if ($timed.ExitCode -ne 124) { throw 'Timeout not propagated.' }
    Reject { Invoke-SteamUploaderProcess (Join-Path $fixture 'missing.exe') @() $fixture }
    # Subsequent live calls are fully simulated. No Steam API is invoked.
    function Get-Process { param($Name, $ErrorAction); return [pscustomobject]@{Id=123} }
    $script:fakeCode = 0
    $script:fakeOutput = ''
    function Invoke-SteamUploaderProcess {
        param($Executable, $Arguments, $WorkingDirectory, $TimeoutSeconds)
        if ($Arguments[0] -eq '--omh-protocol-version') { return [pscustomobject]@{ExitCode=0;Output='OMH_STEAM_UPLOADER_PROTOCOL=1'} }
        return [pscustomobject]@{ExitCode=$script:fakeCode;Output=$script:fakeOutput}
    }
    $cases = @(
        @{Code=1;Output='OMH_UPLOAD_CONFIRMED:9912345678'},
        @{Code=0;Output='Success. Published File Id: 9912345678'},
        @{Code=0;Output='OMH_UPLOAD_CONFIRMED:9987654321'},
        @{Code=0;Output="OMH_UPLOAD_CONFIRMED:9912345678`nOMH_UPLOAD_CONFIRMED:9912345678"},
        @{Code=0;Output="OMH_UPLOAD_CONFIRMED:9912345678`nUpload failed: rejected"},
        @{Code=124;Output='Upload failed: timed out'},
        @{Code=101;Output='thread main panicked'},
        @{Code=0;Output='OMH_PREFLIGHT_OK'}
    )
    $i = 0
    foreach ($case in $cases) {
        $i++; $script:fakeCode = $case.Code; $script:fakeOutput = $case.Output
        $caseLog = Join-Path $fixture "failure-$i.log"
        Reject { Invoke-SteamUploaderUpload $vdfPath $caseLog $PreviewFile }
        $record = Get-Content ([IO.Path]::ChangeExtension($caseLog, '.result.json')) -Raw | ConvertFrom-Json
        if ($record.status -ne 'unconfirmed') { throw 'Failure marked successful.' }
    }
    $script:fakeCode = 0; $script:fakeOutput = 'OMH_UPLOAD_CONFIRMED:9912345678'
    $caseLog = Join-Path $fixture 'simulated-success.log'
    Invoke-SteamUploaderUpload $vdfPath $caseLog $PreviewFile
    $record = Get-Content ([IO.Path]::ChangeExtension($caseLog, '.result.json')) -Raw | ConvertFrom-Json
    if ($record.status -ne 'confirmed' -or $record.itemId -ne '9912345678') { throw 'Confirmation not recorded.' }
    if ([IO.File]::ReadAllText($vdfPath) -cne $text) { throw 'Input descriptor changed.' }
    Write-Host 'PASS: real offline GIF/PNG validation, unchanged Steam, metadata omission, process timeout/start failure, eight rejected outcomes, simulated exact-item confirmation. No Workshop upload.'
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    if ((Split-Path -Parent $resolved) -ne [IO.Path]::GetFullPath($fixtureParent) -or (Split-Path -Leaf $resolved) -notmatch '^uploader-test-[a-f0-9]{32}$') { throw 'Unexpected fixture path.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
