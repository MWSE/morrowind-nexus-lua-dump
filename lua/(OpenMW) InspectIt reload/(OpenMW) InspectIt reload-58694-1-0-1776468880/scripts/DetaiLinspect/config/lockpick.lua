local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Lockpick] = {
        title = 'Lockpick',
        color = util.color.rgb(0.9, 0.5, 0.1),
        showQuality = true,
        showUses = true,
        showValue = true,
		uniqueDescriptions = {
			['pick_apprentice_01'] = {
				'Apprentice Lockpick',
				'Basic lockpick for novice thieves.',
				'Type: Tool (Lockpick)',
				'Location: Novice traders, beginner dungeons, common chests',
				'Description: A simple, brittle lockpick made of low-grade metal.', 
				'Suitable only for the easiest locks. Often breaks on failed attempts.',
				'Recommended for training.'
			},

			['pick_journeyman_01'] = {
				'Journeyman Lockpick',
				'Sturdy lockpick for intermediate locks.',
				'Type: Tool (Lockpick)',
				'Location: Intermediate traders, mid-level dungeons, bandit camps',
				'Description: Crafted from higher-grade metal, this pick is more durable', 
				'and precise than the apprentice model. Can handle locks of moderate', 
				'difficulty without breaking.',
				'Preferred by experienced thieves.'
			},

			['pick_master'] = {
				'Master Lockpick',
				'Expert-grade lockpick for complex mechanisms.',
				'Type: Tool (Lockpick)',
				'Location: High-end traders, master thief guilds, elite dungeon loot',
				'Description: A finely honed lockpick with a flexible tip and ergonomic', 
				'handle. Capable of bypassing the most intricate lock designs. Rarely breaks.',
				'Essential for professional thieves and treasure hunters.'
			},

			['pick_grandmaster'] = {
				'Grandmaster Lockpick',
				'Near-legendary tool for the toughest locks.',
				'Type: Tool (Lockpick)',
				'Location: Grandmaster thief guilds, ancient ruins, elite quest rewards',
				'Description: Forged from rare alloys, this lockpick features a', 
				'micro-adjustable tip and a balanced design. Can open even the most', 
				'advanced magical locks. Almost indestructible.',
				'Owned only by the most skilled thieves.'
			},

			['pick_secretmaster'] = {
				'Secretmaster Lockpick',
				'Mythical lockpick known to the elite.',
				'Type: Artifact (Lockpick)',
				'Location: Secret guild vaults, hidden quest rewards, legendary', 
				'treasure hoards',
				'Description: A perfectly balanced lockpick with a glowing enchanted', 
				'tip. Can bypass any lock, including those protected by powerful spells.', 
				'Legends say it whispers hints to its user.',
				'Said to be forged by ancient master thieves. Extremely rare.'
			},

			['skeleton_key'] = {
				'Skeleton Key',
				'Magical lockpick that never breaks.',
				'Type: Artifact (Lockpick)',
				'Location: Rare quest reward, very rare chests',
				'Description: Legendary tool that can open any lock and never wears', 
				'out. Its ancient runes glow when near a locked mechanism.',
				'Does not degrade with use. Said to have been created by the first', 
				'guild of thieves.'
			}
        }
    }
}