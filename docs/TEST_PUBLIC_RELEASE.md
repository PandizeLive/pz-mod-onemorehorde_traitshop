# Quick two-player release check

Use the private dedicated test server with **Trait Shop 0.9.0 + Horde Night 0.6.16.3**, already confirmed uploaded. Both players launch through Steam. Local installers, if needed: [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) and [OMH.cmd](../../pz-mod-onemorehorde_protectthecure/OMH.cmd), option 1 while PZ is closed.

1. Use a disposable test save with two fresh characters and no inherited Prestige. Each leaves **4 creation points unspent**: expect **4 Tokens, Level 1**. Join the same faction and start a new run.
2. The leader turns Trait Shop OFF and confirms: neither player can access it. Turn it ON and confirm again: both can open it.
3. Only the member buys one affordable trait. Their Tokens decrease and trait appears; the leader stays at 4 Tokens. Run Options must block disabling Trait Shop and explain the member's benefit.
4. The member disconnects and rejoins the same character. Their trait and Token balance stay unchanged; the faction lock remains.
5. The leader resets the test run with the member still present. Trait Shop must still be forced ON; resetting cannot erase the member's purchase.
6. The member leaves the faction; the leader resets again. The leader can now disable Trait Shop, while the member's own run must still prevent disabling it.
7. Both quit normally and report **pass** or the failing step. I will check client/server logs.

No leveling, death, horde wait or changed XP settings is required. Starting Tokens fund the purchase immediately. Keep the leader free of purchases and use the test save for resets.

This checks creation grants, multiplayer access, purchase/account isolation, reconnect persistence and faction/reset restrictions. It does not newly verify Prestige inheritance/retention, horde reward ownership or casualty handling; those retain their existing automated/earlier evidence and live-coverage limits. A pass is not a claim of exhaustive multiplayer acceptance.
