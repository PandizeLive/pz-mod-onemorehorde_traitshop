param(
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid'
)

$ErrorActionPreference = 'Stop'
$traitRoot = Split-Path $PSScriptRoot -Parent
$traitCache = Join-Path $traitRoot '.local\client-smoke'
$traitPackage = Join-Path $traitRoot 'Contents\mods\OneMoreHorde_TraitShop'
$traitJava = Join-Path $GamePath 'jre64\bin\java.exe'
if (-not (Test-Path -LiteralPath $traitJava)) { throw "Game runtime not found: $traitJava" }
if (-not (Test-Path -LiteralPath (Join-Path $traitPackage '42.20\mod.info'))) {
    throw 'Checkpoint package is missing.'
}
$traitRunning = @(Get-Process -Name java,ProjectZomboid64 -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith($GamePath, [StringComparison]::OrdinalIgnoreCase) })
if ($traitRunning.Count -gt 0) { throw 'Close Project Zomboid and its local test server before launching this isolated test.' }

New-Item -ItemType Directory -Path (Join-Path $traitCache 'mods') -Force | Out-Null
Copy-Item -LiteralPath $traitPackage -Destination (Join-Path $traitCache 'mods') -Recurse -Force
$traitEnabled = "VERSION = 1,`nmods`n{`n    mod = OneMoreHorde_TraitShop,`n}`n"
[IO.File]::WriteAllText((Join-Path $traitCache 'mods\default.txt'), $traitEnabled, [Text.UTF8Encoding]::new($false))

Write-Host 'Checkpoint 1: start a NEW singleplayer Sandbox game, enter the world, then quit normally.'
Write-Host 'No shop button is expected yet. This tests package startup only.'
Write-Host "Isolated saves and logs: $traitCache"
Push-Location -LiteralPath $GamePath
try {
    & $traitJava '-Djava.awt.headless=true' --enable-native-access=ALL-UNNAMED `
        --add-exports=java.base/jdk.internal.misc=ALL-UNNAMED '-Dzomboid.steam=0' `
        -XX:-CreateCoredumpOnCrash -XX:-OmitStackTraceInFastThrow -Xmx3072m `
        '-Djava.library.path=./natives/;./natives/win64/;./win64/;./' `
        -cp './;projectzomboid.jar' zombie.gameStates.MainScreenState "-cachedir=$traitCache"
    if ($LASTEXITCODE -ne 0) { throw "Game exited with code $LASTEXITCODE; inspect the isolated console log." }
} finally {
    Pop-Location
}
