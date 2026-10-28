[CmdletBinding()]
param([switch]$ValidateOnly)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'OMH-ReleaseCommon.ps1')
$release = Get-OmhRelease (Split-Path -Parent $PSScriptRoot)
$config = Get-OmhRemoteConfig $release
$ghPath = Find-OmhSharedPath $release.Repository '.tools\gh.exe'
if (-not $ghPath) { $ghPath = (Get-Command gh.exe -ErrorAction Stop).Source }
$ghConfig = Find-OmhSharedPath $release.Repository '.gh-codex'
if ($ghConfig) { $env:GH_CONFIG_DIR = $ghConfig }

function Invoke-Gh {
    param([string[]]$Arguments)
    $result = & $ghPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "GitHub CLI failed: $($Arguments[0])." }
    return $result
}

try {
    Assert-OmhTaggedContent $release
    if (Invoke-OmhReleaseGit $release @('status', '--porcelain', '--untracked-files=all')) { throw 'Commit local changes before mirroring.' }
    Assert-OmhOrigin $release $config
    $prBody = Join-Path $release.Repository "docs\PR_v$($release.Version).md"
    if (-not (Test-Path -LiteralPath $prBody -PathType Leaf)) { throw "Prepare $prBody before mirroring." }
    if ($ValidateOnly) { Write-Host "Local mirror checks passed for $($release.Tag). No network calls or remote changes."; exit 0 }
    Invoke-Gh @('auth', 'status', '--hostname', 'github.com') | Out-Host
    $gitAuth = @('-c', 'credential.helper=', '-c', ('credential.helper=!"' + $ghPath.Replace('\', '/') + '" auth git-credential'))
    $remoteHeads = @(Invoke-OmhReleaseGit $release ($gitAuth + @('ls-remote', '--heads', 'origin')))
    if ($remoteHeads.Count -eq 0) {
        $roots = @(Invoke-OmhReleaseGit $release @('rev-list', '--max-parents=0', 'HEAD'))
        if ($roots.Count -ne 1) { throw 'First mirror requires a single local baseline commit.' }
        Write-Host "Initializing the empty repository's main branch from baseline $($roots[0]). Later mirrors never push main."
        Invoke-OmhReleaseGit $release ($gitAuth + @('push', 'origin', "$($roots[0]):refs/heads/main")) | Out-Host
    }
    Invoke-OmhReleaseGit $release ($gitAuth + @('fetch', 'origin', '--prune')) | Out-Host
    Invoke-OmhReleaseGit $release @('merge-base', '--is-ancestor', 'origin/main', 'HEAD') | Out-Null
    $remoteTag = @(Invoke-OmhReleaseGit $release ($gitAuth + @('ls-remote', 'origin', "refs/tags/$($release.Tag)")))
    $localTag = Invoke-OmhReleaseGit $release @('rev-parse', "refs/tags/$($release.Tag)")
    if ($remoteTag.Count -gt 0 -and ($remoteTag[0] -split '\s+')[0] -ne $localTag) { throw 'Remote release tag differs; never overwrite a release tag.' }
    Invoke-OmhReleaseGit $release ($gitAuth + @('push', '--atomic', 'origin', "HEAD:refs/heads/$($release.Branch)", "refs/tags/$($release.Tag):refs/tags/$($release.Tag)")) | Out-Host
    $prResult = Invoke-Gh @('pr', 'list', '--repo', $config.repository, '--head', $release.Branch, '--base', 'main', '--state', 'open', '--json', 'number,isDraft') | ConvertFrom-Json
    # Windows PowerShell 5.1 emits an empty array as one pipeline object.
    $prs = @($prResult | Where-Object { $null -ne $_ })
    $title = (Get-Content -LiteralPath $prBody | Where-Object { $_ -match '^# ' } | Select-Object -First 1) -replace '^# ', ''
    if (-not $title) { $title = "OMH: Trait Shop v$($release.Version)" }
    if ($prs.Count -gt 1) { throw 'Multiple open PRs match this release branch.' }
    if ($prs.Count -eq 0) {
        Invoke-Gh @('pr', 'create', '--repo', $config.repository, '--head', $release.Branch, '--base', 'main', '--draft', '--title', $title, '--body-file', $prBody) | Out-Host
    } else {
        if (-not $prs[0].isDraft) { throw 'The existing PR is no longer a draft. Review its state before updating it.' }
        Invoke-Gh @('pr', 'edit', [string]$prs[0].number, '--repo', $config.repository, '--title', $title, '--body-file', $prBody) | Out-Host
    }
    $pr = Invoke-Gh @('pr', 'view', $release.Branch, '--repo', $config.repository, '--json', 'headRefOid,isDraft,url,body,title') | ConvertFrom-Json
    if ($pr.headRefOid -ne $release.Head -or -not $pr.isDraft -or $pr.title -ne $title -or
        $pr.body.Replace("`r`n", "`n").Trim() -ne (Get-Content -LiteralPath $prBody -Raw).Replace("`r`n", "`n").Trim()) {
        throw 'Draft PR verification failed.'
    }
    if ($config.reviewer) { Invoke-Gh @('pr', 'edit', $release.Branch, '--repo', $config.repository, '--add-reviewer', $config.reviewer) | Out-Host }
    Assert-OmhRemoteMirror $release $config $gitAuth
    Write-Host "Mirror verified: $($pr.url)"
    Write-Host 'No Steam upload performed.'
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
