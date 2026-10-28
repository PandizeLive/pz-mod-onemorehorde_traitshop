# Checkpoint 8 - Horde Night rewards

Builds: Trait Shop **0.8.0**, Horde Night **0.6.15** (bundled Cure package metadata also 0.6.15; Cure gameplay unchanged). Implementation prepared locally. Live dedicated acceptance and owner publication remain separate.

## Behavior

- Credited active-horde kills award 5 XP by default. Eligible connected survivors of their successfully completed horde receive 100 XP. Both rates remain configurable; zero disables a source.
- Hybrid reserves tagged zombies for the horde adapter: 5 XP total, never 5 + 2. Kills/Survival modes do not pay horde rewards. Missing or older Horde Night disables only horde sources and explains the missing requirement in the XP tooltip.
- The core identifies event members and casualties. Late connected eligible members qualify without an attendance timer. Disconnected/dead players, faction leavers, vigilante outsiders and casualties do not receive completion XP. Respawning does not clear the event's casualty. A completion recipient must still be the exact character captured by the core.
- Failed hordes, manual resets and faction disbanding pay no survival XP. Cleanup/quota retirement cannot create horde kill XP. Installing mid-event never retroactively pays earlier kills.
- New settings retain the existing dependency-aware default: Hybrid standalone, Horde Night with the dependency. Saved RewardMode values are respected; removing the dependency does not silently convert a saved Horde Night mode into Hybrid. The host must choose a standalone mode if desired.

## Boundary and persistence

Horde Night API 3 adds `onKill` after its existing exact-event death deduplication and participant kill ledger. Completion notifications include a minimal snapshot of eligible connected participants and character descriptor IDs. APIs 1 and 2 remain supported. The addon registers the hordeEvents capability only, without replacing core functions or accepting client reward requests.

Trait Shop's server-owned global ledger stores a monotonic participant kill count per event and a terminal receipt per completed event. Receipts are consumed even when a source is disabled or the player is ineligible, preventing replays after changing settings, respawning or reconnecting. Each callback pays at most one kill, never a historical count delta. On completion, per-player kill counters are discarded and the small terminal marker remains. Storage grows by one compact marker per completed horde; no per-frame history scan or per-zombie persistent record is added. Save/restart preserves markers and XP in the same authoritative store. Invalid persisted receipt shapes disable rewards and preserve the data.

Horde rewards use the existing revision checks, progression, Prestige provenance and once-per-second dirty-state delivery. Kill logging occurs at level changes; completion awards are logged. No per-kill catalog broadcast. Core's large engine is at Kahlua's local-variable limit, so its API reference is stored on its existing Engine table.

## Source evidence

- Installed Build 42.20.4 native Kahlua is used for syntax, execution and native table serialization. The local 42.20.2 decompile's `IsoZombie.onKilled`/OnZombieDead location is secondary evidence; existing native death delivery is consumed by Horde Night rather than invented by the addon.
- `OMH_Phase3HordeEngine.onZombieDead` rejects wrong-event/runtime identities, retirement jobs and duplicate death markers; `creditParticipantKill` uses the native `getAttackedBy` attribution and Ownership ledger. The new hook requires active execution and fires before elimination can finalize the event.
- `OMH_Phase4Ownership.creditParticipantKill`, `markParticipantCasualty`, `reconcileOwnerParticipants` and `finalizeEvent` supply credit, sticky casualty and membership semantics.
- `OMH_Phase3Scheduler.finishActiveEvent` notifies after finalized membership/outcome facts; `OMH_ExtensionRuntime` snapshots eligible online players using native descriptors.
- `OMH_Phase3Persistence.readPlayerId` uses username in multiplayer and `singleplayer:<slot>` in SP; Trait Shop resolves that identity only against current connected players.

## Validation and limits

The CP8 Kahlua suite runs the actual registry, extension runtime, Ownership module, extracted unchanged engine death/credit functions, adapter and Trait Shop authority together. It covers handler ordering, kill ownership, terminal/counter replays, native serialization, casualties, reconnect/respawn, late arrivals, missing/old dependencies, mode routing, API 1/2 compatibility and SP. Existing progression/shop/survival/creation suites remain passing. The isolated dedicated probe loads both real packages and exercises disk receipts and native characters over three restarts; no human client joins, so it does not prove client transport or two-player gameplay.

CP7's corrective solo test was reported passed by the owner. Its live pre-spawn dedicated creation check is combined with this checkpoint's short test. CP9's full official lock/history policy and CP10's website acceptance remain separate; this release does not declare the external leaderboard ready.

See [TEST_CHECKPOINT_8.md](TEST_CHECKPOINT_8.md). Publish both matching versions before the live dedicated test. Manual launchers preserve the existing Workshop description, artwork and visibility. Live descriptions were read September 19 and saved privately under `.local/workshop-cp8`; no page metadata is changed.

### Recorded checks (September 19, 2026)

- Trait Shop: 20/20 native Lua compilations; no pcall/xpcall/ipairs/next/goto or tabs in shipped Lua. Core: 106/106 native Lua compilations.
- 39 CP8 integration assertions; existing 191 foundation/progression/feedback, 222 shop/UI, 207 standalone reward/sandbox and 51 CP7 assertions passed (710 total).
- 149 core settings/persistence/score assertions and the existing Cure combat regression passed.
- Corrected paired build: `.local/phase8-server-f93fc1ee8d8d4820b4a144fe3b5d2bc0/stage-{1,2,3}.log`. Exact versions 0.8.0 / 0.6.15 and adapter registration are logged in all three native dedicated cycles. Graceful save/shutdown, disk receipts and offline-player exclusion passed without OMH runtime exceptions. Base-game map/content warnings remain.
- The earlier `phase8-server-99b1ecac5ce945e39b4a222eedc8cf03` attempt used the pre-fix core and is NOT accepted as paired-startup evidence: compilation exceeded Kahlua's 200-local ceiling. The engine reference was moved to its existing table, and the server harness now fails explicitly on OMH runtime exceptions or that compile error before reporting success.
