# v0.8.1: physical trait purchases

## Behavior

- Stout/Strong grant +2/+4 Strength; Fit/Athletic grant +2/+4 Fitness, reading the native definitions. Existing partial skill XP is retained, with a level-10 cap.
- Puny (`base:weak`), Weak (`base:feeble`), Unfit and Out of Shape removals restore the declared negative levels and reach at least level 5, so removal cannot leave a penalty active. Negative removal remains disabled by default and costs only the existing multiplier.
- Existing creator exclusions remain authoritative. Buying Stout does not silently remove Strong; queue a supported conflicting negative removal explicitly. A mixed cart calculates removals first, then additions, independent of item order.
- Native LevelPerk updates choose the resulting trait. The shop does not pin old physical memberships or continually refill lost physical XP. Completed purchases cannot be bought again in the same life, even after the resulting trait changes.
- Trait and receipt tooltips show the planned stat total and resulting trait changes. Names come from the native localized definitions. Owned-trait tooltips remain descriptive.
- Existing ordinary traits, custom standard skill/recipe grants, costs, progression, prestige and horde rewards retain their behavior. Weight and custom physical trait definitions remain excluded pending a dedicated adapter; this is not a universal initialization mechanism.

## Authority and persistence

Server-side offers validate body conditions; the full planner validates conflicts, funds, cap/no-op cases and current stats before payment. The complete cart commits once under the existing revision/life check. A bounded optional `effects.physical` map is backward-compatible with existing schema-3 saves. Each stat target contains absolute XP, a monotonically increasing sequence for that life, and server completion.

Client snapshots carry a copy. The living, nonce-validated client applies an absolute target once and saves its own sequence under `OMHTS_PhysicalReceipts` in character modData. This marker controls only local replay; it is never trusted for server entitlement. Ordinary modData sync cannot undo the server's separate receipt. Death clears server entitlements and a new character has a fresh local marker. Reconnect/restart must not turn a completed target into a permanent XP floor.

Strength XP always passes through native protein modifiers even with multipliers disabled; the grant compensates by the matching native factor. Fitness's `canAddFitnessXp` gate is checked before purchase and application. A zero-amount native `addXpNoMultiplier` call after the server mutation updates the connected player's XP anti-cheat baseline without awarding again. No admin-only `SyncXp` packet or direct NetworkPlayerAI Lua call is used.

## Native evidence

Installed game: **42.20.4**. Live `media/scripts/generated/characters/character_traits.txt` supplies costs, skill bonuses and conflicts. Live `media/lua/server/XpSystem/XpUpdate.lua`, `xpUpdate.levelPerk`, removes previous family traits and assigns 0-1 / 2-4 / 5 / 6-8 / 9-10 tiers. Live English UI labels distinguish Puny (`base:weak`) from Weak (`base:feeble`).

Secondary decompile: `IsoGameCharacter.XP.AddXP` applies protein multipliers before the optional XP boosts and calls native LevelPerk; `Nutrition.canAddFitnessXp` supplies the weight gate. `SyncPlayerFieldsPacket` flag 3 contains traits/recipes, not XP, so the validated local target remains necessary. `GameServer.addXp` refreshes `NetworkPlayerAI.updateXpChecker` for the owning connection; that path was also verified in the installed JAR bytecode. `NetworkPlayerAI` is not Lua-exposed: an exploratory native probe caught that, and the shipped code uses the supported global instead.

## Validation

Kahlua compilation/fundamentals passed (21 shipped Lua files; no banned constructs). Regression suites: 191 foundation/progression, 261 shop/UI/physical, 207 reward/sandbox, 51 prestige, 39 horde assertions: **749 total**. The largest exercised snapshot remains 50,017 bytes against the 60,000-byte bound.

Final physical native evidence: `.local/phasePhysical-server-a83927331f794dd0a95900d965f74cf2/stage-{1,2,3}.log`; all three stages load **0.8.1** and quit gracefully. Actual game physical behavior, 30 nutrition/start-level combinations, persistence and death cleanup passed without OMH exceptions. The earlier exploratory f7e9849b probe failed on the inaccessible NetworkPlayerAI method; it is not a passing result. The dedicated physical probe uses actual IsoPlayer, XP, traits and game Lua, then performs three native save/restart cycles. It includes protein states -400/0/100 across Strength levels 0-9, partial XP, creator exclusions, mixed carts, negative neutralization, cap rejection and natural XP loss after completed grants.

The existing generic shop native probe also passed all three cycles on 0.8.1: `.local/phase2-server-3c9366bf429a4f4e9050c551a8dec869`. It verifies ordinary mixed carts, skill boosts, recipe grants, Smoker cleanup, replay rejection and death replacement.

Human-client solo and dedicated acceptance remain pending. Existing CP8 solo behavior was reported passed by the owner; the combined dedicated CP7/CP8 test remains pending. This feature follow-up does not implement Checkpoint 9's official lock/history policy.

## Release

Local version/tag: 0.8.1 / v0.8.1. Changes are limited to Trait Shop. Live Workshop description retrieval was unavailable; owner-authored description, artwork and visibility are untouched. The existing publisher omits those fields and uses only content/changelog for updates. Mirror/upload remain manual through OMH_TraitShop.cmd options 2 then 3. Workshop item remains 3803035618.

See [six-step solo test](TEST_v0.8.1.md).
