# Checkpoint 8 - dedicated acceptance

**Release prerequisite:** publish Trait Shop 0.8.0 and Horde Night 0.6.15 through their existing launchers (option 2 Mirror, then 3 Publish), then restart the test server and reconnect with matching Workshop copies. Do not call the dedicated build ready before those exact versions are published and loaded.

Use a disposable two-player faction test with Horde Night's existing short/easy horde settings. Trait Shop: Hybrid, ordinary zombie XP 2, Horde Zombie XP 5, Horde Survived XP 100, Day/Night/Player Kill XP 0, Prestige interval 2, retention 30. This customized test is intentionally unofficial. Keep unrelated reward mods off. A second player is required to verify casualty exclusion while the faction survives.

1. Both players join the same faction; open the shop and note Level/XP/Tokens/Prestige. Confirm ordinary kills add 2 XP.
2. During your faction's horde, each kill one tagged zombie: each gets 5 XP for their own kill, with no extra 2 or cross-credit. Stay clear of a level boundary when comparing XP.
3. Player B dies and respawns before completion. Player A completes the horde: A gets 100 XP; B gets no completion XP despite being connected again.
4. Survive another horde; B disconnects and rejoins near its end. Both alive, eligible members receive 100 XP. Continue only until A has at least one Prestige for the creation check.
5. A dies between hordes. Check the creation screen adds the displayed Prestige bonus; back out once and reopen, then enter. Level starts at 1, unused creation points become Tokens, and 30 percent Prestige remains (nearest whole point).
6. Record both balances, quit, restart the server, and reconnect. Balances and purchased traits persist, with no repeated horde/creation awards. Quit normally and report results for SFTP log review.

Keep broader automated edge coverage in CHECKPOINT_8.md; do not add extra owner test steps piecemeal.
