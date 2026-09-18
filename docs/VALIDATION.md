# Future validation checklist

**Current checkpoint:** v0.5.0 implements Checkpoint 5. See [evidence](CHECKPOINT_5_EVIDENCE.txt) and [six-step dedicated follow-up](TEST_CHECKPOINT_5.md). Owner-reported v0.4.3 dedicated purchases passed; real reconnect/restart and the new middle panel remain unverified. The historical checklist below includes planned reward/scoring work, not claims of current functionality.

This is developer coverage tracking, not an owner-facing test script. See [PHASE_2.md](PHASE_2.md) for the foundation and [PATCH_v0.4.0.md](PATCH_v0.4.0.md) for the cart/removal revision. The owner completed that solo test and reported UI changes; [PATCH_v0.4.1.md](PATCH_v0.4.1.md) covers the resize/selection fixes and pending rendered recheck. The owner reported the v0.3.0 solo lifecycle/purchase sequence passed; the reviewed log includes Horde Night, so standalone loading is not independently established by that log. [TEST_PHASE_2.md](TEST_PHASE_2.md) is the current four-step patch test. Dedicated/hosted reconnect/restart, price-rounding, existing-save migration and broader UI/addon compatibility acceptance remain pending; prepare separate 4-8-step instructions when those sessions are selected. Reward earning and prestige creation-screen flows below remain future work.

## Documentation pass

- Verify the README index resolves and the preserved visual reference exists.
- Check that owner decisions, recommendations, deferred work, and open values are distinguished.
- Do not claim a playable build or official eligibility from documentation alone.

## Progression and death

- XP crossing one or multiple level thresholds grants exactly one Token per earned level.
- Levels 4 -> 5 and 9 -> 10 grant exactly one Prestige Point each; replay/reconnect grants no duplicate.
- Granting, spending, or refunding Tokens cannot alter earned prestige or Trait Level; only earned Trait Level milestones generate new prestige.
- Five unused creation points grant exactly five starting Tokens once and no XP, Trait Levels, or prestige.
- Death wipes Tokens and settles prestige once; reconnect, server restart, and repeated death callbacks cannot duplicate settlement.
- Owner example: dying with 3 Prestige Points gives the next character +3 creation points and 1 retained Prestige Point after entering the world, with Trait Level 0.
- Validate repeated retention over at least three lives. Agreed nearest-whole rounding at 30% gives 3 -> 1 -> 0 without new earnings. Verify the documented half-up convention at exact ties and no minimum-one guarantee.
- Validate the separate retention setting, including 0% and 100% if supported, without changing the full bonus offered at that transition.
- Reconnect, canceled creation, repeated spawn callbacks, and crash recovery cannot repeat the bonus or retention step. Do not apply decay both at death and spawn.
- Test retained-plus-newly-earned prestige as the next bonus total. Verify Tokens, Trait Level and partial XP reset on death.

## Rewards

- Every mode shows and uses its intended categories; Hybrid shows all six.
- Horde completion: connected member/non-casualty receives XP; casualty, unrelated player, and disconnected member do not.
- Late connection qualifies when event membership is valid; casualty reconnect/respawn cannot recover eligibility for the old event.
- Replayed completion and kill notifications grant no duplicate XP; separate simultaneous hordes cannot cross-credit players.
- Verify the chosen Hybrid overlap, Unique Player identity, survival timing, sleep, and time-skip rules.

## Shop and UI

- Purchases validate funds, ownership, conflicts, catalog eligibility, and actual trait effects.
- Repeated purchase requests cannot double-spend or grant duplicate traits; failure leaves a recoverable balance/trait state.
- Only health hover reveals the button; hidden button coordinates do not. Moving onto the visible button keeps it usable; clicking opens the shop without breaking health UI.
- Verify all three panels, price ordering, search/filter states, grey inspectable unavailable traits and gold owned/selection styling. A completed purchase transfers selection to the owned positive panel; all current negatives remain inspectable with removal disabled.
- Verify resource tooltip breakdowns, equal Tokens/Prestige emphasis, centered level and gold percentage bar. Modded trait discovery must not bypass effect support or server purchase validation.
- Verify icon scaling and coexistence with reference mods that modify the same UI area.
- Before initial release, negative removal is unavailable. Later, verify default-off toggle, approved price formula, and actual effect removal separately.
- Verify the exact labels Positive Cost Multiplier and Negative Cost Multiplier, their authoritative price calculations, and eventual whole-Token rounding. Keep exclusions separate from price controls.

## Official scoring

- Detection defaults to Horde Night appropriately; standalone mode works without the dependency.
- Locked Official Mode applies authoritative values and rejects conflicting edits.
- Unlocked/matching rules remain eligible; divergent play persistently flags the run, including after restoring the preset and reloading.
- Custom-earned prestige or retained traits cannot bypass eligibility by starting another run or changing settings.
- Score 100 before Trait Shop becomes 50; Cure-only +20% plus Trait Shop turns illustrative base 100 into 60, applied once.
- Hypothetical 80% and 60% reductions produce 8 from 100 in either order (combined 92% reduction), never -40. These are test examples, not approved actual Cure/Trait Shop values. Round only the final result; validate reduction bounds.
- Difficulty-menu breakdown, authoritative score, export, and leaderboard interpretation agree.
- Historical scores retain their original rules; removing the addon does not restore full scoring to an affected run.

## Runtime order

Use the smallest meaningful check: rule-level checks and singleplayer first; one-player dedicated for authority, creation grants, persistence and reconnect; two players only for event membership, casualties, unique-player rewards, and cross-player isolation. Hosted multiplayer should cover any host-specific lifecycle differences. Review relevant logs before declaring a build ready.

Current UI follow-up: [v0.4.2](PATCH_v0.4.2.md) fixes scroll-offset row clipping and updates the footer/XP tooltip. Run the [current solo recheck](TEST_PHASE_2.md), then proceed to the dedicated player session. Dedicated acceptance is still pending.

Current follow-up: [v0.4.3](PATCH_v0.4.3.md) fixes native button color mutation. Its four-step button recheck precedes the dedicated player session.

## Owner acceptance - 2026-09-17

Latest: owner reports v0.5.0 working on dedicated; [SFTP review](DEDICATED_v0.5.0.md) confirms version and resumed settled state. Checkpoint 6 is now implemented as v0.6.0 with 472 behavioral checks, 17-file compilation, 32 release-tooling checks and three native dedicated save/restart cycles. [Evidence](CHECKPOINT_6_EVIDENCE.txt) distinguishes native/fixture coverage from pending [two-player acceptance](TEST_CHECKPOINT_6.md). Survival follows seasonal dawn/dusk, not horde-event hours.

The owner reported **Passed** for the v0.4.3 four-step button recheck. Record this as owner-reported in-game acceptance, separate from automated checks. The dedicated player session remains pending.
