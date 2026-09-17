# Trait Shop design

Status: owner requirements recorded September 14, 2026. Explicit recommendations and unresolved details are tracked in [DECISIONS.md](DECISIONS.md).

## Vocabulary and progression

| Term | Meaning |
|---|---|
| XP | Progress earned from the selected reward sources; fills the Trait Level progress bar. |
| Trait Level | Earned by filling the XP bar. Each level grants one Token. |
| Token | Currency spent on purchasing positive traits or removing negative traits. Lost on death. |
| Prestige Point | Bonus character-creation trait point earned every five Trait Levels; a configurable share of prior prestige can also be retained. This is not shop currency. |
| Unspent creation points | Remaining character-creation trait points converted into starting Tokens; never award XP, levels, or prestige. |

Use **Tokens** for shop currency and **Prestige Points** for creation bonuses. Avoid calling both currencies Tokens.

Each completed Trait Level awards one Token; milestones at levels 5, 10, 15, etc. award one Prestige Point. Newly earned prestige depends only on Trait Level, never Token count, starting grants, spending, or refunds. Level 1 requires 100 XP. Requirements after Level 1 remain undecided.

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

The approved v0.4.2 window is a movable, resizable OMH panel, without pinning/collapsing. It retains geometry while reused during the session. Center the branding: One More Horde uses the full leaderboard Small font and red (0.85, 0.25, 0.25); Trait Shop uses its Large font and gold (0.95, 0.75, 0.2). Header spacing measures the actual font height. Center Trait Level and its separate number; the number and XP fill use gold #E7B428. The XP bar has white `current / required` text and starts at `0 / 100`. Earning still belongs to Phase 3. The XP tooltip will list only source names allowed by the active reward mode whose configured reward is above zero, without amounts. Until reward sources exist, it says that none are available in this build.

Tokens and Prestige have equal weight. Prestige displays retained plus earned as one total; its tooltip shows those components. The Token tooltip explains unused creation points, spending and current balance, with an explicit statement that prestige/XP grants are not implemented yet. No fabricated prestige contribution is displayed.

Use the owner's three boxes: unowned positives left, current positives/profession traits upper right, and current negatives lower right. Positive names are green, negatives red, unavailable choices grey. Selected cart rows have gold outlines and subtle green/red fill. Trait tooltips show the name and description only. There is no duplicate description footer or action-button tooltip.

Plain clicks toggle individual traits without clearing other choices. Shift adds an anchored visible range of eligible traits. Ctrl+A adds eligible visible traits from the last-clicked actionable list, respecting search/filter; while search is focused, it selects text instead. Disabled choices and unresolved conflicts are skipped by bulk selection. A combined selection may exceed the wallet or contain mutually conflicting additions; checkout stays disabled until resolved. Search/filter changes preserve the cart. A scrolling receipt shows additions/removals, individual prices, total and remaining balance. Clicking either a receipt entry or its selected source row removes it. Availability, grey shading and filters immediately reflect valid queued negative removals; undoing a removal restores any conflict. Server validation remains authoritative. Purchase submits the complete cart; Reset clears choices; Close discards an unpaid cart. Validation problems appear once near the receipt. Reset anchors lower-left with the Difficulty menu's black fill and red text/border. Close and Purchase anchor lower-right in that order: red Close, green enabled Purchase, neutral disabled Purchase. All lists and the receipt cull rows in viewport coordinates including the current scroll offset.

Search includes localized names, trait IDs and descriptions. Rank exact names, partial names, ID matches, description phrases, then all query words in the description. Normalize case and repeated whitespace. Within equal relevance, sort current Token price, localized name, then stable ID. Empty search restores price sorting. All matching unavailable traits stay visible.

Only hovering the health area opens the custom shop button; hovering its hidden coordinates cannot reveal it. Keep it open across the visible button and an existing Trait Purchase System popup. Preserve native health behavior. No extra keybind is included.

## Purchases, compatibility and removal

The owner approved broad default eligibility, replacing the ten-trait allowlist. A common processor handles membership, declared skill levels/XP boosts, granted recipes and granted traits. Custom scripts are not automatically rerun; never replay character creation or `applyTraits`. Weight/Strength/Fitness traits remain tied to body progression. Profession/free traits cannot be bought, and profession/other-trait grants cannot be removed individually. Negative traits granting additional traits need a specific cleanup implementation and are currently excluded. Integrations can exclude known custom incompatibilities. Existing registration calls remain accepted but no longer gate ordinary traits.

Removal was brought forward into this update. Allow Negative Trait Removal defaults to disabled. Positive Cost Multiplier defaults to 1; Negative Cost Multiplier defaults to 2. Both range from 0.1 to 100. Prices are `ceil(abs(creation value) * multiplier)`, with **no +2 surcharge**: -1 costs 2 Tokens and -4 costs 8 by default. Free/zero-cost traits need explicit handling rather than automatic pricing.

Validate the whole cart against the final trait combination before charging: removing a conflicting negative and adding its positive counterpart can succeed together. Invalid entries, duplicate entries, changed quotes, insufficient total funds and mutually conflicting additions reject the entire cart. Skill/recipe grants are recorded as recoverable targets; retries never intentionally stack rewards. Removing a negative does not erase trained skills or learned recipes. Smoker removal clears nicotine withdrawal and its smoke timer, without clearing unrelated stress/unhappiness.

No blanket claim of arbitrary mod compatibility or atomic saving across native player files and world ModData is made. Official removal policy remains a future scoring decision.