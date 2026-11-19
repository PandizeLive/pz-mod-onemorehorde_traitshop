[CmdletBinding()]
param()

# Offline regression tests. All writable fixtures live under this repository's ignored .local.
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
$git = Get-OmhGitExecutable
$shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$testRoot = Join-Path $repository ('.local\release-tests\' + [guid]::NewGuid().ToString('N'))
$fixture = Join-Path $testRoot 'repository with spaces'
New-Item -ItemType Directory -Path $fixture -Force | Out-Null
$script:passed = 0

function Assert-Test {
    param([bool]$Condition, [string]$Label)
    if (-not $Condition) { throw "FAIL: $Label" }
    $script:passed++
    Write-Host "PASS: $Label"
}
function Invoke-FixtureGit {
    param([string[]]$Arguments)
    $result = & $git -c "safe.directory=$($fixture.Replace('\', '/'))" -C $fixture @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Fixture git failed: $($Arguments -join ' ')" }
    return $result
}
function Run-Tool {
    param([string]$Name, [string[]]$Arguments = @(), [int]$Expected = 0)
    $scriptPath = Join-Path $fixture "tools\$Name"
    if ($Name -eq 'Install-OMH.ps1') { $scriptPath = $installerHarness }
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue' # Expected negative cases can emit native stderr in PS 5.1.
        $output = & $shell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $scriptPath @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousErrorAction }
    $output | Out-File -LiteralPath (Join-Path $testRoot "$($script:passed)-$Name.log") -Encoding UTF8
    Assert-Test ($code -eq $Expected) "$Name $($Arguments -join ' ') exits $Expected"
    return ($output -join "`n")
}
function Assert-Rejected {
    param([scriptblock]$Action, [string]$Label)
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    Assert-Test $rejected $Label
}
function Get-TreeHashes {
    param([string]$Path)
    return @((Get-ChildItem -LiteralPath $Path -File -Recurse -Force | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($Path.Length) + '=' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    })) -join "`n"
}

foreach ($entry in @('Contents', 'tools', 'docs', 'OMH_TraitShop.cmd', 'preview.gif', 'preview.png', 'workshop.txt', 'WORKSHOP_CHANGELOG.txt', '.gitignore')) {
    Copy-Item -LiteralPath (Join-Path $repository $entry) -Destination $fixture -Recurse
}
$fixtureWorkshop = Join-Path $fixture 'workshop.txt'
$fixtureWorkshopText = [IO.File]::ReadAllText($fixtureWorkshop) -replace '(?m)^id=\d+', 'id=0'
[IO.File]::WriteAllText($fixtureWorkshop, $fixtureWorkshopText, [Text.UTF8Encoding]::new($false))
Invoke-FixtureGit @('init', '-q', '-b', 'codex/release-fixture') | Out-Null
Invoke-FixtureGit @('config', 'user.name', 'Release Fixture') | Out-Null
Invoke-FixtureGit @('config', 'user.email', 'fixture@example.invalid') | Out-Null
Invoke-FixtureGit @('config', 'core.autocrlf', 'false') | Out-Null
Invoke-FixtureGit @('add', '.') | Out-Null
Invoke-FixtureGit @('commit', '-q', '-m', 'Fixture baseline') | Out-Null
$release = Get-OmhRelease $fixture
Invoke-FixtureGit @('tag', $release.Tag) | Out-Null
Invoke-FixtureGit @('remote', 'add', 'origin', 'https://github.com/PandizeLive/pz-mod-onemorehorde_traitshop.git') | Out-Null

# Only the disposable-profile harness suppresses the process check. Production tools retain it.
$installerHarness = Join-Path $testRoot 'Invoke-InstallerFixture.ps1'
$installerPathLiteral = (Join-Path $fixture 'tools\Install-OMH.ps1').Replace("'", "''")
@"
param([switch]`$ValidateOnly, [string]`$UserDataRoot)
function Get-Process { param(`$Name, `$ErrorAction) }
. '$installerPathLiteral' -ValidateOnly:`$ValidateOnly -UserDataRoot `$UserDataRoot
exit `$LASTEXITCODE
"@ | Set-Content -LiteralPath $installerHarness

$parseErrors = @()
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $fixture 'tools') -Filter '*.ps1') {
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    $parseErrors += $errors
}
Assert-Test ($parseErrors.Count -eq 0) 'All PowerShell scripts parse in Windows PowerShell 5.1'
$profile = Join-Path $testRoot 'fake user data'
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $profile)
Assert-Test (-not (Test-Path -LiteralPath $profile)) 'Installer validation writes no destination files'
$null = Run-Tool 'Mirror-OMH.ps1' @('-ValidateOnly')
$preflight = Run-Tool 'Publish-OMHWorkshop.ps1' @('-PreflightOnly')
Assert-Test ($preflight -match '"visibility" "2"' -and $preflight -match '"publishedfileid" "0"') 'First upload manifest creates a private item'

$package = 'OneMoreHorde_TraitShop'
$local = Join-Path $profile "mods\$package"
$staging = Join-Path $profile "Workshop\$package\Contents\mods\$package"
$unrelated = Join-Path $profile 'mods\UnrelatedMod'
New-Item -ItemType Directory -Path $local, $staging, $unrelated -Force | Out-Null
Set-Content -LiteralPath (Join-Path $local 'old-local.txt') -Value 'old local'
Set-Content -LiteralPath (Join-Path $staging 'old-staging.txt') -Value 'old staging'
Set-Content -LiteralPath (Join-Path $unrelated 'keep.txt') -Value 'keep me'
$sourceHash = Get-TreeHashes (Join-Path $fixture "Contents\mods\$package")
$null = Run-Tool 'Install-OMH.ps1' @('-UserDataRoot', $profile)
Assert-Test ((Get-TreeHashes $local) -eq $sourceHash -and (Get-TreeHashes $staging) -eq $sourceHash) 'Both installed copies match all source file hashes; stale files removed'
$backups = @(Get-ChildItem -LiteralPath (Join-Path $profile 'OMH-TraitShop-local-backups') -Directory)
Assert-Test ($backups.Count -eq 1 -and
    (Get-Content -LiteralPath (Join-Path $backups[0].FullName "local\$package\old-local.txt")) -eq 'old local' -and
    (Get-Content -LiteralPath (Join-Path $backups[0].FullName "staging\$package\old-staging.txt")) -eq 'old staging') 'Previous local and staging packages are preserved in backups'
Assert-Test ((Get-Content -LiteralPath (Join-Path $unrelated 'keep.txt')) -eq 'keep me') 'Unrelated mods remain intact'

# Induce failure on the second copy to exercise rollback of both destinations.
$rollbackProfile = Join-Path $testRoot 'rollback profile'
$rollbackLocal = Join-Path $rollbackProfile "mods\$package"
$rollbackStaging = Join-Path $rollbackProfile "Workshop\$package\Contents\mods\$package"
New-Item -ItemType Directory -Path $rollbackLocal, $rollbackStaging -Force | Out-Null
Set-Content -LiteralPath (Join-Path $rollbackLocal 'before.txt') -Value 'before local'
Set-Content -LiteralPath (Join-Path $rollbackStaging 'before.txt') -Value 'before staging'
$rollbackHarness = Join-Path $fixture 'tools\Invoke-RollbackFixture.ps1'
@'
param([string]$UserDataRoot)
$script:copyCalls = 0
function Get-Process { param($Name, $ErrorAction) }
function Copy-Item {
    param($LiteralPath, $Destination, [switch]$Recurse)
    $script:copyCalls++
    if ($script:copyCalls -eq 2) { throw 'Simulated staging copy failure' }
    Microsoft.PowerShell.Management\Copy-Item -LiteralPath $LiteralPath -Destination $Destination -Recurse:$Recurse
}
. (Join-Path $PSScriptRoot 'Install-OMH.ps1') -UserDataRoot $UserDataRoot
exit $LASTEXITCODE
'@ | Set-Content -LiteralPath $rollbackHarness
$null = Run-Tool 'Invoke-RollbackFixture.ps1' @('-UserDataRoot', $rollbackProfile) 1
Assert-Test ((Get-Content -LiteralPath (Join-Path $rollbackLocal 'before.txt')) -eq 'before local' -and
    (Get-Content -LiteralPath (Join-Path $rollbackStaging 'before.txt')) -eq 'before staging' -and
    @(Get-ChildItem -LiteralPath $rollbackLocal).Count -eq 1 -and @(Get-ChildItem -LiteralPath $rollbackStaging).Count -eq 1) 'Second-copy failure restores both old packages'
Remove-Item -LiteralPath $rollbackHarness

$linkedProfile = Join-Path $testRoot 'linked profile'
New-Item -ItemType Junction -Path $linkedProfile -Target $profile | Out-Null
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $linkedProfile) 1
Assert-Test ((Get-TreeHashes $local) -eq $sourceHash) 'Linked destination is rejected without changing its target'

$info = Join-Path $fixture 'Contents\mods\OneMoreHorde_TraitShop\42.20\mod.info'
Add-Content -LiteralPath $info -Value '# changed after tag'
Invoke-FixtureGit @('add', 'Contents') | Out-Null
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $profile) 1
Invoke-FixtureGit @('restore', '--source=HEAD', '--staged', '--worktree', '--', 'Contents') | Out-Null
$ignored = Join-Path $fixture 'Contents\untracked.class'
Set-Content -LiteralPath $ignored -Value 'ignored but must never ship'
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $profile) 1
Remove-Item -LiteralPath $ignored
Invoke-FixtureGit @('remote', 'set-url', '--push', 'origin', 'https://github.com/other/wrong.git') | Out-Null
$null = Run-Tool 'Mirror-OMH.ps1' @('-ValidateOnly') 1
Invoke-FixtureGit @('config', '--unset', 'remote.origin.pushurl') | Out-Null
Set-Content -LiteralPath (Join-Path $fixture 'dirty.txt') -Value 'uncommitted'
$null = Run-Tool 'Mirror-OMH.ps1' @('-ValidateOnly') 1
Remove-Item -LiteralPath (Join-Path $fixture 'dirty.txt')
Invoke-FixtureGit @('checkout', '-q', '-b', 'main') | Out-Null
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $profile) 1
Invoke-FixtureGit @('checkout', '-q', 'codex/release-fixture') | Out-Null
Invoke-FixtureGit @('tag', '-d', $release.Tag) | Out-Null
$null = Run-Tool 'Install-OMH.ps1' @('-ValidateOnly', '-UserDataRoot', $profile) 1
Invoke-FixtureGit @('tag', $release.Tag) | Out-Null

# Load only publisher function definitions, never its executable upload body.
. (Join-Path $PSScriptRoot 'OMH-SteamHelpers.ps1')
$ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Publish-OMHWorkshop.ps1'), [ref]$null, [ref]$null)
foreach ($definition in $ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] }) {
    Invoke-Expression $definition.Extent.Text
}
$workshopAppId = '108600'
$previewPath = Join-Path $fixture 'preview.gif'
$initial = New-WorkshopVdf 'C:\fixture\Contents' 'First upload' '0' 'Description' $previewPath
Assert-Test ($initial -match '"previewfile"' -and $initial.Contains('preview.gif')) 'First upload uses owner animated preview'
Assert-Rejected { New-WorkshopVdf 'C:\fixture' 'First upload' '0' 'Description' (Join-Path $fixture 'missing.gif') } 'Missing first-upload preview is rejected'
$update = New-WorkshopVdf 'C:\fixture\Contents' 'Update' '1234567890' 'Must not overwrite'
Assert-Test ($update -notmatch '"(title|description|visibility|previewfile)"' -and $update -match '"publishedfileid" "1234567890"') 'Existing-item uploads preserve description, title, cover and visibility'
$previewUpdate = New-WorkshopVdf '' '' '3803035618' '' $previewPath -PreviewOnly
Assert-Test ($previewUpdate -match '"previewfile"' -and $previewUpdate -notmatch '"(contentfolder|changenote|title|description|visibility)"') 'Preview-only update cannot replace content or page metadata'
Assert-Rejected { New-WorkshopVdf '' '' '0' '' $previewPath -PreviewOnly } 'Preview-only action cannot create a new item'
Assert-Rejected { New-WorkshopVdf '' '' '1234567890' '' $previewPath -PreviewOnly } 'Preview-only action cannot target another item'
Assert-Rejected { New-WorkshopVdf '' '' '3803035618' '' (Join-Path $fixture 'preview.png') -PreviewOnly } 'Non-GIF preview is rejected'
Assert-Rejected { New-WorkshopVdf 'C:\fixture' 'Update' '3777891317' '' } 'Horde Night Workshop ID is blocked'
Assert-Rejected { New-WorkshopVdf 'C:\fixture' "line`nbreak" '0' 'Description' $previewPath } 'Manifest rejects control characters'
Assert-Rejected { New-WorkshopVdf 'C:\fixture' 'quote"' '0' 'Description' $previewPath } 'Manifest rejects double quotes'
$workshopMetadataPath = Join-Path $fixture 'workshop.txt'
$returnedVdf = Join-Path $testRoot 'returned.vdf'
Set-Content -LiteralPath $returnedVdf -Value $update
$returnedId = Save-CreatedWorkshopId $returnedVdf
Assert-Test ($returnedId -eq '1234567890' -and (Get-OmhWorkshopId $fixture) -eq '1234567890') 'Steam-returned ID is persisted for later updates'
Assert-Rejected { Save-CreatedWorkshopId $returnedVdf } 'Creation cannot replace an already-recorded Workshop ID'
Set-Content -LiteralPath $workshopMetadataPath -Value 'id=3777891317'
Assert-Rejected { Get-OmhWorkshopId $fixture } 'Metadata cannot target Horde Night'
Invoke-FixtureGit @('restore', '--', 'workshop.txt') | Out-Null
$null = Run-Tool 'OMH-Release.ps1' @('-Action', 'Check', '-UserDataRoot', $profile)
$null = Run-Tool 'Mirror-OMH.ps1' @('-ValidateOnly')
$emptyPrResult = '[]' | ConvertFrom-Json
Assert-Test (@($emptyPrResult | Where-Object { $null -ne $_ }).Count -eq 0) 'Empty GitHub PR JSON normalizes correctly on Windows PowerShell 5.1'

Write-Host "$($script:passed) release-tooling checks passed. No network calls or real user-profile changes."
Write-Host "Retained test fixtures and logs: $testRoot"
