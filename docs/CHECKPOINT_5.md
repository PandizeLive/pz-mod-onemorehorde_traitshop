# Checkpoint 5 - v0.5.0

Implements the approved progression foundation, Other Traits panel, and starting-Token investigation follow-up. Player-facing reward sources remain Checkpoint 6; prestige creation bonuses/30% retention remain Checkpoint 7. No client XP-award command, admin currency control, or invented kill reward was added.

## Curve and awards

For current Trait Level n, the next level costs `floor((100 + 35n + (65/19)n*n) / 50 + 0.5) * 50`. Values come directly from the unrounded formula. Reaching Level 20 costs exactly 2,000 XP; the formula continues beyond 20.

Levels 1-20: **100, 150, 200, 250, 300, 350, 450, 500, 600, 700, 800, 900, 1,000, 1,150, 1,250, 1,400, 1,550, 1,700, 1,850, 2,000**. These are per-level requirements, not lifetime totals.

`OMHTS_Progression.requiredXP/advance` supplies shared calculations. Server-only `Authority.awardXP(player, lifeId, revision, amount)` validates the current life and expected revision, then `State.awardXP` atomically updates remainder XP, levels, Tokens and earned prestige. One Token is awarded per newly reached level; prestige is the difference between old/new five-level milestone counts. It validates numeric bounds before committing. Replaying the same revision fails. Future source adapters must deduplicate their own source events before obtaining a fresh revision; revision checks do not make a freshly constructed duplicate source event unique.

Starting Tokens and purchases do not earn prestige. Death clears Tokens, level and partial XP, preserving next-character prestige entitlement once. The UI includes pending prestige in its single total so entitlement does not disappear after death; it explicitly says applying this to character creation is still upcoming. The XP bar uses the actual next-level threshold. Its tooltip continues to report no active XP sources.

## Other Traits

Owned zero-cost traits appear in a neutral read-only list between positive and negative traits, including High/Low Weight and profession abilities such as Burglar. Description tooltips remain. Clicking, Shift selection and Ctrl+A cannot add these rows to the cart; their zero cost is not a free purchase/removal entitlement. The middle panel holds up to two rows before scrolling at normal sizes and shares available space at minimum dimensions. It does not change native trait effects or removal eligibility.

## First-join investigation

The owner's first v0.4.3 dedicated character bound at revision 1, while its replacement bound at revision 4, showed 19 Tokens, and successfully purchased traits. The first grant was skipped; the old authority did not log survived hours. The owner reports MultiplayerFastForwarding was paused during connection. That does not establish the precise historical clock value or prove that mod caused the problem. Active server settings also had `AllowNegativeRemoval=false`, explaining grey removal rows.

Source inspection found a timing dependency: v0.4.3 initialized creation only when `hours == 0`, but authority binding occurs later through a one-second scan or a client state request. `CreatePlayerPacket.processServer` applies traits/recipes, sets username, fires **OnNewGame**, then saves the new native profile. `GameServer.receivePlayerConnect` later reloads that profile and adds a different player object to the connected list. Object identity cannot carry a creation receipt between those stages.

v0.5.0 captures remaining creation points during the authority-side OnNewGame event, keyed by username and descriptor ID (local slot and descriptor in singleplayer). It stores only a numeric receipt under the existing server-owned global state, not client-writable player ModData. Binding matches that receipt to the authenticated account/character, grants it once even when survived time is positive, then consumes it. A failed calculation captures an invalid sentinel so it cannot later reconstruct a different budget. Pending captures survive normal world save/restart. Existing nonzero-age characters without capture evidence remain ineligible. The existing zero-age fallback remains for initial attachment when no capture exists. This update does not retroactively restore the first failed character's balance.

Schema 3 record and network shapes remain unchanged; initialization adds/validates an optional top-level `creations` receipt map for older saves. Duplicate creation callbacks and reloads do not add Tokens to an already settled life. Server logs now include capture amount, initial survived hours, creation status and starting Tokens for future diagnosis.

## Source evidence and verification

Applied Alex's PZ modding, Lua and Build 42 multiplayer skills. Shipped code retains the no-pcall/xpcall/ipairs/next/goto/tabs audit and explicit requires. Installed Build **42.20.4** `CreatePlayerPacket` bytecode confirms OnNewGame placement after trait application and username assignment, before native profile saving. Readable source: `references/ProjectZomboid-42.20.2-decompiled/source/zombie/network/packets/character/CreatePlayerPacket.java (processServer)`; `GameServer.java (receivePlayerConnect)`; `SurvivorDesc.java (save/load)` preserves descriptor ID. Native generated `character_traits.txt` and UI translations establish the zero-cost weight/profession cases.

Automated evidence and native dedicated results are recorded in [CHECKPOINT_5_EVIDENCE.txt](CHECKPOINT_5_EVIDENCE.txt). The native probe invokes the real event on native IsoPlayers and performs disk save/restart cycles; no human player joins it, so it does not establish end-to-end network acceptance or actual rendered layout. Use [the six-step owner test](TEST_CHECKPOINT_5.md) for those remaining checks. Remote server configuration and Workshop publishing remain owner-run.
