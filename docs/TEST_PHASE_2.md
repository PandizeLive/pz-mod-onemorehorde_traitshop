# v0.4.3 - four-step button recheck

1. Close the game. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) -> **1**, then launch through Steam and load your existing test character.
2. Open the shop and select an affordable available trait. Purchase stays green after several seconds and when hovering on/off it.
3. Build a valid cart matching your Token balance exactly: Purchase remains green. Add another trait to exceed the balance: Purchase becomes disabled and neutral. Remove that extra trait: green returns.
4. Reset, then select an affordable trait again: green returns and Close retains its red border. Close the shop, quit normally and report **Passed** or the failing step. No actual purchase is required.

Use the existing funded test character shown in the report. If its balance cannot form an exact-price cart, report that check as untested rather than changing currency. After this recheck, proceed to the dedicated player session.
