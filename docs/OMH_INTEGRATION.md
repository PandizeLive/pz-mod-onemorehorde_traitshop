# OMH integration and official scoring

> Current policy (2026-09-21): [Checkpoint 9](CHECKPOINT_9.md) supersedes earlier Locked Official Mode planning. Run Options provides Enable Trait Shop, default ON when installed with Horde Night; standalone stays enabled. Existing benefits force access, missing creation provenance is unofficial, and default-or-harder rules retain eligibility.

Status: required future integration; no Horde Night or website files changed by this documentation pass.

## Optional dependency

Trait Shop owns XP, Trait Levels, Tokens, prestige, the shop, and its persistence. Horde Night retains horde lifecycle, ownership, membership, casualty outcomes, kill attribution, run integrity, and score authority. Trait Shop must function without Horde Night and must not duplicate its scheduler or combat ledger.

The existing local `docs/EXTENSION_API.md` describes API v2 and the `hordeEvents` capability with authoritative `onStarted` / `onFinished` callbacks. This is a candidate integration point, not proof that today's callback payload contains all reward data. Verify the live source and payload before implementation; add a narrow core hook only where necessary.

Horde-completion XP uses the exact event's player membership, connected state, and casualty status. No new attendance timer or minimum contribution requirement. Horde kill XP must use authoritative attribution and exact event/zombie identity, not a nearby-player guess or client-provided count.

## Official eligibility and persistence

- With Horde Night active, default to Horde Night reward mode.
- Only the Horde Night reward mode can qualify Trait Shop play for official scores, subject to the complete approved preset and existing OMH checks.
- Offer Locked Official Mode to enforce the preset. Unlocked but matching settings remain eligible; actual divergent play adds a persistent run flag.
- Returning to official settings never clears that run's flag.
- The multiplier and relevant rules history must survive reconnects, save/reload, and mod/settings changes. Removing Trait Shop cannot erase advantages already received.
- Prestige earned under custom rules can affect a later character even after the original run ends. Its provenance must remain visible to eligibility checks; exact next-character treatment is an open policy decision, not solved by a per-run flag alone.
- Starting a fresh official run while retaining custom-rule purchased traits or prestige must not silently restore eligibility. Define the approved reset boundary before release.

The local Horde Night official boundary already captures configuration fingerprints, tags, integrity flags, and score snapshots. Preserve its existing handling of previously eligible score history when integrating persistent Trait Shop flags. Do not rewrite historical submissions.

## Score multiplier

The owner specifies an initial Trait Shop multiplier of **0.50**, applied once after existing score modifiers. A score of 100 before this multiplier becomes 50. This changes score, not recorded kills or completed/survived horde counts.

**Stack reductions multiplicatively, never add their percentages.** For reduction fractions r1 and r2, use `finalScore = scoreBeforeReductions * (1 - r1) * (1 - r2)`. The owner's hypothetical 80% reduction plus 60% reduction yields `100 * 0.20 * 0.40 = 8`: 8% remains, or a combined 92% reduction. It does not produce a 140% reduction or negative score. Applying the larger or smaller reduction first gives the same result; preserve precision and round once at the end. Validate reduction settings within 0-100% rather than accepting negative remaining-score factors.

Those example reductions do not replace the initial Trait Shop x0.50 value or change Cure's existing policy. This requirement concerns stacking score reductions; do not silently redesign unrelated core scoring rules.

Working interpretation of installed: enabled in the running game/server, not merely subscribed on disk. This clarification was recommended and should be confirmed when implementing detection. Persist use within the affected run to prevent removal restoring full score.

Local `OMH_ScoreRules.lua` currently lists Cure Run as +20%. With that modifier alone, an illustrative base 100 becomes 120; Trait Shop then yields 60. Use the authoritative calculated modifier set rather than hardcoding this example into UI.

Future tuning must record the applicable scoring rules version. A custom score multiplier cannot claim official equivalence to the approved value.

## Difficulty-menu requirement

Update **OMH: Horde Night's difficulty menu** to display score modifiers and the resulting multiplier, including Cure gamemode and Trait Shop. This is a required future core change, not an addon-only label.

Show a readable breakdown, for example: Cure +20%; Trait Shop x0.50; combined x0.60 when those are the only modifiers. Also show whether the current run is official and explain any persistent custom-settings flag. The source of the display must be the same calculation used by authoritative scores.

Score exports and leaderboard validation/display must agree with the new modifier and rules version. Inspect existing paths first; record any necessary coordinated website work before official support ships. No external publishing is authorized by this docs request.

## Local evidence and coordination

Reference project: `C:/Users/bandi/Zomboid_Modding/OMH/pz-mod-onemorehorde_protectthecure`.

- `docs/ARCHITECTURE.md`: core/addon boundaries and authoritative event kill ledger.
- `docs/EXTENSION_API.md`: extension capabilities and horde callbacks.
- `Contents/mods/OneMoreHorde_HordeNight/42.20/media/lua/shared/OMH_ScoreRules.lua`: current score representation and Cure modifier.
- `Contents/mods/OneMoreHorde_HordeNight/42.20/media/lua/server/OMH_OfficialScoreBoundary.lua`: score snapshots and eligibility history.

September 14 context check: latest available OMH: Website update concerned the release-date text; OMH: Presentation confirmed the extension API exists and corrected a published documentation link. Neither introduced a known conflict with this design. Tasks named OMH: Horde Night and OMH: Cure Defense were absent from the available task listing. Recheck relevant project work before implementation.
