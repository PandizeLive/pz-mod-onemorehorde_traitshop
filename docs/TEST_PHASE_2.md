# v0.4.2 - five-step solo recheck

1. Close the game. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) -> **1**, then launch through Steam and load your existing Trait Shop test character.
2. Open the shop at its initial size. Scroll the positive list from top to bottom: later entries should remain visible, with no unexplained blank area. Repeat after shrinking and enlarging the window.
3. Select several traits to fill the receipt, then scroll it to the last entry. Rows remain visible; clicking an entry still removes it. Reset clears the cart without changing your character.
4. Check Reset at lower-left and red Close then Purchase at lower-right. Select an affordable available trait: Purchase turns green; Reset returns it to disabled grey. Hover XP: it lists no amounts and says no sources are available in this build.
5. Close and reopen the shop: cart is empty and scrolling still works. Quit normally and report **Passed**, or the failing step. The next session is the dedicated player test.

No purchase or new character is required for this UI recheck. If the current character cannot afford any trait, report that part as untested; do not generate currency. Dedicated setup and its complete 4-8-step sequence will be handled together after the solo check.
