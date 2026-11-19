# Fix multiplayer character creation waiting forever for Prestige

On a first multiplayer join, B42.20.4 queues ordinary GlobalModData responses until playerConnectSent. Trait Shop disabled Play while waiting for that response, creating a deadlock for both fresh accounts and saved Prestige.

Send a minimal creation preview through the native GlobalObjectSystem initial state in ConnectionDetails. Read it after OnConnected, before character creation. Same-connection respawns continue to request fresh authoritative previews after world entry. Unknown or invalid connection state blocks with a diagnostic; it never silently discards earned Prestige. The server still settles each creation once from its own records.

Validation: 771 Kahlua assertions, all 22 shipped Lua files compile, and real native initial-state write/read/register with playerConnectSent=false. Dedicated startup/save/restart evidence and final human-client acceptance status are recorded in PATCH_v0.8.1.1.md. No changes to Horde Night or its release.
