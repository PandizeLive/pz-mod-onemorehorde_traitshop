# Validation and remaining acceptance

Current candidate: **Trait Shop 0.9.0 / Horde Night 0.6.16.3**, PZ 42.20.4. Both content uploads are confirmed. Website compatibility is deployed. See [release evidence](PUBLIC_RELEASE_READINESS.md) and the [single remaining targeted player test](TEST_PUBLIC_RELEASE.md). This is developer coverage tracking, not another player checklist.

## Established evidence

- Owner-reported solo shop/UI checks, purchases, progression, Prestige milestones and corrected respawn behavior passed across the recorded checkpoints.
- Latest dedicated/client captures load the intended pair, settle death, verify replacement creation and grant starting Tokens once. The previous client `observePlayers` loop is absent; vanilla startup/asset warnings are separate.
- CP9 automated checks: 777 Trait Shop assertions, 149 core settings assertions, native Kahlua compilation of 22 addon / 107 core files, three dedicated save/restart probe cycles. Core follow-up adds 34 integrity assertions and a fresh-client callback regression. These are automated/native results, not two human players.
- Website: 55 API tests; known Trait Shop/Character Unverified flags, x0.50 and multiplicative Cure scoring, frozen official boundaries and current-version configuration. Production bundle hash verified; public leaderboard and snapshot endpoints healthy; no existing public record removed or rewritten.
- Historical reports remain in CHECKPOINT_1.md through CHECKPOINT_9.md and individual PATCH/LIVE/DEDICATED reports. Their original pending statements do not override the current evidence above.

## Remaining live acceptance

The owner has not yet reported the focused two-player Prestige creation, shared faction lock/count, individual reward ownership, reconnect and membership-change sequence. TEST_PUBLIC_RELEASE.md contains the complete seven-step check. Inspect client and SFTP logs afterward; do not infer success from package uploads or automated probes.

Standalone and hosted/split-screen combinations, arbitrary third-party traits and optional negative-removal multiplayer combinations are not exhaustively certified. They remain compatibility coverage limits, not new required full test matrices. Broaden testing only for a demonstrated failure or changed behavior.

## Regression rules

- Start at displayed Level 1, 0 / 100 XP. Each earned level grants configured Tokens (default 1); displayed Levels 5, 10, etc. grant Prestige by default. Multi-level gains and repeated callbacks must not duplicate rewards.
- Creation points become starting Tokens once; they grant no XP/levels/Prestige. Death wipes Tokens/XP/level progress and settles retained plus earned Prestige once. Next creation uses the full bonus, then retains the configured share once. At 30%, 3 -> 1 -> 0 without fresh earnings.
- Purchases validate the complete cart and server prices; repeat requests cannot double-charge or stack effect grants. Native physical traits apply stat changes; zero-cost Other Traits remain read-only. Negative removal is default OFF, costs ceil(abs(value) * multiplier), and has no surcharge.
- XP rewards follow active mode and positive configured rates. Hybrid never pays one tagged kill twice. Enemy-player rewards use separate accounts and a same-victim cooldown; day/night survival follows full connected native dawn/dusk periods, not horde hours. Only connected, eligible non-casualty members receive horde completion rewards.
- Resizing/scrolling keeps every matching trait reachable. Plain-click toggles, Shift ranges, Ctrl+A, receipt removal, name/description search and server-conflict validation remain consistent. Gold XP bar uses current / required; tooltip lists sources without amounts.
- Run Options enables/disables shop access and rewards. Acquired benefits/Prestige force ON. There is no Locked Official Mode. Default-or-harder rules remain eligible; easier/removal/non-Horde reward settings disqualify the affected run. Character benefit/provenance history persists across new runs and addon removal.
- x0.50 applies once to eligible Trait Shop scoring; Cure +20% with Shop yields x0.60. UI, authoritative totals, exports, website and frozen official boundaries must agree. Restoring settings or respawning never erases old run flags; fix causes and reset for a fresh check.

## Public handoff

After the short multiplayer pass and log review, use the prepared Workshop description and owner-selected public visibility. Keep uploaded changelogs intact until a new gameplay change starts a new cumulative draft. No gameplay package changed in this release-readiness pass.
