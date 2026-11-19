Scrolling past the first viewport hid later traits and receipt rows because the custom renderer tested content coordinates against viewport height without the scroll offset. Include getYScroll() in visibility checks, keeping native drawing coordinates and complete list height intact.

Place Reset lower-left, with Close then Purchase lower-right. Match Horde Night Difficulty's red Close and black/red Reset; valid Purchase uses Confirm green and disabled Purchase stays neutral. Simplify the XP tooltip to source availability with no amounts; actual reward-source filtering remains tied to the unimplemented Phase 3 earning system.

Regression coverage reproduces the original scrolling failure and checks all four lists at three sizes and three offsets, button positioning/color transitions and XP wording in the game Kahlua VM. See docs/PATCH_v0.4.2_EVIDENCE.txt. Rendered solo recheck and real dedicated player acceptance remain pending. No server, save-schema or publication changes.
