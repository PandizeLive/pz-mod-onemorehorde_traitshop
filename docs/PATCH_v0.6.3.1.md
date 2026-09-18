# v0.6.3.1 — Prestige, audio and preview update

Displayed Level 1 is the starting level. Prestige now arrives at displayed Levels 5, 10, 15, etc., independently of Tokens. Internal saved `life.level` remains the earned-level count; milestone math uses `floor((life.level + 1) / 5)`. A one-time living-character migration grants any missing milestone Prestige. It never grants Tokens or removes existing prestige.

Sounds use native `SoundManager.playUISound`, then `getUIEmitter():set3D(handle, false)` for the returned channel, verified against installed 42.20.4 bytecode. Listening still needs in-game acceptance. Feedback logs report displayed level, Token/Prestige rewards and selected sound. No pcall/xpcall or speculative fallback is used.

Launcher option **6** uploads only `preview.gif` to existing item **3803035618**. The file matches the owner's `postertraits.gif`. The manifest supplies no content folder, change note, title, description or visibility. GIF signature, size under 1 MB and exact item identity are checked. Use **2 Mirror** first; **6** then asks for **PREVIEW** and uses the existing Steam login. Nothing uploads automatically. `OMH_TraitShop.cmd -Action Preview -ValidateOnly` checks offline. Steam supports GIF primary previews: https://partner.steamgames.com/doc/api/ISteamUGC#SetItemPreview.

## Verification

- 17 Lua files compile in installed Kahlua; fundamentals audit passes.
- 164 state/lifecycle/feedback assertions, including displayed Levels 2–10 and persisted migration.
- 167 reward/sandbox assertions; 36 offline release-tool checks.
- Companion Horde Night evidence: `docs/TRAIT_SHOP_INTEGRATION.md` in its repository.

## Complete owner test (after uploading both builds)

1. Close the game. Use each launcher's **2 Mirror**, then **3 Publish**; update/restart the server and confirm Trait Shop **0.6.3.1**, Horde Night **0.6.13** loaded.
2. On a disposable Hybrid test character, reach displayed Levels **4, 5 and 6**: normal sound at 4/6; at 5, one Prestige Point and Prestige sound. Turn/move the camera while listening: sound should stay centered.
3. Reconnect: balances stay unchanged and no sound replays. An existing living Level 5 character missing its point receives it once.
4. In a fresh official Horde Night-mode test run, check Difficulty Settings shows Trait Shop **x0.50** (with Cure, **x1.20**, combined **x0.60**); complete a horde and check its reduced score.
5. Raise Positive Cost Multiplier: **Hardened**, still official. Then lower it below 1 or leave Horde Night reward mode: unofficial; restoring defaults and reconnecting must not clear the flag.
6. Optional page-art check: Trait Shop launcher **6**, type **PREVIEW**, then refresh its Workshop page. Confirm the GIF changed and page text/visibility remained intact.

Horde Night XP remains Checkpoint 8, so use Hybrid for audio/milestones; that run is intentionally unofficial. Website changes are local and require separate deployment for global submissions. Prestige character-creation bonuses/retention remain Checkpoint 7. Pre-integration run history cannot be retrospectively approved.
