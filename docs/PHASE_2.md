# Phase 2 - Positive trait shop

Build **v0.3.0**, September 15, 2026. Checkpoints 3 and 4 are implemented. Owner acceptance is one combined session covering Phase 1 and Phase 2; see [TEST_PHASE_2.md](TEST_PHASE_2.md). XP rewards, prestige creation bonuses, negative removal and Horde Night score integration remain later phases.

## Player behavior

Hover over the normal health icon to reveal the owner's Trait Shop icon immediately beside it. The existing health button keeps its normal behavior. The separate shop window displays Tokens, Trait Level, XP, earned/retained/pending prestige, a positive-trait list, descriptions, prices and availability. Buying an available trait spends Tokens after server validation. Owned, conflicting, unaffordable or unsupported offers explain their status and cannot be bought.

The window uses translated text, preserves selection/scroll while refreshing, scales its dimensions with the font and screen, and disposes its controls on close/disconnect. Sidebar rebuilds dispose the hover button. When the reference Trait Purchase System popup exists, the button is placed after that popup; actual coexistence still belongs to the live test.

`Positive Cost Multiplier` is a Sandbox double, default **1.0**, range **0.1-100.0**. Price is `ceil(native positive creation cost * multiplier)`, minimum one Token. The server recalculates the price and compares it with the displayed quote; a changed price requires another explicit purchase. The initial defaults and catalog are implementation choices under the owner's full Phase 2 authorization, not a finalized official scoring preset.

## Initial catalog

Prices below are the installed B42.20.4 definitions at multiplier 1.0. Labels/descriptions come from the native definition, so game translations and future native cost changes are respected.

| Native ID | English label | Tokens |
|---|---|---|
| base:dextrous | Dextrous | 2 |
| base:fastreader | Fast Reader | 2 |
| base:brave | Brave | 4 |
| base:outdoorsman | Outdoorsy | 2 |
| base:irongut | Iron Gut | 2 |
| base:resilient | Resilient | 4 |
| base:lighteater | Light Eater | 2 |
| base:lowthirst | Low Thirst | 2 |
| base:fasthealer | Fast Healer | 6 |
| base:organized | Organized | 4 |

These traits are read by ongoing native/Lua behavior. No XP-level initialization, free recipes or child-trait grants are required. A definition changed by another mod to require any of those effects is unavailable, rather than partially applied. Profession/free traits and multiplayer-disabled definitions cannot enter the shop. Other positive traits need a verified adapter before sale; no broad trait mutation or `applyTraits` replay is used.

## Starting Tokens and persistence

On a fresh zero-age life, the authority reconstructs unused creation points from native profession cost, `CharacterFreePoints`, selected trait costs and all four `NegativeTraitsPenalty` modes. Profession/trait-granted children and free traits are excluded from double charging. Unknown definitions, invalid settings or a negative budget fail closed with a visible explanation. The client never supplies the budget or a balance.

The grant is settled once, including a zero grant, and never changes XP, Trait Level or prestige. New replacement lives calculate their own grant. Existing aged characters receive no retroactive grant; their current trait list is not reliable evidence of their original unused points. Prestige-derived creation points are not produced in this phase; Phase 3 will add their separate authoritative grant before incorporating that bonus into this calculation.

Schema 2 stays under the existing `OMHTraitShop_State_v1` world table name so v0.2.0 saves are found. Migration validates all schema-1 records before altering any, preserves existing counters and identities, and adds `creation={status="legacy",tokens=0}` plus an empty purchase ledger. No retroactive grant runs during migration. Unknown/ambiguous schemas remain preserved and unavailable.

Purchases carry only trait ID, life ID, expected revision and quoted price. The engine-bound sender determines the account. The authority validates shape, liveness, revision, supported definition, mutual exclusions in both directions, ownership, funds and current price. Debit and per-life receipt commit before the native effect. Repeated requests cannot charge or add membership twice. Recovery reasserts paid catalog traits missing from an older player profile, without paying or charging again. Death clears receipts with the wallet; a replacement cannot recover the prior life's purchases.

Native `sendSyncPlayerFields(player, 2)` sends the server's trait membership to the owning player. UI state uses bounded player-targeted snapshots. No client currency writes, admin privileges or client global-ModData imports are involved. Native player profiles and global ModData are separate save files: complete normal saves/restarts are tested, but this does not claim atomic power-loss recovery across independently written native files. Restore complete world backups. A purchased trait is a per-life entitlement; another mod intentionally removing it will have that removal reversed while the definition remains supported.

## Source and skill evidence

Applied the PZ modding, Lua and B42 multiplayer skills. No `pcall`, `xpcall`, `ipairs`, `next`, `goto`, tab indentation, custom events or copied third-party gameplay code are shipped.

- Live `CharacterCreationProfession.PointToSpend/negativeTraitOffset`, plus `CharacterProfessionDefinition` and `CharacterTraitDefinition`, establish creation-point reconstruction and exclusions.
- Live generated `character_traits.txt` establishes current IDs, costs and effect metadata. The native server probe checks all ten definitions again through the Java bridge.
- `IsoGameCharacter` hunger/thirst, panic and ingestion logic; `BodyDamage` panic, illness and healing routines; `ISReadABook` reading duration; `ItemContainer.getEffectiveCapacity`; and native item-transfer code read the supported trait flags during ongoing behavior. Fast Healer affects the native rules for subsequent wounds; this mod does not rewrite existing injuries.
- Installed JAR `LuaManager.GlobalObject.sendSyncPlayerFields`, `GameServer.sendSyncPlayerFields` and `SyncPlayerFieldsPacket` establish the server-to-owner trait packet. The admin-only `SyncXp` path is not used.
- Live `ISEquippedItem.prerender/removeFromUIManager/checkSidebarSizeOption` and ISUI classes establish the sidebar lifecycle. The subscribed Trait Purchase System is a behavior reference only.
- B42.20 translation loading uses `Translate/EN/UI.json` and `Sandbox.json`; the native probe invokes `Translator.loadFiles` after mods are initialized and verifies both. The client uses this order in `Core.ResetLua`; dedicated startup otherwise loads its translation cache before mods. The older text-file naming in skill examples is superseded by the target build's actual loader.
- Extensionless `tryGetTexture("OMHTS_ShopIcon")` resolves the owner's unchanged PNG under `media/textures`; a sprite lookup without the fallback would not load a standalone file.

## Verification

- All 11 packaged Lua files compile in the installed Kahlua VM; the fundamentals audit passes.
- All 53 Phase 1 regression assertions pass with schema 2 and shop snapshots.
- 93 Phase 2 assertions cover creation budgets/penalties/granted-trait graphs, migration, transactions, replay/foreign-life rejection, malformed requests, native table serialization, recovery, client retries, UI lifecycle and hover geometry. UI fixtures execute the shipped Lua with UI doubles; they do not prove actual rendering or live network delivery.
- Three real dedicated-server save/restart cycles with native IsoPlayer/trait/container objects verify the ten-entry catalog, starting eight Tokens, purchases for two plus four, a remaining balance of two, and Organized's actual capacity change from 10 to 13. Restart restores receipts and effects; death/replacement removes the old entitlement and grants starting Tokens once. No player joined this isolated probe.
- The multiplayer skill audit reports no high-severity findings. Its one medium warning matches `ISScrollingListBox:addItem` in the UI, which adds a display row, not an inventory item; reviewed as a false positive.

Final release-tooling results and native log hashes are recorded in [PHASE_2_EVIDENCE.txt](PHASE_2_EVIDENCE.txt). Actual UI appearance, player joins/reconnects and hosted account binding remain owner acceptance checks. No source mirror or Workshop upload is performed by this implementation.
