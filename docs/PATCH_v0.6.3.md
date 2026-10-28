# v0.6.3 — Sandbox sections

Trait Shop sandbox settings now have three large, centered white headings matching Horde Night's native section style:

- **Trait Costs:** Positive Cost Multiplier, Negative Cost Multiplier, Allow Negative Trait Removal.
- **XP Rewards:** Reward Mode and the reward amounts applicable to that mode.
- **Player Kill Rules:** Player Kill Cooldown; the whole section hides in Survival and Horde Night modes.

No empty Prestige section is added before its settings exist. The cooldown moves below all XP rewards. Option identifiers, defaults, tooltip wording, server authority and saved values remain unchanged.

The existing Trait Shop panel attachment creates native ISLabel children. It uses the same Large font, white color, centering and section spacing as `SandboxOptionsScreen.createPanel` and the host editor's `createPanel` in the installed 42.20.4 Lua. The live admin builder lacks native section titles, so the same attachment supplies them there. Headers participate in scroll height but not controller focus. Resizing recenters them without resetting scroll; changing modes resets to the top and rebuilds visible controller rows. Other mods' panels are untouched.

Verification: 167 Checkpoint 6 reward/sandbox assertions pass, including section placement, visibility in all four modes, resize/scroll behavior, duplicate attachment, three menu entry points and unrelated-panel isolation. All 17 shipped Lua files compile and the no-pcall fundamentals audit passes. The 140 lifecycle/level-feedback assertions also pass. Native visual acceptance remains owner-run.

## Test now

1. Close the game and run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) → 1. Launch through Steam and open Trait Shop's sandbox page in new-world or host setup.
2. Select Hybrid: expect Trait Costs, XP Rewards and Player Kill Rules, with the cooldown last and no overlaps.
3. Switch to Survival, Horde Night, then Kills: expect matching XP fields; Player Kill Rules appears only for Kills/Hybrid. Scroll to the final setting in each mode.
4. Switch back to Hybrid, save and reopen the settings. Confirm values persist and report any missing headers or overlap. Then continue the previously supplied level-up test.

For the dedicated admin check, upload v0.6.3 and restart the server first, then perform steps 2–4 in its sandbox menu. No agent upload or local install is implied.
