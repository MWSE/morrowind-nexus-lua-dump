local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Probe] = {
        title = 'Probe',
        color = util.color.rgb(0.9, 0.5, 0.1),
        showQuality = true,
        showUses = true,
        showValue = true,
		uniqueDescriptions = {
			['probe_apprentice_01'] = {
				'Apprentice Probe',
				'Basic probe for novice.',
				'Type: Tool (Probe)',
				'Location: Local traders, beginner blacksmiths, novice guild halls',
				'Description: A simple, unrefined metal rod', 
				'Often breaks. Suitable for training.'
			},

			['probe_journeyman_01'] = {
				'Journeyman Probe',
				'Type: Tool (Probe)',
				'Location: Experienced blacksmiths, mid-tier shops, journeyman guild halls',
				'Description: A sturdier, more precise instrument than the apprentice model.',
				'Less prone to breaking than the apprentice version.'
			},

			['probe_bent'] = {
				'Bent Probe',
				'Damaged probe with limited functionality.',
				'Type: Tool (Probe, Damaged)',
				'Location: Dungeons, battlefields, discarded blacksmith waste',
				'Description: A warped and bent probe that still functions.',
			},

			['probe_master'] = {
				'Master Probe',
				'Precise tool',
				'Type: Tool (Probe)',
				'Location: Master blacksmiths, elite guild halls, rare chests',
				'Description: A finely calibrated device with an ergonomic handle.',
				'Trusted by professionals'
			},

			['probe_grandmaster'] = {
				'Grandmaster Probe',
				'Advanced probe',
				'Type: Tool (Probe, Advanced)',
				'Location: Grandmaster blacksmiths, ancient armories, elite quest rewards',
				'Description: A sophisticated instrument forged from rare alloys.',
				'Owned only by the most skilled specialists.'
			},

			['probe_secretmaster'] = {
				'Secretmaster Probe',
				'Mythical probe',
				'Type: Artifact (Probe)',
				'Location: Secret guild vaults, hidden quest rewards, legendary treasure hoards',
				'Description: A perfectly balanced probe with a glowing enchanted tip.',
				'Legends say it whispers tips to its user.', 
				'Extremely rare — said to be forged by ancient master armorers.'
			}
        }
    }
}