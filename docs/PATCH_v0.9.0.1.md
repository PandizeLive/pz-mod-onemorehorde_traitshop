# v0.9.0.1 — purchase provenance correction

Pair with Horde Night **0.6.16.4**. A successful purchase no longer calls the XP/Prestige earnings audit. Starting Tokens represent unused creation points and buying traits with them must not invent earned XP/Prestige history. All actual reward handlers retain their audit. Purchases still force Trait Shop benefits/scoring restrictions normally.

Read-only dedicated save inspection found both test accounts had zero XP/earned levels/Prestige, creation grants of four Tokens, purchases, and an unofficial earnings marker introduced by the purchase path. Horde Night's companion correction no longer infers unofficial earnings from purchases alone. Existing persistent flags are deliberately preserved; use fresh characters for the short retest.

Validation: reproduction failed before the patch and passes afterward; 262 shop/UI/physical, 191 foundation/feedback and 45 horde integration assertions pass. All 22 files compile in native Kahlua; fundamentals audit passes. No new OMH error loop appeared in current console/SFTP logs.

Previous confirmed content upload: 0.9.0, Workshop 3803035618, `traitshop-v0.9.0-20260921-133340.log`. This starts a new cumulative draft after that upload. Live descriptions were read September 21; the publisher preserves description, cover and visibility. Manual mirror/upload through **OMH_TraitShop.cmd**; no remote publication performed here.
