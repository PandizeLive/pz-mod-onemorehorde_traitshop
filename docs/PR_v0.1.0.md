# Prepare OMH: Trait Shop foundation and release tooling

Provides the standalone OneMoreHorde_TraitShop package and a Trait Shop-specific OMH.cmd for local installation, backups, GitHub mirroring and Steam Workshop publication. The menu reads version 0.1.0 from packaged metadata, verifies the immutable v0.1.0 content tag, and keeps this addon's staging and publication identity separate from Horde Night.

The gameplay package currently logs startup only. No shop UI, trait purchases, XP, prestige, or Horde Night reward integration is implemented. Singleplayer world entry alongside Horde Night/Cure Defense passed; standalone singleplayer verification remains pending.

Validation: all three packaged Lua files passed the installed Kahlua compiler; an isolated B42.20.4 dedicated server loaded the addon without Horde Night. Release-tooling checks are recorded in RELEASE_TOOLING.md. Steam upload and live PR-update validation require owner-run external actions.
