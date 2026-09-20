# v0.8.1.1 - dedicated Prestige regression

Run only after both client and dedicated logs confirm Trait Shop **0.8.1.1**. Publish first using [OMH_TraitShop.cmd](../OMH_TraitShop.cmd), **2 Mirror**, then **3 Publish**; update/restart the server and restart the client through Steam. Keep the existing Horde Night build. Do not reset a valued world or character.

Use the disposable dedicated test world: Hybrid, Zombie XP **7450**, Night XP **0**, Prestige interval **5**, retention **30%**, and default character points. These accelerated settings are deliberately unofficial. Choose Unemployed with no traits for each character below.

1. Join with a fresh test character/account: creation shows **+0 Prestige** and allows entry, without hanging.
2. Kill one zombie: expect **Level 15, Prestige 3**. Avoid further XP during the test.
3. Die: creation shows **+3 points**. Leave the server from creation and reconnect: it must still show **+3** without hanging.
4. Back out/reopen creation once, then enter: expect **Level 1, Tokens 11, Prestige 1**.
5. Disconnect/reconnect the living character: the balances stay the same.
6. Die/create twice without earning XP: first **+1 creation point, Tokens 9, Prestige 0**, then **+0, Tokens 8, Prestige 0**. Quit and report the failed step or pass; review client console and SFTP server logs afterward.

The no-player dedicated probe cannot replace this connected-client check. Hosted multiplayer uses the same connection bootstrap and should receive a focused first-join check before broad release. Existing SP preview behavior is unchanged and covered by the Kahlua regression suite.
