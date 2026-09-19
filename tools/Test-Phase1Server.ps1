[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid',
    [ValidateSet(1, 2, 3, 4, 7, 8)][int]$Phase = 1
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$cache = Join-Path $repo ('.local\phase' + $Phase + '-server-' + [guid]::NewGuid().ToString('N'))
$mods = Join-Path $cache 'mods'
$settings = Join-Path $cache 'Server'
New-Item -ItemType Directory -Path $mods, $settings -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop') -Destination $mods -Recurse
if ($Phase -eq 8) {
    $core = Join-Path (Split-Path -Parent $repo) 'pz-mod-onemorehorde_protectthecure\Contents\mods\OneMoreHorde_HordeNight'
    Copy-Item -LiteralPath $core -Destination $mods -Recurse
}
Copy-Item -LiteralPath (Join-Path $repo "tests\phase${Phase}_server_probe.lua") -Destination (Join-Path $mods 'OneMoreHorde_TraitShop\42.20\media\lua\server\ZZ_StateProbe.lua')
@'
PauseEmpty=true
Open=false
Public=false
UPnP=false
SteamVAC=false
SteamScoreboard=false
DefaultPort=17271
UDPPort=17272
Mods=OneMoreHorde_TraitShop
WorkshopItems=
Map=Muldraugh, KY
MaxPlayers=1
'@ | Set-Content -LiteralPath (Join-Path $settings 'TraitShopPhase1.ini') -Encoding ASCII

if ($Phase -eq 8) {
    $ini = Join-Path $settings 'TraitShopPhase1.ini'
    $text = [IO.File]::ReadAllText($ini).Replace('Mods=OneMoreHorde_TraitShop', 'Mods=OneMoreHorde_HordeNight;OneMoreHorde_TraitShop')
    [IO.File]::WriteAllText($ini, $text, [Text.UTF8Encoding]::new($false))
}

for ($stage = 1; $stage -le 3; $stage++) {
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = Join-Path $GamePath 'jre64\bin\java.exe'
    $start.WorkingDirectory = $GamePath
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $arguments = @('-Djava.awt.headless=true', '--enable-native-access=ALL-UNNAMED', '--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED', '-Dzomboid.steam=0', '-XX:-CreateCoredumpOnCrash', '-Xmx2048m', '-Djava.library.path=./natives/;./natives/win64/;./win64/;./', '-cp', './;projectzomboid.jar', 'zombie.network.GameServer', "-cachedir=$cache", '-servername', 'TraitShopPhase1', '-ip', '127.0.0.1', '-adminpassword', 'local-fixture-only')
    $start.Arguments = ($arguments | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $lines = [Collections.Generic.List[string]]::new()
    $ready = $false
    try {
        if (-not $process.Start()) { throw 'Dedicated fixture did not start.' }
        $stdout = $process.StandardOutput.ReadLineAsync()
        $stderr = $process.StandardError.ReadLineAsync()
        $deadline = [DateTime]::UtcNow.AddMinutes(2)
        while ([DateTime]::UtcNow -lt $deadline) {
            foreach ($stream in @('stdout', 'stderr')) {
                $task = Get-Variable -Name $stream -ValueOnly
                $drained = 0
                while ($task -and $task.IsCompleted -and $drained -lt 512) {
                    $line = $task.GetAwaiter().GetResult()
                    if ($null -eq $line) { Set-Variable -Name $stream -Value $null; break }
                    $lines.Add($line)
                    if ($line.Contains('ZZ_StateProbe.lua:')) { throw "Native probe failed; inspect $cache." }
                    if ($line.Contains('more than 200 local variables') -or
                        ($line.Contains('Exception thrown') -and $line.Contains('MOD:OMH:'))) {
                        throw "OMH native runtime error; inspect $cache."
                    }
                    if ($line.Contains("[OMHTS TEST] disk stage $stage ready")) { $ready = $true }
                    $reader = if ($stream -eq 'stdout') { $process.StandardOutput } else { $process.StandardError }
                    $task = $reader.ReadLineAsync()
                    Set-Variable -Name $stream -Value $task
                    $drained++
                }
            }
            if ($ready -and -not $sentQuit) {
                $process.StandardInput.WriteLine('quit')
                $process.StandardInput.Flush()
                $sentQuit = $true
            }
            if ($process.HasExited -and -not $stdout -and -not $stderr) { break }
            Start-Sleep -Milliseconds 10
        }
        if (-not $process.HasExited) { throw "Dedicated fixture stage $stage timed out." }
        if (-not $ready -or $process.ExitCode -ne 0) { throw "Dedicated fixture stage $stage failed; inspect $cache." }
        Write-Host "PASS: dedicated disk persistence stage $stage, graceful quit."
    } finally {
        if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit(10000) | Out-Null }
        [IO.File]::WriteAllLines((Join-Path $cache "stage-$stage.log"), $lines)
        $process.Dispose()
        $sentQuit = $false
    }
}
Write-Host "Three real dedicated-server save/restart cycles passed. No players joined. Evidence: $cache"
