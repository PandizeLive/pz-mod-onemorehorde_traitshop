# v0.8.1.1 - multiplayer Prestige creation loading

## Problem and correction

Read-only dedicated/client capture `OMH/tools/bisect-sftp/mod-isolation/deep-diagnostic/captures/20260919T234030Z-hang` showed both sides on Trait Shop 0.8.1 and Horde Night 0.6.15.1. The server answered 255 repeating creation-preview requests while the client remained in creation. This was a transport deadlock, not missing earned currency or a version mismatch.

B42.20.4 queues ordinary GlobalModData packets until playerConnectSent. The shop disabled Play while waiting for that queued reply. A nonexistent table produces a false reply through the same blocked packet type, so even an account with no Prestige could not proceed.

The server now registers the empty `OMHTS_Creation` GlobalObjectSystem. Its initial-state callback reads authoritative account records and exports only creation bonus amounts. Native ConnectionDetails carries this state during connection; the client registers/reads it on OnConnected, after native loadInitialState and before creation. Registration is never attempted early from a constructor/render path. A complete ready map gives absent accounts zero. An invalid account or missing/invalid bootstrap produces a specific unavailable message and no first-join request loop.

After entering the world, the original ModData request path still refreshes each new creation context, so subsequent deaths use current balances. Disconnect invalidates context and cached bootstrap, even if a descriptor is reused. SP file previews, server-authoritative budget checks, one-time settlement, retention and physical purchases remain unchanged. No save reset or currency migration is needed.

## Native evidence and limits

Installed game and bytecode: 42.20.4. `GlobalModDataPacket` handlingType=3 excludes ClientLoading; `PacketTypes.PacketType.onClientLoadingPacket` rejects that route and GameClient queues it while playerConnectSent=false. Replacing it with ordinary client/server commands would have the same limitation.

`ConnectionDetails.writeGlobalObjects` invokes `SGlobalObjects.saveInitialStateForClient`; `ConnectToServerState.receiveGlobalObjects` loads it before receiveWorldDictionary fires OnConnected. Live vanilla `Map/SGlobalObjectSystem.lua` and `Map/CGlobalObjectSystem.lua` use these registered systems. `CGlobalObjects.registerSystem` imports the initial table. `IngameState.enter` subsequently fires OnGameStart and sends player connect. Secondary 42.20.2 decompile was checked against installed 42.20.4 javap output, including `.local/globalobjects-bytecode.txt`.

The connection preview is shared with joining clients: account keys and nonzero creation bonuses only, plus invalid-record markers. It contains no wallets, purchased traits, audit flags or complete account records. Existing account-specific preview tags were already readable through native ModData requests. This map is display input only, never authority for spending. It is sparse and generated once per connection, with work proportional to saved accounts, not per-frame scanning. No new periodic task, physical world object, client mutation endpoint or duplicate persistent currency store is introduced.

## Validation

- All 22 shipped Lua files compile in the installed Kahlua VM; fundamentals audit passes without pcall/xpcall, ipairs, next, goto or tabs.
- 771 assertions: 191 foundation/progression, 261 shop/UI/physical, 207 rewards/sandbox, 73 Prestige, 39 Horde Night. The largest existing shop snapshot is 50,017 bytes.
- The actual installed SGlobalObjects initial-state writer calls the shipped Lua callback, then the actual CGlobalObjects loader/register path restores its output with playerConnectSent=false. Positive entitlement, invalid authority and native client reset/reconnect are checked. Exercised initial payloads are 66-118 bytes.
- UI regression covers creation before OnConnected, fresh zero balances, positive bonuses, no repeated first-join requests, malformed authority/account data, account isolation, cancellation, reconnect invalidation and same-connection respawn refreshes.
- Real dedicated-server probe: `.local/phase7-server-95d3dc8e84404a61bc260d996bd16050/stage-{1,2,3}.log`. Each loads 0.8.1.1 and exits gracefully. Native registration/callback, current death entitlement, restart reconstruction, one-time creation grants and 3 -> 1 -> 0 retention passed. No OMHTS Lua exception or failed probe assertion. Logs also contain game asset/directory and map warnings unrelated to this new callback; they are not described as globally error-free logs.

The earlier harness failures were missing Rand initialization, instance-versus-static playerConnectSent access, and an absent ModData.get fixture; they were corrected before passing results. The old tests injected a reply directly and therefore missed the original transport restriction.

No human client joined the automated dedicated probe. Connected dedicated first join, reconnect with pending Prestige, and hosted first join still require acceptance. See TEST_v0.8.1.1.md for the six-step dedicated test after publishing both matching client/server copies. This patch does not complete Checkpoint 9.

## Changed files and release

Runtime: new server OMHTS_CreationBootstrap, client OMHTS_CreationScreen, shared Prestige system name, UI translation and 0.8.1.1 version markers. Tests: native initial-state runner, bootstrap fixtures, creation UI assertions and dedicated CP7 startup/persistence probe. Documentation: patch/PR/test/Steam changelog, README and roadmap handoff.

Target local tag: v0.8.1.1 on codex/phase-2. No Horde Night source changes. The live Workshop description was retrieved and preserved in `.local/workshop-before-v0.8.1.1.html`; it still describes the older 0.4.3 development build. This corrective update deliberately preserves that owner-facing description, artwork and visibility. The publisher omits those fields and submits only content/changelog. GitHub mirror and Workshop upload remain owner-run via OMH_TraitShop.cmd options 2 then 3.
