# Fix displayed prestige milestones and local level-up audio

Starting at displayed Level 1 delayed the first Prestige Point until Level 6. Award it at displayed Levels 5, 10, 15 and subsequent multiples of five, with a one-time correction for living saves and no Token duplication. Explicitly force both supplied notification sounds into 2D using the native UI emitter.

Adds launcher option 6 for a GIF-only update to the existing Trait Shop Workshop preview. Ordinary uploads retain their metadata-preserving behavior.

Validation: all 17 Lua files compile in native Kahlua; 164 lifecycle/feedback, 167 rewards/sandbox and 36 offline release-tool assertions pass. Companion Horde Night 0.6.13 adds settings approval and score reduction; website deployment and live acceptance are separate. See docs/PATCH_v0.6.3.1.md.
