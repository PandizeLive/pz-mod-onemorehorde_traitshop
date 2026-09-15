# Checkpoint 1 - Package and integration feasibility

Date: September 14, 2026. Build: **0.1.0**. Status: minimal package implemented; Kahlua compilation and isolated dedicated-server startup passed. Interactive singleplayer world-entry verification remains pending. Do not mark this checkpoint fully passed yet.

## Implemented scope

- Display name: OMH: Trait Shop. Mod ID: `OneMoreHorde_TraitShop`, selected to match the existing series convention.
- Package: `Contents/mods/OneMoreHorde_TraitShop/common/` plus `42.20/`; metadata minimum 42.20.0, actually tested against installed 42.20.4 (Steam build 24909800). Earlier 42.20 patch compatibility is not yet tested; this is not a B41 package.
- Three Lua files: shared module identity, client world-start marker, dedicated-server-start marker. They do not modify traits, settings, time, XP, player data, or scores. No required Horde Night dependency and no reward listeners.
- Copied the owner's Trait Shop image unchanged as the package icon. No third-party source or art is bundled.
- Independent local source project, with `.local/`, build output and Java classes ignored. No remote or Workshop identity assigned. Existing Horde Night repository and game/server settings were not edited.
- Renumbered the roadmap globally as Checkpoints 1-14 while retaining six phases. Corrected references to the moved Horde Night repository.

## Source evidence

The installed game is at `C:/Program Files (x86)/Steam/steamapps/common/ProjectZomboid`. Live Lua and installed JAR bytecode take precedence over older decompiles. The server startup log identifies `version=42.20.4 b0bbce05d5`.

### Health-hover menu

- Live `media/lua/client/ISUI/ISEquippedItem.lua`, `initialise`, `prerender`, and `removeFromUIManager`: the sidebar owns `healthBtn` and its normal health-panel behavior. The supplied two-icon hover menu is not provided by these vanilla functions.
- Subscribed `steamapps/workshop/content/108600/3211693903/mods/TraitsPurchaseSystem/42/media/lua/client/TraitsPurchaseSystem/ISEquippedItem.lua`: wraps `initialise` and `prerender` and creates `ISTraitsIconPopup`; visibility follows mouse-over of either health button or popup.
- Feasible path: original, small UI integration using the live sidebar button and an independently owned popup. Preserve existing wrappers, disposal and per-player ownership; account for sidebar size changes. Coexistence with another mod claiming the same hover area requires a live test in Checkpoint 3. No reference code is copied.

### Character-creation points and prestige

- Live `media/lua/client/OptionScreens/CharacterCreationProfession.lua`, `PointToSpend` (around line 860): remaining points include chosen-trait balance, profession cost, `SandboxVars.CharacterFreePoints`, and `negativeTraitOffset`.
- Its `negativeTraitOffset` uses the `NegativeTraitsPenalty` option and number of selected negative traits. Server reconstruction must include this rule, not just sum listed trait prices.
- Live `CoopCharacterCreationProfession.lua` derives from the same screen but overrides Next/Back navigation. A Next-button hook on the main screen alone would miss this route.
- The subscribed EarnTraitPoints example changes `PointToSpend` and uses client-side state. It establishes a presentation concept, not authoritative B42 persistence or transport suitable for this addon.
- Feasible singleplayer path: wrap the point calculation with the pending prestige bonus, capture the final creation selection, and settle exactly once when the life enters the world. Do not globally change CharacterFreePoints for every player. Ordinary unused-point conversion and prestige-derived conversion need separate bookkeeping.
- **Multiplayer constraint:** installed JAR bytecode for `GameServer.receiveClientCommand` returns when the connection has no player. Ordinary client commands cannot be assumed to fetch prestige before first spawn. A client-supplied remaining-point number cannot be trusted for authoritative Token grants.
- Candidate pre-creation transport: a minimal server-owned, read-only prestige snapshot via the game's global mod-data request path. The reference `GlobalModDataRequestPacket` requires LoginOnServer, and `GlobalModData.receiveRequest` replies to the requesting connection without requiring an IsoPlayer. Client receipt uses `OnReceiveGlobalModData`. This is a source-backed candidate, **not a proven pre-creation handshake**; verify current packet handling and actual join/respawn timing before implementing Checkpoint 7. A globally requestable table must not contain private account data or authoritative wallet state. Settle payload visibility and server validation during Checkpoint 2.
- Prestige screen presentation, cancellation/reconnect behavior, and server reconstruction remain mandatory validation work; the minimal loader does not prove them. Do not silently substitute client-trusted balances if the candidate transport fails.

### Trait catalog and effects

- Live `media/lua/client/ISUI/PlayerStats/ISPlayerStatsUI.lua`, `onAddTrait`: uses `getCharacterTraits():add`, `modifyTraitXPBoost`, free recipes, and an admin stats-send path. It demonstrates that trait effects can involve more than membership.
- Installed 42.20.4 `CharacterTraits.set/add/remove` bytecode changes the trait map and known-traits list; it does not by itself replay all character-creation initialization. Repeated add calls can also duplicate known-list entries, so purchase validation must reject already-owned traits before applying.
- Installed `IsoGameCharacter` exposes `getCharacterTraits`, `getDescriptor`, `modifyTraitXPBoost`, and `applyTraits`. Existence is not evidence that applying a whole creation routine mid-game is safe.
- Feasible path: a verified positive catalog and effect-specific adapters, server-approved mutations, and a validated synchronization route. The admin UI's privileged network path is not automatically appropriate for a normal player's shop purchase. Verify that route in Checkpoint 4; broad removal support remains last.

### Multiplayer identity

- Installed `IsoPlayer` bytecode exposes `getSteamID`, `getUsername` and `getOnlineID`. Online ID is a session routing identity, not an account key across death/reconnect.
- Proposed identity policy: world/server-scoped account identity, using a stable Steam ID where supported and authenticated username fallback for non-Steam, plus a separate persistent life identifier. Singleplayer needs its own world/player-slot identity. Final schema and split-screen/account semantics belong to Checkpoint 2.
- Store authoritative values separately from client-replaceable player modData. Never key identity from localized display names or trust a player identity supplied in purchase arguments.

### Horde Night integration

- Current repository: `C:/Users/bandi/Zomboid_Modding/OMH/pz-mod-onemorehorde_protectthecure`.
- `Contents/mods/OneMoreHorde_HordeNight/42.20/media/lua/server/OMH_ExtensionRuntime.lua`, `buildEventSnapshot`, `dispatchEventHook`, `notifyEventFinished`: `onFinished` receives a copied snapshot containing event/owner IDs, run generation, timestamps, outcome, reason, objective, quota and extension metadata.
- **Gap:** this snapshot does not include the event participant/casualty roster or per-player kill facts. It is insufficient by itself for the approved reward rule.
- Checkpoint 8 must add a narrow authoritative reward-data interface or enrich the existing extension snapshot and verify completion ordering. Reuse the core's existing event membership, casualty and kill ledger; do not infer eligibility from proximity or track new attendance thresholds. No core patch is made here.

## Verification performed

| Check | Result | Evidence / limitation |
|---|---|---|
| Game Kahlua compiler | Passed, 3/3 Lua files | `.local/checks/kahlua-syntax.log`; compiled against the installed game JAR. |
| Real dedicated-server startup | Passed | `.local/server-smoke/server-console.txt`: loaded `OneMoreHorde_TraitShop`, emitted shared/server markers, reached SERVER STARTED on B42.20.4. No Horde Night or other Workshop mods loaded. |
| Test isolation | Verified | Separate cache, save, database and mod folder under `.local/server-smoke`; Steam/public listing/UPnP disabled, bound to 127.0.0.1:17261. |
| Server shutdown | Process stopped after startup evidence | Input pipe was closed, so a graceful console quit was unavailable. Verified the owning loopback port and game Java path before stopping that test process. Save/reload is not claimed tested. |
| Game startup log review | No Trait Shop failure found | The log is not error-free: native content reports missing assets/sounds, map-property exceptions and mannequin/basement data warnings. The addon only logs startup and does not load custom world content. These messages did not prevent server startup; no blanket claim that all game errors were fixed. |
| Live singleplayer world entry | Pending | Requires the interactive test below; compilation/server startup do not substitute for this. |
| Multiplayer player join / prestige handshake | Not tested | Future checkpoint tests; no player connected in this startup-only test. |

## Owner test

Run [Test-Checkpoint1.cmd](../Test-Checkpoint1.cmd). It launches the installed game with a separate `.local/client-smoke` cache and only this addon selected, leaving normal saves and mod selections alone. Start a **new singleplayer Sandbox game**, enter the world, then quit normally. No shop window or button should exist in this checkpoint.

The log to review is `.local/client-smoke/console.txt`. Expected markers:

```text
[OMH Trait Shop] v0.1.0 shared loaded: singleplayer
[OMH Trait Shop] v0.1.0 client game started; checkpoint 1
```

Only after checking that log can the singleplayer load gate pass. Remaining pre-creation transport feasibility should be recorded as conditional until validated; it must not be represented as finished multiplayer prestige support.
