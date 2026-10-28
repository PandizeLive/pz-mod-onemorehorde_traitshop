[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local\checkpoint7'
$tests = Join-Path $repo 'tests'
$lua = Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop\42.20\media\lua'
$policy = Join-Path (Split-Path -Parent $repo) 'pz-mod-onemorehorde_protectthecure\Contents\mods\OneMoreHorde_HordeNight\42.20\media\lua\shared\OMH_ModSettingsIntegrity.lua'
New-Item -ItemType Directory -Path $output -Force | Out-Null
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile Kahlua runner.' }
$stages = @("_=$GamePath\stdlib.lua", "_=$tests\phase1_setup.lua", "_=$tests\phase2_setup.lua", "OMH_ModSettingsIntegrity=$policy")
foreach ($name in @('Bootstrap','RewardsConfig','Physical','Catalog','Effects','Progression','Prestige')) {
    $stages += "OMHTS_${name}=$lua\shared\OMHTS_${name}.lua"
}
foreach ($name in @('State','Creation')) {
    $stages += "OMHTS_${name}=$lua\server\OMHTS_${name}.lua"
}
$stages += "_=$tests\checkpoint7.lua"
$stages += "OMHTS_CreationBootstrap=$lua\server\OMHTS_CreationBootstrap.lua"
$stages += "_=$tests\creation_bootstrap.lua"
$stages += "OMHTS_CreationScreen=$lua\client\OMHTS_CreationScreen.lua"
$stages += "_=$tests\checkpoint7_ui.lua"
& (Join-Path $GamePath 'jre64\bin\java.exe') --enable-native-access=ALL-UNNAMED -cp "$(Join-Path $GamePath 'projectzomboid.jar');$output" KahluaBehaviorCheck @stages |
    Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Checkpoint 7 checks failed.' }
