# Trait Shop design

Status: owner requirements recorded September 14, 2026. Explicit recommendations and unresolved details are tracked in [DECISIONS.md](DECISIONS.md).

## Vocabulary and progression

| Term | Meaning |
|---|---|
| XP | Progress earned from the selected reward sources; fills the Trait Level progress bar. |
| Trait Level | Earned by filling the XP bar. Each level grants one Token. |
| Token | Currency spent on purchasing positive traits or, later, removing negative traits. Lost on death. |
| Prestige Point | Bonus character-creation trait point earned every five Trait Levels; a configurable share of prior prestige can also be retained. This is not shop currency. |
| Unspent creation points | Remaining character-creation trait points converted into starting Tokens; never award XP, levels, or prestige. |

Use **Tokens** for shop currency and **Prestige Points** for creation bonuses. Avoid calling both currencies Tokens.

Each completed Trait Level awards one Token; milestones at levels 5, 10, 15, etc. award one Prestige Point. Newly earned prestige depends only on Trait Level, never Token count, starting grants, spending, or refunds. XP requirements and whether level requirements grow are undecided.

Examples:

- A character enters the world with five unused creation points: grant five starting Tokens once, with no earned levels or prestige.
- Five earned Trait Levels: five Tokens awarded over those levels and one Prestige Point earned, regardless of spending.
- Twelve earned Trait Levels: twelve Tokens awarded and two Prestige Points earned. Token balance may be lower after purchases.
- Death wipes the character's remaining Tokens, resets Trait Level, and resets partial XP.

Prestige grants bonus points at new-character creation, not a direct Token payout. Any conversion of unused creation points happens after character creation. Starting Tokens, refunds, and prestige-derived creation points must never count as earned levels.

### Prestige retention across lives

Prestige is not a permanently accumulated lifetime total. At death, the available prestige supplies the next character's full bonus creation points. Once that replacement character successfully enters the world, retain a configurable percentage of that prestige for subsequent lives; the owner's default is **30%**. This retained amount remains even though the full creation bonus was offered or spent. Apply retention once per completed life transition, never on ordinary login/reconnect and never a second time at death.

Owner example: die with 3 Prestige Points -> next character receives +3 creation points -> after entering the world, the character has 1 retained Prestige Point and Trait Level 0. The retained point does not grant an additional creation bonus in that same transition.

Agreed rounding: nearest whole point, with no minimum-one guarantee. The documented exact-tie convention is half up for nonnegative values. At 30%, a no-new-earnings sequence is 3 -> 1 -> 0. Do not always round up: that would keep the final point forever and undermine decay.

Confirmed with Phase 1 approval: available prestige at death equals retained prestige plus new points earned from this life's Trait Levels. Thus a character retaining 1 and earning 2 more would offer +3 creation points next time, then retain 30% of 3. This is not a separate lifetime prestige total. Retained prestige itself never grants levels or Tokens. Phase 1 reserves this amount as pending state; the creation-screen grant and retention step are implemented in the later prestige phase.

## Reward modes

| Reward Mode | XP settings shown |
|---|---|
| Kills | Zombie; Unique Player |
| Survival | Day Survived; Night Survived |
| Horde Night | Horde Zombie; Horde Survived |
| Hybrid | All six settings above |

With OMH: Horde Night active, Horde Night is the default reward mode and the only mode eligible for official Trait Shop scoring. Without OMH, the addon must remain usable; the standalone default is undecided (Kills is recommended).

Hybrid reveals all reward settings. Values and overlap behavior remain configurable design decisions. Recommendation: a horde zombie grants Horde Zombie XP instead of also granting ordinary Zombie XP. This recommendation has not been approved.

Unique Player needs a stable definition and repeat-reward policy before implementation. Recommendation: identify the victim by account, not respawned character. Survival day/night boundaries, required elapsed time, sleep, disconnect, and time-skip behavior are also undecided.

### Horde completion eligibility

Reward a player who is connected when **their horde** completes, provided they are not a casualty of that event. Use OMH's authoritative event membership and casualty outcome. Do not introduce minimum attendance, minimum kills, damage thresholds, or distance requirements.

A late-connected member can qualify under this rule. A casualty must not regain that event's reward by reconnecting or respawning. An unrelated connected player does not qualify. Reward each eligible player once per event; repeated completion delivery or server reload must not duplicate XP. Players disconnected at completion do not receive a deferred reward under this rule.

## Shop and UI

One progression window contains the trait catalog, costs, Token balance, XP bar, Trait Level, and Prestige Points. Distinguish retained prestige from prestige earned during the current life, and clearly show the projected next-character creation bonus.

The owner wants a Trait Purchase System-style hover menu beside the health icon, using the supplied Trait Shop icon. Treat this as custom integration to inspect and recreate, not a presumed vanilla feature. Preserve existing health-button behavior and coexist with other mods adding nearby buttons. The menu must remain reachable when the pointer moves from the health icon to the shop button.

Tooltip and optional keybind were suggested, not explicitly approved. UI scaling, resolution, and competing health-menu mods need validation. The owner's GIF is preserved in `art/references/health-hover-reference.gif`.

## Purchasing and later negative-trait removal

Positive-trait purchasing is an initial feature. Purchase approval must check the authoritative balance, already-owned traits, exclusions, incompatible traits, and the ability to activate the trait's actual effects.

Negative-trait removal is a later feature and is not required for initial release. When implemented, it will have a sandbox toggle disabled by default. Until implemented, do not expose an operational-looking removal toggle or permit removal transactions.

Use the owner-approved setting names **Positive Cost Multiplier** and **Negative Cost Multiplier**. Each controls the corresponding cost relative to the trait's absolute creation-point value. Multiplier defaults and whole-Token rounding remain undecided. Catalog exclusions remain separate from price controls.

For negative traits, the earlier `2 * abs(value) + 2` proposal remains unresolved: changing the setting name does not confirm or cancel the flat +2 surcharge. If retained, the formula would be `abs(value) * Negative Cost Multiplier + 2`. With multiplier 2, example costs are -1 -> 4 Tokens and -4 -> 10. Do not silently treat the additive surcharge as part of the multiplier. Zero-cost or special traits need explicit catalog handling, not automatic eligibility from the formula.

Complex removal support is deferred. This does not authorize shipping positive traits whose effects fail to initialize. Do not promise universal trait-mod compatibility.
