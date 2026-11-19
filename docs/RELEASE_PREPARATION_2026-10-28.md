# Trait Shop 0.9.1.1 release preparation

Owner-approved local preparation only. No GitHub mirror, Workshop upload, website deployment, gameplay change, version bump or replacement tag is part of this checkpoint.

## Confirmed upload baseline

**Current baseline (recorded 2026-11-17):** Workshop item **3803035618** last successfully uploaded **0.9.1.1** on October 28, 2026. Evidence: `C:/Users/bandi/AppData/Local/OMH/TraitShopPublisher/Logs/traitshop-v0.9.1.1-20261028-150449.log`, containing `Uploading content...` and `Committing update...Success`. Packaged `mod.info`, the installed copies and the `v0.9.1.1` tag all agree on 0.9.1.1, and Contents are identical to that tag. WORKSHOP_CHANGELOG.txt now holds the published 0.9.1.1 notes; retain it until the next change starts a new draft, and do not republish those notes. The live Steam change-notes page was not read for this record.

**Baseline at preparation time (superseded by the upload above):** Workshop item **3803035618** had last successfully uploaded **0.9.0.1** on September 21, 2026. Evidence: `C:/Users/bandi/AppData/Local/OMH/TraitShopPublisher/Logs/traitshop-v0.9.0.1-20260921-203514.log`, containing `Uploading content...` and `Committing update...Success`; retained `traitshop-upload.vdf` targets that exact item and includes the 0.9.0.1 change note. This agrees with PATCH_v0.9.0.1.md and PUBLIC_RELEASE_READINESS.md.

Compared all commits after `v0.9.0.1` with the pending draft. Removed only the already-published starting-Token provenance correction. Combined the defense XP addition and subsequent single-player ownership correction into the final behavior. Preserved minimum eligible rewards, same-character offline delivery, equal PvP assist shares and diagnostic logging. The draft has one heading matching packaged 0.9.1.1 and retains the publisher's category/bullet format.

## Prepared files and boundaries

Reviewed and retained the existing shared release-menu refactor and local Workshop presentation edits. Included the previously untracked ReleaseMenu.ps1 helper. Restored the required disclaimer in both local description copies. Existing-item content uploads omit description, title, cover and visibility; these local presentation edits do not silently publish the page.

The current PR notes include the cumulative defense XP change. The immutable `v0.9.1.1` content tag is retained; subsequent preparation commits must leave Contents identical to that tag. Older public-release acceptance describes 0.9.0.1, not proof of connected multiplayer acceptance for this new integration.

Use OMH_TraitShop.cmd option 2, then option 3. Mirror/publish authentication and live network operations remain owner-run. Keep this cumulative changelog until a successful content upload for this exact item and version is confirmed. Preview-only updates never reset it.

## Validation

All 36 offline release-tooling checks passed, including installer rollback, linked-path rejection, existing-item metadata preservation and preview-only separation. The first restricted run could not create the test junction; the complete rerun with fixture-directory permission passed. Actual CMD install validation and content-manifest preflight passed. Both description copies match and contain the required disclaimer. Contents remain identical to v0.9.1.1.

Read-only GitHub checks confirmed fetched main is an ancestor and the matching open PR is still a draft. The current release tag is not yet remote; option 2 will create it. Local mirror validation is performed after the preparation commit; remote upload authentication and successful content publication are not claimed by these checks.
