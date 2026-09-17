[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local\phase2'
$java = Join-Path $GamePath 'jre64\bin\java.exe'
$jar = Join-Path $GamePath 'projectzomboid.jar'
$lua = Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop\42.20\media\lua'
$tests = Join-Path $repo 'tests'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$translations = Get-Content -LiteralPath (Join-Path $lua 'shared\Translate\EN\UI.json') -Raw | ConvertFrom-Json
$translationLines = [Collections.Generic.List[string]]::new()
$translationLines.Add('UI_EN = {')
foreach ($property in $translations.PSObject.Properties) {
    if ($property.Value.Contains(']=]')) { throw 'Unsupported fixture translation delimiter.' }
    $translationLines.Add('    ["' + $property.Name + '"] = [=[' + $property.Value + ']=],')
}
$translationLines.Add('}')
$translationFixture = Join-Path $output 'translations.lua'
[IO.File]::WriteAllLines($translationFixture, $translationLines, [Text.UTF8Encoding]::new($false))
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile the game-VM runner.' }
$stages = @(
    "_=$GamePath\stdlib.lua",
    "_=$tests\phase1_setup.lua",
    "_=$tests\phase2_setup.lua",
    "OMHTS_Bootstrap=$lua\shared\OMHTS_Bootstrap.lua",
    "OMHTS_Catalog=$lua\shared\OMHTS_Catalog.lua",
    "OMHTS_Effects=$lua\shared\OMHTS_Effects.lua",
    "OMHTS_State=$lua\server\OMHTS_State.lua",
    "OMHTS_Creation=$lua\server\OMHTS_Creation.lua",
    "OMHTS_Shop=$lua\server\OMHTS_Shop.lua",
    "_=$tests\phase2_shop.lua",
    "OMHTS_Authority=$lua\server\OMHTS_Authority.lua",
    "_=$tests\phase2_authority.lua",
    "OMHTS_ClientState=$lua\client\OMHTS_ClientState.lua",
    "_=$tests\phase2_client.lua",
    "_=$translationFixture",
    "_=$tests\phase2_ui_setup.lua",
    "ISUI/ISResizeWidget=$GamePath\media\lua\client\ISUI\ISResizeWidget.lua",
    "OMHTS_Presentation=$lua\client\OMHTS_Presentation.lua",
    "_=$tests\phase2_catalog.lua",
    "OMHTS_ShopWindow=$lua\client\OMHTS_ShopWindow.lua",
    "_=$lua\client\OMHTS_HealthButton.lua",
    "_=$tests\phase2_ui.lua"
)
& $java --enable-native-access=ALL-UNNAMED -cp "$jar;$output" KahluaBehaviorCheck @stages | Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Phase 2 behavior check failed.' }
