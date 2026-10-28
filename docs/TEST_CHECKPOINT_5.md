# v0.5.0 - dedicated follow-up

Owner acceptance is pending. XP conversion is checked by game-VM tests and native dedicated probes; kills/survival do not earn XP until Checkpoint 6. This test covers the UI, real connection path, and previously outstanding purchase persistence.

1. Close the game. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) -> **1**, then launch through Steam and update the existing Workshop item **3803035618** through **Workshop -> Create/update items**. Use [the Steam-formatted changelog](WORKSHOP_v0.5.0.txt).
2. Stop the test server, update its Workshop download to **v0.5.0**, and enable **Allow Negative Trait Removal**. Leave cost multipliers at **1 / 2**, then start it. Preserve the current test save.
3. Rejoin your existing purchased character. Check its traits and remaining Tokens persisted; owned zero-cost traits now appear in **Other Traits**. Clicking them or pressing Ctrl+A there must not add anything to the receipt.
4. Shrink and scroll the shop: all lists remain usable. Then let this test character die, disconnect, and reconnect to create a replacement with **All Thumbs**, leaving at least **12 unused points**. Record that total; let the loading/entry screens finish normally with your existing fast-forward setup.
5. Open the shop: Tokens must equal those unused points, with Level **0** and XP **0 / 100**. Queue All Thumbs removal and Dextrous together and purchase. Record the resulting balance and traits.
6. Disconnect and reconnect; verify the recorded balance and traits. Disconnect again, stop the server normally, restart it, reconnect and verify them again. Quit normally and report **Passed** or the failing step; logs now include captured points, starting grant status and survived time.
