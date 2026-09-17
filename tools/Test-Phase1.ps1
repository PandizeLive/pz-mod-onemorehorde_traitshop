[CmdletBinding()]
param([string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid')

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$output = Join-Path $repo '.local\phase1'
$java = Join-Path $GamePath 'jre64\bin\java.exe'
$jar = Join-Path $GamePath 'projectzomboid.jar'
$lua = Join-Path $repo 'Contents\mods\OneMoreHorde_TraitShop\42.20\media\lua'
$tests = Join-Path $repo 'tests'
New-Item -ItemType Directory -Path $output -Force | Out-Null
foreach ($source in Get-ChildItem -LiteralPath $lua -Recurse -Filter '*.lua') {
    $text = [IO.File]::ReadAllText($source.FullName)
    if ($text -match '\b(pcall|xpcall|ipairs|next)\s*\(|\bgoto\b|\t') {
        throw "Forbidden Lua construct or tab in $($source.FullName)."
    }
}
Write-Host 'Lua fundamentals audit passed: no pcall/xpcall, ipairs, next, goto or tabs.'
& javac.exe -d $output (Join-Path $PSScriptRoot 'KahluaSyntaxCheck.java') (Join-Path $PSScriptRoot 'KahluaBehaviorCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile the reflection-based test runners.' }
$classpath = "$jar;$output"
& $java -cp $classpath KahluaSyntaxCheck $lua | Tee-Object -FilePath (Join-Path $output 'syntax.log')
if ($LASTEXITCODE -ne 0) { throw 'Kahlua syntax check failed.' }
$stages = @(
    "_=$GamePath\stdlib.lua",
    "_=$tests\phase1_setup.lua",
    "OMHTS_Bootstrap=$lua\shared\OMHTS_Bootstrap.lua",
    "OMHTS_Catalog=$lua\shared\OMHTS_Catalog.lua",
    "OMHTS_Effects=$lua\shared\OMHTS_Effects.lua",
    "OMHTS_Progression=$lua\shared\OMHTS_Progression.lua",
    "OMHTS_State=$lua\server\OMHTS_State.lua",
    "OMHTS_Creation=$lua\server\OMHTS_Creation.lua",
    "OMHTS_Shop=$lua\server\OMHTS_Shop.lua",
    "_=$tests\phase1_state.lua",
    "_=$tests\checkpoint5_progression.lua",
    "OMHTS_Authority=$lua\server\OMHTS_Authority.lua",
    "_=$tests\phase1_authority.lua",
    "_=$tests\checkpoint5_authority.lua",
    "_=$lua\client\OMHTS_ClientState.lua",
    "_=$tests\phase1_client.lua"
)
& $java --enable-native-access=ALL-UNNAMED -cp $classpath KahluaBehaviorCheck @stages | Tee-Object -FilePath (Join-Path $output 'behavior.log')
if ($LASTEXITCODE -ne 0) { throw 'Phase 1 behavior check failed.' }
Write-Host 'These tests execute the game Kahlua VM and serialization with lifecycle/network fixtures; they do not replace live player-join testing.'
