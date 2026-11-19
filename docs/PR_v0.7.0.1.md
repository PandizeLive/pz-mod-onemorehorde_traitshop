# Fix Prestige creation-screen render errors

Opening character creation or respawning with CP7 repeatedly threw `__add not defined for operands`: the Prestige label referenced the native screen's file-local spacing constant as a global. Define that spacing locally, following the installed 42.20.4 Lua source. Replace the unescaped percent in the retention tooltip with "percent" to avoid the observed native formatter warning.

The corrected Kahlua fixture reproduces the original failure without supplying a nonexistent global. It now checks valid font arguments, creation layout, numeric label coordinates and repeated rendering. All 51 CP7 assertions, 191 foundation/progression/feedback assertions and 19 Lua compile checks pass; the fundamentals audit finds no banned constructs. No progression or retention logic changes.

The owner reported a possible crash during the final respawn. Logs reach successful life-3 entry and then stop; no separate crash report was found in the checked profile/game directories or Windows Application events. This patch fixes the demonstrated render loop, not a proven native crash. Live respawn confirmation remains required. Companion Horde Night stays at 0.6.14.
