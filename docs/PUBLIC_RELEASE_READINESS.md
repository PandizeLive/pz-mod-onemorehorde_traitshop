# Public release readiness — September 21, 2026

**Release candidate:** Trait Shop 0.9.0 with Horde Night 0.6.16.3; PZ 42.20.4. Gameplay packages are already uploaded. Website compatibility is deployed. Final two-player acceptance and the owner-run Workshop page/visibility handoff remain; this is not a claim that every manual test has passed.

## Verified

- Trait Shop 0.9.0 source `1a7163c`, tag `v0.9.0`; Horde Night 0.6.16.3 source `f0cdccb`, tag `test/v0.6.16.3`.
- Successful content uploads: item 3803035618, `traitshop-v0.9.0-20260921-133340.log`; item 3777891317, `workshop-v0.6.16.3-20260921-142758.log`. Logs are under `%LOCALAPPDATA%/OMH/TraitShopPublisher/Logs` and `%LOCALAPPDATA%/OMH/WorkshopPublisher/Logs`, respectively. Both contain successful content commit evidence.
- Latest client console and read-only SFTP capture `OMH/tools/bisect-sftp/mod-isolation/deep-diagnostic/captures/20260921T194050Z-hang` load those versions. Dedicated life 3 death settled; character 107 verified; life 4 received 11 starting Tokens once. The former `observePlayers` client exception loop is absent from these logs. Unrelated vanilla startup/asset warnings remain.
- Owner reports the corrected local/dedicated behavior works. This does not prove the outstanding two-player cases or every optional mod combination.
- Website API deployed as `52fe4663-c746-42e6-9ffe-b20e92970edd`: 55 API tests, successful build/dry run, downloaded production bundle hash match, live version configuration verified, public endpoints healthy, existing published score unchanged. Full evidence: `OMH/OMH Website/RELEASE_TRAITSHOP_2026-09-21.md`.
- The live Workshop description was read before drafting additions. Owner wording and both GIF URLs are preserved in [the prepared description](WORKSHOP_DESCRIPTION.txt).

## Remaining handoff

Complete [the seven-step two-player test](TEST_PUBLIC_RELEASE.md). After a passing report and log review, update the Workshop description from the prepared text and choose public visibility in Steam. No new gameplay version/content upload is needed for these documentation and API changes. The page and visibility were not changed by this pass.

Keep both existing uploaded `WORKSHOP_CHANGELOG.txt` drafts intact. The next gameplay change starts a new cumulative draft from the confirmed versions above; website/docs-only work is not a new mod changelog. GitHub mirroring remains owner-run.

## Release limits

Zero-cost profession abilities/weight conditions are read-only. Native Strength/Fitness purchases apply stat changes; the game chooses the resulting trait. Generic declared trait effects are supported, but arbitrary third-party initialization/removal scripts are not guaranteed. Negative removal is optional/default OFF and makes an otherwise official Horde Night run unofficial when enabled. Existing characters without Horde Night creation proof remain playable but unverified; fixing the cause and resetting the run starts new eligibility, rather than erasing old flags.

SP/world and multiplayer/server accounts keep separate Prestige. Preserve complete save backups, including world ModData and native player records. No claim of tamper-proof user-controlled saves, universal mod compatibility, or complete hosted/split-screen acceptance is made.
