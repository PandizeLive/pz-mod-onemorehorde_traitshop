# Sandbox options specification

Positive Cost Multiplier, Negative Cost Multiplier and Allow Negative Trait Removal are implemented in v0.4.0; other options remain specifications for later phases. XP defaults, caps, and the complete official preset remain undecided. The owner has specified the initial 0.50 score multiplier and 30% prestige retention default.

| Setting | Behavior / default | Status |
|---|---|---|
| Locked Official Mode | When enabled, force the official Trait Shop preset, including Horde Night rewards; prevent edits to governed values. | Owner-requested behavior; label and default pending. |
| Reward Mode | Kills, Survival, Horde Night, Hybrid. Default Horde Night when OMH: Horde Night is active. | Confirmed; standalone default pending. |
| Zombie XP | XP for a qualifying ordinary zombie kill. Visible in Kills and Hybrid. | Value pending. |
| Unique Player XP | XP for a qualifying unique player kill. Visible in Kills and Hybrid. | Value and uniqueness scope pending. |
| Day Survived XP | XP for a qualifying survived day. Visible in Survival and Hybrid. | Value and timing rules pending. |
| Night Survived XP | XP for a qualifying survived night. Visible in Survival and Hybrid. | Value and timing rules pending. |
| Horde Zombie XP | XP for a qualifying OMH horde-zombie kill. Visible in Horde Night and Hybrid. | Value pending. |
| Horde Survived XP | XP upon the player's horde completion while connected and not a casualty. Visible in Horde Night and Hybrid. | Value pending; eligibility confirmed. |
| XP per Trait Level | XP required for each level, possibly a curve. Each earned level grants one Token. | Level 1 = 100 XP confirmed; later levels/curve pending. |
| Prestige cadence | One Prestige Point every five earned Trait Levels, independent of Token count. | Confirmed; whether exposed as a custom setting pending. |
| Prestige Retention Percentage | Retain 30% of the previous available prestige after the next character receives its full creation bonus and enters the world. Repeats once per life transition; round to nearest whole point with no minimum-one guarantee. | Separate setting, 30% default, and nearest-whole rounding confirmed; label working. |
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
