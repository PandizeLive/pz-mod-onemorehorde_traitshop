# Sandbox options specification

> Current policy (2026-09-21): [Checkpoint 9](CHECKPOINT_9.md) supersedes earlier Locked Official Mode planning. Run Options provides Enable Trait Shop, default ON when installed with Horde Night; standalone stays enabled. Existing benefits force access, missing creation provenance is unofficial, and default-or-harder rules retain eligibility.

As of v0.8.0, settings are grouped under **Trait Costs** (multipliers and removal toggle), **Level Rewards** (Tokens per Level and Prestige Level Interval), **XP Rewards** (mode and applicable rates), and **Player Kill Rules** (cooldown, shown in Kills/Hybrid). The latter section follows all XP rates. These headers appear in solo setup, host setup and the live admin menu. **Prestige** now contains Prestige Retention Percentage.

Current package: Trait Shop 0.9.0 with Horde Night 0.6.16.3. All controls below are implemented. The approved official baseline is documented below; no Locked Official Mode or extra currency cap is part of this release.

| Setting | Behavior / default | Status |
|---|---|---|
| Enable Trait Shop | Horde Night Run Options control, default ON when installed. Character/faction benefits force it ON. | Implemented; standalone always enabled. This is not a sandbox lock preset. |
| Reward Mode | Kills, Survival, Horde Night, Hybrid. Default Hybrid standalone; default Horde Night when OMH: Horde Night is active. | Defaults approved; existing saved settings are not implicitly overwritten. |
| Zombie XP | Default 2 XP per qualifying ordinary zombie kill. Visible in Kills and Hybrid. | Implemented in v0.6.0. |
| Player Kill XP | Default 75 XP for an enemy player outside the killer's faction, subject to the same-victim cooldown. Visible in Kills and Hybrid. Replaces Unique Player XP. | Implemented in v0.6.0. |
| Player Kill Cooldown | Default 2 in-game days before killing the same player can reward XP again. | Implemented with persistent directional server-account pairs; no shared faction includes factionless players. |
| Day Survived XP | Default 0 XP for a qualifying survived day. | Implemented in v0.6.0 using native seasonal dawn/dusk; full connected periods only. |
| Night Survived XP | Default 25 XP for a qualifying survived night. | Implemented in v0.6.0 using native seasonal dawn/dusk; full connected periods only. |
| Horde Zombie XP | Default 5 XP per qualifying OMH horde-zombie kill. Visible in Horde Night and Hybrid. | Implemented in v0.8.0; core credit only, no Hybrid overlap. |
| Horde Survived XP | Default 100 XP upon the player's horde completion while connected and not a casualty. Visible in Horde Night and Hybrid. | Implemented in v0.8.0; connected eligible survivors, with persistent replay protection. |
| XP per Trait Level | Rounded to nearest 50: `100 + 35n + (65/19)n²`, where n is the saved earned-level counter (displayed level minus 1). The Level 1 bar costs 100 and Level 20 bar costs 2,000. | Implemented curve; not a sandbox control. Starting Level 1 grants nothing. |
| Tokens per Level | Integer 0-1000, default 1. Zero disables Token rewards from levels. | Implemented; applies to future earned levels. |
| Prestige cadence | One Prestige Point at displayed Trait Levels 5, 10, 15 and subsequent multiples of five, independent of Token count. | Configurable Prestige Level Interval, default 5, implemented in v0.6.4. |
| Prestige Retention Percentage | Retain 30% of the previous available prestige after the next character receives its full creation bonus and enters the world. Repeats once per life transition; round to nearest whole point with no minimum-one guarantee. | Implemented in v0.7.0; integer 0-100, default 30, half-up rounding, no minimum. |
| Allow Negative Trait Removal | Disabled by default. Enables supported negative removals in the cart. | Implemented in v0.4.0. |
| Negative Cost Multiplier | Default 2.0; range 0.1-100. Multiply absolute creation value, round up to whole Tokens. No surcharge. | Implemented in v0.4.0. |
| Positive Cost Multiplier | Multiply the native positive creation-point cost by this value, then round up to a whole Token. Default 1.0; range 0.1-100. Catalog exclusions are separate. | Implemented; values below 1 are Lessened. |
| Trait Shop score multiplier | 0.50 for official scoring, applied after existing score modifiers. | Initial owner value; future tuning allowed through a versioned official policy. |

Score reductions compose by multiplying the remaining-score factors, never by adding reduction percentages. See [OMH_INTEGRATION.md](OMH_INTEGRATION.md). Prestige retention is a separate progression setting, not a score modifier.

## Official policy

There is no lock preset. Defaults or harder settings remain eligible, subject to Horde Night's other fairness checks. The baseline is positive/negative costs x1/x2, negative removal OFF, Horde Night reward mode, Horde Zombie 5 XP, Horde Survived 100 XP, one Token per level, Prestige every 5 displayed levels, retention 30%.

Higher costs, lower active XP rewards, fewer Tokens per level, a longer Prestige interval and lower retention are harder. Cheaper costs, greater rewards, a shorter Prestige interval, retention above 30%, or enabling negative removal are Lessened. Leaving Horde Night reward mode is separately disqualifying. Mixed changes retain the easier-rule flag.

Enable Trait Shop controls shop access and rewards for the current run. It cannot remove acquired benefits. Purchased/removed traits or a Prestige creation bonus force it enabled for the affected character/faction. Character history and unofficial-earned benefits survive new runs, faction changes, reloads and addon removal.

The server tracks effective settings and earning provenance; restoring defaults does not clear old flags. Existing saved reward modes are preserved when dependencies change. Fix the cause and reset the run for a new eligibility check; inherited unofficial advantages remain relevant.

Day/night survival follows the native seasonal cycle, independently of OneMoreHorde.StartHour/EndHour. Sleep and fast-forward count; partial periods after joining/reconnecting/restarting do not. Endless day/night has no completed alternating periods. See CHECKPOINT_6.md for timing, saved-mode behavior and implementation limits.

## v0.6.4 Level Rewards

- Tokens per Level: integer 0–1000, default 1. Zero disables Token awards from leveling.
- Prestige Level Interval: integer 1–1000, default 5. One Prestige at newly reached displayed-level multiples; starting Level 1 grants nothing.
- Settings affect future XP awards only; no retroactive grants or deductions. Repeated interval changes cannot repeat already-earned Prestige entitlements.
- Higher Token rewards or lower Prestige intervals flag Lessened in Horde Night 0.6.13.1; lower Token rewards or higher intervals flag Hardened and remain eligible.

Retention 0-30 remains default-or-harder under Horde Night 0.6.14. Values above 30 are Lessened. Update both matching packages together.
