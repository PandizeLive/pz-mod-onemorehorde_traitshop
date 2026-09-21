# Final two-player check

Use the private dedicated test server with **Trait Shop 0.9.0 + Horde Night 0.6.16.3**, already confirmed uploaded. Both players launch through Steam. Local installers, if needed: [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) and [OMH.cmd](../../pz-mod-onemorehorde_protectthecure/OMH.cmd), option 1 while PZ is closed.

1. Join with two accounts. Use a fresh leader with no Prestige/purchases and a member with at least 1 earned Prestige; if needed, earn it at Level 5 first. Keep default Horde Night rewards (5 per horde kill, 100 per completion).
2. The member dies and creates a replacement using the Prestige bonus, then joins the leader's faction. Expect Level 1 / 0 XP and the retained share rounded once (1 Prestige retains 0 at 30%).
3. The leader resets the test run and opens Run Options. Trait Shop must be forced ON, explain the member's Prestige use, and refuse disabling. The member must see the same shared setting.
4. Both survive one normal faction horde. One tagged kill gives its killer 5 XP, not the other player; completion gives each survivor 100 XP. Have the member buy one affordable trait: only their wallet/traits change. Keep the leader free of purchases/Prestige.
5. The member disconnects and rejoins the same character. Expect unchanged progression/traits, no repeated Prestige grant or completion reward, and the shared lock still present.
6. The member leaves the faction. Inspect the existing run: its recorded Trait Shop score reduction/history must remain. Reset a new run with only the clean leader; prior-member benefits must not force that new clean run's shop ON.
7. Both quit normally. Report **pass** or the failing step; I will inspect client/server logs before declaring public-release acceptance.

This is the remaining targeted live check, not a request to repeat previously passed solo UI tests. Do not use your competitive run for the death/reset steps. If you change sandbox rewards or use admin grants to accelerate setup, the resulting unofficial flags are expected; this test does not certify that modified run as Official.
