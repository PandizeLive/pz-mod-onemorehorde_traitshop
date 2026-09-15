# OMH: Trait Shop

Standalone trait progression and purchasing addon for Project Zomboid Build 42, with optional OMH: Horde Night integration.

**Status: Phase 1 implemented, v0.2.0; live player verification pending.** The addon now stores character-life identity, Tokens, XP, Trait Level and separate prestige state, with server-owned snapshots and repeat-safe death settlement. The new state code passed 53 game-VM checks, including native binary serialization. The shop, reward earning, prestige creation bonuses and OMH score integration remain later phases. There is no Workshop item yet.

Players earn XP, gain Trait Levels, and receive Tokens to purchase traits. Every five earned Trait Levels awards one Prestige Point for future character creation; Token count never determines prestige. Tokens and Trait Level reset on death. The next character receives the available prestige as bonus creation points and retains 30% as prestige after entering the world, rounded to the nearest whole point. Prestige is not an undiminished permanent lifetime total.

## Documentation

- [Roadmap](docs/ROADMAP.md): six phases and sequential Checkpoints 1-14. Phase 1 is in verification; Phases 2-6 have not started.
- [Checkpoint 1 report](docs/CHECKPOINT_1.md): package identity, source-backed feasibility, integration gaps, actual results, and the singleplayer test.
- [Checkpoint 2 report](docs/CHECKPOINT_2.md): implemented persistence/authority, automated evidence, limits, and normal Steam tests.
- [Release tooling](docs/RELEASE_TOOLING.md): OMH.cmd, local install/restore, private GitHub mirror, Workshop setup, and verification.
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
  OMH.cmd
  workshop.txt
  WORKSHOP_CHANGELOG.txt
  tools/  (menu, installer, mirror, publisher and tooling checks)
  .local/  (ignored test caches and logs)
```

Mod ID: `OneMoreHorde_TraitShop`. Metadata minimum: 42.20.0; actual installed-game startup verification: 42.20.4. The package has no required Horde Night dependency. The independent private repository is [PandizeLive/pz-mod-onemorehorde_traitshop](https://github.com/PandizeLive/pz-mod-onemorehorde_traitshop). This project has its own history, release tags and Workshop identity; `id=0` means its Workshop item has not been created.

Run [OMH.cmd](OMH.cmd) for local installation, GitHub mirroring, Workshop publication and read-only checks. Menu option 4 checks installation readiness; option 1 installs after the game is closed. Launch the game normally through Steam after installation. Version 0.2.0 provides the state foundation; no shop button is expected. Creating the private GitHub repository did not mirror source or publish a Workshop item.

The package's mod-list icon is copied unchanged from [icon_7.png](art/Images/icon_7.png). The separate health-hover asset remains at [traitshop ingame icon.png](../Images/Trait%20Shop/traitshop%20ingame%20icon.png). The [hover-menu reference](art/references/health-hover-reference.gif) records the intended interaction, not proof that the menu is native to Zomboid.

## Release boundary

Initial release can provide positive-trait purchasing and the progression system without negative-trait removal. Negative-trait removal and its special compatibility handling come last. Unsafe or unverified positive traits must still be withheld from the initial catalog until their effects work correctly.

Official-score support requires coordinated Horde Night and score-validation changes. Documentation does not make current runs official or implement the 50% modifier.
