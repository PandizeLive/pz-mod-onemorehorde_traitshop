# v0.6.2 — Level-up reward lines

The overhead message now reads `Trait Level Up!`, followed by `+1 Token`, and `+1 Prestige` when earned. Multiple earned levels in one authoritative update display their actual Token and Prestige totals. Token gains come from the earned-level delta rather than wallet changes, so purchases or other grants cannot distort the receipt.

The native halo keeps its Small font and gold color, with explicit line breaks. A smaller secondary font is not implemented: `TextDrawObject.readTag` permits only one open formatting tag, so nesting font tags inside HaloTextHelper's color tag would display invalid markup. This retains native queuing and avoids replacing unrelated overhead messages.

Verification: 17 shipped Lua files compile; 140 lifecycle/feedback assertions pass, including reward amounts for both singleplayer and multiplayer batches and quiet duplicate/reconnect behavior. Translation keys use native numeric placeholders. The v0.6.1 sound assets and Level 1 behavior are unchanged.

Use the complete six-step test in [PATCH_v0.6.1.md](PATCH_v0.6.1.md), installing v0.6.2. Step 3 should show `+1 Token`; step 4 should also show `+1 Prestige`. Native appearance remains owner-tested. No upload or installation is implied.
