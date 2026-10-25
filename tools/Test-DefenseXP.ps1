[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local/defense-xp'
$lua = Join-Path $repo 'Contents/mods/OneMoreHorde_TraitShop/42.20/media/lua'
$tests = Join-Path $repo 'tests'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Runner compile failed.' }
$stages = @("_=$GamePath/stdlib.lua", "_=$tests/phase1_setup.lua")
foreach ($name in @('Bootstrap','RewardsConfig','Physical','Catalog','Effects','Progression','Prestige','InjuryEvidence')) {
    $stages += "OMHTS_${name}=$lua/shared/OMHTS_${name}.lua"
}
foreach ($name in @('State','Rewards','DefenseRewards','DefenseCredit')) {
    $stages += "OMHTS_${name}=$lua/server/OMHTS_${name}.lua"
}
$stages += "_=$tests/defense_xp.lua"
& "$GamePath/jre64/bin/java.exe" --enable-native-access=ALL-UNNAMED -cp "$GamePath/projectzomboid.jar;$output" KahluaBehaviorCheck @stages | Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Defense XP verification failed.' }
