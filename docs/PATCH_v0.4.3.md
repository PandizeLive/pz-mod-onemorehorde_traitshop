# v0.4.3 - Purchase color mutation fix

The owner reported a neutral Purchase button on a valid 30-Token cart with a 30-Token balance. Installed Build 42.20.4 `ISButton:setEnable` caches enabled colors, then restores them by mutating the current button color tables on each call. Assigning shared palette tables to the button let a later refresh overwrite the supposedly constant green palette with cached neutral values. The button could remain enabled while appearing neutral.

Use native RGBA setters on button-owned tables after updating availability. No shared mutable Purchase palette remains. Reset also gets an independent border table so disabling it cannot mutate Close. No pricing, cart eligibility, network, persistence or effect behavior changes.

The prior test double's setEnable changed only a boolean and missed this native behavior. The runner now loads the installed ISButton.lua and uses its actual setEnable and RGBA setters with fixture UI primitives. The new repeated-refresh assertion fails on v0.4.2 before the fix, then passes after it. Coverage includes twelve valid refreshes, exact balance, insufficient funds, restored green after disabling, and Reset/Close isolation. This does not claim a rendered game test.

Results: [PATCH_v0.4.3_EVIDENCE.txt](PATCH_v0.4.3_EVIDENCE.txt). Owner check: [four steps](TEST_PHASE_2.md), using the existing funded character. Dedicated player acceptance remains next; no automatic profile install, remote mirror or Workshop upload.
