# OMH: Trait Shop roadmap

**Prepared XP integration: 0.9.1.** Adds authoritative optional defense credit, equal assist settlement, offline pending shares and matched client body-state recovery replies. Native death settlement waits for the post-hit callback and outstanding authorized injury receipts. [Patch and verification](PATCH_v0.9.1.md). Coordinated local installation pending; Workshop and connected-player acceptance pending.


This is the active phase/checkpoint roadmap. It organizes the approved product direction; creating the roadmap does not authorize implementation or publication.

**Current status:** Trait Shop 0.9.0 and Horde Night 0.6.16.3 are uploaded and running on the dedicated test server. Checkpoints 1–10 are implemented; the website compatibility update is deployed. Checkpoint 11 awaits the targeted two-player acceptance; Checkpoint 12 documentation/package preparation is complete, with final owner page/visibility handoff after acceptance. See [current evidence](PUBLIC_RELEASE_READINESS.md) and [the final test](TEST_PUBLIC_RELEASE.md). Historical checkpoint notes below retain their original scope and are not new test requests.

Progression, Prestige, Horde Night rewards and official scoring are present. Common negative removal is optional/default OFF; enabling it is Lessened and unofficial under the current Horde Night policy.
## Checkpoint workflow

- Resolve only the decisions needed for the upcoming checkpoint. Keep the remaining decisions in [DECISIONS.md](DECISIONS.md); do not silently implement recommendations as approved values.
- Before major implementation, recommend the lowest suitable model/effort and estimate duration. If work could exceed 25 minutes, recommend Fast as requested by the owner. Assess each checkpoint separately rather than promise a duration for the entire project.
- Implement the checkpoint, run its smallest meaningful checks, and report changed behavior, evidence, limitations, and the exact build to test. Use [VALIDATION.md](VALIDATION.md) for the broader acceptance list.
- Give the owner the complete test sequence, prerequisites, expected results and final reporting point together before testing begins. Include required reloads, deaths, replacement characters and restarts up front; do not drip-feed known steps across extra conversation turns.
- Keep each owner-facing test to 4-8 short numbered steps. No long setup sections, nested lists, repeated-mode matrices or bonus checklists. Keep broader coverage in developer validation notes; provide a complete short sequence for the selected test session.
- Prefer singleplayer for shared rules; use one-player dedicated for authority, persistence, creation, and reconnect; add two players for cross-player behavior. Do not postpone all multiplayer verification until release.
- Batch the remaining Phase 1 owner tests with the Phase 2 acceptance session. Continue source review, game-VM checks and appropriate automated server checks during implementation; defer the live dedicated player session until the shop and purchases are available. Deferred checks remain unverified, not failed or passed.
- Stop at the checkpoint handoff for owner feedback. Use **Test now** only for a verified available build, **Wait for a patch** when a known defect needs correction, or **Decision needed** when an explicit design choice or next implementation authorization is required.
- Record completion evidence below each checkpoint when it actually passes. No release, Git commit/tag, or Workshop state is implied by this document. Follow the target repository's applicable release instructions when preparing builds; external publishing requires explicit authorization.

## Overview

| Phase | Outcome | Checkpoints | Status |
|---|---|---|---|
| 1. Foundation | Loadable standalone package and reliable character/account state | 1-2 | Implemented; solo and dedicated lifecycle evidence recorded |
| 2. Positive trait shop | Usable health-hover entry and safe positive-trait purchases | 3-4 | v0.4.3 implemented; solo button and dedicated replacement-character purchases reported passed; remaining persistence checks and follow-ups carried forward |
| 3. Progression and prestige | XP rewards, Trait Levels, death resets, and next-character bonuses | 5-7 | Implemented; solo and dedicated creation verified; two-account inheritance/reconnect check remains |
| 4. Horde Night integration | Horde XP, Run Options, persistent eligibility, and score display | 8-10 | CP8-10 implemented; API deployed; two-player acceptance remains |
| 5. Initial release | Verified standalone and OMH builds, documentation, release package | 11-12 | Release preparation complete; final two-player test and owner public handoff pending |
| 6. Negative-trait removal | Optional default-off removal with verified effect cleanup | 13-14 | Common removal and official policy implemented; custom adapters remain targeted follow-ups |

## Phase 1 - Foundation

### Checkpoint 1 - Package and integration feasibility

**Deliver:** confirm Mod ID and supported B42 build; create the standalone package using the existing OMH folder conventions. Inspect actual vanilla and reference-mod sources for health UI, character-creation remaining points, trait application, and multiplayer identity. Inspect Horde Night's extension callbacks and identify missing data without modifying the core yet. Document feasible integration paths and any blocker before building dependent systems.

**Selected during implementation:** `OneMoreHorde_TraitShop`, version 0.1.0, `42.20/` layout with metadata minimum 42.20.0; actual installed build 42.20.4. Separate private repository `PandizeLive/pz-mod-onemorehorde_traitshop`; Workshop identity was later assigned as 3803035618. Do not copy Horde Night's release identity or bundle third-party code unchanged.

**Supporting tooling:** the owner separately authorized a Trait Shop-specific OMH_TraitShop.cmd and private repository. Installer, mirror and publisher preparation is recorded in [RELEASE_TOOLING.md](RELEASE_TOOLING.md). This does not complete later gameplay checkpoints or the initial-release acceptance checks.

**Pass when:** the minimal package loads without Horde Night in singleplayer and dedicated multiplayer; relevant logs are clean; the source-backed feasibility notes establish paths for creation bonuses, remaining-point conversion, UI, and horde facts. A discovered API limitation is a decision/patch issue, not a passed checkpoint.

**Evidence:** [Checkpoint 1 report](CHECKPOINT_1.md). Dedicated startup, compilation, and singleplayer world entry alongside Horde Night/Cure Defense passed. Standalone singleplayer world entry is pending, and pre-creation multiplayer prestige transport remains a conditional source-backed path to validate. The existing horde callback needs additional reward facts in Checkpoint 8. Do not mark full completion from the loader alone.

### Checkpoint 2 - Authoritative state and life identity

**Deliver:** character-life identity, Token wallet, level/XP fields, separate prestige state, versioned persistence, and minimal client state transport. Establish retry-safe initialization and mutation boundaries. Add only the development diagnostics needed to verify this checkpoint; no public reward/admin feature is implied.

**Decisions resolved:** use native server account/slot identity and save/world scope. State distinguishes retained prestige, newly earned prestige, and pending creation grants.

**Implemented:** authenticated multiplayer username/native slot and singleplayer save/local-slot identity; generated life IDs; schema-versioned world state; per-life wallet/XP/level; separate retained/earned/pending prestige; repeat-safe death settlement; read-only client requests and per-player snapshots. Partial XP resets on death. Details and test results: [Checkpoint 2 report](CHECKPOINT_2.md).

**Pass when:** singleplayer save/reload and one-player dedicated reconnect/restart retain the correct state; a replacement life cannot recover the prior wallet; clients cannot assign their own balances. Any diagnostic controls are explicitly development-only and cannot award official progression.

## Phase 2 - Positive trait shop

**Live acceptance after Checkpoint 4:** combine foundation and shop behavior in each selected session, using only 4-8 short owner-facing steps. Start with the solo test in TEST_PHASE_2.md; track remaining dedicated/hosted and compatibility coverage in VALIDATION.md. Verify a nonzero wallet and purchased trait survive the appropriate reconnect/restart, creation grants do not repeat, and the replacement cannot recover the old wallet. Give each session's complete sequence and expected results up front without a repeated-mode matrix.

### Checkpoint 3 - Health-hover entry and progression window

**Deliver:** the custom health-icon hover interaction using the owner's asset, and one window showing Tokens, XP, Trait Level, prestige, and a read-only positive-trait catalog. Display one Prestige total, with retained and newly earned components in its tooltip. Preserve the normal health UI.

**Implemented:** v0.4.0 retains health-only hover and adds the resizable three-panel cart, name/description search, equal currencies, gold two-line level and `0 / 100` bar. See [patch report](PATCH_v0.4.0.md).

**Pass when:** the pointer can move from the health icon onto the shop button without losing the menu; the window opens/closes correctly at supported UI scales; state updates correctly in dedicated play; relevant competing health-menu mods do not break the interaction.

### Checkpoint 4 - Positive purchases and initial Token grants

**Deliver:** Positive Cost Multiplier, broad ordinary-trait support with explicit exclusions, authoritative purchase validation and actual trait effect activation. Convert unused creation points into starting Tokens once. Protect against duplicate requests and interrupted purchases. Include the owner-approved optional removal cart.

**Implemented:** generic declared trait effects; default multipliers 1 and 2; whole-cart server validation; starting Tokens; schema 1/2 to 3 migration; recoverable addition/removal/skill/recipe targets. XP and prestige creation bonuses remain Phase 3. Native API/persistence checks pass; live player acceptance remains separate.

**Pass when:** a character with five unused creation points receives five Tokens once and no levels/prestige; purchases consume the correct amount and activate effects; conflicts, duplicates, and insufficient funds are rejected. Singleplayer and one-player dedicated confirm reconnect and interrupted-purchase recovery without free traits or lost payments.

## Phase 3 - Progression and prestige

### Checkpoint 5 - XP conversion, Trait Levels, and death reset

**Deliver:** XP thresholds, one Token per earned Trait Level, one newly earned Prestige Point every five Trait Levels, and death resets. Threshold calculations must handle a reward crossing multiple levels without duplicate milestones. Token grants/spending/refunds never create prestige.

**Approved carry-forward (2026-09-17):** add a compact read-only **Other Traits** panel between owned positive and negative traits. Place owned zero-cost traits there, including profession abilities and weight conditions; retain description tooltips, exclude them from selection/cart actions, and verify the layout and scrolling at small window sizes. Investigate the first dedicated character's skipped starting-Token grant using actual first-join lifecycle evidence. The owner reports MultiplayerFastForwarding was paused on connection; this is context, not proof of cause. Current logs distinguish a skipped first-life settlement from the successful replacement grant but do not establish initial survived time. Fix a demonstrated lifecycle defect without allowing existing characters to claim reconstructed creation points. Include remaining dedicated reconnect/restart and one-time-grant checks in the checkpoint's concise owner test. Do not require another full test of unchanged purchases beforehand.

**Dedicated test context:** replacement character displayed 19 Tokens and the owner confirmed purchases worked. Server settings had `AllowNegativeRemoval=false`; grey removal entries were expected under that setting. Live negative-removal acceptance remains unverified. Source/log findings are recorded in [diagnosis](../../../diagnostics/2026-09-17-traitshop/diagnosis.md).

**Approved curve:** round `100 + 35n + (65/19)n²` to the nearest 50, half-up, where n is the saved earned-level counter (displayed Trait Level minus 1). The current Level 1 bar requires 100 XP and the Level 20 bar requires 2,000 XP; the starting Level 1 itself grants nothing. Compute from the unrounded formula each time. Partial XP, Trait Level and Token reset on death; prestige entitlement persists. See [implementation report](CHECKPOINT_5.md).

**Pass when:** level transitions 4 -> 5 and 9 -> 10 grant exactly one Prestige Point each; multi-level gains grant the expected Tokens and milestones; reload/replayed requests do not repeat awards; death resets the appropriate life fields while preserving the intended next-character prestige entitlement. Verify shared rules and dedicated persistence.

### Checkpoint 6 - Standalone reward sources and mode settings

**Latest handoff (2026-09-17):** owner reports v0.5.0 working on dedicated. [SFTP review](DEDICATED_v0.5.0.md) confirms server/client v0.5.0 and restoration of the existing settled life without a Trait Shop Lua failure. New-character and live progression paths were not exercised in this capture; retain their automated evidence and carry remaining focused live checks forward. Ready to resolve Checkpoint 6 decisions, not a claim that all of Phase 3 is complete.

**Deliver:** Kills and Survival reward sources, the four-mode setting structure, and Hybrid visibility for all six XP categories. Without OMH, explain unavailable horde sources rather than manufacturing rewards. Introduce live reward sources after conversion rules are verified.

**Approved rewards:** Zombie 2 XP, Player Kill 75 XP, Night Survived 25 XP, Day Survived 0 XP. Player Kill replaces Unique Player: only enemies outside the killer's faction, with a default same-victim cooldown of 2 in-game days.

**Approved mode default:** Hybrid standalone; Horde Night when OMH: Horde Night is detected, preserving the earlier dependency rule.

**Implemented in v0.6.0:** authenticated server-account cooldown pairs; no shared faction (including factionless players) qualifies; full connected seasonal day/night periods; horde-tagged zombies are excluded from ordinary rewards to prevent overlap. The owner explicitly corrected the attempted link between survival timing and horde event hours. See [Checkpoint 6](CHECKPOINT_6.md) and [owner test](TEST_CHECKPOINT_6.md). Horde rates are approved for Checkpoint 8; live two-player acceptance is pending.

**Pass when:** each enabled standalone source awards XP as specified; hidden/disabled sources cannot pay; player kills respect faction eligibility and the same-victim cooldown. Verify survival timing across sleep/time skips and reconnects without duplicate bursts. Use two-player multiplayer for kill attribution and separation of player rewards.

**v0.6.4 addition:** Level Rewards exposes Tokens per Level (default 1) and Prestige Level Interval (default 5). Changes affect future level-ups only; interval changes cannot repeat Prestige entitlements. The owner reports the v0.6.3.1 fix working; console.txt confirms Level 5 earned one Prestige with its sound.

### Checkpoint 7 - Prestige creation bonus and retention

**Deliver:** the full next-character prestige creation bonus, followed by the separate Prestige Retention Percentage setting (default 30%) after successful world entry. Round retention to the nearest whole point; use half-up at exact ties and no minimum-one guarantee. Persist one-time bonus/retention markers through creation cancellation, reconnect, restart, and death.

**Implemented in v0.7.0:** creation preview, authoritative budget/settlement, retained Prestige, menu persistence, cancellation/replay protections and inherited-origin tracking. [Source evidence and limits](CHECKPOINT_7.md). Live creation UI and dedicated pre-spawn handshake still require acceptance; use the [short solo test](TEST_CHECKPOINT_7.md) first.

**Correction v0.8.1.1:** dedicated first-join logs proved ordinary ModData responses cannot reach creation before spawning. The new native connection bootstrap supplies the creation bonus before entry; existing respawn refresh and settlement are preserved. See [patch evidence](PATCH_v0.8.1.1.md) and [six-step dedicated regression](TEST_v0.8.1.1.md). Connected-client acceptance remains pending.

**Pass when:** 3 prestige gives +3 creation points then 1 retained point at starting Trait Level 1; without new earnings, consecutive lives demonstrate 3 -> 1 -> 0. Spending Tokens never changes this. Canceled creation and repeated load callbacks do not grant twice or decay twice. Verify the sequence in singleplayer and one-player dedicated, with two-player account isolation where needed.

## Phase 4 - Horde Night integration

### Checkpoint 8 - Optional horde XP adapter

**Deliver:** Horde Zombie and Horde Survived XP from authoritative OMH facts. Default new applicable settings to Horde Night when the dependency is detected. Use the narrow existing extension interface where adequate; implement a reviewed core extension only if source evidence requires it. Finish Hybrid routing for horde sources.

**Approved rewards:** Horde Zombie 5 XP; Horde Survived 100 XP.

**Implemented in v0.8.0:** 5 XP horde kills, 100 XP completion, API 3 core facts and persistent receipt checks. Hybrid pays horde kills once; new settings use dependency-aware defaults and saved modes remain unchanged. See [Checkpoint 8](CHECKPOINT_8.md).

**Pass when:** connected members of their completed horde receive completion XP unless they are casualties; late-connected eligible members can qualify; unrelated players, disconnected players, and casualties do not. Reconnect/respawn cannot undo event casualty status. Two-player testing proves event/kill attribution and no cross-credit or replay awards. The addon still loads and works without OMH.

**Live follow-up (2026-09-21):** owner reports working behavior after v0.8.1.1, with incomplete manual coverage. [Log review and upload baseline](LIVE_v0.8.1.1.md) confirm successful dedicated first-join creation, starting Tokens and death settlement. Carry the unverified inheritance/reconnect/hosted cases into later acceptance; the loading defect is no longer a demonstrated blocker.

### Checkpoint 9 - Run Options and persistent character eligibility

**Implemented in v0.9.0 with Horde Night v0.6.16:** Run Options, server access toggle, verified creation, durable benefits/rules history, and official earning provenance. Locked Official Mode was explicitly rejected. See [implementation and evidence](CHECKPOINT_9.md) and the [six-step local check](TEST_CHECKPOINT_9.md).

**Acceptance:** owner-reported live UI and dedicated lifecycle checks passed after core 0.6.16.3. Automated/native evidence remains in the report. Two-player faction acceptance remains in TEST_PUBLIC_RELEASE.md; ordinary standalone play is supported.

### Checkpoint 10 - Score multiplier and difficulty-menu breakdown

**Implemented and deployed — September 21, 2026:** mod calculation/display/export support and website validation are present. The API passes 55 tests, accepts 0.6.16.3 / 42.20.4 and preserves the existing public record. See PUBLIC_RELEASE_READINESS.md. Final live multiplayer acceptance belongs to Checkpoint 11.

**Deliver:** Trait Shop x0.50 applied once, multiplicative stacking of score reductions, and a Horde Night difficulty-menu breakdown showing Cure, Trait Shop, combined multiplier, and official eligibility. Use the authoritative calculation for display, export, and leaderboard validation. Identify and prepare any necessary website changes within this checkpoint; publish externally only when explicitly authorized.

**Decisions needed:** only actual core/website integration choices revealed by inspection; the owner's hypothetical 80% and 60% reductions are not new modifier values.

**Pass when:** 100 before Trait Shop becomes 50; illustrative Cure +20% with Trait Shop turns base 100 into 60. Hypothetical 80% and 60% reductions leave 8 in either order, with rounding only at the end. Menu, saved/exported score, and validator agree; counters remain unchanged and historical submissions retain their rules. Required official-path dependencies must be ready before claiming official support.

## Phase 5 - Initial release

### Checkpoint 11 - Complete-flow acceptance and balancing

**Deliver:** one complete verified flow from creation through XP earning, purchases, horde rewards where enabled, death, prestige creation bonus, and retention. Resolve release-blocking bugs and tune explicitly approved values. Document the verified initial catalog and compatibility limits. Optional common negative removal is already implemented.

**Pass when:** the applicable [validation checklist](VALIDATION.md) passes in standalone singleplayer, hosted multiplayer, and dedicated multiplayer. Use focused two-player scenarios for casualties, enemy-player rewards/cooldowns, ownership isolation, and repeated requests. Logs show no unresolved material errors; reward processing and UI updates do not introduce noticeable continuous load. Repeat tests only for changed or unresolved behavior.

### Checkpoint 12 - Release package and owner handoff

**Deliver:** versioned package, install/recovery instructions, accurate README and sandbox documentation, known limitations, and owner-reviewable Workshop assets/description/changelog. Confirm release identities rather than inventing IDs. Include the required Workshop disclaimer: `DISCLAIMER: This mod was made in tandem with ChatGPT`.

**Pass when:** package contents match tested source, a clean installation loads the intended version, required official-score integration is available, and the owner has a concrete release package to review. Publishing is a separate explicitly authorized action; a prepared package is not a published release. Record actual publication and post-publication verification when they occur.

**Initial release boundary:** positive purchases, all agreed reward modes, prestige, and optional official OMH integration are present; common negative removal is included, default OFF and unofficial when enabled. An earlier reduced release would need an explicit scope decision.

## Phase 6 - Negative-trait removal and compatibility (common support brought forward)

### Checkpoint 13 - Removal rules and verified trait support

**Implemented in v0.4.0:** default-2 multiplier, upward rounding, no surcharge; common negative removal, body/grant exclusions, and Smoker cleanup. Remaining work is live multiplayer acceptance and adapters for demonstrated custom incompatibilities.

**Pass when:** verified removals actually remove effects in singleplayer and multiplayer, survive reload appropriately, and respect conflicts. The catalog and prices are reviewable; complex traits are either supported with evidence or excluded.

### Checkpoint 14 - Optional UI, official policy, and removal release

**Implemented in v0.4.0:** default-off removal setting, mixed cart and pricing controls, persistence and compatibility documentation. **Official policy implemented:** enabling removal is Lessened/unofficial. Custom trait adapters remain case-specific follow-ups.

**Pass when:** the default disables removal; enabling it permits only validated removals at the correct prices; duplicate/interrupted requests are safe; official eligibility follows the approved policy. Positive purchasing, progression, prestige, and score regressions pass. Prepare a separate versioned release for owner review.

## Decision timing

| Resolve before | Decisions |
|---|---|
| 1 | Mod ID, supported build, repository setup |
| 2 | Player/account identity and persistence scope - resolved for Phase 1 |
| 4 | Positive multiplier/rounding/catalog; unused prestige-derived creation points |
| 5 | XP thresholds/curve - resolved: gentle acceleration, Level 20 = 2,000 |
| 6 | Implementation choices recorded in CHECKPOINT_6.md; owner feedback/live reward acceptance pending |
| 7 | Remaining character-creation transport and transaction details |
| 8 | Dependency changes with saved settings; any remaining Hybrid overlap |
| 9 | Resolved: Run Options, no lock preset, fresh verified characters, durable benefits and unofficial provenance |
| 13-14 | Official removal policy resolved (OFF for official); custom adapters only for demonstrated incompatibilities |

No open Phase 6 decision blocks the initial release. No unimplemented checkpoint should be marked complete solely because its design is documented.

Historical v0.4.2/v0.4.3 UI follow-ups were reported passed. Use TEST_PUBLIC_RELEASE.md for the current remaining test.
