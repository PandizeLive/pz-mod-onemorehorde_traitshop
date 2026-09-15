# Proposed architecture

Phase 1 persistence and authority are implemented in v0.2.0. The shop, earning and creation-screen systems below remain future work. See [CHECKPOINT_1.md](CHECKPOINT_1.md) for feasibility and [CHECKPOINT_2.md](CHECKPOINT_2.md) for the implemented state design, source anchors and verification limits.

## Packaging

Use the existing OMH project's broad structure: root README, durable `docs/`, source artwork under `art/`, deployable content under `Contents/mods/`, and tools added when needed. Keep documentation outside installed content.

Current package:

```text
Contents/mods/OneMoreHorde_TraitShop/
  common/
  42.20/
    mod.info
    media/
      lua/
        client/
        shared/
        server/
      textures/
```

Mod ID is `OneMoreHorde_TraitShop`, with metadata minimum 42.20.0 and real dedicated startup verified on installed 42.20.4. Earlier 42.20 patch compatibility is not yet tested. Translation placement and texture content will expand when player-facing gameplay UI is implemented. The current build persists state and logs lifecycle diagnostics; do not describe it as a working trait shop or assign an invented Workshop identity.

## Responsibilities

| Area | Responsibility |
|---|---|
| Shared gameplay rules | XP conversion, level milestones, prices, eligibility predicates, serializable definitions. |
| Authoritative runtime | Validate rewards and purchases; own balances, prestige, event deduplication, death settlement, and official rules history. |
| Client UI | Hover menu, catalog, progress display, settings presentation, and requests to the authority. |
| Optional OMH adapter | Consume authoritative OMH facts; contribute supported metadata without copying horde logic. |
| Trait adapters | Apply and verify supported trait effects; complex negative-trait removal added later. |

Use the same gameplay rules in singleplayer, hosted multiplayer, and dedicated multiplayer. Authority and transport differ; outcomes must not.

## Durable state requirements

Separate character-life state from the player/account prestige record. A replacement character must not inherit the dead character's Token wallet or Trait Level. Newly earned prestige derives from Trait Level; Token changes cannot generate it.

- Character state: life identity, current XP, Trait Level, Token balance, initialization marker, purchased-trait facts, reward deduplication, and rules provenance.
- Prestige state: retained prestige, prestige newly earned through this life's Trait Levels, pending next-character creation bonus, life settlement/creation-grant/retention markers, applicable retention percentage, rules provenance, and schema version. Retention rounds to nearest whole point (documented half-up tie convention), with no minimum-one guarantee. Retained plus earned prestige form the next bonus total. Phase 1 stores the separate balances and death-settlement marker; creation-grant/retention markers are added with that later transaction, before it can execute.
- OMH association: event and owner identities, reward recipient life identity, processed completion/kill facts, and casualty result where needed.

Implemented identity: authenticated multiplayer username/native player slot, or singleplayer local slot, inside the current world's registry. Display names are not used. The server/singleplayer registry uses native global ModData persistence and is never replaced from client packets; it contains no credentials. Global ModData is not a confidentiality boundary, as explained in the Checkpoint 2 report. Avoid unbounded reward ledgers; retention and compaction must preserve replay protection.

Creation-point conversion, level rewards, five-level milestones, purchases, and death settlement must be retry-safe. Reconnecting or recreating a character must not replay starting grants or prestige. A crash between debit and trait application must not leave a free trait or permanent lost payment; select a recoverable transaction sequence based on verified trait APIs.

Snapshot the full creation bonus for the replacement character before applying retention. Once that character successfully enters the world, retain 30% by default, exactly once. Reopening/canceling character creation or ordinary reconnect must not apply another retention step or duplicate the bonus. Do not reduce prestige both at death and at spawn. The retained amount is for a subsequent transition, not another bonus for the character just created.

Do not rely on unguarded client-synchronized player modData for authoritative balances. Inspect vanilla persistence and the multiplayer skill before selecting storage. Clients request actions; the authority validates the player and computes rewards/prices. Persist only serializable facts and send minimal UI state.

## Performance and compatibility

Prefer reward and lifecycle events. No continuous world scans for the shop. Survival timing, when implemented, must handle game-time jumps and reconnects without burst duplication; use the existing time-mod investigation as context before selecting a timer approach.

Inspect the current Trait Purchase System and vanilla health UI before implementing the custom hover menu. Recreate the interaction with supported hooks; do not assume that menu is native or copy third-party source/assets without checking permission. The owner-supplied icon is the intended asset.

Broad trait discovery is not proof that runtime purchase/removal works. Start with verified positive traits and add explicit support where initialization is required. Negative removal and its complex compatibility work are deferred until after the initial release.
