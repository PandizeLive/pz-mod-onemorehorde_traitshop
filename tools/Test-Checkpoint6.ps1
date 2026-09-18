[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local\checkpoint6'
$tests = Join-Path $repo 'tests'
$lua = Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop\42.20\media\lua'
$java = Join-Path $GamePath 'jre64\bin\java.exe'
$jar = Join-Path $GamePath 'projectzomboid.jar'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile Kahlua runner.' }
$stages = @("_=$GamePath\stdlib.lua", "_=$tests\phase1_setup.lua")
foreach ($name in @('Bootstrap','RewardsConfig','Catalog','Effects','Progression','Prestige')) {
    $stages += "OMHTS_${name}=$lua\shared\OMHTS_${name}.lua"
}
foreach ($name in @('State','Creation','Shop','Rewards','Authority')) {
    $stages += "OMHTS_${name}=$lua\server\OMHTS_${name}.lua"
}
$stages += "_=$tests\checkpoint6_rewards.lua"
$stages += "_=$tests\checkpoint6_ui_setup.lua"
$stages += "OMHTS_SandboxUI=$lua\client\OMHTS_SandboxUI.lua"
$stages += "_=$tests\checkpoint6_ui.lua"
& $java --enable-native-access=ALL-UNNAMED -cp "$jar;$output" KahluaBehaviorCheck @stages |
    Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Checkpoint 6 reward checks failed.' }
