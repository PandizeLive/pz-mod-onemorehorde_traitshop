# Prestige respawn rendering correction

## Evidence and fix

The September 18 owner test loaded Trait Shop 0.7.0. Its console contains 670 render exceptions at OMHTS_CreationScreen.lua:114. Native CharacterCreationProfession.lua declares `local UI_BORDER_SPACING = 10`; it is not a shared global. Trait Shop now declares its own local constant using the native value. No protected calls or error suppression were added.

The earlier fixture mistakenly supplied that global and did not exercise create(). Removing it reproduced the exact Kahlua error before the fix. The revised fixture checks font arguments, creation list placement, label coordinates and 120 repeated renders, alongside the existing cancellation, response and retention checks. Results: 51 CP7 assertions, 191 foundation/progression/feedback assertions, 19/19 native Lua compilations and the fundamentals audit pass.

The session DebugLog also records a formatting warning for the retention tooltip's literal percent sign. It now says "30 percent". Captured console: `.local/diagnostics/respawn-20260918/console-before-fix.txt`; session source: `C:/Users/bandi/Zomboid/Logs/2026-09-18_17-18_DebugLog.txt`.

The last character reaches life 3 with 10 starting Tokens and a ready client state before the logs stop. No independent JVM crash report or matching Windows Application crash event was found in the locations checked. A native crash cause remains unconfirmed; successful automated fixtures do not establish live UI or multiplayer acceptance.

## Short retest

Use the locally installed 0.7.0.1 and launch through Steam. The launcher remains [OMH_TraitShop.cmd](../OMH_TraitShop.cmd). Horde Night remains 0.6.14.

1. Load the same test save and open the shop; note current Prestige.
2. Die, open character creation, and leave it open for ten seconds; confirm the Prestige label displays without an error counter climbing.
3. Create a replacement, open the shop, then repeat one respawn; confirm both entries complete without a freeze or crash.
4. Quit normally and report the result so the new logs can be checked.

No GitHub push or Workshop upload is performed automatically.
