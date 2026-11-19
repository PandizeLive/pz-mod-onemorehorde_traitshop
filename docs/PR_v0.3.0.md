## Change

Players can open OMH: Trait Shop beside the health icon and buy ten verified positive traits with Tokens. New characters receive unused creation points once as starting Tokens; the authority reconstructs the native budget, including profession grants and negative-trait penalties. Prices use the new Positive Cost Multiplier (default 1.0) and round up.

The server validates each purchase and records its debit/receipt before applying the trait. Replayed requests cannot double-charge, and saved receipts repair purchased traits missing from an older character profile. Schema-1 saves migrate without resetting counters or issuing retroactive grants. Client snapshots and native server-to-owner trait sync keep UI and character state aligned.

## Validation

11/11 Lua files compile in the installed B42.20.4 Kahlua VM. All 53 foundation and 93 Phase 2 assertions pass. Three isolated dedicated save/restart cycles verify native trait effects, nonzero balance persistence, receipt recovery and replacement grants. Release-tooling checks are recorded in docs/PHASE_2_EVIDENCE.txt. Live UI/player-network acceptance follows the complete docs/TEST_PHASE_2.md checklist.

XP rewards, prestige creation bonuses, negative removal and official-score integration remain later phases. Native player/world saves are not a cross-file atomic transaction; full world backup/restore remains the supported boundary. No Workshop upload is included.
