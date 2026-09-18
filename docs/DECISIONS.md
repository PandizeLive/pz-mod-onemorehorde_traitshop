# Decisions and open questions

Recorded September 14, 2026 from the OMH: Trait Shop conversation. New owner instructions supersede these documents; keep the documents consistent when decisions change.

## Confirmed requirements

1. Project home: `C:/Users/bandi/Zomboid_Modding/OMH/Trait Shop`; standalone operation plus optional Horde Night integration.
2. A unified shop and progression window, entered through a custom health-icon hover interaction similar to Trait Purchase System; use the owner's icon and GIF reference.
3. XP fills a level bar. One Token per Trait Level and one Prestige Point every five Trait Levels. Newly earned prestige depends on Trait Level, never Token count.
4. Tokens buy traits and later removals. Prestige Points grant bonus character-creation trait points. These are distinct resources.
5. Tokens wipe and Trait Level resets on death. Unused creation points become starting Tokens once (five unused points -> five Tokens), with no prestige credit because they do not grant Trait Levels.
6. Reward modes: Kills, Survival, Horde Night, Hybrid; six XP reward categories as specified in DESIGN.md.
7. Horde completion rewards require connection at completion of the player's horde and no casualty status for that event. No minimum participation tracking.
8. Horde Night mode defaults on with Horde Night detected and is required for official Trait Shop scoring.
9. Official lock forces the approved settings. Unlocking permits edits; divergent play persistently flags the run. Restoring settings cannot clear the flag.
10. Initial Trait Shop score modifier is x0.50. Multiple reductions multiply their remaining-score factors; never sum the reduction percentages. Round only the final score. Horde Night's difficulty menu must explain modifiers, including Cure and Trait Shop. The owner's 80% and 60% reductions are an illustrative example, not new approved Cure/Trait Shop settings.
11. Negative-trait removal is a later feature, disabled by default when available. Initial release need not include it or complex removal support.
12. Prestige does not remain an undiminished cumulative lifetime total. The next character receives the available prestige as creation points, then retains 30% after entering the world. A separate retention setting controls this percentage. Owner example: 3 points -> +3 creation points and 1 retained Prestige Point.
13. Cost setting names are Positive Cost Multiplier and Negative Cost Multiplier. Exclusions are separate from pricing.
14. Prestige retention rounds to the nearest whole point, with no minimum-one guarantee: 3 -> 1 -> 0 at 30% without new earnings. The documented tie convention is half up for nonnegative values; always rounding upward is rejected.
15. Use sequential Checkpoints 1-14 across the six phases, not dotted phase/checkpoint numbering. The owner authorized Checkpoint 1 implementation.
16. Checkpoint 1 selected `OneMoreHorde_TraitShop` and v0.1.0 for the independent package. Metadata minimum is 42.20.0; dedicated startup and singleplayer world entry alongside Horde Night/Cure Defense verified on 42.20.4. Standalone singleplayer verification remains pending.
17. Use a separate private GitHub repository, `PandizeLive/pz-mod-onemorehorde_traitshop`, as selected by the owner. Adapt the core OMH.cmd workflow for this addon, retaining independent packages, backups, tags, credentials/logs and Workshop identity. Repository creation is authorized; source mirroring and Steam publication remain owner-run menu actions.
18. Install locally through OMH_TraitShop.cmd and launch Project Zomboid normally through Steam. The owner requested removal of the isolated singleplayer launch option and helper; game tests use the normal launch workflow.
19. The owner authorized completion of all Phase 1 after the persistence recommendations were presented. Apply save/server-scoped prestige, reset partial XP with Tokens/levels on death, and combine retained plus newly earned prestige for the next creation bonus. No cross-world transfer.
20. Phase 1 implementation uses the authenticated server username plus native player slot for multiplayer records, and the local player slot within each singleplayer save. Split-screen slots remain separate; changing server login identity starts a separate record. This matches the native dedicated player-profile scope without rounding 64-bit Steam IDs through Lua numbers.
21. Provide complete player test instructions, prerequisites, expected results and the final reporting point up front; do not drip-feed known steps across extra turns.
22. September 15: defer the live dedicated player test until after Phase 2 so it covers shop access, purchases and actual balance/trait persistence along with Phase 1 lifecycle behavior. Batch remaining owner checks into that session. Continue automated and source-based verification during implementation; deferred live acceptance does not block starting Phase 2 and must not be described as passed.
23. The owner authorized full Phase 2 implementation, both Checkpoints 3 and 4, using the three PZ skills and native/decompiled sources. v0.3.0 implements the health-hover shop and positive purchases; the current owner test is TEST_PHASE_2.md.
24. Phase 2 implementation choices: Positive Cost Multiplier defaults to 1.0 (range 0.1-100), prices round upward, and the initial catalog contains ten source-verified native traits requiring only membership effects. The tooltip is included; no additional keybind. Native costs and translations supply presentation. These defaults do not settle the later official scoring preset.
25. Starting-Token conversion applies to new zero-age lives under the new code. Existing characters and migrated v0.2.0 records preserve counters without retroactive grants. Purchase receipts are per-life entitlements used to repair missing native trait membership; restoring full world backups is the supported persistence boundary.
26. Owner testing must use 4-8 short numbered steps per test, with the whole sequence up front. The first Phase 2 handoff was too long; TEST_PHASE_2.md now contains the focused eight-step solo test. Dedicated/hosted and broader coverage remain pending, with short checklists to be prepared for those sessions.
27. Historical v0.3.1 decision (superseded by 29-33 below): the owner reported that solo sequence passed, then approved the three-box UI patch: catalog left, current positive traits upper right, current negative traits lower right. Health-only opening, persistent hover across the visible button, equal Tokens/Prestige prominence, centered Trait Level, gold percentage XP bar, compact descriptions, and tooltip breakdowns replace the first UI. One Prestige number represents retained plus earned; negative removal stays deferred.
28. Discover modded traits through the loaded registry and sort by current Token cost, cheapest first, with alphabetical ties. Visibility does not authorize unsupported effects. v0.3.1 adds an explicit shared membership-only registration hook for verified integrations; it does not certify arbitrary trait packs or infer custom initialization from empty metadata. The current owner handoff is the six-step UI test in TEST_PHASE_2.md.

29. v0.4.0 replaces the preceding UI design with a resizable, unpinned OMH panel; centered red/green branding; gold #E7B428 two-line level; equal Token/Prestige controls; and numeric XP progress. Trait descriptions appear only in tooltips. Positive/negative rows are green/red, unavailable rows grey, selections gold-outlined.
30. One Purchase button checks out a receipt containing additions and removals. Ctrl/Shift multiselection, Reset and Close are approved. Search includes descriptions after name matches, with price sorting inside relevance groups.
31. Level 1 requires 100 XP; the display begins at `0 / 100`. Checkpoint 5 later approves gentle acceleration: round `100 + 35n + (65/19)n²` to the nearest 50 (half-up), where n is current level. Level 20 costs exactly 2,000. Earning rates remain undecided.
32. Negative removal is brought forward into this patch, default-off. Negative Cost Multiplier defaults to 2, prices round up, and the owner explicitly rejected the +2 surcharge.
33. Broad default eligibility replaces the ten-trait allowlist. Common standard effects are processed together; a small reasoned exclusion set covers body progression and known unsupported cases. This does not promise execution of arbitrary mod initialization scripts.

## Open decisions

| Topic | Unresolved choice | Recommendation / impact |
|---|---|---|
| Prestige conversion | Can unused prestige-derived creation points also become starting Tokens? | Confirmed in CP7 scope: yes, without levels or newly earned Prestige. |
| Official prestige provenance | What happens when custom-earned prestige enters a new character/run? | Persist provenance; do not silently treat it as official after changing settings. Decide whether to exclude that prestige from an official start or make the affected run unofficial. |
| Official preset | XP rates/curve, prices, caps, eligible traits, prestige lifecycle and limits, future removal settings. | Must be explicit and versioned; 50% score alone cannot establish fairness. |
| Official lock default | Default enabled with Horde Night? | Recommend yes. Unlocked but matching settings must remain eligible. |
| Custom compatibility | Trait-specific scripts beyond declared effects. | Common effects are implemented in v0.4.0; add targeted adapters for demonstrated incompatibilities. |
| Score detection | Enabled mod versus mere subscription; adding/removing during a run. | Recommend enabled runtime detection plus durable affected-run history. |
| UI conveniences | Optional keybind beyond the implemented hover button and tooltip. | Add only if desired; live scale and competing-popup checks remain in the test plan. |
| Workshop presentation | Final cover, description, visibility and readiness for public release. | Tooling creates a private development item on first owner-run publication; live updates preserve existing presentation. No Workshop ID is invented or borrowed. |

## Superseded proposals

- Unique-player lifetime rewards are replaced by repeatable Player Kill rewards with enemy/faction eligibility and a default 2-in-game-day same-victim cooldown.

- Prestige as 20% of unspent or total earned Token balance is replaced by the confirmed Trait Level milestone model.
- Permanent undiminished prestige accumulation is rejected; a configurable 30% retention rule replaces it. Trait Level resets on death.
- Prestige as next-life shop currency is superseded by bonus character-creation points.
- Carrying unspent Tokens through death is rejected; Tokens wipe.
- Minimum horde attendance or contribution thresholds are rejected; use connected and not-casualty status at completion.
- Assuming the health hover menu is vanilla is rejected; inspect and implement custom UI behavior.
- The earlier post-release-only removal schedule is superseded by approval for v0.4.0.

## Implementation boundary

The owner authorized all Phases 1 and 2 in the [roadmap](ROADMAP.md), plus [release tooling](RELEASE_TOOLING.md) and a private repository. This includes state, lifecycle handling, the shop, purchases and unused-point starting Tokens. The owner additionally approved the v0.4.0 UI/cart, broad compatibility and negative removal update. Reward earning, prestige creation-screen grants, core patches and publication remain outside this implementation. No third-party gameplay implementation is bundled. Remaining prestige conversion details and the official preset still need resolution before their dependent phases.

## v0.4.1 owner-approved UI refinement

- Fix resize anchoring feedback; preserve window position while resizing and drag only from the header.
- Match full leaderboard branding: Small red One More Horde, Large leaderboard-gold Trait Shop. This supersedes the green subtitle above; level/XP gold remains #E7B428.
- Plain clicks toggle cart entries in any source list or receipt. Shift adds eligible ranges; Ctrl is no longer required for multiple choices.
- Ctrl+A adds eligible visible choices in the active purchase/removal list and respects search/filter. Search retains normal text selection. Bulk choices can exceed the wallet or conflict with each other; receipt validation blocks checkout.
- Queued valid negative removals immediately update positive availability and filters. Reversing the removal restores conflicts; final server validation is unchanged.
- Rename the sole launcher to OMH_TraitShop.cmd. Link it in every complete 4-8-step owner test.

## v0.4.2 owner-approved UI patch

- Reset belongs lower-left, with Close then Purchase grouped lower-right. Use Horde Night Difficulty menu colors, but do not copy its upper-right Reset placement. Purchase is green only when checkout is valid.
- Treat the reported missing rows as a scrolling/rendering defect, without presuming resizing causes it. Source investigation confirmed the shared row renderer omitted the scroll offset from its visibility test; fix every trait list and receipt.
- XP tooltip lists source names only, filtered by active mode and positive reward values once Phase 3 implements rewards. Current builds have no XP sources and must say so rather than advertise unimplemented earning methods.
- Finish the UI patch and short solo recheck before the dedicated player test; no dedicated acceptance is implied by automated game-VM checks.

## v0.5.0 / Checkpoint 5 owner approval

- Complete the progression conversion foundation with the approved curve; keep actual reward sources in Checkpoint 6 and prestige creation bonuses in Checkpoint 7.
- Put owned zero-cost traits in **Other Traits**, a read-only middle panel between owned positive and negative lists, retaining description tooltips. This includes profession abilities and weight conditions.
- Carry the first-character starting-Token investigation into this checkpoint. The owner reports fast-forward was paused on connection, which is context rather than proof of cause. Capture creation points using the authoritative native new-game event to avoid relying only on zero survived time at later attachment; preserve existing-character exclusion.
- Record the owner's successful dedicated purchases separately from still-unverified live reconnect/restart acceptance. Keep the next owner test to six complete steps.

## Approved reward defaults after Checkpoint 5

- Ordinary zombie kill: 2 XP.
- Night survived: 25 XP. Day survived: 0 XP.
- Horde zombie kill: 5 XP. Eligible horde completion: 100 XP.
- Player Kill replaces Unique Player and defaults to 75 XP. Only enemies outside the killer's faction qualify. Default cooldown before the same victim can reward again: 2 in-game days.
- Default to Hybrid standalone. The earlier default-to-Horde-Night rule when OMH: Horde Night is detected remains in effect.
- These are design approvals, not implemented rewards or a complete official preset. Survival timing and Hybrid overlap recommendations remain open. Horde reward implementation remains Checkpoint 8.
- Recommended exploit prevention: store cooldowns on the server by directional killer/victim account pair and preserve them across character deaths, reconnects and restarts. Same-faction kills should not pay even if friendly fire is allowed. Treatment of unaffiliated players and recent faction changes remains to be finalized; faction exclusion and cooldown alone cannot prevent colluding enemies from farming rewards.

## Checkpoint 6 implementation approval and timing correction

The owner approved Checkpoint 6 with the documented reward values and Hybrid default. Implementation choices: directional server-account cooldown pairs persist across death/reconnect/restart; players without a shared faction qualify; tagged horde kills are reserved rather than double-paid. Live two-player acceptance remains pending.

The owner explicitly corrected both fixed day/night windows and use of Horde Night event hours. Survival now follows native seasonal dawn/dusk and the host's DayNightCycle, independently of OneMoreHorde.StartHour/EndHour. Complete connected periods qualify; sleep/fast-forward count, partial join/reconnect periods and endless day/night do not. These choices and limits are detailed in CHECKPOINT_6.md. No remote server settings or publication were changed by this implementation.
# v0.6.1: level presentation and feedback

Characters start at displayed Trait Level 1 with 0 / 100 XP toward Level 2. The starting level grants no currency. Saved earned-level counts and the existing XP curve are preserved; five earned levels produce the first Prestige Point at displayed Level 6. Existing characters display their earned count plus one without an XP or currency migration.

Use the owner's `levelup.wav` for normal level-ups and `levelup_prestige.wav` instead when earned prestige increases. Show gold `Trait Level Up!` overhead text. Feedback belongs to the local living character and does not replay on loading/reconnection or duplicate updates. Sandbox category grouping was subsequently approved and implemented in v0.6.3: Trait Costs, XP Rewards and Player Kill Rules, with no empty Prestige section.

## Checkpoint 7 approval and implementation (2026-09-18)

The owner approved full CP7 after the scope recap: creation bonus, unused-point conversion, 30% retention, half-up rounding and one-time persistence. v0.7.0 implements that scope; see CHECKPOINT_7.md for the pre-spawn transport and old-save preview limits. No external publication is authorized by this implementation approval.
