# OMH: Trait Shop roadmap

This is the active phase/checkpoint roadmap. It organizes the approved product direction; creating the roadmap does not authorize implementation or publication.

**Current status:** Phases 1 and 2 are implemented in v0.3.0. All 53 foundation and 93 Phase 2 game-VM assertions pass; the native dedicated probe verifies purchases, trait effects and receipt recovery across saves/restarts. The owner authorized both Phase 2 checkpoints and deferred live dedicated acceptance until they were implemented. The [complete combined test checklist](TEST_PHASE_2.md) now covers the shop and remaining foundation checks. Checkpoints 5-14 have not started. Checkpoint numbering is sequential across phases, as requested by the owner.

Initial release follows Phase 5 and includes standalone progression, positive-trait purchasing, prestige, optional Horde Night rewards, and official-score integration. Negative-trait removal is Phase 6, after release. This ordering is proposed for execution; changes to scope or checkpoint boundaries should be recorded here.

## Checkpoint workflow

- Resolve only the decisions needed for the upcoming checkpoint. Keep the remaining decisions in [DECISIONS.md](DECISIONS.md); do not silently implement recommendations as approved values.
- Before major implementation, recommend the lowest suitable model/effort and estimate duration. If work could exceed 25 minutes, recommend Fast as requested by the owner. Assess each checkpoint separately rather than promise a duration for the entire project.
- Implement the checkpoint, run its smallest meaningful checks, and report changed behavior, evidence, limitations, and the exact build to test. Use [VALIDATION.md](VALIDATION.md) for the broader acceptance list.
- Give the owner the complete test sequence, prerequisites, expected results and final reporting point together before testing begins. Include required reloads, deaths, replacement characters and restarts up front; do not drip-feed known steps across extra conversation turns.
- Prefer singleplayer for shared rules; use one-player dedicated for authority, persistence, creation, and reconnect; add two players for cross-player behavior. Do not postpone all multiplayer verification until release.
- Batch the remaining Phase 1 owner tests with the Phase 2 acceptance session. Continue source review, game-VM checks and appropriate automated server checks during implementation; defer the live dedicated player session until the shop and purchases are available. Deferred checks remain unverified, not failed or passed.
- Stop at the checkpoint handoff for owner feedback. Use **Test now** only for a verified available build, **Wait for a patch** when a known defect needs correction, or **Decision needed** when an explicit design choice or next implementation authorization is required.
- Record completion evidence below each checkpoint when it actually passes. No release, Git commit/tag, or Workshop state is implied by this document. Follow the target repository's applicable release instructions when preparing builds; external publishing requires explicit authorization.

## Overview

| Phase | Outcome | Checkpoints | Status |
|---|---|---|---|
| 1. Foundation | Loadable standalone package and reliable character/account state | 1-2 | Implemented; combined live acceptance pending |
| 2. Positive trait shop | Usable health-hover entry and safe positive-trait purchases | 3-4 | Implemented in v0.3.0; combined live acceptance pending |
| 3. Progression and prestige | XP rewards, Trait Levels, death resets, and next-character bonuses | 5-7 | Pending |
| 4. Horde Night integration | Horde XP, official lock, persistent eligibility, and score display | 8-10 | Pending |
| 5. Initial release | Verified standalone and OMH builds, documentation, release package | 11-12 | Pending |
| 6. Negative-trait removal | Optional default-off removal with verified effect cleanup | 13-14 | Deferred until after initial release |

## Phase 1 - Foundation

### Checkpoint 1 - Package and integration feasibility

**Deliver:** confirm Mod ID and supported B42 build; create the standalone package using the existing OMH folder conventions. Inspect actual vanilla and reference-mod sources for health UI, character-creation remaining points, trait application, and multiplayer identity. Inspect Horde Night's extension callbacks and identify missing data without modifying the core yet. Document feasible integration paths and any blocker before building dependent systems.

**Selected during implementation:** `OneMoreHorde_TraitShop`, version 0.1.0, `42.20/` layout with metadata minimum 42.20.0; actual installed build 42.20.4. Separate private repository `PandizeLive/pz-mod-onemorehorde_traitshop`; Workshop identity remains unassigned. Do not copy Horde Night's release identity or bundle third-party code unchanged.

**Supporting tooling:** the owner separately authorized a Trait Shop-specific OMH.cmd and private repository. Installer, mirror and publisher preparation is recorded in [RELEASE_TOOLING.md](RELEASE_TOOLING.md). This does not complete later gameplay checkpoints or the initial-release acceptance checks.

**Pass when:** the minimal package loads without Horde Night in singleplayer and dedicated multiplayer; relevant logs are clean; the source-backed feasibility notes establish paths for creation bonuses, remaining-point conversion, UI, and horde facts. A discovered API limitation is a decision/patch issue, not a passed checkpoint.

**Evidence:** [Checkpoint 1 report](CHECKPOINT_1.md). Dedicated startup, compilation, and singleplayer world entry alongside Horde Night/Cure Defense passed. Standalone singleplayer world entry is pending, and pre-creation multiplayer prestige transport remains a conditional source-backed path to validate. The existing horde callback needs additional reward facts in Checkpoint 8. Do not mark full completion from the loader alone.

### Checkpoint 2 - Authoritative state and life identity

**Deliver:** character-life identity, Token wallet, level/XP fields, separate prestige state, versioned persistence, and minimal client state transport. Establish retry-safe initialization and mutation boundaries. Add only the development diagnostics needed to verify this checkpoint; no public reward/admin feature is implied.

**Decisions resolved:** use native server account/slot identity and save/world scope. State distinguishes retained prestige, newly earned prestige, and pending creation grants.

**Implemented:** authenticated multiplayer username/native slot and singleplayer save/local-slot identity; generated life IDs; schema-versioned world state; per-life wallet/XP/level; separate retained/earned/pending prestige; repeat-safe death settlement; read-only client requests and per-player snapshots. Partial XP resets on death. Details and test results: [Checkpoint 2 report](CHECKPOINT_2.md).

**Pass when:** singleplayer save/reload and one-player dedicated reconnect/restart retain the correct state; a replacement life cannot recover the prior wallet; clients cannot assign their own balances. Any diagnostic controls are explicitly development-only and cannot award official progression.

## Phase 2 - Positive trait shop

**Combined live acceptance after Checkpoint 4:** provide one complete owner checklist for standalone loading, health-hover shop access, initial Tokens, positive-trait purchases and effects, save/reload, dedicated reconnect/server restart, death/replacement and replacement reload. Include hosted account binding in the same test plan. Verify a nonzero wallet and purchased trait survive the appropriate reconnect/restart, creation grants do not repeat, and the replacement cannot recover the old wallet. This closes the deferred Phase 1 checks alongside Phase 2 behavior. Prepare exact prerequisites and expected results against the finished build before handing it off.

### Checkpoint 3 - Health-hover entry and progression window

**Deliver:** the custom health-icon hover interaction using the owner's asset, and one window showing Tokens, XP, Trait Level, prestige, and a read-only positive-trait catalog. Clearly distinguish retained and newly earned prestige. Preserve the normal health UI.

**Implemented:** independent health-hover button using the owner's ingame icon; tooltip; scrollable catalog with trait descriptions, server prices and unavailable reasons; separate state totals and responsive window size. Vanilla health behavior is preserved. A separate keybind is not added. Source and test details: [Phase 2 report](PHASE_2.md).

**Pass when:** the pointer can move from the health icon onto the shop button without losing the menu; the window opens/closes correctly at supported UI scales; state updates correctly in dedicated play; relevant competing health-menu mods do not break the interaction.

### Checkpoint 4 - Positive purchases and initial Token grants

**Deliver:** Positive Cost Multiplier, a small verified positive-trait catalog, authoritative purchase validation and actual trait effect activation. Convert unused creation points into starting Tokens once. Protect against duplicate requests and interrupted purchases. Keep negative removal unavailable.

**Implemented:** ten verified native traits; Positive Cost Multiplier default 1.0 with upward whole-Token rounding; authoritative native-budget reconstruction for new-life grants; per-life debit/receipt records, native trait sync and reconnect recovery; schema-1 migration with no retroactive grant. Prestige creation bonuses remain Phase 3, including their contribution to unused creation points. Exclusions stay separate from price controls. The owner authorized all Phase 2 rather than a separate stop between Checkpoints 3 and 4.

**Pass when:** a character with five unused creation points receives five Tokens once and no levels/prestige; purchases consume the correct amount and activate effects; conflicts, duplicates, and insufficient funds are rejected. Singleplayer and one-player dedicated confirm reconnect and interrupted-purchase recovery without free traits or lost payments.

## Phase 3 - Progression and prestige

### Checkpoint 5 - XP conversion, Trait Levels, and death reset

**Deliver:** XP thresholds, one Token per earned Trait Level, one newly earned Prestige Point every five Trait Levels, and death resets. Threshold calculations must handle a reward crossing multiple levels without duplicate milestones. Token grants/spending/refunds never create prestige.

**Decisions needed:** XP requirement/curve. Partial XP, Trait Level and Token reset on death are confirmed and handled by the Phase 1 lifecycle.

**Pass when:** level transitions 4 -> 5 and 9 -> 10 grant exactly one Prestige Point each; multi-level gains grant the expected Tokens and milestones; reload/replayed requests do not repeat awards; death resets the appropriate life fields while preserving the intended next-character prestige entitlement. Verify shared rules and dedicated persistence.

### Checkpoint 6 - Standalone reward sources and mode settings

**Deliver:** Kills and Survival reward sources, the four-mode setting structure, and Hybrid visibility for all six XP categories. Without OMH, explain unavailable horde sources rather than manufacturing rewards. Introduce live reward sources after conversion rules are verified.

**Decisions needed:** standalone default, Zombie and Unique Player XP rates, uniqueness identity/scope, Day/Night Survived rates and timing, and Hybrid kill overlap policy. Horde reward rates are finalized in Checkpoint 8.

**Pass when:** each enabled standalone source awards XP as specified; hidden/disabled sources cannot pay; repeat kills respect the agreed uniqueness scope. Verify survival timing across sleep/time skips and reconnects without duplicate bursts. Use two-player multiplayer for Unique Player attribution and separation of player rewards.

### Checkpoint 7 - Prestige creation bonus and retention

**Deliver:** the full next-character prestige creation bonus, followed by the separate Prestige Retention Percentage setting (default 30%) after successful world entry. Round retention to the nearest whole point; use half-up at exact ties and no minimum-one guarantee. Persist one-time bonus/retention markers through creation cancellation, reconnect, restart, and death.

**Decisions needed:** resolve remaining character-creation integration constraints from Checkpoint 1. Retained-plus-newly-earned prestige as the next bonus total and nearest-whole rounding are agreed; half-up tie handling is the documented convention.

**Pass when:** 3 prestige gives +3 creation points then 1 retained point at Trait Level 0; without new earnings, consecutive lives demonstrate 3 -> 1 -> 0. Spending Tokens never changes this. Canceled creation and repeated load callbacks do not grant twice or decay twice. Verify the sequence in singleplayer and one-player dedicated, with two-player account isolation where needed.

## Phase 4 - Horde Night integration

### Checkpoint 8 - Optional horde XP adapter

**Deliver:** Horde Zombie and Horde Survived XP from authoritative OMH facts. Default new applicable settings to Horde Night when the dependency is detected. Use the narrow existing extension interface where adequate; implement a reviewed core extension only if source evidence requires it. Finish Hybrid routing for horde sources.

**Decisions needed:** both horde XP values and any remaining Hybrid overlap decision; handling of saved settings when enabling/disabling the dependency.

**Pass when:** connected members of their completed horde receive completion XP unless they are casualties; late-connected eligible members can qualify; unrelated players, disconnected players, and casualties do not. Reconnect/respawn cannot undo event casualty status. Two-player testing proves event/kill attribution and no cross-credit or replay awards. The addon still loads and works without OMH.

### Checkpoint 9 - Locked Official Mode and persistent rules history

**Deliver:** a versioned approved Trait Shop preset, authoritative lock enforcement, and persistent run flags for divergent play. Unlocked but matching values remain eligible. Carry relevant custom-rule provenance through prestige and retained benefits; restoring settings must not restore eligibility for affected history. Integrate with existing OMH eligibility rather than replace its other checks.

**Decisions needed:** full official preset, lock default, enabled-mod detection semantics, and the policy for custom-earned prestige/retained advantages at a new official start. Review the new preset explicitly; do not infer it from current sandbox values.

**Pass when:** lock enforcement works beyond the UI; temporary divergent settings flag the run before benefits can be earned; restore/reconnect/restart do not clear the flag; switching modes, resetting runs, or removing/reinstalling the addon cannot silently make custom benefits official. Verify normal OMH eligibility rules still hold.

### Checkpoint 10 - Score multiplier and difficulty-menu breakdown

**Deliver:** Trait Shop x0.50 applied once, multiplicative stacking of score reductions, and a Horde Night difficulty-menu breakdown showing Cure, Trait Shop, combined multiplier, and official eligibility. Use the authoritative calculation for display, export, and leaderboard validation. Identify and prepare any necessary website changes within this checkpoint; publish externally only when explicitly authorized.

**Decisions needed:** only actual core/website integration choices revealed by inspection; the owner's hypothetical 80% and 60% reductions are not new modifier values.

**Pass when:** 100 before Trait Shop becomes 50; illustrative Cure +20% with Trait Shop turns base 100 into 60. Hypothetical 80% and 60% reductions leave 8 in either order, with rounding only at the end. Menu, saved/exported score, and validator agree; counters remain unchanged and historical submissions retain their rules. Required official-path dependencies must be ready before claiming official support.

## Phase 5 - Initial release

### Checkpoint 11 - Complete-flow acceptance and balancing

**Deliver:** one complete verified flow from creation through XP earning, purchases, horde rewards where enabled, death, prestige creation bonus, and retention. Resolve release-blocking bugs and tune explicitly approved values. Document the verified initial catalog and compatibility limits. Negative removal stays unavailable.

**Pass when:** the applicable [validation checklist](VALIDATION.md) passes in standalone singleplayer, hosted multiplayer, and dedicated multiplayer. Use focused two-player scenarios for casualties, unique-player rewards, ownership isolation, and repeated requests. Logs show no unresolved material errors; reward processing and UI updates do not introduce noticeable continuous load. Repeat tests only for changed or unresolved behavior.

### Checkpoint 12 - Release package and owner handoff

**Deliver:** versioned package, install/recovery instructions, accurate README and sandbox documentation, known limitations, and owner-reviewable Workshop assets/description/changelog. Confirm release identities rather than inventing IDs. Include the required Workshop disclaimer: `DISCLAIMER: This mod was made in tandem with ChatGPT`.

**Pass when:** package contents match tested source, a clean installation loads the intended version, required official-score integration is available, and the owner has a concrete release package to review. Publishing is a separate explicitly authorized action; a prepared package is not a published release. Record actual publication and post-publication verification when they occur.

**Initial release boundary:** positive purchases, all agreed reward modes, prestige, and optional official OMH integration are present; negative-trait removal is not required. An earlier reduced release would need an explicit scope decision.

## Phase 6 - Negative-trait removal (after initial release)

### Checkpoint 13 - Removal rules and verified trait support

**Deliver:** decide Negative Cost Multiplier default/rounding and whether to retain the proposed +2 surcharge. Audit removable traits and implement effect cleanup for a small verified set. Document exclusions and any trait-specific initialization/cleanup requirements. Do not expose unsupported traits for sale/removal.

**Pass when:** verified removals actually remove effects in singleplayer and multiplayer, survive reload appropriately, and respect conflicts. The catalog and prices are reviewable; complex traits are either supported with evidence or excluded.

### Checkpoint 14 - Optional UI, official policy, and removal release

**Deliver:** default-off Allow Negative Trait Removal setting, removal UI and transactions, Negative Cost Multiplier controls, and updated compatibility documentation. Review whether/how removal is permitted in the official preset; update rules history and release materials accordingly.

**Pass when:** the default disables removal; enabling it permits only validated removals at the correct prices; duplicate/interrupted requests are safe; official eligibility follows the approved policy. Positive purchasing, progression, prestige, and score regressions pass. Prepare a separate versioned release for owner review.

## Decision timing

| Resolve before | Decisions |
|---|---|
| 1 | Mod ID, supported build, repository setup |
| 2 | Player/account identity and persistence scope - resolved for Phase 1 |
| 4 | Positive multiplier/rounding/catalog; unused prestige-derived creation points |
| 5 | XP thresholds/curve |
| 6 | Standalone default; non-horde reward values; uniqueness; survival timing; Hybrid overlap |
| 7 | Remaining character-creation transport and transaction details |
| 8 | Horde XP values; dependency changes with saved settings |
| 9 | Official preset/lock default; detection; custom-earned prestige and retained-benefit policy |
| 13-14 | Negative multiplier/rounding/+2 surcharge, removable traits, and official removal policy |

No open Phase 6 decision blocks the initial release. No unimplemented checkpoint should be marked complete solely because its design is documented.
