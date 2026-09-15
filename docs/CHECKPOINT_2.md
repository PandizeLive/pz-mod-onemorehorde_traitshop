# Checkpoint 2 - Persistent state and life identity

Build: **v0.2.0**, September 14, 2026. Phase 1 implementation is present; full acceptance requires the live player tests below. No shop, XP reward source or character-creation grant is active.

## Implemented behavior

- Singleplayer uses the local player slot within its save. Multiplayer uses the server-bound authenticated username plus native player slot, scoped to the server's world save. Split-screen records stay separate. Account renames/server-login changes do not silently transfer prestige. No 64-bit Steam ID passes through Lua numeric formatting.
- Each life receives a generated ID. The authority tracks the native character descriptor and survival age to distinguish a replacement from a reconnect. Ordinary positive-age save lag does not reset a wallet. A changed descriptor or fresh zero-age character replacing an aged life closes the old wallet; a known death always closes it first.
- Tokens, partial XP and Trait Level belong to the current life. Death clears them once, moving retained plus newly earned prestige into pending prestige. Repeated/late death callbacks cannot pay twice or touch a newer life. Pending prestige survives replacement/restart until the later creation-grant implementation consumes it; Phase 1 does not apply retention or grant creation points prematurely.
- Server code exposes a validated mutation function requiring the current life ID and revision. No network command invokes it. Future trusted reward/purchase code can use that boundary. Updates reject negative/fractional Tokens, nonfinite/out-of-range counters, unknown fields, dead lives and stale revisions before writing.
- The only accepted client command is an empty `requestState` for its engine-bound sender. Requests are throttled per player. Fixed-size snapshots contain only that slot's visible state, no registry or account key. Clients validate/copy snapshots, reject older life/revision data, retry an unanswered initial read every five seconds, and clear cache on disconnect/world initialization.
- All Phase 1 records are marked development/unofficial internally. No development balance-changing network commands, debug rewards or official-score export are shipped. The internal marker does not implement Horde Night's eventual official-score integration.

## Persistence and lifecycle

The authoritative registry is the server/singleplayer table `OMHTraitShop_State_v1`, stored by native global ModData in the world's `global_mod_data.bin`. Back up the complete world, including that file and the player database. There are no balances in player mod-data, no client global-table imports and no client writes to the registry. Restoring only a player file is not a supported transaction rollback.

Schema 1 keeps a monotonic life counter and one current record per account/slot. Each record contains revision, current life, separate retained/earned/pending prestige, the last settled life and development provenance. No unbounded per-tick history is accumulated. Unknown/corrupt schemas or records are preserved and rejected rather than reset to defaults. Empty stores initialize once. Future schema changes must add explicit migration before changing the accepted version.

Native global ModData is requestable by clients who know a table name. This storage provides authoritative writes, **not confidentiality**: do not put credentials or private profile data in it. Normal transport sends only the player's own snapshot. The pre-creation snapshot proposed for the later prestige UI must remain a separate minimal payload; the account registry is not that UI protocol.

`OnCharacterDeath` handles both SP and dedicated player death, filtered to IsoPlayer. A once-per-real-second pass over connected/local players attaches new sessions and catches missed death events; it never scans zombies or world objects. Disconnected object bindings are released. Native world initialization rebinds persisted tables, and normal game saves persist them. Base-game character/profile data remains part of the trust boundary; this addon does not replace the game's anti-cheat or make native save files atomic with each other.

## Source anchors

- Installed B42.20.4 JAR: `IsoPlayer.getPlayerNum`, `getUsername`, `getHoursSurvived`; `IsoGameCharacter.OnDeath`; `GlobalModData.init/save/receiveRequest`; `LuaManager.GlobalObject` client/server command methods. The 42.20.2 decompile supplies readable control flow; current JAR signatures/bytecode are checked where relied upon.
- `GameServer.receivePlayerConnect` loads the native player profile, binds its slot and authenticated username, and registers the player before ordinary client commands are dispatched.
- `ServerPlayerDB` keys dedicated profiles by username/world/slot; hosted Steam profile storage differs, so host account/slot behavior remains a live test.
- `IsoPlayer.OnDeath` emits `OnPlayerDeath` only for local non-server players. Its parent `IsoGameCharacter.OnDeath` emits `OnCharacterDeath`, which is why the authority uses the latter.
- Native global ModData request returns a table; receiving a client global table only fires an event. The addon never imports such an event into its store.

## Automated verification

`tools/Test-Phase1.ps1` runs packaged Lua against the installed game VM, not stock Lua. **6/6 packaged files compile; 53 behavior checks pass.** Tests exercise nonzero wallet/XP/level persistence, distinct prestige fields, account/world/slot isolation, duplicate and late deaths, retired-life requests, malformed/future schema preservation, forged network requests, player mod-data clobber resistance, native binary table save/load, reconnect object replacement, and client retry/staleness handling. The native serialized snapshot is 243 bytes.

`tools/Test-Phase1Server.ps1` is a developer-only dedicated-server disk test, not a game-launch menu option. It stages an unshipped probe in a disposable loopback server, saves a nonzero record, restarts to check and settle it, then restarts again to verify the zero wallet and pending prestige. No player joins this test; its results cannot substitute for the reconnect test below. Probe code exists only under `tests/` and the ignored fixture cache.

**Three native B42.20.4 dedicated save/restart cycles passed**, each with a graceful console quit. The second process restored 37 Tokens, 2.5 XP, level 9 and distinct 1 retained/2 earned prestige; the third restored the replacement's zero wallet/XP/level and 3 pending prestige. Relevant log excerpts and hashes are in [CHECKPOINT_2_EVIDENCE.txt](CHECKPOINT_2_EVIDENCE.txt). Native asset/map warnings remain; no Trait Shop runtime error was found. The 30 release-tooling checks also passed with this build.

The PZ modding, Lua and multiplayer skills were applied alongside decompiled source and installed-JAR verification. The packaged Lua audit rejects `pcall`, `xpcall`, `ipairs`, `next`, `goto` and tabs. No custom Lua events, client-side currency writes or per-frame world scans were introduced.

## Normal Steam tests for acceptance

**Schedule updated September 15:** the owner deferred the dedicated player test until after Phase 2, when the shop and purchases provide meaningful visible behavior. Batch the remaining owner checks below into that complete acceptance checklist, including nonzero wallet and purchased-trait persistence. These checks do not block starting Phase 2 and are not being marked passed. Automated and source-based verification continues during implementation.

**Owner tests recorded September 14-15:** v0.2.0 entered a B42.20.4 singleplayer world, initialized schema 1 and created slot 0 / life 1 / revision 1. After normal world save/exit, the same character reloaded and resumed life 1 / revision 1; the client accepted life 1 again. Death then settled life 1 exactly once in the reviewed log, and the replacement initialized slot 0 / life 2 / revision 3; the client accepted life 2. No Trait Shop runtime error was found. Horde Night and Cure Defense were also loaded. Initial state initialization, same-character world reload and death/replacement pass with those addons; this live test has zero balances. Replacement reload, standalone isolation and multiplayer player tests remain pending. See [singleplayer evidence](CHECKPOINT_2_SINGLEPLAYER_EVIDENCE.txt).

Close the game, install v0.2.0 using **OMH.cmd -> 1**, and launch through Steam normally. No shop button is expected and balances begin at zero; reward earning belongs to Phase 3.

1. With only Trait Shop enabled, enter a new Sandbox world. Quit normally and reload that same character. Expect `authority ready`, `state created` on first entry, then `state resumed` with the same life ID and `client state ready`. This also covers Checkpoint 1's standalone SP gate.
2. Die and create a replacement in the same save. Expect one `death settled` for the retired life, then a different life ID. Reload the replacement to verify its ID stays stable.
3. Join a dedicated server with Trait Shop, disconnect and reconnect the same living character, then reconnect after a normal server save/restart. The server life ID must persist and the client must receive its snapshot. Repeat death/replacement and confirm a fresh zero wallet. Include a hosted Steam session for host-specific account binding.

Review the player's normal `%USERPROFILE%/Zomboid/console.txt` plus server logs. Do not report these live checks complete merely because the unit fixtures pass. Production has no balance-seeding command; automated tests cover nonzero values without adding a public debug grant path.
