# Trait Shop release tooling

## Status and repository choice

Prepared September 14, 2026. The owner selected a separate private repository: [PandizeLive/pz-mod-onemorehorde_traitshop](https://github.com/PandizeLive/pz-mod-onemorehorde_traitshop). Creation and privacy were verified, and local `origin` points there. No branches were pushed during setup. No Steam Workshop item exists yet.

A separate repository keeps the addon's standalone releases, Workshop identity and change history independent of Horde Night. Both projects can share the local GitHub CLI and SteamCMD installation. Coordinated gameplay changes still need matching work in Horde Night; this repository choice does not implement that integration.

The current package is **v0.1.0, startup diagnostics only**. Release-tooling preparation does not make it a playable shop or mark later roadmap checkpoints complete.

## One launcher

Run the root [OMH.cmd](../OMH.cmd). The stable wrapper calls `tools/OMH-Release.ps1`; versions come from the packaged `mod.info` files.

| Option | Action |
|---|---|
| 1 | Install locally, backing up and verifying both the local mod and Workshop staging copy. Requires the game to be closed. |
| 2 | Mirror the current working branch and immutable version tag; create or update its draft PR against `main`. |
| 3 | Publish through SteamCMD. The first upload creates a private item; subsequent uploads update the recorded item. |
| 4 | Check package and installation paths without changing files. |
| 5 | Validate and display the Workshop upload manifest without files, credentials, network calls or upload. |
| 6 | Launch the isolated Checkpoint 1 singleplayer test after the game is closed. |
| 0 | Exit. |

The former `Test-Checkpoint1.cmd` is replaced by option 6. Trait Shop does not need the core mod's leaderboard patch option.

Useful command-line forms from this directory:

```powershell
.\OMH.cmd -Action Info
.\OMH.cmd -Action Check
.\OMH.cmd -Action Mirror -ValidateOnly
.\OMH.cmd -Action Publish -ValidateOnly
```

## Tagged content and local installation

The release tag is `v<modversion>` (currently `v0.1.0`). Work from a named development branch. The tag must be an ancestor of HEAD, and all `Contents` files must match it. Untracked files, including ignored build debris, are rejected. Tooling/documentation commits may follow the tag when packaged content is unchanged. Never move an existing release tag; use a new version/tag for changed packages.

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

`workshop.txt` has `id=0` until the owner creates the first Trait Shop item through option 3. The first upload requests private visibility and includes an accurate development title/description with `DISCLAIMER: This mod was made in tandem with ChatGPT`. It does not upload a cover. The owner must review final presentation and visibility before public release.

The publisher requires tagged content, committed release files and a verified GitHub mirror, then asks for `CREATE` or `PUBLISH`. It uses the shared `.tools/steamcmd/steamcmd.exe`. Steam credentials are encrypted using Windows credential export under `%LOCALAPPDATA%\OMH\TraitShopPublisher\steam-credential.xml`, separately from the core publisher. Steam Guard input is hidden. Upload manifests, recovery markers and masked logs live in that same Trait Shop publisher directory, outside Git. A running Steam client is closed for upload and restarted afterward; a running game blocks publication.

On successful first upload, the script reads the Steam-assigned ID from the returned VDF and writes it into `workshop.txt`. **Commit and mirror this identity change before the next upload.** If creation is interrupted, `creation-pending.json` prevents blindly creating a duplicate. The next attempt can recover a returned ID; otherwise inspect the retained VDF/log and your Workshop items before resolving the marker. Do not reset a known item ID to zero to retry an update.

Updates omit title, description, cover and visibility so the existing Workshop presentation is preserved. `WORKSHOP_CHANGELOG.txt` becomes a single-line BBCode change note. Both metadata and VDF generation reject Horde Night's Workshop ID `3777891317`.

Steam's documented create/update behavior uses an unset/zero published ID for creation, returns the new ID in the VDF, and only updates fields supplied in subsequent uploads. See [Steamworks Workshop implementation](https://partner.steamgames.com/doc/features/workshop/implementation). The separate private repository was created without pushing source using the [GitHub CLI repository-creation command](https://cli.github.com/manual/gh_repo_create).

## Verification

Run the offline checks with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\Test-ReleaseTooling.ps1
```

**30 checks passed on Windows PowerShell 5.1**, covering script parsing; read-only preflights; installation hashes and backups at both destinations; rollback after an induced second-copy failure; unrelated-mod preservation; rejection of linked paths, staged content changes, ignored package debris, missing tags, main-branch installs, dirty mirrors and incorrect push URLs; private-create/content-only-update manifests; Workshop ID recording and rejection; and empty GitHub PR-list handling. Fixtures/logs are retained in ignored `.local/release-tests` directories. Only the disposable-profile harness suppresses the game-process check. The real installer independently refused installation while Project Zomboid was running, without copying files.

No live GitHub push/PR mutation or Steam upload was run during verification. Authentication, live draft PR creation, first Workshop item creation and Steam restart still require owner-run validation. Singleplayer world entry remains the outstanding Checkpoint 1 test.
