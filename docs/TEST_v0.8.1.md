# v0.8.1 physical traits: short solo test

1. Close the game, run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) -> **1**, then launch through Steam. Enable the local Trait Shop copy (0.8.1).
2. Make a disposable Sandbox character: **Unemployed**, **Weak** (-2 Strength), **Out of Shape** (-2 Fitness); no other traits. Set **Character Free Points = 50** and **Allow Negative Trait Removal = enabled**. Leave cost multipliers at their defaults.
3. In the shop, Stout/Fit should initially conflict. Select removal of Weak and Out of Shape, then add Stout and Fit. Hover the selected traits/receipt: Strength **3 -> 7**, Fitness **3 -> 7**, replacing the negatives with Stout/Fit.
4. Purchase once. Check the character's Skills and Traits: **7 Strength, 7 Fitness**, Stout/Fit present, Weak/Out of Shape absent; Tokens decrease by the receipt total only once.
5. Strong and Athletic should remain unavailable because Stout/Fit conflict. Close/reopen the shop: no extra levels or charges.
6. Quit normally, reload that character, and verify the same stats, traits and Tokens. Quit and report pass/fail for log review.

Dedicated follow-up needs the exact 0.8.1 Workshop update published and loaded first; use the same transaction/reconnect checks with a normal non-admin player. Headless probes do not replace real client transport/anti-cheat acceptance.
