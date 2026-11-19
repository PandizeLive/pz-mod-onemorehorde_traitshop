# v0.3.1 - Trait Shop UI revision

The owner reported the eight-step v0.3.0 solo purchase/reload/death/replacement test passed. The reviewed console supports life 1 resuming at revision 4, one death settlement, creation of life 2 at revision 7, and its reload at revision 8. That log also contains Horde Night activity; it does not independently establish a Trait Shop-only run or live multiplayer acceptance.

## Changed behavior

The hover button opens only through the health area, stays reachable while moving onto the visible button, and closes after leaving. Invisible button coordinates no longer activate it. The wrapper preserves vanilla behavior, supports the reference Trait Purchase System health overlay/bridge, and removes detached tooltips when hiding or closing.

The shop follows the [owner's three-box mockup](../art/references/shop-three-panel-reference.png): unowned positive traits on the left, owned positive/free profession traits at upper right, and current negative traits at lower right. An accepted purchase transfers the selected row to the owned list. Removal remains visibly unavailable. Current negatives can be inspected without an implemented removal feature.

Trait Level is centered above a gold bar with centered white percentage text. Tokens and Prestige have matching emphasis. Prestige displays retained plus newly earned points, with the components in its tooltip. The Token tooltip explains the starting grant, authoritative purchase spending and current balance. XP rewards and prestige creation bonuses are still deferred; the bar stays at 0%, and the tooltip explicitly says no prestige contributed to the starting grant in this build. No XP curve or new creation bonus has been invented.

Rows use icons, compact names and prices. Owned traits are gold; selected rows have an OMH leaderboard gold outline and muted green/red background; unavailable unowned traits are grey but inspectable. Details occupy a shallow footer with full descriptions in hover tooltips. Search covers names and namespaced mod IDs; the filter cycles All, Available and Unavailable. Rebuilds preserve selection by trait ID and preserve/clamp scrolling.

## Catalog and mod compatibility

The display discovers the loaded native registry, including modded definitions. With the installed native set, the registry contains 97 definitions; 49 unowned positive non-free traits can appear before ownership/conflict filtering, including 39 unverified positives. Display order is ascending current Token price, then localized name, then stable ID. Owned negatives use absolute creation cost until removal pricing is implemented; no removal price is shown yet.

Discovery does not grant purchase permission. The ten verified built-in traits remain purchasable. A trusted shared compatibility module can register a further trait after verifying that adding native membership during play activates its complete effect and that receipt recovery can safely reassert it:

```lua
local Catalog = require("OMHTS_Catalog")
Catalog.registerMembershipTrait("my_mod:verified_trait")
```

Use this only with Trait Shop enabled, during shared module initialization on client and server. Registration is idempotent, validates the stable ID, and returns false when invalid or beyond the 100-trait purchase-catalog limit. It does not bypass free/profession, multiplayer-disabled, XP boost, recipe or child-grant checks. Metadata cannot reveal arbitrary custom Lua initialization, so empty metadata alone never certifies a modded trait. Mods with dynamic trait loss also require review because paid membership is a per-life entitlement. No third-party trait pack is certified by this patch.

The server supplies purchase quotes and computes spending from saved receipts. A life already holding 100 receipts cannot buy another trait, including after changing enabled integrations; this preserves the existing save-format limit. Display rows and descriptions stay client-local, keeping network payloads bounded. Cache discovery at initialization/opening; do not copy the whole native registry in every frame or every purchase check. Persistent schema remains 2; install the same package on server and clients.

## Source evidence

- Installed B42.20.4 `media/lua/client/ISUI/ISEquippedItem.lua`: `prerender` and popup lifecycle.
- Installed `CharacterCreationProfession.lua`: registry population and `CharacterCreationMain.sortByCost`.
- Installed `ISUIElement.lua`: children keyed by element ID; native `UIElement.isPointOver` checks visibility/occlusion.
- Decompiled `CharacterTraitDefinition.getTraits/getCharacterTraitDefinition` and `CharacterTrait.toString`: registry enumeration and namespaced identity. The installed native process checks these paths again.
- Installed `OMH_ScoreboardUI.lua`: `VIEWER_COLOR = {0.99, 0.88, 0.49}` supplies the matching gold.
- Installed `stdlib.lua` supplies table sorting; the behavior runner now loads that real file. Installed JAR `StringLib.stringByte` operates on Java UTF-16 characters, so shortened labels preserve surrogate pairs. UI fixtures remain doubles, not a rendering proof.

## Verification

- 12 packaged Lua files compile in the installed Kahlua VM; no pcall/xpcall/ipairs/next/goto/tabs in shipped Lua.
- 53 foundation and 143 Phase 2 assertions passed. The updated Phase 2 fixture verifies registration, unsupported purchase rejection, native serialization/recovery, sorting, filters, Unicode labels, equal resource emphasis, selection transfer, negative inspection, tooltip cleanup, screen/font geometry, and hidden/occluded health hover.
- Three isolated native dedicated save/restart cycles passed. Native registry lookup, display prices, original ten trait effects, spending, saved receipts and replacement behavior passed. No player joined. Evidence: `.local/phase2-server-72a3814130ab4443b44ca8eee04e3214`. The final packaged server/shared behavior files match that probe.
- All 30 offline release-tooling checks passed for this package, including both installed-copy hashes and rollback in disposable profiles. Evidence: `.local/release-tests/9bafaf63c23543cbbadff6942db2e36a`.
- MP audit: zero high findings; the one MP017 medium finding is the UI list `addItem`, not inventory mutation.

The current owner handoff is the short UI test in TEST_PHASE_2.md. Real rendered UI, addon hover coexistence and player network acceptance remain distinct from automated checks. Installation readiness is verified after tagging the package; publishing and mirroring remain owner-run actions.
