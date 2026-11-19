# Checkpoint 6 - v0.6.0 dedicated test

Use two players and disposable test characters for PvP. Full evidence is tracked separately in CHECKPOINT_6_EVIDENCE.txt.

1. Close Zomboid. Run [OMH_TraitShop.cmd](../OMH_TraitShop.cmd): **1** install, **2** mirror, **3** update Workshop. Stop/update/restart your dedicated server with v0.6.0.
2. Select **Hybrid** with default rewards. Cycle modes once: only matching reward settings should show; return to Hybrid. Horde rewards remain unavailable.
3. Join with fresh characters: unused creation points should match starting Tokens once. Kill 50 ordinary zombies: **2 XP each**, then **Level 1 and +1 Token**.
4. Kill the other player outside your faction: **+75 XP**. Have that same player respawn and repeat within two game days: **no second reward**. Same-faction kills must also give no XP.
5. Stay connected from before actual sunset through sunrise; sleep/fast-forward is fine. Expect **25 XP at dawn**, **0 for daytime**, independent of the horde schedule. Reconnecting midway forfeits that incomplete period.
6. Check the XP tooltip: active source names without amounts; zero-rate days should be absent. Record XP/level/Tokens, disconnect, then stop/restart/rejoin: progress must remain and the PvP cooldown must still apply.
7. Reply **Passed**, or identify the failing step. I will review the dedicated and client logs.

Exact cooldown expiry and reverse-direction behavior have automated coverage; no separate two-day wait is required for this test. Prestige character-creation bonuses remain Checkpoint 7.
