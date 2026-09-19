# Trait Shop release tooling

## First upload through Project Zomboid (owner-selected 2026-09-17)

The owner chose the in-game uploader for the first item. This route does not require the GitHub mirror or SteamCMD login prerequisite of the separate command-line publisher.

Prepared `C:/Users/bandi/Zomboid/Workshop/OneMoreHorde_TraitShop` with all 21 v0.4.3 content files hash-matching the source, `workshop.txt` containing the title/description/disclaimer, blank new-item ID and explicit private visibility, and a 512x512 PNG preview derived from the owner's still. The original 400x400 PNG and GIF are unchanged. Build 42.20.4's native `SteamWorkshopItem.validateContents()` accepted the staged folder; metadata read back as OMH: Trait Shop, private, no existing ID.

The in-game uploader specifically reads preview.png and accepts square 256 or 512 pixel images; the GIF remains available for a later SteamCMD preview update. Select this staged folder in the game's Workshop submission screen, create the item, review the metadata/visibility and publish. After upload, read the generated ID from the staged workshop.txt and record it in the repository's workshop.txt before using any other publisher. Never create a second item because the repository still says id=0.

## Status and repository choice

Prepared September 14, 2026. The owner selected a separate private repository: [PandizeLive/pz-mod-onemorehorde_traitshop](https://github.com/PandizeLive/pz-mod-onemorehorde_traitshop). Creation and privacy were verified, and local `origin` points there. No branches were pushed during setup. No Steam Workshop item exists yet.

A separate repository keeps the addon's standalone releases, Workshop identity and change history independent of Horde Night. Both projects can share the local GitHub CLI and SteamCMD installation. Coordinated gameplay changes still need matching work in Horde Night; this repository choice does not implement that integration.

The current package is **v0.8.0, Checkpoint 8 Horde Night rewards**, with the owner-supplied icons. Current behavior and acceptance are recorded in [CHECKPOINT_8.md](CHECKPOINT_8.md). The owner created **Workshop item 3803035618**, Unlisted, through the native uploader; the staged metadata was read back and that ID is now recorded in the repository. The owner uploaded v0.5.0, verified in dedicated logs. Update this existing item for v0.8.0; no v0.8.0 publication is implied by preparation.

## One launcher

Run the root [OMH_TraitShop.cmd](../OMH_TraitShop.cmd). The stable wrapper calls `tools/OMH-Release.ps1`; versions come from the packaged `mod.info` files.

| Option | Action |
|---|---|
| 1 | Install locally, backing up and verifying both the local mod and Workshop staging copy. Requires the game to be closed. |
| 2 | Mirror the current working branch and immutable version tag; create or update its draft PR against `main`. |
| 3 | Publish through SteamCMD. The first upload creates a private item; subsequent uploads update the recorded item. |
| 4 | Check package and installation paths without changing files. |
| 5 | Validate and display the Workshop upload manifest without files, credentials, network calls or upload. |
| 6 | Replace only the existing Trait Shop Workshop preview with preview.gif. Requires the normal mirrored-release check; type PREVIEW to upload. |
| 0 | Exit. |

Install with option 1, then launch Project Zomboid normally through Steam. The owner requested removal of the isolated game-launch option and helper. Trait Shop does not need the core mod's leaderboard patch option.

Useful command-line forms from this directory:

```powershell
.\OMH_TraitShop.cmd -Action Info
.\OMH_TraitShop.cmd -Action Check
.\OMH_TraitShop.cmd -Action Mirror -ValidateOnly
.\OMH_TraitShop.cmd -Action Publish -ValidateOnly
.\OMH_TraitShop.cmd -Action Preview -ValidateOnly
```

## Tagged content and local installation

The release tag is `v<modversion>` (currently `v0.8.0`). Work from a named development branch. The tag must be an ancestor of HEAD, and all `Contents` files must match it. Untracked files, including ignored build debris, are rejected. Tooling/documentation commits may follow the tag when packaged content is unchanged. Never move an existing release tag; use a new version/tag for changed packages.

Only `Contents/mods/OneMoreHorde_TraitShop` is installed. Default destinations are:

- `%USERPROFILE%\Zomboid\mods\OneMoreHorde_TraitShop`
- `%USERPROFILE%\Zomboid\Workshop\OneMoreHorde_TraitShop\Contents\mods\OneMoreHorde_TraitShop`

Previous copies move into `%USERPROFILE%\Zomboid\OMH-TraitShop-local-backups\before-v<VERSION>-<timestamp>\local` and `staging`. The installer verifies SHA-256 hashes and restores the previous copies if either copy fails. It validates exact package targets and rejects linked target paths/ancestors. Other mods, subscribed Workshop content and Steam launch options are left alone. A custom `-UserDataRoot` is available for disposable test profiles.

For manual recovery, close the game and restore each backed-up `OneMoreHorde_TraitShop` directory to its matching destination. Preserve any newer copy separately first; restore whole package directories so stale files do not mix across versions. An absent backup means there was no previous copy at that destination.

## GitHub mirror

`tools/omh-release.json` defines the expected repository and `main` base. The mirror validates fetch **and push** URLs, committed files, tag/content agreement and a prepared `docs/PR_v<VERSION>.md` body. It uses the shared `.tools/gh.exe` and `.gh-codex` when available, otherwise the installed GitHub CLI. The CLI must be signed into an account with access to this private repository.

On the **first owner-run mirror only**, an empty repository receives `main` at this project's original baseline commit, providing a base for the release PR. The menu then pushes the current development branch and version tag and creates the draft PR. Later mirrors never push `main`; they require its fetched history to be included locally. Branch/tag pushes are atomic and never forced. Conflicting tags or an existing non-draft PR stop the action. Reviewer configuration is initially blank; no collaborator access is granted automatically.

After merging a PR, start the next development branch from updated `main`. For package changes, bump metadata, update the changelog/PR body, commit and create the next version tag. Mirror again before publication. The publisher verifies that the exact current branch commit and tag exist remotely.

## Steam Workshop identity and upload

`workshop.txt` now has `id=3803035618`, recovered from the owner's first in-game upload. Normal publishing must update this existing item. Native first upload used its required PNG, while root preview.gif remains available for a separately approved cover change. Keep `DISCLAIMER: This mod was made in tandem with ChatGPT`. Later SteamCMD updates preserve existing presentation and visibility. The owner must review final presentation and visibility before public release.

The publisher requires tagged content, committed release files and a verified GitHub mirror, then asks for `CREATE` or `PUBLISH`. It uses the shared `.tools/steamcmd/steamcmd.exe`. Steam credentials are encrypted using Windows credential export under `%LOCALAPPDATA%\OMH\TraitShopPublisher\steam-credential.xml`, separately from the core publisher. Steam Guard input is hidden. Upload manifests, recovery markers and masked logs live in that same Trait Shop publisher directory, outside Git. A running Steam client is closed for upload and restarted afterward; a running game blocks publication.

On successful first upload, the script reads the Steam-assigned ID from the returned VDF and writes it into `workshop.txt`. **Commit and mirror this identity change before the next upload.** If creation is interrupted, `creation-pending.json` prevents blindly creating a duplicate. The next attempt can recover a returned ID; otherwise inspect the retained VDF/log and your Workshop items before resolving the marker. Do not reset a known item ID to zero to retry an update.

Updates omit title, description, previewfile and visibility so the existing Workshop presentation is preserved. `WORKSHOP_CHANGELOG.txt` becomes a single-line BBCode change note. Both metadata and VDF generation reject Horde Night's Workshop ID `3777891317`.

Steam's documented create/update behavior uses an unset/zero published ID for creation, returns the new ID in the VDF, and only updates fields supplied in subsequent uploads. See [Steamworks Workshop implementation](https://partner.steamgames.com/doc/features/workshop/implementation). The separate private repository was created without pushing source using the [GitHub CLI repository-creation command](https://cli.github.com/manual/gh_repo_create).

## Verification

Run the offline checks with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Test-ReleaseTooling.ps1
```

**30 checks passed on Windows PowerShell 5.1**, covering script parsing; read-only preflights; installation hashes and backups at both destinations; rollback after an induced second-copy failure; unrelated-mod preservation; rejection of linked paths, staged content changes, ignored package debris, missing tags, main-branch installs, dirty mirrors and incorrect push URLs; private-create/content-only-update manifests; Workshop ID recording and rejection; and empty GitHub PR-list handling. Fixtures/logs are retained in ignored `.local/release-tests` directories. Only the disposable-profile harness suppresses the game-process check. The real installer independently refused installation while Project Zomboid was running, without copying files.

No live GitHub push/PR mutation or Steam upload was run during tooling verification. Authentication, live draft PR creation, first Workshop item creation and Steam restart still require owner-run validation. The owner subsequently installed successfully; both destination copies match all six packaged source files. Singleplayer world entry alongside Horde Night/Cure Defense passed. Standalone singleplayer world entry remains the outstanding Checkpoint 1 load test.
