# SteamUploader compatibility build

The existing Publish menus use Steam-Uploader-rs v0.3.0 with the reviewed patch in this directory. Keep Steam open and signed in to the Workshop owner account; close Project Zomboid. No saved Steam credentials, Guard prompt, Steam shutdown or Steam restart is used.

The workspace binary is `.tools/steam-uploader/SteamUploader.exe`, with its matching Steamworks DLL. Each project carries the same helper, patch and build recipe so it remains independently maintainable. `OMH_STEAM_UPLOADER` can override the binary path, but the executable must report protocol 1. The original downloaded executable is untouched and deliberately rejected by this workflow: it requires metadata fields and can exit zero after upload errors.

## Preserved presentation

| Project | Cover supplied | Description and tags |
| --- | --- | --- |
| Horde Night, item 3777891317 | Existing root preview.gif, 969089 bytes | Omitted; Steam retains them |
| Trait Shop, item 3803035618 | Existing root preview.gif, 801794 bytes | Omitted; Steam retains them |
| Turrets & Traps | Omitted; current cover retained | Omitted; Steam retains them |
| New Music: Mixtape Separator | Existing approved preview.png | Omitted; Steam retains them |

Both GIFs matched the live Workshop covers byte-for-byte on 2026-10-31. Horde Night's source is `OMH/Images/Horde Night/160c400p.gif`; its oversized `art/workshop-cover.gif` is not used. Existing titles are also omitted. Horde Night and Trait Shop preserve visibility; T&T and NMMS retain their existing Unlisted policy. The Trait Shop creation path still requires complete metadata, a preview and Private visibility, and retains its duplicate-creation recovery marker. Routine updates never create an item.

The Rust patch makes fields optional and only invokes a Steam setter for a supplied field. This preserves live metadata without a public API fetch, including unlisted items. Preview validation accepts GIF/PNG/JPEG below 1 MiB. Steam remains the final authority on image acceptance.

## Confirmation and evidence

Each upload saves a unique sparse JSON manifest, exact preview copy, change-note file, output log and result receipt. Receipts include item ID, upload kind/version, hashes and exit code. A successful process alone is insufficient: the patched executable emits `OMH_UPLOAD_CONFIRMED:<item-id>` only after the successful Steam submit callback, matching ID and accepted Workshop agreement. The wrapper requires exit zero and exactly one matching confirmation, with no failure text. Rejection, crash, missing confirmation and timeout remain unconfirmed; interrupted processes retain pending evidence. Inspect Steam before retrying an ambiguous outcome because a remote commit may have happened before the local interruption.

Dry runs validate without initializing Steam and are marked `preflight`. Preview and leaderboard uploads are separately labeled. No failed, unverified, preview-only or leaderboard-only attempt advances a gameplay changelog baseline. Existing cumulative changelogs are never cleared by this integration. T&T still publishes its frozen content/changelog snapshot and only writes release evidence after confirmation.

## Rebuild

Upstream: https://github.com/SimKDT/Steam-Uploader-rs/releases/tag/v0.3.0
Pinned commit: `73c6db2702114cafe3ab67e2843c2a1ba16feacb`.
Install Git, Rust with the Windows MSVC target, and Visual Studio C++ build tools. The validated toolchain was Rust 1.99.1. Run `Build.ps1 -WorkspaceRoot <workspace>` with a suitable `-CargoExecutable` when Cargo is not on PATH. Dependencies are locked; the patch includes the upstream Cargo.lock package-version correction. `BUILD.json` records the deployed hashes. Review future upstream changes before replacing the patch; do not point the publisher at the stock binary.

Upstream license is retained in LICENSE.upstream. Steamworks DLL comes from the pinned steamworks-sys 0.13.0 dependency and remains a local build artifact.

## Verification on 2026-10-31

- Rust tests: sparse metadata, new-item restrictions, matching callback ID and agreement requirement.
- `tools/Test-SteamUploader.ps1`: real executable dry run with existing cover; preview hash unchanged; Steam PID unchanged; missing-preview failure; actual process timeout/start failure; eight simulated unconfirmed outcomes and exact-item simulated success.
- Existing suites: Horde Night 30 publisher checks; Trait Shop 36 release-tooling checks; T&T 15 staging/publication checks including unchanged baseline after failure. NMMS existing-item and metadata checks.
- No live upload, gameplay version change, release promotion or changelog-baseline reset. The first actual publication remains an owner-run check through the existing menu.

API contract: https://partner.steamgames.com/doc/api/ISteamUGC#SetItemPreview and https://partner.steamgames.com/doc/api/ISteamUGC#SubmitItemUpdate
