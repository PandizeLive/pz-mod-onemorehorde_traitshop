# v0.8.1.1 - partial live acceptance and upload baseline

## Owner report - 2026-09-21

The owner reports that it appears done and working, explicitly noting that not all tests were performed. Accept the demonstrated first-join loading correction; do not mark the full Prestige or multiplayer acceptance matrix passed. No repeat of the full manual test was requested.

## Read-only log review

Capture: `OMH/tools/bisect-sftp/mod-isolation/deep-diagnostic/captures/20260921T051911Z-hang`, collected 2026-09-21 05:19 UTC from the dedicated server via SFTP and the local console.

- Client and server both load Trait Shop **0.8.1.1**.
- Client logs `creation Prestige from connection; slot=0; bonus=0`, followed by client game start and state ready for life 1. This demonstrates that the previously blocked first-join creation completed.
- Server registers the connection preview and Horde reward adapter API 3, captures 10 remaining creation points, grants 10 starting Tokens for life 1, and later logs death settlement/wallet reset.
- No OMHTS Lua exception, connection-preview-unavailable message, or repeated missing-preview request loop was found in the captured client/server logs.
- Logs still contain native asset/map warnings, including missing optional animation directories under the mod package; this is not a claim that all logs are error-free.

Unverified in this capture: first join with a nonzero saved Prestige bonus; a full 3 -> 1 -> 0 inheritance sequence with real clients; reconnect balance stability; hosted first join; two-player isolation. Existing automated/native persistence checks remain evidence for those implementation paths, not substitutes for live acceptance. Checkpoint 9 is the next implementation scope, pending owner approval.

## Confirmed Workshop content baseline

Workshop item **3803035618**, uploaded release **0.8.1.1**, completed **2026-09-20 23:11 local time**.

Evidence:
- `C:/Users/bandi/AppData/Local/OMH/TraitShopPublisher/Logs/traitshop-v0.8.1.1-20260920-231134.log` records `Uploading content...` and `Committing update...Success.Unloading Steam API...OK`.
- The matching `C:/Users/bandi/AppData/Local/OMH/TraitShopPublisher/traitshop-upload.vdf`, timestamp 23:11:16, identifies item 3803035618 and the v0.8.1.1 content changelog. It does not describe a preview-only upload.
- Dedicated and client version markers corroborate the uploaded build being in use.

Keep WORKSHOP_CHANGELOG.txt intact until the next gameplay change starts a new cumulative draft. The next draft should contain net changes after this confirmed 0.8.1.1 upload, preserving any later unpublished notes. No changelog or runtime source was changed during this review. Existing uncommitted RELEASE_TOOLING.md edits were preserved.
