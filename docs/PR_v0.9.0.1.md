# Keep purchase history separate from unofficial earnings

Purchases funded by unused creation points wrongly marked a character's XP/Prestige history unofficial when Horde Night's run was ineligible. Stop calling the earnings audit after purchases; actual reward paths still audit earnings. Horde Night 0.6.16.4 contains the companion classification fix and participant-name tooltip.

Validation: the new regression failed before the correction and passes afterward. 262 shop/UI/physical, 191 foundation/feedback and 45 horde integration assertions pass in installed B42.20.4 Kahlua; all 22 Lua files compile. Existing saved restrictions are preserved; fresh-character dedicated acceptance follows publication.
