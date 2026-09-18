# Dedicated v0.5.0 log review

Owner reports the update is working on dedicated and is ready to proceed. Read-only SFTP capture completed at 2026-09-18 02:07 UTC (September 17 in the owner's timezone). No server files or settings were changed.

Capture: `OMH/tools/bisect-sftp/mod-isolation/deep-diagnostic/captures/20260918T020728Z-hang`, relative to the workspace. The collector's historical `hang` suffix does not indicate a hang in this session. The complete current server debug/console and connection/command logs were downloaded; the local client console was also captured.

## Confirmed

- Server debug lines 1522 and 2221: v0.5.0 loaded and dedicated Checkpoint 5 startup completed.
- Server debug line 2159: authority initialized with schema 3.
- Server debug line 2230: existing life 2 resumed at revision 5, with positive survived time, `creation=granted`, and historical `startingTokens=19`. This is the original grant amount, not a claim that the current wallet contains 19 Tokens. The settled life resumed rather than receiving a new creation grant.
- Client console lines 1175 and 1181: v0.5.0 game startup and state ready for the same life.
- No Trait Shop Lua exception or transaction failure found in this capture. Current command log contains state requests but no purchase command.

## Limits and follow-up

This session confirms startup and existing-character state restoration after the update. No new birth, death, purchase/removal, or live XP award occurred in the captured session. The new birth-capture path and progression persistence retain their previously recorded automated/native-server evidence; this session does not independently establish live acceptance for those paths. Carry focused remaining checks into the next checkpoint test rather than repeating the complete unchanged shop test.

The logs are not globally error-free: startup reports absent animation/actiongroup directories for Trait Shop and other OMH packages, plus native fluid-container and map/world-generation messages. No associated Trait Shop runtime failure was observed after entry. These are distinct from the successful authority/state exchange and should not be described as a completely clean game log.

Proceed to Checkpoint 6 design decisions within Phase 3: standalone reward sources and mode settings. Reward values, standalone default, player-kill uniqueness scope, survival timing, and Hybrid overlap remain unapproved. Checkpoint 7 adds prestige character-creation bonuses/retention; Checkpoint 8 adds live Horde Night rewards.
