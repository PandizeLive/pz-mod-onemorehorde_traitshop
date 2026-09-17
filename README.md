# OMH: Trait Shop

Standalone trait progression and purchasing addon for Project Zomboid Build 42, with optional OMH: Horde Night integration.

**Status: v0.5.0 implements Checkpoint 5.** The movable, resizable shop has a shared purchase/removal cart, selection shortcuts and name/description search. Owned zero-cost traits now occupy a read-only Other Traits panel. Server-side XP conversion awards one Token per level and one Prestige Point every five levels, using a gradual curve from 100 XP for Level 1 to 2,000 for Level 20. New-character starting points are captured at creation to avoid delayed-join initialization loss. **XP earning sources, prestige creation bonuses and Horde Night scoring remain future work.** The owner reported v0.4.3 dedicated purchases passed; live reconnect/restart and the new UI remain owner checks. Workshop test item: [3803035618](https://steamcommunity.com/sharedfiles/filedetails/?id=3803035618), uploaded by the owner as Unlisted; v0.5.0 still requires owner upload.

The planned full progression loop lets players earn XP from kills, survival or hordes, gain Trait Levels, and receive Tokens to purchase traits. The conversion and death-reset foundation is implemented; XP sources are next. Every five earned levels awards one Prestige Point independently of Token count. Applying that prestige as creation points and retaining 30% after entry remain Checkpoint 7.

## Documentation

- [Checkpoint 5 report](docs/CHECKPOINT_5.md): curve, authority, creation investigation and native evidence.
- [Current six-step test](docs/TEST_CHECKPOINT_5.md): Workshop update, Other Traits, delayed creation and dedicated persistence.
- [Roadmap](docs/ROADMAP.md): six phases and sequential Checkpoints 1-14. Checkpoint 5 conversion is implemented; XP sources, creation bonuses and scoring follow. Common removal was brought forward into v0.4.0.
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
- [Validation](docs/VALIDATION.md): future acceptance checks, not completed tests.

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

The owner brought common negative removal forward into v0.4.0, disabled by default. Progression, prestige creation bonuses, scoring integration and live multiplayer acceptance still precede the intended full release. Custom trait exceptions need targeted compatibility handling; broad default eligibility is not a universal compatibility guarantee.

Official-score support requires coordinated Horde Night and score-validation changes. Documentation does not make current runs official or implement the 50% modifier.

The owner-supplied [animated Workshop preview](preview.gif) and [still image](preview.png) are included unchanged. The still is also packaged as the in-game poster; the existing mod-list and health icons remain in use.
