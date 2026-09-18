# Sandbox options specification

As of v0.7.0, settings are grouped under **Trait Costs** (multipliers and removal toggle), **Level Rewards** (Tokens per Level and Prestige Level Interval), **XP Rewards** (mode and applicable rates), and **Player Kill Rules** (cooldown, shown in Kills/Hybrid). The latter section follows all XP rates. These headers appear in solo setup, host setup and the live admin menu. **Prestige** now contains Prestige Retention Percentage.

Positive Cost Multiplier, Negative Cost Multiplier and Allow Negative Trait Removal are implemented in v0.4.0; reward modes and standalone sources are implemented in v0.6.0; Prestige creation bonuses are implemented in v0.7.0; horde XP remains Checkpoint 8. Reward XP defaults below are approved. Caps and the complete official preset remain undecided. The owner has specified the initial 0.50 score multiplier and 30% prestige retention default.

| Setting | Behavior / default | Status |
|---|---|---|
| Locked Official Mode | When enabled, force the official Trait Shop preset, including Horde Night rewards; prevent edits to governed values. | Owner-requested behavior; label and default pending. |
| Reward Mode | Kills, Survival, Horde Night, Hybrid. Default Hybrid standalone; default Horde Night when OMH: Horde Night is active. | Defaults approved; existing saved settings are not implicitly overwritten. |
| Zombie XP | Default 2 XP per qualifying ordinary zombie kill. Visible in Kills and Hybrid. | Implemented in v0.6.0. |
| Player Kill XP | Default 75 XP for an enemy player outside the killer's faction, subject to the same-victim cooldown. Visible in Kills and Hybrid. Replaces Unique Player XP. | Implemented in v0.6.0. |
| Player Kill Cooldown | Default 2 in-game days before killing the same player can reward XP again. | Implemented with persistent directional server-account pairs; no shared faction includes factionless players. |
| Day Survived XP | Default 0 XP for a qualifying survived day. | Implemented in v0.6.0 using native seasonal dawn/dusk; full connected periods only. |
| Night Survived XP | Default 25 XP for a qualifying survived night. | Implemented in v0.6.0 using native seasonal dawn/dusk; full connected periods only. |
| Horde Zombie XP | Default 5 XP per qualifying OMH horde-zombie kill. Visible in Horde Night and Hybrid. | Value approved; implementation Checkpoint 8. |
| Horde Survived XP | Default 100 XP upon the player's horde completion while connected and not a casualty. Visible in Horde Night and Hybrid. | Value and eligibility approved; implementation Checkpoint 8. |
| XP per Trait Level | Rounded to nearest 50: `100 + 35n + (65/19)nÂ²`, where n is the current level. Level 1 costs 100 and Level 20 costs 2,000. Each earned level grants one Token. | Approved and implemented in Checkpoint 5; no new sandbox control. |
| Prestige cadence | One Prestige Point at displayed Trait Levels 5, 10, 15 and subsequent multiples of five, independent of Token count. | Configurable Prestige Level Interval, default 5, implemented in v0.6.4. |
| Prestige Retention Percentage | Retain 30% of the previous available prestige after the next character receives its full creation bonus and enters the world. Repeats once per life transition; round to nearest whole point with no minimum-one guarantee. | Implemented in v0.7.0; integer 0-100, default 30, half-up rounding, no minimum. |
| Allow Negative Trait Removal | Disabled by default. Enables supported negative removals in the cart. | Implemented in v0.4.0. |
| Negative Cost Multiplier | Default 2.0; range 0.1-100. Multiply absolute creation value, round up to whole Tokens. No surcharge. | Implemented in v0.4.0. |
| Positive Cost Multiplier | Multiply the native positive creation-point cost by this value, then round up to a whole Token. Default 1.0; range 0.1-100. Catalog exclusions are separate. | Implemented with broad default eligibility in v0.4.0; this does not finalize the official preset. |
| Trait Shop score multiplier | 0.50 for official scoring, applied after existing score modifiers. | Initial owner value; future tuning allowed through a versioned official policy. |

Score reductions compose by multiplying the remaining-score factors, never by adding reduction percentages. See [OMH_INTEGRATION.md](OMH_INTEGRATION.md). Prestige retention is a separate progression setting, not a score modifier.

## Official lock behavior

Enabling the lock must apply and enforce the preset on the authority, not just disable UI controls. Disabling the lock permits editing. Disabling alone is not disqualifying if all effective values still match the approved preset; playing under divergent values persistently flags the run. Re-enabling the lock must not clear that history.

Recommend defaulting the lock on when Horde Night is active, but this default is not yet approved. Without Horde Night, the lock cannot create official eligibility and should be unavailable with an explanation (recommended presentation).

The exact official preset still needs values for XP, prices, progression, prestige, permitted traits, and later removal. Mode selection alone does not define the complete rules. Existing OMH fairness requirements continue to apply.

Track effective settings changes before granting rewards or purchases so a temporary custom configuration cannot be used and then hidden by restoring the preset. Do not silently reset an existing custom server merely because dependencies are detected after loading a save; fresh-default versus saved-setting behavior needs validation.

Day/night survival follows the native seasonal cycle, independently of OneMoreHorde.StartHour/EndHour. Sleep and fast-forward count; partial periods after joining/reconnecting/restarting do not. Endless day/night has no completed alternating periods. See CHECKPOINT_6.md for timing, saved-mode behavior and implementation limits.

## v0.6.4 Level Rewards

- Tokens per Level: integer 0–1000, default 1. Zero disables Token awards from leveling.
- Prestige Level Interval: integer 1–1000, default 5. One Prestige at newly reached displayed-level multiples; starting Level 1 grants nothing.
- Settings affect future XP awards only; no retroactive grants or deductions. Repeated interval changes cannot repeat already-earned Prestige entitlements.
- Higher Token rewards or lower Prestige intervals flag Lessened in Horde Night 0.6.13.1; lower Token rewards or higher intervals flag Hardened and remain eligible.

Retention 0-30 remains default-or-harder under Horde Night 0.6.14. Values above 30 are Lessened. Update both matching packages together.
