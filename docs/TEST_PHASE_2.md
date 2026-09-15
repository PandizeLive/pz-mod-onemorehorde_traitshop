# Test now - v0.3.0 complete checklist

This is the complete owner test plan for the remaining Phase 1 checks and Phase 2. Read the setup and sequence before starting; report once at the end, including anything you could not run. No further known reload/death steps are being held for a later turn.

## Setup

1. Close Project Zomboid. Run this addon's **OMH.cmd -> 1** to install v0.3.0, then launch normally through Steam. There is no special game-launch option. Use B42.20.4 and disposable test worlds/characters; the sequence deliberately includes death.
2. For the standalone pass, enable only **OMH: Trait Shop**. Leave **Positive Cost Multiplier = 1.0**, **CharacterFreePoints = 0**, and **NegativeTraitsPenalty = none**. Select **Unemployed** with no chosen traits. The creation screen should show **8 unused points**. If it shows a different number, record that number and the settings before entering.
3. For multiplayer, install the exact same v0.3.0 package on the test server under its `Zomboid/mods` directory and enable `OneMoreHorde_TraitShop` in its `Mods` setting. There is no Workshop item ID yet. Use the same account and player slot for reconnects. Keep the server's normal save/restart controls available.
4. XP earning, prestige creation bonuses, negative-trait removal and Horde Night score penalties are not active. Use test worlds rather than official-score runs.

## Run this sequence in standalone, then dedicated, then Steam-hosted play

1. **Create and inspect.** Enter with the character above. Hover over the health icon, move onto the new shop icon, and click. Expect eight Tokens; level, XP and prestige all zero. The normal health button must still work. Select several traits and check descriptions, prices and scroll behavior.
2. **Purchase and reject.** Buy Dextrous for two Tokens, then Organized for four. Expect **two Tokens remaining** and both traits on the native character information panel. Owned entries must be unavailable for another purchase. Brave costs four and must be unavailable with only two Tokens. Repeated clicking must not charge again. Organized should increase the capacity available in an ordinary bag/container; the character's own main inventory is not a suitable capacity test.
3. **Reload/reconnect.** Quit the world normally in solo, or disconnect in multiplayer, then return to the same character. Expect the same two Tokens, both purchased traits and the same logged life ID. The starting eight Tokens must not be granted again.
4. **Restart persistence.** Solo: quit the game completely, relaunch through Steam and reload. Multiplayer: disconnect, save/stop the test server normally, restart it, then reconnect. Expect the same balance and purchased traits. Use the same sequence for the Steam-hosted server through its normal Host workflow.
5. **Death and replacement.** Let this test character die. Create another Unemployed character in the same save/account/slot, this time selecting only All Thumbs. With the settings above, the creation screen should show **10 unused points**. Expect ten starting Tokens, no inherited Dextrous/Organized, and a new logged life ID. Dextrous must show a conflict with All Thumbs and remain unavailable. This must not silently remove the negative trait.
6. **Replacement purchase and reload.** Buy Fast Reader for two, leaving **eight Tokens**. Quit/reconnect, then perform one normal full game/server restart and return again. Expect eight Tokens, Fast Reader, All Thumbs and the same replacement life ID. Neither the initial grant nor the old wallet should be recovered again.
7. **UI lifecycle.** Close/reopen the shop. Change sidebar size and font/UI scale through the normal options, then open it again. The button should remain beside health, the shop should stay usable, and duplicate windows or orphan icons should not appear. Return your UI settings to their preferred values.

The dedicated and hosted passes use ordinary player privileges. Admin tools must not be required for buying traits.

## Finish with these short checks

- **Price rounding:** create a separate solo test world with **Positive Cost Multiplier = 1.25**. Unemployed/no traits still gives eight Tokens. Dextrous should cost three and Organized five. Buy both and expect zero remaining; reload once and verify. This tests the new setting and whole-Token rounding together.
- **Existing save migration:** load the disposable v0.2.0 Phase 1 character previously tested. Expect its previous life and balance preserved, no retroactive starting grant, and a usable shop. The window explains that starting conversion applies to new characters. Save and reload once.
- **Addon compatibility:** in a disposable test world, enable Horde Night/Cure Defense and repeat shop opening, one affordable purchase and a reload. If you intend to use Trait Purchase System alongside this addon, also check pointer movement across its hover popup into this shop icon. Record competing-mod/UI failures separately.

## Report once

Report solo/dedicated/hosted outcomes, starting and final balances, any unavailable part of the checklist, and any UI or purchase problem. Keep the normal client `Zomboid/console.txt` and corresponding server logs for review. Multiple game launches can rotate logs; preserve the relevant logs for each completed mode if you will continue into another mode before reporting.

Expected log progression: `v0.3.0`, `authority ready; schema=2`, `state created`, then `state resumed` for the same life; one `death settled` before a replacement's different life ID; `client state ready` for the matching life. Gameplay checks above establish the visible balance and trait effects. Empty error counters alone do not prove persistence or correct pricing.
