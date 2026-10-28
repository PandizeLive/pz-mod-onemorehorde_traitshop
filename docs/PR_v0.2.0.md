# Add Phase 1 persistent player state and server authority

Adds save-scoped account/slot records, generated character-life IDs, a versioned Token/XP/level wallet and separate retained, earned and pending prestige. Reconnects resume a living wallet; death clears it and reserves prestige once. Client requests can only retrieve their own state, and stale/malformed snapshots cannot rewind the UI cache. The owner continues installing locally and launching through Steam.

Validation: 6/6 packaged Lua files compile in the installed B42.20.4 Kahlua VM; 53 behavior checks and 30 release-tooling checks pass. Three real dedicated-server save/restart cycles preserved nonzero state, then the death/replacement result. Live player acceptance remains pending; evidence and limits are tracked in docs/CHECKPOINT_2.md. Shop UI, reward earning, creation-screen prestige grants and official Horde Night integration remain later phases. No remote publication is included.
