[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local\checkpoint8'
$tests = Join-Path $repo 'tests'
$lua = Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop\42.20\media\lua'
$core = Join-Path (Split-Path -Parent $repo) 'pz-mod-onemorehorde_protectthecure\Contents\mods\OneMoreHorde_HordeNight\42.20\media\lua'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile Kahlua runner.' }
$stages = @("_=$GamePath\stdlib.lua", "_=$tests\phase1_setup.lua", "_=$tests\checkpoint8_setup.lua")
foreach ($name in @('Extensions','RunFlags')) { $stages += "OMH_${name}=$core\shared\OMH_${name}.lua" }
foreach ($name in @('ExtensionRuntime','Phase4Ownership','DefenseIntegration')) { $stages += "OMH_${name}=$core\server\OMH_${name}.lua" }
foreach ($name in @('Bootstrap','RewardsConfig','Physical','Catalog','Effects','Progression','Prestige','InjuryEvidence')) {
    $stages += "OMHTS_${name}=$lua\shared\OMHTS_${name}.lua"
}
foreach ($name in @('State','Creation','Shop','Rewards','DefenseRewards','DefenseCredit','Authority','HordeIntegration')) {
    $stages += "OMHTS_${name}=$lua\server\OMHTS_${name}.lua"
}
$engine = [IO.File]::ReadAllText((Join-Path $core 'server\OMH_Phase3HordeEngine.lua'))
$extracted = [IO.File]::ReadAllText((Join-Path $tests 'checkpoint8_engine_setup.lua'))
foreach ($name in @('creditParticipantKill','onZombieDead')) {
    $match = [regex]::Match($engine, "(?ms)^local function $name\(.*?(?=^---@|^---[A-Z])")
    if (-not $match.Success) { throw "Missing engine function $name" }
    $extracted += "`n" + $match.Value
}
$extracted += "`nfunction testEngineDeath(zombie, runtime) registry[runtime.event.eventId] = runtime; onZombieDead(zombie) end`n"
$integration = Join-Path $output 'engine.lua'
[IO.File]::WriteAllText($integration, $extracted, [Text.UTF8Encoding]::new($false))
$stages += "_=$integration"
$stages += "_=$tests\checkpoint8_rewards.lua"
& (Join-Path $GamePath 'jre64\bin\java.exe') --enable-native-access=ALL-UNNAMED -cp "$(Join-Path $GamePath 'projectzomboid.jar');$output" KahluaBehaviorCheck @stages |
    Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Checkpoint 8 checks failed.' }
