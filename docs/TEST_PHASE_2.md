# v0.4.1 - seven-step solo test

1. Close Project Zomboid. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd), choose **1**, then launch normally through Steam with only Trait Shop enabled.
2. Start a new Sandbox with **20 Free Trait Points**, **negative removal enabled**, Unemployed and **All Thumbs**. Leave the remaining points unused for shop Tokens.
3. Open the shop from the health icon. Move it by its header, then resize wider/narrower and taller/shorter. Hold the pointer still mid-resize: no jitter or drifting. Check the small red brand and larger gold Trait Shop title.
4. Plain-click two available positives: both stay in the receipt. Click one again, then the other's receipt entry: each disappears. Shift-click a range: several eligible traits queue. Reset.
5. Click the positive list and press Ctrl+A: eligible visible rows queue. Reset, search `fast`, then click a result and press Ctrl+A: only matching eligible positives queue. Ctrl+A inside search selects text instead. Clear search and Reset.
6. Click All Thumbs in Your Negative Traits and press Ctrl+A: eligible negatives queue. Dextrous becomes available. Click All Thumbs again: Dextrous returns grey. Queue All Thumbs and Dextrous together.
7. Purchase that pair, note Tokens, then quit and reload. Dextrous, removed All Thumbs and the balance persist. Report **Passed**, or the step and unexpected behavior.

Broader multiplayer and compatibility coverage remains in VALIDATION.md; no additional solo sequence is implied by this test.
