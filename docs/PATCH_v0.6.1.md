# v0.6.1 — Level-up feedback

New characters display Trait Level 1 and 0 / 100 XP toward Level 2. Existing characters display one level higher while preserving earned levels, XP, Tokens and prestige. The schema-3 `level` field remains the number of XP-earned levels: starting at zero prevents a free Token or Prestige Point and requires no save migration. Token tooltips continue to count earned levels. Five earned levels produce the first prestige milestone at displayed Level 6; subsequent milestones are 11, 16, and so on. The Checkpoint 5 XP curve is unchanged.

Accepted authoritative level increases play the owner's normal sound, or the prestige sound instead when earned prestige also increases. Each accepted batch produces one sound and gold (#E7B428) `Trait Level Up!` overhead text, whether or not the shop is open. This runs locally in singleplayer and multiplayer without world noise or broadcasting to other clients.

The client requires a living current actor, living same-life previous state, a newer revision and a higher earned-level count. Multiplayer also requires an already completed character handshake. Initial load, reconnect, replacement characters, dead states, duplicate/stale snapshots and wallet-only changes stay quiet. A batch crossing multiple milestones uses one prestige celebration. Native halo text can coalesce repeated text while it remains visible.

## Assets and native evidence

Source files are `../Audio/Trait Shop/levelup.wav` and `levelup_prestige.wav`, copied byte-for-byte into `42.20/media/sound/OMHTS_LevelUp.wav` and `OMHTS_PrestigeLevelUp.wav`. Both are 48 kHz, 16-bit stereo PCM, approximately 5.727 seconds. Source SHA-256:

- Normal: `F9182299139E3B99454ED8344C86DBFF0882E8345D30C39882ABBDD29C0EEE79`
- Prestige: `05A2104B5CAB7C820EB8891EE90EA2674E641C1BDB788893C1169467B93BB19E`

Native 42.20.4 `GameSoundScript.Load` accepts both packaged definitions as non-spatial UI sounds and resolves their packaged WAV paths. Java audio decoding accepts both PCM files. `HaloTextHelper.addText(IsoPlayer, String, String, int, int, int)` is verified against the installed JAR. Readable 42.20.2 `HaloTextHelper.addText` and `SoundManager.playUISound` establish local halo/UI-emitter behavior; vanilla `ISButton` uses that sound API. No world emitter or custom network command was added.

## Verification

- All 17 shipped Lua files compile in the native Kahlua VM; fundamentals audit passes.
- Phase 1 plus notification regression: 138 assertions, including singleplayer/client feedback and suppression cases above.
- Shop/UI regression: 222 assertions, including Level 1 display without granting earned progression and unchanged 0 / 100 requirement.
- Native sound-script parsing, PCM decoding and source/package hash comparisons pass.
- Actual playback volume, native overhead appearance and live multiplayer delivery remain owner checks. No install, mirror or Workshop upload is implied.

Sandbox category headers remain a separate, unapproved proposal.

## Test now

1. Close the game. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd) → 1, then launch through Steam. For dedicated testing, mirror/upload this version and restart the server first.
2. Use a new character with Kills or Hybrid mode and temporarily set Zombie XP to 100. The shop should show Level 1, 0 / 100 XP, and no earned prestige.
3. Close the shop and kill one ordinary zombie. Expect the normal sound and gold `Trait Level Up!`; reopen the shop to see Level 2 and one earned Token.
4. Kill nine more ordinary zombies. At ten total, expect the prestige sound instead of the normal sound, displayed Level 6, and one earned Prestige Point.
5. Quit/rejoin the same character. Progress must persist without a level-up sound or text on joining. Restore Zombie XP to 2.
6. Report whether both sounds, overhead text, Level 1 start and quiet reconnect passed, plus whether the test was solo or dedicated.
