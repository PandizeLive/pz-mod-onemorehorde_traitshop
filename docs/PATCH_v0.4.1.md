# v0.4.1 - resize and selection fixes

The owner completed the v0.4.0 solo test and reported unstable resizing, mismatched title sizing and selection improvements. This patch addresses that feedback; it does not change authoritative purchases, effects, progression or saved-state schema.

## Changes

- The resize handle uses explicit layout positioning without right/bottom automatic anchoring. The window position stays fixed during resize; only the header starts a window drag.
- Small red One More Horde and Large gold Trait Shop match the full leaderboard's fonts and RGB values. Font-height-aware spacing avoids overlap at larger text sizes. Trait Level and XP retain #E7B428.
- Plain clicks add/toggle choices without clearing other cart entries. Clicking a selected source row or receipt removes it. Shift adds eligible ranges.
- Ctrl+A adds eligible visible traits in the active catalog or negative list. It respects filters/search and leaves text selection to the focused search field. Owned positives and disabled removals cannot become bulk purchases. Wallet, cart limits and mutual conflicts still block invalid checkout.
- Queued valid negative removals update conflict shading and availability filters immediately. Undoing a removal restores the conflict. The server still validates the complete transaction.
- The sole launcher is now [OMH_TraitShop.cmd](../OMH_TraitShop.cmd); install, mirror, publisher checks, tooling fixtures and documentation use the new name.

## Source evidence and regression coverage

Installed Build 42.20.4 `ISResizeWidget:onMouseMove` calculates size changes from local pointer position. Its default constructor anchors the handle right/bottom. `UIElement.onResize` (local decompiled source) applies parent size deltas to those anchors after Lua layout. v0.4.0 also manually positioned the handle during Resize, producing a second displacement and oscillating local pointer deltas. Removing the competing anchors fixes that feedback loop.

The Kahlua regression runner now loads the actual installed `ISResizeWidget.lua`. It tests a stationary pointer through 12 deferred-anchor frames, dimensions and position, minimum-size clamping and outside release. Other regressions exercise plain toggles, Shift ranges, list focus, Ctrl+A with search and disabled removals, receipt changes, dynamic filters, checkout and title fonts/colors. UI primitives and deferred anchor scheduling remain fixtures: this is not a rendered game test.

The full leaderboard reference is `OMH_ScoreboardUI.lua`, `FullPanel:prerender`: Small title red (0.85, 0.25, 0.25), Large subtitle gold (0.95, 0.75, 0.2). Keyboard routing follows native `UIElement.isKeyConsumed` / `UIManager.onKeyPress`, with `ISTextEntryBox:isFocused` and `unfocus`.

Run results are recorded in [PATCH_v0.4.1_EVIDENCE.txt](PATCH_v0.4.1_EVIDENCE.txt). The [seven-step owner test](TEST_PHASE_2.md) is the remaining rendered UI check. Earlier native dedicated persistence evidence remains in v0.4.0; no server logic changed here. A real multiplayer player session is still pending. No automatic install, remote push or publication is included.

## Owner poster assets

The owner added postertraits.gif and postertraits.png during this patch. Both were found under the current `OMH/Images/Trait Shop` workspace directory; the older `Zomboid/_Modding` path no longer exists. Copies preserve source bytes. Root preview.gif is the 400x400, 75-frame animation; root preview.png is the still. The package references its identical still copy as poster.png in mod.info, retaining the existing icon.

The first Workshop creation manifest now includes the animated preview. Existing-item uploads still omit previewfile so a future ordinary update does not replace the published cover. Missing or oversized first-upload previews fail preflight. Valve's [SetItemPreview documentation](https://partner.steamgames.com/doc/api/ISteamUGC#SetItemPreview) lists GIF among supported preview formats. No media was hosted or uploaded; animation on Steam awaits the owner's first publication.
