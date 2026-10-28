# Quick two-player release check

**Acceptance recorded September 21:** owner reports the latest test passes; final console/SFTP logs reviewed. Both patch uploads below are now confirmed. Keep this checklist for future regressions; no repeat is requested.

**Wait for both patch uploads:** Trait Shop **0.9.0.1** and Horde Night **0.6.16.4**. In [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) and [OMH.cmd](../../pz-mod-onemorehorde_protectthecure/OMH.cmd), use option 2 (Mirror), then 3 (Publish). Restart the private server and launch through Steam after both updates download. No XP grind is needed.

1. Use two fresh characters with no inherited Prestige, leaving **4 creation points unspent** each: expect **4 Tokens, Level 1**. Join the same faction, keep default Trait Shop rules and reset the run. Old test characters retain their recorded flags.
2. The leader turns Trait Shop OFF and confirms: neither player can access it. Turn it ON and confirm again: both can open it.
3. Only the member buys one affordable trait; the leader stays at 4 Tokens. Run Options locks Trait Shop ON. Hover the gold **1 participating character(s)**: only the member's username appears, with no zero-Prestige sentence.
4. The member disconnects and rejoins the same character. Their trait and Token balance stay unchanged; the faction lock remains.
5. The leader resets the run with the member present. The lock/name and 50% reduction remain, but **Trait Shop Lessened must not appear** from this purchase. Other existing server-rule flags are separate.
6. The member leaves the faction; the leader resets again. The leader can now disable Trait Shop, while the member's own run must still prevent disabling it.
7. Both quit normally and report **pass** or the failing step. I will check client/server logs.

No leveling, horde wait or changed XP settings is required. Starting Tokens fund the purchase immediately. Keep the leader free of purchases and use the test save for resets. This retest needs fresh characters because the previous build already saved incorrect flags on both tested characters; the patch does not rewrite historical flags.

This checks creation grants, multiplayer access, purchase/account isolation, reconnect persistence and faction/reset restrictions. It does not newly verify Prestige inheritance/retention, horde reward ownership or casualty handling; those retain their existing automated/earlier evidence and live-coverage limits. A pass is not a claim of exhaustive multiplayer acceptance.
