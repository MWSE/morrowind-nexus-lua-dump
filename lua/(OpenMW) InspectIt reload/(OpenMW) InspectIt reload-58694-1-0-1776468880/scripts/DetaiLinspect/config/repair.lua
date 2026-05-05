local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Repair] = {
        title = 'Repair Item',
        color = util.color.rgb(0.6, 0.6, 0.3),
        showQuality = true,
        showValue = true,
		uniqueDescriptions = {
			['hammer_repair'] = {
				'Repair Hammer',
				'Basic hammer for weapon and armor repair.',
				'Type: Tool (Repair)',
				'Location: Traders, blacksmiths, general stores',
				'Description: A sturdy hammer used to mend dented armor and slightly damaged weapons. Suitable for quick fixes in the field.',
				'Notes: Weight: 0.5, Value: 5 gold. Restores a small amount of condition. Can be used with basic repair kits.'
			},

			['repair_prongs'] = {
				'Repair Prongs',
				'Specialized tool for intricate repairs.',
				'Type: Tool (Repair)',
				'Location: Blacksmith workshops, artisan shops, rare loot',
				'Description: Fine metal prongs used to fix small, delicate parts of weapons and armor — such as crossguard details, rivets, or edge alignment.',
				'Notes: Weight: 0.3, Value: 15 gold. Requires skill to use effectively. Complements repair kits for detailed work.'
			},

			['repair_journeyman_01'] = {
				'Journeyman Repair Kit',
				'Intermediate kit for weapon and armor maintenance.',
				'Type: Tool (Repair Kit)',
				'Location: Experienced blacksmiths, mid-tier shops, guild halls',
				'Description: A set of quality tools and materials designed for repairing moderate damage. Includes specialized files, hammers, and hardening compounds.',
				'Notes: Weight: 0.5, Value: 25 gold. Restores medium levels of condition. Suitable for journeyman-level craftsmen.'
			},

			['repair_master_01'] = {
				'Master Repair Kit',
				'Professional kit for advanced weapon and armor restoration.',
				'Type: Tool (Repair Kit)',
				'Location: Master blacksmiths, elite guild halls, rare chests',
				'Description: A comprehensive set of high-grade tools and alchemical repair materials. Capable of restoring weapons and armor to near-perfect condition, including fixing cracks and reinforcing weak points.',
				'Notes: Weight: 0.5, Value: 75 gold. Restores up to 90% of condition. Required for repairing master-grade equipment.'
			},

			['repair_grandmaster_01'] = {
				'Grandmaster Repair Kit',
				'Elite kit for restoring legendary weapons and armor.',
				'Type: Tool (Repair Kit, Elite)',
				'Location: Grandmaster blacksmiths, ancient armories, elite quest rewards',
				'Description: A meticulously crafted set of tools and rare materials — including enchanted alloys and stabilizing elixirs. Capable of fully restoring even the most damaged legendary gear, sealing magical flaws, and enhancing durability.',
				'Notes: Weight: 0.5, Value: 500 gold. Restores 100% condition and may slightly boost item stats. Used only by the greatest artisans.'
			},

			['repair_secretmaster_01'] = {
				'Secretmaster Repair Kit',
				'Mythical repair set known to the elite few.',
				'Type: Artifact (Repair Kit)',
				'Location: Secret guild vaults, hidden quest rewards, legendary treasure hoards',
				'Description: A divine set of tools and ancient repair formulas. Not only restores any damage but can also awaken dormant enchantments, mend broken runes, and even improve item rarity.',
				'Notes: Weight: 0.5, Value: 1000 gold. Legends say it can transform a common weapon into a legendary one. Utterly rare — a treasure beyond price.'
			}
        }
    }
}