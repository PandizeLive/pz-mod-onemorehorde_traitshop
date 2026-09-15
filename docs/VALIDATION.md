# Future validation checklist

This checklist defines broader gameplay acceptance expectations. See [CHECKPOINT_1.md](CHECKPOINT_1.md) and [CHECKPOINT_2.md](CHECKPOINT_2.md) for completed startup, state/serialization and dedicated disk tests. Full reward, purchase and creation-screen flows below are not implemented or validated yet.

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
- Hovering reveals the button; moving onto it keeps it usable; clicking opens the shop without breaking health UI.
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
