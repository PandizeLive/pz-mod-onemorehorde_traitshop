# v0.6.4 — Configurable level rewards

Adds **Level Rewards** to solo, host and live-admin sandbox settings:

| Option | Default | Range |
|---|---|---|
| Tokens per Level | 1 | 0–1000 |
| Prestige Level Interval | 5 | 1–1000 |

Prestige uses displayed levels: interval 5 means Levels 5, 10, 15, etc. Starting Level 1 grants nothing, including with interval 1. Changes affect future level-ups without recomputing past rewards. Tokens can be disabled with zero. Multiple levels gained together use the server's current settings and commit atomically.

Changing the interval cannot repeat already-earned Prestige entitlements: gaining the first point at Level 5, then changing to interval 6, does not grant another first point at Level 6. New awards are limited to newly crossed milestones and the currently permitted lifetime milestone count. Changing to a smaller interval does not backfill skipped levels.

An optional persisted `earnedLevelTokens` counter records actual level rewards independently of balance, purchases and creation points. Pre-patch saves infer their prior one-Token-per-level history once; snapshots and feedback carry the actual total. No packet schema change, client award command, pcall or speculative native API was introduced. Integer sandbox settings follow the native SandboxOptions integer option path; section layout uses the existing tested native panel hooks.

Companion Horde Night **0.6.13.1** reviews both options. More than one Token per level or an interval below five makes the run Lessened. Fewer Tokens or an interval above five makes it Hardened and remains eligible under the existing policy. Missing/invalid values remain unverified. Update both packages together. No website code change is needed for these existing flags; the earlier website deployment remains outstanding.

## Verification

- 17 Lua files compile in native Kahlua; fundamentals audit passes.
- 191 lifecycle/progression/feedback assertions, 191 reward/sandbox assertions, 222 shop/UI assertions.
- 140 Horde Night policy/persistence/score assertions, including both options and malformed intervals.
- Tests cover changed rewards, zero Tokens, batched levels, saved Token history, no backfill, interval-toggle abuse, feedback after spending, and all four sandbox modes.
- Prior-build acceptance: the owner reports it working; console.txt confirms v0.6.3.1 solo Levels 2–5, normal sounds at 2–4 and one Prestige with its sound at 5.

## Short owner test

After installing the matching builds through each launcher's option 1:

1. New solo Sandbox: Hybrid, Zombie XP **100**, Tokens per Level **3**, Prestige interval **3**.
2. Kill one zombie: Level **2**, **+3 Tokens**, no Prestige.
3. Kill two more: Level **3**, another **+3 Tokens** and **+1 Prestige**, matching the overhead text.
4. Save, quit and reload: balances stay unchanged; report any mismatch.

This is an unofficial disposable reward test. Checkpoint 7 (creation bonus and retention) has not been implemented by this patch. Workshop uploads remain owner-run; this document does not claim the new builds are installed or published.
