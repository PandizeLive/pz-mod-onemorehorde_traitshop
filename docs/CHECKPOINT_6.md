# Checkpoint 6 - v0.6.0

Implements standalone XP earning and mode controls. Horde rewards remain Checkpoint 8; prestige creation bonuses/retention remain Checkpoint 7. Official scoring and the 0.50 multiplier are not implemented here.

## Rewards

| Source | Default XP | Active modes |
|---|---:|---|
| Ordinary zombie | 2 | Kills, Hybrid |
| Enemy player | 75 | Kills, Hybrid; multiplayer only |
| Day survived | 0 | Survival, Hybrid |
| Night survived | 25 | Survival, Hybrid |
| Horde zombie | 5 | Reserved; no adapter yet |
| Horde survived | 100 | Reserved; no adapter yet |

Hybrid is the standalone default. The shared module sets the native default to Horde Night when its dependency is loaded, before the dedicated server loads its saved sandbox file. Explicit saved values win. Built-in new-game presets receive the dependency default; user presets retain their values. Existing saved modes are not overwritten when dependencies change. Horde Night mode pays nothing until the adapter exists; select Hybrid or Kills/Survival to test these sources alongside Horde Night.

Solo sandbox, live admin sandbox and host settings editors hide/reflow inactive reward categories while retaining saved values. Hybrid shows all six categories. Server routing prevents hidden/disabled sources from paying. The XP tooltip uses validated server-provided active source names, excludes zero-rate sources and unavailable horde rewards, and lists no reward amounts.

## Attribution and persistence

Native OnZombieDead/OnCharacterDeath events supply the attacked-by player. There is no client award or kill-report command. Killers must be alive and connected (or the active local player in solo). Unknown attackers, self/same-account kills and same-faction kills receive no player XP. Different factions and factionless players qualify; eligibility is checked at death. This is an implementation choice under the approved outside-faction rule, not a faction-war system.

Player Kill Cooldown defaults to 48 game hours. Directional killer/victim pairs use authenticated server usernames, independent of character life/slot. Expiry survives death, reconnect and normal save/restart in server-owned global data. Reverse-direction pairs are independent. Changing the setting affects future rewarded kills, not existing expiry timestamps. Zero is configurable; duplicate notifications for the same death are still blocked. The existing account/world policy remains: account renames do not transfer history. This is not Steam-wide anti-alt protection, and different accounts can still collude.

Zombie deduplication uses native kill-completion state and a bounded 4,096-entry local cache reset for pooled zombie creation. No Lua weak-table assumption or client-writable zombie ModData receipt is used. Tagged OMHEventId zombies are excluded from ordinary XP while Horde Night is enabled, reserving a single future horde payout. The tag is only an exclusion, never authorization. Progress updates immediately; outbound shop snapshots batch through the one-second scan. Ordinary kills log only level transitions.

World/record schema 3 remains unchanged. An optional `rewards` table with schema 1 stores cooldowns and consumed player-death life IDs. Invalid reward data is preserved and disables rewards rather than clearing balances. Snapshot additions contain active source names and horde availability.

## Day/night correction

The owner's correction supersedes both fixed-hour proposals and the attempted link to OneMoreHorde.StartHour/EndHour. Day/night survival follows native seasonal dawn/dusk. Horde schedules can occur at any time and do not define day/night.

A complete connected dawn-to-dusk period earns Day XP; dusk-to-dawn earns Night XP. Joining/reconnecting/restarting mid-period forfeits that partial period. Sleep and fast-forward count. Endless day/night has no completed alternating periods and pays no survival XP. Changing mode/rates/cycle resets incomplete-period eligibility; clock rewinds reset tracking. Seasonal boundaries recalculate for each crossed date, including month/year changes. There are no custom night-hour controls.

Time skips process at most 12 dawn/dusk/midnight boundaries per player per scan, carrying larger backlogs to later scans without replay. Already-awarded XP persists. Incomplete periods and unprocessed exceptional multi-day backlogs are session-local and discarded on disconnect/restart; normal sleep/night skips fit within one bounded pass. No offline survival reward is granted.

## Evidence and limits

Applied Alex's PZ modding, Lua and B42 multiplayer skills. Readable reference: workspace `references/ProjectZomboid-42.20.2-decompiled/source/zombie`; execution checks use the installed 42.20.4 game/Kahlua VM.

- IsoGameCharacter.Kill/DoDeath, IsoZombie.onKilled and VirtualZombieManager.createRealZombieAlways establish attribution, death events and pooled-zombie creation.
- Faction.isInSameFaction establishes membership/owner exclusion.
- GameTime.isDay/isNight, ErosionSeason.getDawn/getDusk/setDay/clone and ClimateManager.updateDayInfo establish seasonal timing. GameTime supplies the calendar date because ClimateManager.getCurrentDay can be null during early server startup; the native test reproduced and fixed that issue.
- GameServer startup loads Lua before saved sandbox values.
- Native SandboxOptionsScreen.createPanel/addPresetToList, ISServerSandboxOptionsUI.createPanel and ServerSettingsScreen.create/Page3.createPanel establish UI integration.

Final results are in CHECKPOINT_6_EVIDENCE.txt. Native probes use isolated local servers without human/network clients; they do not establish live two-player acceptance. See TEST_CHECKPOINT_6.md for the owner test.
