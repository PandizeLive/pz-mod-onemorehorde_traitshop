# Add Phase 1 persistent player state and server authority

Adds save-scoped account/slot records, generated character-life IDs, a versioned Token/XP/level wallet and separate retained, earned and pending prestige. Reconnects resume a living wallet; death clears it and reserves prestige once. Client requests can only retrieve their own state, and stale/malformed snapshots cannot rewind the UI cache. The owner continues installing locally and launching through Steam.

Validation: 6/6 packaged Lua files compile in the installed B42.20.4 Kahlua VM; 53 behavior checks pass, including native binary serialization and sender/transaction validation. Live player acceptance status and dedicated disk-test evidence are tracked in docs/CHECKPOINT_2.md. Shop UI, reward earning, creation-screen prestige grants and official Horde Night integration remain later phases. No remote publication is included.
