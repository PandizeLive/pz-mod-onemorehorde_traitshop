# v0.4.0 - cart, removal and broad trait support

The approved patch replaces the pinned shop window and one-trait checkout with an OMH-style resizable panel and one cart for additions/removals. It also replaces the ten-trait allowlist with broad registry-based eligibility and a shared declared-effect processor.

## Player behavior

- Three trait panels; Ctrl/Shift selection within each actionable list; selections in the other panel remain in the cart. Search/filter changes preserve selections. Receipt entries can be clicked to remove them.
- Purchase validates and charges the complete cart. Reset clears choices; Close discards an unpaid cart. No separate Remove button, description footer, or action-button tooltips.
- Centered red One More Horde / green Trait Shop branding. Trait Level label and gold #E7B428 number are on separate centered lines. Tokens and Prestige have equal emphasis and tooltip breakdowns.
- Gold XP bar with centered white `0 / 100`. Level 1 = 100 XP is confirmed; XP earning and later thresholds remain future work.
- Green positive traits, red negatives, grey unavailable traits; gold selection border and subtle green/red fill. Hover shows descriptions only. Checkout issues appear by the receipt.
- Search ranks names before descriptions; ID search remains. Phrase matches beat scattered description words, and price sorts equal relevance. Case and repeated whitespace are ignored.
- Negative removal defaults off. Positive multiplier = 1, negative multiplier = 2; both 0.1-100. Prices round upward, with no additive surcharge.

## Compatibility and transactions

Normal registered positive traits, including modded traits, no longer require individual approval. Common effects include membership, positive starting skill bonuses, XP boosts, recipes, and recursively granted traits. Recipe/skill progress acquired elsewhere is preserved; skill XP within the existing level is retained when increasing levels. Skill grants cap at 10. The installed native registry offers 45 eligible positive traits in the tested build, versus the original ten. This count is eligibility, not a claim that every gameplay effect has been exercised.

Weight, Strength and Fitness traits remain tied to physical progression and are excluded by known IDs and skill metadata. Profession/free traits cannot be purchased; negatives granted by a profession or another owned trait cannot be removed separately. Removing a negative with granted child traits still needs a dedicated handler. Cyclic or contradictory grant plans fail before payment. Compatibility integrations can call `require("OMHTS_Catalog").excludeTrait(id)` in shared initialization. The old `registerMembershipTrait(id)` remains callable but is no longer an approval gate.

Ordinary negative removal deletes membership and adjusts declared XP boosts while preserving learned skill levels and recipes. Smoker has explicit nicotine-withdrawal and smoke-timer cleanup; unrelated stress/unhappiness is not erased. Arbitrary mod-owned initialization, inventory grants or cleanup callbacks are not discovered or replayed automatically. A known incompatibility should get a targeted implementation or exclusion.

The server accepts at most 64 cart lines, recalculates each price, verifies ownership/current settings and the final trait combination, then records one debit/revision and recoverable targets. Removing All Thumbs and buying Dextrous together is supported. Replayed, duplicate, stale, conflicting and underfunded requests do not partially charge. Existing entitlements prevent a second charge even if native membership temporarily lags.

Save schema 3 migrates schemas 1/2 without retroactive grants. Receipts retain additions, removals and effect targets. Recovery restores membership and minimum granted skill XP without stacking bonuses or rewinding later XP. Increasing XP-boost targets can recover an older profile; a reduction only changes the expected prior boost, avoiding overwriting unrelated later modifications. Another mod deliberately removing a purchased trait or lowering granted XP may be counteracted by these persistent entitlements. Native player saves and GlobalModData are separate files; atomic power-loss recovery is not claimed. Full-world backups remain the recovery boundary.

Catalog offers and paid transactions are bounded at 192 per life; a cart has at most 64 lines. Effect records allow 256 memberships, 512 recipe names and 64 skill targets. Trait/skill IDs have a conservative 128-byte UTF-8 bound. Larger catalogs remain visible but traits outside the bounded offer set cannot be bought through this UI; pagination is not implemented. Standard metadata does not certify a custom mod's private behavior.

## Authority and synchronization

SP and dedicated authority use the same validation/effect code. Server-owned balances/receipts remain in GlobalModData, not client-writable player ModData. Native `sendSyncPlayerFields(player, 3)` synchronizes recipes and trait membership. Skill targets travel in the owner's validated shop snapshot and apply on the owner client as absolute targets. A per-character request nonce handshake prevents a late previous-character response from authorizing effects on a replacement character. The generic `SyncXp` helper is not used: in this installed build it is client-only and its native packet requires an administrative capability.

## Source evidence

Three Alex skills were applied: pz-modding-practices, pz-lua-best-practices, pz-multiplayer-42. Shipped Lua has no pcall/xpcall, ipairs, bare next, goto or tabs.

- Installed Build 42.20.4 JAR and matching native runtime; explanatory decompile is 42.20.2 at `references/ProjectZomboid-42.20.2-decompiled/source/zombie`.
- `IsoGameCharacter.applyTraits` includes starting Fitness/Strength and weight initialization; it is not rerun mid-life. `XP.AddXP`, `getPerkBoost` and `setPerkBoost` supply the limited shared processor.
- `LuaManager.transformIntoKahluaTable` retains Java Integer values. Native verification exposed this; values are explicitly converted with `tonumber(tostring(value))` before arithmetic.
- `CharacterTraitDefinition` exposes declared skills, recipes, granted traits and mutual exclusions; `CharacterTraits.add/remove` change membership without replaying creation scripts.
- `BodyDamage.Update` generates nicotine withdrawal while Smoker is present; `Stats.getEffectiveStress` still includes stored withdrawal after membership removal, motivating explicit cleanup.
- `SyncPlayerFieldsPacket` flags 1/2 cover recipes/traits. `LuaManager.SyncXp` and `PlayerXpPacket` explain why that helper is not the server synchronization solution.
- Installed `ISPanel`, `ISResizeWidget` and `ISScrollingListBox`, plus OMH `FullPanel` in `OMH_ScoreboardUI.lua`, ground panel/resize/selection behavior.
- Installed Trait Purchase System was inspected for comparison: registry discovery, exclusions, skill/recipe grants and simple negative membership removal. Its gameplay source is not bundled.
- Actual installed `stdlib.lua` provides table.sort/math helpers despite the older skill note saying no such file exists.

## Verification and limits

See `PATCH_v0.4.0_EVIDENCE.txt` for final command results, native cache paths and package hashes. Checks cover Kahlua compilation, lifecycle/authority, mixed-cart validation, migration, native serialization, declarative effects and recovery, client nonce isolation, search, UI fixtures and health-hover continuity. Native dedicated probes perform three save/restart cycles with real game objects; recipe compatibility is exercised by adding a real recipe to a trait in the disposable test runtime only.

No player joins occur in those probes. They do not establish hosted/dedicated networking acceptance, rendered pixels, or arbitrary mod-pack compatibility. The owner test is [TEST_PHASE_2.md](TEST_PHASE_2.md). No real-profile install, GitHub push or Workshop upload is performed by this patch.
