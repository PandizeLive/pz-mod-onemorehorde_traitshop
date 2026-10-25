# OMH: Trait Shop

**C467 corrective build: 0.9.1.1.** Refresh same-life defense ownership after native single-player username initialization; apply the approved minimum1XP once after merged eligible shares, and add bounded reward summaries/details. Preserve zero/ineligible/duplicate suppression, fractional awards>=1, character-bound pending delivery and ordinary rewards. [Patch and verification](docs/PATCH_v0.9.1.1.md). Approved, installed locally and hash-verified with backups. No Workshop publication or connected multiplayer acceptance.

**Prepared XP integration: 0.9.1.** Adds authoritative optional defense credit, equal assist settlement, offline pending shares and matched client body-state recovery replies. Native death settlement waits for the post-hit callback and outstanding authorized injury receipts. [Patch and verification](docs/PATCH_v0.9.1.md). Coordinated local installation and native startup/restart verified; Workshop and connected-player acceptance pending.


Standalone trait progression and purchasing addon for Project Zomboid Build 42, with optional OMH: Horde Night integration.

**Release candidate: v0.9.0, paired with Horde Night 0.6.16.3.** Both Workshop content uploads are confirmed; the leaderboard API update is deployed. Local/dedicated owner checks passed, with the targeted two-player check remaining. See [release evidence](docs/PUBLIC_RELEASE_READINESS.md) and [the final short test](docs/TEST_PUBLIC_RELEASE.md).

Characters start at Level 1, with 0 / 100 XP toward Level 2. By default, each earned level grants one Token and displayed Levels 5, 10, 15 and subsequent multiples of five grant one Prestige Point; both rewards are configurable. Level-ups play the supplied normal or prestige sound and show gold overhead text. Your next character receives the full Prestige bonus, then retains 30% by default after entering the world.

## Documentation

- [Current release readiness](docs/PUBLIC_RELEASE_READINESS.md), [seven-step multiplayer test](docs/TEST_PUBLIC_RELEASE.md), and [prepared Workshop description](docs/WORKSHOP_DESCRIPTION.txt).

- [Prestige loading correction](docs/PATCH_v0.8.1.1.md) and [six-step dedicated test](docs/TEST_v0.8.1.1.md).
- [Physical traits patch](docs/PATCH_v0.8.1.md) and [six-step solo test](docs/TEST_v0.8.1.md).

- [Checkpoint 8](docs/CHECKPOINT_8.md): authoritative horde rewards, verification and limits.
- [Combined dedicated test](docs/TEST_CHECKPOINT_8.md): six steps after publishing both matching versions.

- [Respawn rendering fix](docs/PATCH_v0.7.0.1.md): diagnosis and four-step retest.
- [Checkpoint 7](docs/CHECKPOINT_7.md): creation flow, retention, native evidence and limits.
- [Historical CP7 solo test](docs/TEST_CHECKPOINT_7.md): eight steps for 3 -> 1 -> 0.

- [Checkpoint 5 report](docs/CHECKPOINT_5.md): curve, authority, creation investigation and native evidence.
- [v0.6.4 level rewards](docs/PATCH_v0.6.4.md): configurable rewards and four-step test.
- [v0.6.3.1 fixes](docs/PATCH_v0.6.3.1.md): prestige, audio, GIF preview and integration test.
- [Checkpoint 6 report](docs/CHECKPOINT_6.md): reward rules, seasonal survival, cooldowns and source evidence.
- [Current dedicated test](docs/TEST_CHECKPOINT_6.md): mode controls, kill/survival rewards, PvP and persistence.
- [Roadmap](docs/ROADMAP.md): six phases and sequential Checkpoints 1-14. Checkpoints 7 and 8 are implemented; combined dedicated acceptance remains. Common removal was brought forward into v0.4.0.
- [Phase 2 report](docs/PHASE_2.md): shop, catalog, starting Tokens, purchase recovery, source evidence and verification limits.
- [v0.4.3 patch](docs/PATCH_v0.4.3.md): stable Purchase colors under native button refreshes.
- [v0.4.2 patch](docs/PATCH_v0.4.2.md): scroll-aware row rendering, action layout/colors and XP tooltip.
- [v0.4.1 patch](docs/PATCH_v0.4.1.md): stable resizing, leaderboard branding, selection and launcher fixes.
- [v0.4.0 patch](docs/PATCH_v0.4.0.md): cart, removal, broader trait support, source evidence and limitations.
- [v0.3.1 UI patch](docs/UI_PATCH_v0.3.1.md): three-panel layout, registry discovery, mod compatibility hook and source evidence.
- [Test now: seven-step patch check](docs/TEST_PHASE_2.md): layout, selection, a mixed cart, skill effects and reload.
- [Checkpoint 1 report](docs/CHECKPOINT_1.md): package identity, source-backed feasibility, integration gaps, actual results, and the singleplayer test.
- [Checkpoint 2 report](docs/CHECKPOINT_2.md): implemented persistence/authority, automated evidence, limits, and normal Steam tests.
- [Release tooling](docs/RELEASE_TOOLING.md): OMH_TraitShop.cmd, local install/restore, private GitHub mirror, Workshop setup, and verification.
- [Design](docs/DESIGN.md): confirmed behavior, vocabulary, reward modes, shop UI, and death lifecycle.
- [Sandbox options](docs/SANDBOX_OPTIONS_SPEC.md): settings, defaults, visibility, and values still to decide.
- [OMH integration](docs/OMH_INTEGRATION.md): horde rewards, official eligibility, score multiplier, and difficulty-menu work.
- [Architecture](docs/ARCHITECTURE.md): proposed packaging, authority, persistence, and source references.
- [Decisions](docs/DECISIONS.md): settled requirements and open questions; recommendations are not approved settings.
- [Validation](docs/VALIDATION.md): current evidence and remaining acceptance coverage.

## Workspace structure

This project follows the existing OMH repository's separation of documentation, assets, deployable content, and tools.

```text
Trait Shop/
  README.md
  docs/
  art/references/health-hover-reference.gif
  Contents/mods/OneMoreHorde_TraitShop/
    common/
    42.20/mod.info
    42.20/icon.png
    42.20/media/lua/{shared,client,server}/
  OMH_TraitShop.cmd
  workshop.txt
  WORKSHOP_CHANGELOG.txt
  tools/  (menu, installer, mirror, publisher and tooling checks)
  .local/  (ignored test caches and logs)
```

Mod ID: `OneMoreHorde_TraitShop`. Metadata minimum: 42.20.0; actual installed-game startup verification: 42.20.4. The package has no required Horde Night dependency. The independent private repository is [PandizeLive/pz-mod-onemorehorde_traitshop](https://github.com/PandizeLive/pz-mod-onemorehorde_traitshop). Its Workshop ID is `3803035618`; update that existing item rather than creating another.

Run [OMH_TraitShop.cmd](OMH_TraitShop.cmd) for local installation, GitHub mirroring, Workshop publication and read-only checks. Menu option 4 checks installation readiness; option 1 installs after the game is closed. Launch normally through Steam, then hover over the health icon to open Trait Shop. Newly created characters receive unused creation points as Tokens; existing characters receive no retroactive grant. Source mirroring and Workshop publication remain owner-run actions.

The package's mod-list icon is copied unchanged from [icon_7.png](art/Images/icon_7.png). The separate health-hover asset remains at [traitshop ingame icon.png](../Images/Trait%20Shop/traitshop%20ingame%20icon.png). The [hover-menu reference](art/references/health-hover-reference.gif) records the intended interaction, not proof that the menu is native to Zomboid.

## Release boundary

Progression, Prestige creation bonuses, Horde Night rewards and scoring integration are implemented. Common negative removal is included, disabled by default. Final two-player acceptance remains; custom trait exceptions need targeted compatibility handling, and broad default eligibility is not a universal compatibility guarantee.

With Horde Night, Enable Trait Shop is in Run Options and defaults ON. Actual purchases/removals or a Prestige creation bonus force it ON for the affected character/faction. Eligible Trait Shop scoring uses x0.50, multiplied with other score modifiers. Default-or-harder settings stay eligible; easier rules, enabling removal, or leaving Horde Night reward mode make the affected run unofficial. Older characters without creation proof remain playable but unverified. The current leaderboard API recognizes these rules; see the release evidence above.

The owner-supplied [animated Workshop preview](preview.gif) and [still image](preview.png) are included unchanged. The still is also packaged as the in-game poster; the existing mod-list and health icons remain in use.
