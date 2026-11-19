# B42.22 single-player compatibility - 0.9.1.2

Prepared 2026-11-18 from a Steam bug report relayed by the Horde Night chat (Horde decision 1O, option B: the fix belongs to Trait Shop). Local source only at the time of writing: not installed, committed, tagged, mirrored or uploaded.

## Report

Steam thread: https://steamcommunity.com/workshop/filedetails/discussion/3777891317/500617242799507098/ (posted in the Horde Night thread; the error is Trait Shop). Player on PZ 42.22.2, single player, Trait Shop version not stated (Workshop had 0.9.1.1).

```
java.lang.RuntimeException: __len not defined for operand
encode (OMHTS_Prestige.lua:19) <- localPath (:42) <- publish (:87) <- sendSnapshot (OMHTS_Authority.lua:89) <- bind (:159) / scanPlayers (:348, :372)
```

## Cause (verified)

`javap` on the installed `projectzomboid.jar` (dated 2026-11-09, Steam build 26486631): `IsoWorld.getGameMode()` and `Core.getGameMode()` now return `zombie.core.GameMode`. In 42.20 they returned `String`. `Prestige.localPath` passed that object to `Prestige.encode`, which takes `#value`. `IsoWorld.getWorld()` still returns `String`.

`GameMode.toString()` returns the plain id given at registration (`Apocalypse`, `Sandbox`, ...). Vanilla Lua builds save paths with `getWorld():getGameMode():toString()`, so the id is the same folder name the old string was. The preview path is unchanged and existing preview files still match; no migration.

## Impact on 0.9.1.1 with 42.22

- Single player only. Dedicated and hosted servers use the ModData branch and never call `localPath`.
- `Prestige.publish` threw inside `sendSnapshot` before the snapshot was sent, so the shop received no state updates. It also threw in `initialize` before "authority ready", and on the creation screen when making a new character in an existing save.
- It is the only `getGameMode()` call in Trait Shop Contents.

## Change

- `OMHTS_Prestige.lua`: `localPath` accepts either a string or the new object (`tostring`), and returns nil with one log line when the game cannot name the save. `publish` skips the preview file when there is no path. No `pcall` (project Lua rule).
- `OMHTS_CreationScreen.lua`: reads the preview only when a path exists; otherwise the bonus stays 0 as before for a missing file.
- Version 0.9.1.2 in `mod.info` and `OMHTS_Bootstrap.lua`. `versionMin` stays 42.20.0; the same code runs on both API shapes.
- Tests: `KahluaBehaviorCheck.java` exposes the game's real `GameMode.SANDBOX`; `checkpoint7.lua` adds 9 assertions (82 total).

## Verification

Run against the installed 42.22 jar and its Kahlua VM:

- The real `GameMode` object has no length (reproduces the reported throw).
- With the real object, `localPath` returns `OMHTraitShop/Sandbox/Fixture/prestige-0.txt`, identical to the string case, and the preview is written.
- Nil game mode and nil world return no path, publishing continues, and the preview recovers afterward.
- Test-Phase1 (lint, 26/26 files compile, 191 assertions), Phase2 (262), Checkpoint6 (207), Checkpoint7 (82), Checkpoint8 (45), DefenseXP (60 + 8) all pass.

## Not verified

- Not run in a live game. The harness calls `tostring` on an unexposed Java object; in game the object is exposed to Lua. Both paths end in `GameMode.toString()`, but the live single-player check is the proof.
- Not re-tested on a 42.20 or 42.21 game install (none available); the string branch is covered by the fixture.
- Whether 42.22 broke anything else in Trait Shop beyond this call. This patch addresses the reported error only.
