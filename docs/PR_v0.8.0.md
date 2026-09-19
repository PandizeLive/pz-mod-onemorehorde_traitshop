# Add Checkpoint 8 Horde Night XP rewards

Trait Shop now pays 5 XP for a core-credited horde kill and 100 XP to eligible connected survivors, through Horde Night 0.6.15's API 3 notifications. Hybrid pays a horde kill once. Core membership and sticky casualties exclude dead, disconnected, departed and respawned casualties from completion rewards.

Persistent event receipts prevent kill/completion replay across mode changes, lives and restarts. Existing creation, progression, default rates and standalone behavior are retained. Old or missing core versions disable horde sources with a clear tooltip; saved modes are not silently changed.

Validation: native Kahlua integration and regression suites, package syntax and dedicated disk-cycle probe; see docs/CHECKPOINT_8.md for recorded results and limits. Human-client dedicated acceptance remains pending. Both matching Workshop packages are required. No GitHub push, Workshop upload or website deployment is performed automatically.
