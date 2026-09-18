# Checkpoint 7 — Prestige creation bonus and retention

Build: **0.7.0**, companion Horde Night **0.6.14**. Implementation complete; player acceptance of the creation screen and its real pre-spawn multiplayer request remains pending.

## Behavior

The full available Prestige becomes additional character-creation points. Successful entry converts remaining creation points into Tokens and retains the configured percentage of the original bonus. Default retention is 30%, rounded to the nearest whole point with halves up and no minimum. With no new earnings, 3 → 1 → 0. Tokens, earned levels and XP reset on death; the displayed starting level remains 1. Creation points never award levels or new Prestige.

The new **Prestige** sandbox section contains **Prestige Retention Percentage**, integer 0–100, default 30. Zero still gives the full creation bonus but retains nothing. A setting change affects future entries; it does not recalculate a completed grant. The Token tooltip separates the creation bonus and its unused portion. Bookkeeping treats ordinary creation points as spent first, so unused Prestige is `min(remaining points, bonus)`; the total grant is unaffected by this convention.

## Authority and persistence

- Native profession, selected trait costs, granted/free traits and NegativeTraitsPenalty reconstruct the creation budget. Add the saved server bonus before validating the final nonnegative balance, allowing Prestige-funded selections beyond the vanilla budget.
- The existing authoritative birth capture includes that bonus. A single settlement writes starting Tokens, the original Prestige bonus, unused Prestige Tokens, retention percentage, provenance and the consumed pending balance. Repeated birth/attachment callbacks cannot repeat settlement. Cancellation only reads a preview and never changes the balance.
- The existing schema-3 state gains optional validated fields; old saves retain their balances. Pre-audit Prestige has unverified origin. Existing aged characters cannot claim retroactive creation grants; pending entitlements wait for their replacement.
- Multiplayer creation uses `ModData.request` for a separate, minimal preview per account/slot. The response contains only schema, bonus and revision, never the wallet, accounts table, username or receipts. Preview tags are predictable; another authenticated client who knows an account name can request its next-life bonus. These previews are display data, never authorization. Client pushes have no server listener and cannot replace the ledger or previews.
- The creation screen disables Next while waiting, retries at most every two seconds, and rejects invalid, unrelated and older replies. The server still decides the grant from its account identity and saved state. Native co-op screens inherit the wrapped point calculation.
- Singleplayer uses a small menu-readable preview file scoped to game mode, save name and slot. It survives ResetLua and is written only when the bonus changes. Fresh worlds ignore old previews. The authoritative world state still settles the grant. An old save upgraded while already at the creation screen has no preexisting preview: its preserved bonus is included in unused starting Tokens on entry, and subsequent lives have the normal creation preview. Restoring only part of a save/cache backup can stale the display preview; it cannot increase the authoritative grant.

## Official origin

New earnings preserve whether their XP/life used reviewed official settings. Standalone/custom earnings and pre-audit saves remain unverified. Spending inherited custom Prestige marks that character, including when retention rounds to zero; its future Prestige earnings retain that origin. Restoring settings or starting a new OMH run cannot clear the applied creation benefit.

Horde Night 0.6.14 reviews retention (0–30 default-or-harder, 31–100 Lessened). Personal runs and active faction members check inherited origin; missing authority is Unknown, confirmed custom inheritance is Lessened. Existing persistent flags and score boundaries are reused. No new website flag or score format is introduced. Full mod-removal, lock enforcement and all character-advantage provenance remain Checkpoint 9 work; this is not a claim that every competitive bypass is closed.

## Native evidence

Installed Build 42.20.4 Lua and the local 42.20.2 Java decompile were inspected together:

- `CharacterCreationProfession.PointToSpend` and `render`: wrap the native budget and Next control without modifying shared CharacterFreePoints.
- `CoopCharacterCreationProfession` inherits the point calculation; `CoopCharacterCreation.playerIndex` and `CoopUserName.getUserName` provide the native slot/account context.
- `GameServer.receiveClientCommand` requires an existing player. `GlobalModDataRequestPacket` requires LoginOnServer; `GlobalModData.receiveRequest` replies to the requesting connection without an IsoPlayer. `GlobalModDataPacket.parse` delivers OnReceiveGlobalModData without installing the received table.
- `LuaManager.getFileReader/getFileWriter` support the small .txt menu cache under the Lua cache directory. The cache stores no multiplayer balances.

## Validation

Native Kahlua tests cover creation overspending funded by Prestige, the 3 → 1 → 0 sequence, 0/100% and half-up retention, repeat death/entry, native serialization, invalid settings, overflow, old-character exclusion, provenance, account isolation, creation cancellation, stale responses and request throttling. Existing rewards, shop and UI suites remain required. The isolated server probe exercises actual IsoPlayer traits, sandbox defaults, birth capture and disk restarts; it does not connect a human client and cannot prove the pre-spawn UI handshake.

See [TEST_CHECKPOINT_7.md](TEST_CHECKPOINT_7.md) for the short first test. Dedicated acceptance follows the solo result and matching Workshop publication. Nothing is automatically pushed or published.

### Recorded automated results (September 18)

- 19/19 shipped Lua files compile in the installed Kahlua VM; no banned constructs or tabs.
- 191 foundation/progression/feedback, 207 reward/sandbox, 222 shop/UI and 46 new CP7 assertions passed.
- 149 Horde Night settings/persistence/score assertions passed, including retention and inherited personal/faction advantages.
- Three real dedicated-server save/restart cycles passed with graceful shutdown. Actual native traits and delayed birth capture produced the expected creation Tokens, then 3 -> 1 -> 0 retention. Evidence: `.local/phase7-server-652b701bebe743bf969e701a5359bded/stage-{1,2,3}.log`. This isolated candidate still printed the prior version label when copied; the tested gameplay code is included in 0.7.0. No human client connected.
- Native startup also emitted the previously observed base-game content/map warnings; no Trait Shop probe failure occurred. This is not a claim that the whole native server log is warning-free.
