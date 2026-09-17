function Find-OmhSharedPath {
    param([string]$RepositoryPath, [string]$RelativePath)
    $folder = [IO.Path]::GetFullPath($RepositoryPath)
    while ($folder) {
        $candidate = Join-Path $folder $RelativePath
        if (Test-Path -LiteralPath $candidate) { return $candidate }
        $folder = Split-Path -Parent $folder
    }
    return $null
}

function Get-OmhGitExecutable {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    foreach ($candidate in @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw 'Git is required. Install Git for Windows and reopen OMH_TraitShop.cmd.'
}

function Invoke-OmhReleaseGit {
    param($Release, [string[]]$Arguments)
    $options = @('-c', "safe.directory=$($Release.Repository.Replace('\', '/'))", '-C', $Release.Repository)
    $result = & $Release.GitPath @options @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments -join ' ')" }
    return $result
}

function Get-OmhRelease {
    param([Parameter(Mandatory)][string]$RepositoryPath)
    $repository = [IO.Path]::GetFullPath($RepositoryPath)
    $packagePath = Join-Path $repository 'Contents\mods\OneMoreHorde_TraitShop'
    $infos = @(Get-ChildItem -LiteralPath $packagePath -Directory |
        Where-Object { $_.Name -match '^\d+(\.\d+)*$' } |
        ForEach-Object { Join-Path $_.FullName 'mod.info' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    if ($infos.Count -eq 0) { throw 'No versioned Trait Shop mod.info found.' }
    $versions = @()
    foreach ($info in $infos) {
        $source = Get-Content -LiteralPath $info -Raw
        $ids = [regex]::Matches($source, '(?m)^id=([^\r\n]+)\r?$')
        $matches = [regex]::Matches($source, '(?m)^modversion=(\d+(?:\.\d+){2,3})\r?$')
        if ($ids.Count -ne 1 -or $ids[0].Groups[1].Value -ne 'OneMoreHorde_TraitShop' -or $matches.Count -ne 1) {
            throw "Invalid Trait Shop identity or version in $info."
        }
        $versions += $matches[0].Groups[1].Value
    }
    $versions = @($versions | Select-Object -Unique)
    if ($versions.Count -ne 1) { throw 'All Trait Shop package versions must match.' }
    $release = [pscustomobject]@{
        Repository = $repository
        Version = $versions[0]
        Tag = "v$($versions[0])"
        Branch = ''
        Head = ''
        GitPath = Get-OmhGitExecutable
    }
    $release.Head = [string](Invoke-OmhReleaseGit $release @('rev-parse', '--verify', 'HEAD'))
    $release.Branch = [string](Invoke-OmhReleaseGit $release @('branch', '--show-current'))
    return $release
}

function Assert-OmhTaggedContent {
    param($Release)
    if ([string]::IsNullOrWhiteSpace($Release.Branch) -or $Release.Branch -in @('main', 'master')) {
        throw 'Use a working branch, not main/master or a detached checkout.'
    }
    $tagCommit = Invoke-OmhReleaseGit $Release @('rev-parse', "$($Release.Tag)^{commit}")
    Invoke-OmhReleaseGit $Release @('merge-base', '--is-ancestor', $tagCommit, 'HEAD') | Out-Null
    Invoke-OmhReleaseGit $Release @('diff', '--exit-code', $tagCommit, '--', 'Contents') | Out-Null
    if (Invoke-OmhReleaseGit $Release @('ls-files', '--others', '--', 'Contents')) {
        throw 'Untracked or ignored files exist under Contents; do not ship them.'
    }
    $contents = Join-Path $Release.Repository 'Contents'
    $top = @(Get-ChildItem -LiteralPath $contents -Force)
    $packages = @(Get-ChildItem -LiteralPath (Join-Path $contents 'mods') -Force)
    if ($top.Count -ne 1 -or $top[0].Name -ne 'mods' -or
        $packages.Count -ne 1 -or $packages[0].Name -ne 'OneMoreHorde_TraitShop') {
        throw 'Contents must contain only mods/OneMoreHorde_TraitShop.'
    }
    foreach ($item in @(Get-Item -LiteralPath $contents) + @(Get-ChildItem -LiteralPath $contents -Force -Recurse)) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked content is not allowed: $($item.FullName)" }
    }
}

function Get-OmhRemoteConfig {
    param($Release)
    $config = Get-Content -LiteralPath (Join-Path $Release.Repository 'tools\omh-release.json') -Raw | ConvertFrom-Json
    if ($config.repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' -or $config.baseBranch -ne 'main') {
        throw 'Invalid release repository or base branch configuration.'
    }
    if ($config.repository -eq 'AlexVDefi/pz-mod-onemorehorde_protectthecure') {
        throw 'Trait Shop must not mirror into the Horde Night repository.'
    }
    return $config
}

function Assert-OmhOrigin {
    param($Release, $Config)
    $allowed = @("https://github.com/$($Config.repository).git", "https://github.com/$($Config.repository)", "git@github.com:$($Config.repository).git")
    $fetchUrls = @(Invoke-OmhReleaseGit $Release @('remote', 'get-url', '--all', 'origin'))
    $pushUrls = @(Invoke-OmhReleaseGit $Release @('remote', 'get-url', '--push', '--all', 'origin'))
    if ($fetchUrls.Count -ne 1 -or $pushUrls.Count -ne 1 -or $fetchUrls[0] -notin $allowed -or $pushUrls[0] -notin $allowed) {
        throw "Origin fetch and push URLs must target only $($Config.repository)."
    }
}

function Assert-OmhRemoteMirror {
    param($Release, $Config, [string[]]$GitOptions = @())
    Assert-OmhOrigin $Release $Config
    $refs = @(Invoke-OmhReleaseGit $Release ($GitOptions + @('ls-remote', 'origin', "refs/heads/$($Release.Branch)", "refs/tags/$($Release.Tag)", "refs/tags/$($Release.Tag)^{}")))
    $remote = @{}
    foreach ($line in $refs) {
        $parts = $line -split '\s+', 2
        if ($parts.Count -eq 2) { $remote[$parts[1]] = $parts[0] }
    }
    $tagObject = Invoke-OmhReleaseGit $Release @('rev-parse', "refs/tags/$($Release.Tag)")
    if ($remote["refs/heads/$($Release.Branch)"] -ne $Release.Head -or $remote["refs/tags/$($Release.Tag)"] -ne $tagObject) {
        throw 'The exact current branch and release tag are not mirrored. Select Mirror to GitHub first.'
    }
}

function Get-OmhWorkshopId {
    param([string]$RepositoryPath)
    $metadata = Get-Content -LiteralPath (Join-Path $RepositoryPath 'workshop.txt') -Raw
    $matches = [regex]::Matches($metadata, '(?m)^id=(\d+)\r?$')
    if ($matches.Count -ne 1) { throw 'workshop.txt must contain exactly one numeric id.' }
    $id = $matches[0].Groups[1].Value
    if ($id -eq '3777891317') { throw 'Refusing to publish Trait Shop to Horde Night Workshop item 3777891317.' }
    if ($id -ne '0' -and $id -notmatch '^[1-9]\d{5,19}$') { throw 'Invalid Workshop item ID.' }
    return $id
}
