# B42.22 single-player compatibility - 0.9.1.2

Fix a single-player error on Project Zomboid 42.22, where `IsoWorld.getGameMode()` returns a `GameMode` object instead of a string. `Prestige.localPath` now accepts either form and returns no path instead of throwing, so a creation-preview problem cannot interrupt state snapshots, saving or character creation. The preview file path is unchanged; no migration.

Dedicated and hosted servers were not affected. `versionMin` stays 42.20.0.

Offline suites pass against the installed 42.22 game jar, including new assertions that use the game's real `GameMode` object. Not verified in a live game at the time of this note. See [patch and verification](PATCH_v0.9.1.2.md).

Also included since the last mirror: publisher tooling that uploads through the running Steam client, the recorded 0.9.1.1 upload baseline (October 28, 2026), and the ID'd decision log in DECISIONS.md.
