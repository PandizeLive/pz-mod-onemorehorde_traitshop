# Support physical trait purchases and removals

Stout, Strong, Fit and Athletic now grant their declared Strength/Fitness levels. Removing a native negative physical trait restores its declared penalty, to at least neutral level 5. Existing XP progress is preserved and level 10 is respected. Creator conflicts must be resolved explicitly in the cart; vanilla LevelPerk selects the resulting trait.

Physical grants use separate bounded, sequenced completion receipts instead of permanent membership or XP floors. The server owns payment and its receipt; the client keeps only its local application marker. Native nutrition modifiers are compensated for Strength and Fitness nutrition blocks reject payment. A native zero-XP server grant refreshes the XP anti-cheat baseline. Tooltip previews share the planner used by authority.

Validation: Kahlua regression suites, serialization/replay checks, and a real-game dedicated probe including nutrition/starting-level combinations and three save/restart cycles. See PATCH_v0.8.1.md for evidence and limitations. Human-client solo/dedicated acceptance is still pending; no remote push or publication was performed.
