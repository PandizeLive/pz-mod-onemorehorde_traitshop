# Checkpoint 9 — Run Options and character eligibility

Prepared pair: Trait Shop **0.9.0** and Horde Night/Cure Defense **0.6.16**. Use both matching updates. There is no Locked Official Mode.

## Player behavior

Run Options contains Checkpoints, Enable Trait Shop and the existing Difficulty Settings editor. These are drafts until Confirm in the main menu. Faction leadership controls changes; the addon toggle remains available to the run owner even when server difficulty selection is locked. Trait Shop is shown only when installed, defaults ON with Horde Night, and stays available standalone.

An unconfirmed default ON choice is a preview. Viewing the menu or repeatedly checking an unused disabled addon does not apply a penalty or taint its rules history. Confirming enabled applies x0.50 to that run. Actual XP, Prestige or purchases also records use. Existing run penalties persist after disabling. Purchases/removals or a creation Prestige grant force enabled for that character and any faction run they join. The dialog gives affected-character and Prestige counts. Ordinary unused creation Tokens alone do not force the addon or generate Prestige.

Server authority denies purchases and XP while disabled; the client closes/hides the shop. Disabled horde reward receipts are consumed, so re-enabling cannot replay them. Interrupted survival periods are restarted rather than credited across an off interval. Existing effects are retained.

Native OnNewGame creates server-owned character verification. Already-existing or missing/corrupt records remain unverified, including zero-hours characters. Reconnect does not create a clean record. Existing players can continue with unofficial scores, or create a character while Horde Night is active and start a new run. Apocalypse creation fingerprints and starting disadvantages/advantages use the existing vanilla policy. New characters still inherit any restrictions attached to Prestige.

The approved baseline remains costs x1/x2, negative removal OFF, Horde Night rewards 5/100, one Token per level, Prestige every five levels, retention 30%. Harder settings stay official; easier settings or leaving Horde Night rewards persist on the affected character/run. Earning provenance checks full Horde Night eligibility as well as Trait Shop settings. Partial XP is included; Prestige cannot become official merely through respawn or changing settings.

## Persistence and compatibility

Horde Night owns global ModData `OMH_CharacterIntegrity_v1`, keyed by existing player identity with current descriptor ID, verification, benefit markers and flags. No client receives a mutation route to that store. The ledger reads the existing Trait Shop schema-3 creation/purchase/removal receipts without requiring Trait Shop code to be loaded. Run reset/faction changes therefore cannot clear recorded benefits. An addon toggle changes access, not which Lua mods are loaded. Existing exports and score calculation retain their existing multiplicative x0.50 behavior; historical submissions are not rewritten.

Character records are local/server save authority, not cryptographic proof. A server owner or singleplayer user who deliberately edits/rolls back all related saved state is outside this trust boundary. The fresh-character rule closes the ordinary install-later path; it is not a claim of tamper-proof files.

New checks scan connected players and current faction participants, never the world. Complete earning classification is cached per owner for one real second; current shop/vanilla policy is rechecked during awards. UI work occurs on state changes; no full catalog work was added per frame.

## Native evidence and verification

Installed 42.20.4 `CreatePlayerPacket.serverProcess` bytecode fires OnNewGame after native profession/trait application and before saving the character. Secondary 42.20.2 CreatePlayerPacket/IsoWorld/GameLoadingState confirms the lifecycle ordering. Native global ModData owns persistence; existing commands address the server-selected player. Native ISRichTextPanel.paginate supports fixed-height scrollable explanations.

Validation completed: 777 Trait Shop assertions across the foundation, shop, rewards, Prestige and Horde integration suites; 149 core settings assertions; 30 new character/provenance/scoring assertions; Run Options and Difficulty presentation checks; 9,128 custom-editor category assertions and 13 native font/layout renders. All 107 core Lua files and 22 Trait Shop Lua files compile in installed Kahlua. The new production code contains no pcall/xpcall workarounds.

The paired versions passed three real dedicated-server save/restart cycles in `.local/phase9-server-b2f6b51b942345cebef8193181ee3272`. These exercised native character creation, disabled purchase/reward gates, persistent benefit locks, addon-account removal and fresh-character replacement. No feature Lua exceptions or probe failures occurred; unrelated vanilla asset/world-generation warnings remain. Automated probes do not represent a human client joining. Live Run Options presentation and real two-player faction acceptance still require the six-step test; previously incomplete nonzero inheritance/reconnect/hosted acceptance is not retroactively marked passed.

The website API policy now recognizes `Character Unverified` as a known disqualifying flag, rather than suspicious unknown data. Its eligibility/review suites pass 36 tests. This small local change is in the separate OMH Website workspace; its existing unrelated work was preserved. Deploy that reviewed API policy before public release. No website deployment or broad website commit was performed here.

## Publication baseline

Trait Shop 0.8.1.1 was successfully uploaded to item 3803035618: `%LOCALAPPDATA%/OMH/TraitShopPublisher/Logs/traitshop-v0.8.1.1-20260920-231134.log`, matching content manifest and successful content commit; see LIVE_v0.8.1.1.md.

Horde Night/Cure Defense 0.6.15.1 was successfully uploaded to item 3777891317: `%LOCALAPPDATA%/OMH/WorkshopPublisher/Logs/workshop-v0.6.15.1-20260919-190826.log` contains Uploading content and Committing update...Success. That publisher targets 3777891317 explicitly; subsequent dedicated logs previously verified 0.6.15.1 loaded. The pending changelog contained only that already-published release. Each next draft therefore begins with this update; these new drafts remain cumulative until their exact content upload succeeds.

Both live Workshop pages were retrieved into each repository's ignored `.local/workshop-before-v<version>.html` and their descriptions read. Owner page text, artwork and visibility are preserved. Content publishers omit these fields. No GitHub push, PR update or Workshop upload is executed by this task; the owner uses Mirror then Publish. Local source commits and tags provide the rollback point before installation.
