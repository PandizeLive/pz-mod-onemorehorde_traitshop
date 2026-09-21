# OMH integration and official scoring

> Current policy (2026-09-21): [Checkpoint 9](CHECKPOINT_9.md) supersedes earlier Locked Official Mode planning. Run Options provides Enable Trait Shop, default ON when installed with Horde Night; standalone stays enabled. Existing benefits force access, missing creation provenance is unofficial, and default-or-harder rules retain eligibility.

Status: implemented in Trait Shop 0.9.0 / Horde Night 0.6.16.3. Website compatibility deployed September 21, 2026; [release evidence and remaining live acceptance](PUBLIC_RELEASE_READINESS.md).

## Optional dependency

Trait Shop owns XP, Trait Levels, Tokens, prestige, the shop, and its persistence. Horde Night retains horde lifecycle, ownership, membership, casualty outcomes, kill attribution, run integrity, and score authority. Trait Shop must function without Horde Night and must not duplicate its scheduler or combat ledger.

The core extension API v3 supplies authoritative horde reward facts. The adapter consumes credited horde kills and completion membership/casualty facts, with persistent receipt protection; see CHECKPOINT_8.md and the core `docs/EXTENSION_API.md`.

Horde-completion XP uses the exact event's player membership, connected state, and casualty status. No new attendance timer or minimum contribution requirement. Horde kill XP must use authoritative attribution and exact event/zombie identity, not a nearby-player guess or client-provided count.

## Official eligibility and persistence

- With Horde Night active, default to Horde Night reward mode.
- Only Horde Night reward mode can qualify Trait Shop play for official scores, subject to the default-or-harder baseline and existing OMH checks.
- No Locked Official Mode. Run Options exposes Enable Trait Shop; harder settings remain eligible, easier settings and enabling negative removal persistently disqualify the affected run.
- Returning to official settings never clears that run's flag.
- The multiplier and relevant rules history must survive reconnects, save/reload, and mod/settings changes. Removing Trait Shop cannot erase advantages already received.
- Prestige earned under unofficial rules carries its provenance into later characters. Resetting the run does not make inherited advantages official.
- Horde Night records verified fresh-character creation and benefits in server-owned global ModData, independent of Trait Shop being loaded. Existing characters without proof remain playable but unverified. Acquired trait benefits/Prestige force the shop enabled for the affected character/faction.

The local Horde Night official boundary already captures configuration fingerprints, tags, integrity flags, and score snapshots. Preserve its existing handling of previously eligible score history when integrating persistent Trait Shop flags. Do not rewrite historical submissions.

## Score multiplier

The owner specifies an initial Trait Shop multiplier of **0.50**, applied once after existing score modifiers. A score of 100 before this multiplier becomes 50. This changes score, not recorded kills or completed/survived horde counts.

**Stack reductions multiplicatively, never add their percentages.** For reduction fractions r1 and r2, use `finalScore = scoreBeforeReductions * (1 - r1) * (1 - r2)`. The owner's hypothetical 80% reduction plus 60% reduction yields `100 * 0.20 * 0.40 = 8`: 8% remains, or a combined 92% reduction. It does not produce a 140% reduction or negative score. Applying the larger or smaller reduction first gives the same result; preserve precision and round once at the end. Validate reduction settings within 0-100% rather than accepting negative remaining-score factors.

Those example reductions do not replace the initial Trait Shop x0.50 value or change Cure's existing policy. This requirement concerns stacking score reductions; do not silently redesign unrelated core scoring rules.

Runtime detection checks enabled mods, not mere subscription. A clean character can disable Trait Shop in Run Options; acquired benefits prevent disabling it. Durable affected-run history prevents addon removal from restoring full score.

Local `OMH_ScoreRules.lua` currently lists Cure Run as +20%. With that modifier alone, an illustrative base 100 becomes 120; Trait Shop then yields 60. Use the authoritative calculated modifier set rather than hardcoding this example into UI.

Future tuning must record the applicable scoring rules version. A custom score multiplier cannot claim official equivalence to the approved value.

## Difficulty-menu requirement

**OMH: Horde Night's difficulty menu** displays score modifiers and the resulting multiplier, including Cure and Trait Shop, from authoritative state. Difficulty Settings and Checkpoints are in Run Options.

Show a readable breakdown, for example: Cure +20%; Trait Shop x0.50; combined x0.60 when those are the only modifiers. Also show whether the current run is official and explain any persistent custom-settings flag. The source of the display must be the same calculation used by authoritative scores.

Score exports and the deployed leaderboard validator recognize the modifiers, severe/default-or-harder flags and frozen official boundaries. The API update passed 55 checks; production source/configuration and public endpoints were verified. Existing published records were not rewritten.

## Local evidence and coordination

Reference project: `C:/Users/bandi/Zomboid_Modding/OMH/pz-mod-onemorehorde_protectthecure`.

- `docs/ARCHITECTURE.md`: core/addon boundaries and authoritative event kill ledger.
- `docs/EXTENSION_API.md`: extension capabilities and horde callbacks.
- `Contents/mods/OneMoreHorde_HordeNight/42.20/media/lua/shared/OMH_ScoreRules.lua`: current score representation and Cure modifier.
- `Contents/mods/OneMoreHorde_HordeNight/42.20/media/lua/server/OMH_OfficialScoreBoundary.lua`: score snapshots and eligibility history.

September 14 context check: latest available OMH: Website update concerned the release-date text; OMH: Presentation confirmed the extension API exists and corrected a published documentation link. Neither introduced a known conflict with this design. Tasks named OMH: Horde Night and OMH: Cure Defense were absent from the available task listing. Recheck relevant project work before implementation.
