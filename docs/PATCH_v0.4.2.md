# v0.4.2 - scrolling and footer fixes

The owner reported missing rows while scrolling, observed after resizing but not established as caused by resizing. The shared `drawTrait` callback culled rows using their unscrolled content coordinates. Native `ISScrollingListBox:prerender` passes those coordinates and native `doDrawItem` includes `getYScroll()` when deciding visibility. The custom renderer now follows that rule while keeping drawing coordinates and row-height returns unchanged. This corrects all trait lists and the receipt without changing the catalog or purchase logic.

## Footer and XP tooltip

- Reset anchors lower-left. It uses Horde Night Difficulty's black background, red text/border and dark red hover.
- Close then Purchase form a compact group anchored lower-right. Close uses the Difficulty menu's red fill/hover/border. Purchase uses its green Confirm palette only when the cart can be purchased; invalid, pending or unavailable checkout stays neutral and disabled.
- Button widths account for label width and available space. All three remain on one bottom row during resizing.
- XP tooltip now says `XP sources / None available in this build.` It omits the threshold and reward amounts. No XP reward options or earning handlers exist yet: the agreed positive-rate, active-mode source-name filtering belongs with Phase 3, not an invented list of currently usable methods.

## Evidence

Local sources: installed Build 42.20.4 `ISScrollingListBox:prerender` and `doDrawItem`; decompiled `UIElement.setYScroll` and native `ISUIElement:setYScroll` for scroll coordinates; core `OMH_DifficultyUI.lua`, `DifficultyPanel:initialise` for action colors and Close/Confirm ordering. Owner specifically overrides that menu's upper-right Reset placement.

The new regression failed on unpatched v0.4.1 at the middle scroll offset before any resize. With the fix, it checks 49 rows in all four list groups at three viewport heights and top/middle/bottom offsets. Other assertions check footer anchors at default/minimum dimensions, action color transitions and an honest amount-free XP tooltip. The game Kahlua VM executes the shipped callbacks with UI drawing fixtures; this is not a rendered game test.

Run results: [PATCH_v0.4.2_EVIDENCE.txt](PATCH_v0.4.2_EVIDENCE.txt). Use the [five-step solo recheck](TEST_PHASE_2.md), then the dedicated player session. Existing authoritative state, effects, networking, save schema and source artwork are unchanged. No automatic install, remote mirror or Workshop publication.
