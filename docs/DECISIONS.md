# Decisions and open questions

Recorded September 14, 2026 from the OMH: Trait Shop conversation. New owner instructions supersede these documents; keep the documents consistent when decisions change.

## Confirmed requirements

1. Project home: `C:/Users/bandi/Zomboid_Modding/OMH/Trait Shop`; standalone operation plus optional Horde Night integration.
2. A unified shop and progression window, entered through a custom health-icon hover interaction similar to Trait Purchase System; use the owner's icon and GIF reference.
3. XP fills a level bar. One Token per Trait Level and one Prestige Point every five Trait Levels. Newly earned prestige depends on Trait Level, never Token count.
4. Tokens buy traits and later removals. Prestige Points grant bonus character-creation trait points. These are distinct resources.
5. Tokens wipe and Trait Level resets on death. Unused creation points become starting Tokens once (five unused points -> five Tokens), with no prestige credit because they do not grant Trait Levels.
6. Reward modes: Kills, Survival, Horde Night, Hybrid; six XP reward categories as specified in DESIGN.md.
7. Horde completion rewards require connection at completion of the player's horde and no casualty status for that event. No minimum participation tracking.
8. Horde Night mode defaults on with Horde Night detected and is required for official Trait Shop scoring.
9. Official lock forces the approved settings. Unlocking permits edits; divergent play persistently flags the run. Restoring settings cannot clear the flag.
10. Initial Trait Shop score modifier is x0.50. Multiple reductions multiply their remaining-score factors; never sum the reduction percentages. Round only the final score. Horde Night's difficulty menu must explain modifiers, including Cure and Trait Shop. The owner's 80% and 60% reductions are an illustrative example, not new approved Cure/Trait Shop settings.
11. Negative-trait removal is a later feature, disabled by default when available. Initial release need not include it or complex removal support.
12. Prestige does not remain an undiminished cumulative lifetime total. The next character receives the available prestige as creation points, then retains 30% after entering the world. A separate retention setting controls this percentage. Owner example: 3 points -> +3 creation points and 1 retained Prestige Point.
13. Cost setting names are Positive Cost Multiplier and Negative Cost Multiplier. Exclusions are separate from pricing.
14. Prestige retention rounds to the nearest whole point, with no minimum-one guarantee: 3 -> 1 -> 0 at 30% without new earnings. The documented tie convention is half up for nonnegative values; always rounding upward is rejected.
15. Use sequential Checkpoints 1-14 across the six phases, not dotted phase/checkpoint numbering. The owner authorized Checkpoint 1 implementation.
16. Checkpoint 1 selected `OneMoreHorde_TraitShop` and v0.1.0 for the independent package. Metadata minimum is 42.20.0; actual dedicated startup verified on 42.20.4. Singleplayer world-entry verification remains pending.
17. Use a separate private GitHub repository, `PandizeLive/pz-mod-onemorehorde_traitshop`, as selected by the owner. Adapt the core OMH.cmd workflow for this addon, retaining independent packages, backups, tags, credentials/logs and Workshop identity. Repository creation is authorized; source mirroring and Steam publication remain owner-run menu actions.

## Open decisions

| Topic | Unresolved choice | Recommendation / impact |
|---|---|---|
| Cost formulas | Multiplier defaults, Token rounding, and whether negative removal keeps the proposed flat +2. | Setting names are settled; a multiplier does not itself express a surcharge. Decide removal details with the later feature. |
| Retained plus earned prestige | Confirm that retained prestige and this life's newly earned prestige form the next creation bonus. | Working interpretation: retained 1 + newly earned 2 -> +3 creation points next life, then apply retention to 3 once. |
| Partial XP lifecycle | Trait Level reset is confirmed; explicitly reset partial XP too? | Recommend resetting partial XP on death. |
| Prestige conversion | Can unused prestige-derived creation points also become starting Tokens? | Owner's general unused-points rule suggests yes, without prestige credit. Confirm this edge case. |
| Official prestige provenance | What happens when custom-earned prestige enters a new character/run? | Persist provenance; do not silently treat it as official after changing settings. Decide whether to exclude that prestige from an official start or make the affected run unofficial. |
| Official preset | XP rates/curve, prices, caps, eligible traits, prestige lifecycle and limits, future removal settings. | Must be explicit and versioned; 50% score alone cannot establish fairness. |
| Official lock default | Default enabled with Horde Night? | Recommend yes. Unlocked but matching settings must remain eligible. |
| Standalone default | Default reward mode without Horde Night. | Recommend Kills; no owner decision yet. |
| Hybrid kills | Stack ordinary and horde-zombie XP? | Recommend no double payout. |
| Unique Player | Account identity and how long uniqueness lasts. | Recommend account-based identity; scope still pending. |
| Survival rewards | Day/night definition, elapsed-time requirements, sleep, offline and time-skip treatment. | Owner relaxed horde attendance only; do not assume that settles survival timing. |
| Initial catalog | Which positive traits are runtime-safe; prices and conflict handling. | Must be verified before sale. Broad negative removal support can wait. |
| Score detection | Enabled mod versus mere subscription; adding/removing during a run. | Recommend enabled runtime detection plus durable affected-run history. |
| UI conveniences | Tooltip, optional keybind, exact menu integration. | Tooltip/keybind suggested; inspect vanilla and reference mod before UI work. |
| Workshop presentation | Final cover, description, visibility and readiness for public release. | Tooling creates a private development item on first owner-run publication; live updates preserve existing presentation. No Workshop ID is invented or borrowed. |

## Superseded proposals

- Prestige as 20% of unspent or total earned Token balance is replaced by the confirmed Trait Level milestone model.
- Permanent undiminished prestige accumulation is rejected; a configurable 30% retention rule replaces it. Trait Level resets on death.
- Prestige as next-life shop currency is superseded by bonus character-creation points.
- Carrying unspent Tokens through death is rejected; Tokens wipe.
- Minimum horde attendance or contribution thresholds are rejected; use connected and not-casualty status at completion.
- Assuming the health hover menu is vanilla is rejected; inspect and implement custom UI behavior.
- Negative removal is not an initial-release requirement.

## Implementation boundary

The owner authorized Checkpoint 1 in the [roadmap](ROADMAP.md): minimal package, feasibility, and loading verification, then separately authorized [release tooling](RELEASE_TOOLING.md) and a private repository. Later gameplay checkpoints, core changes and publication are not completed by that tooling work. No third-party gameplay implementation is bundled. Remaining prestige combination details and the official preset need resolution before dependent implementation. The roadmap assigns each open decision to its first dependent checkpoint.
