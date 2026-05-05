local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Container] = {
        title = 'Container',
        color = util.color.rgb(0.4, 0.4, 0.4),
        showWeight = true,
		uniqueDescriptions = {
			['ancient_chest'] = {
				'Ancient Chest',
				'Old, intricately carved chest.',
				'Capacity: 200. Often found in ruins and ancient tombs. May contain valuable loot.'
			},
			['ancient_wooden_chest'] = {
				'Ancient Wooden Chest',
				'Weathered wooden chest with ancient markings.',
				'Capacity: 200. Common in old Dunmer strongholds and ancestral tombs.'
			},
			['barrel'] = {
				'Barrel',
				'Standard wooden barrel.',
				'Capacity: 50. Found in warehouses, taverns, and merchant stalls. Usually contains food or trade goods.'
			},
			['basket'] = {
				'Basket',
				'Woven basket of reeds or wood.',
				'Capacity: 50. Commonly used for carrying food, herbs, and small items. Found in homes and markets.'
			},
			['chest'] = {
				'Chest',
				'Simple wooden chest.',
				'Capacity: 200. Standard storage container found in homes, shops, and guild halls.'
			},
			['chest_of_drawers'] = {
				'Chest of Drawers',
				'Wooden cabinet with multiple drawers.',
				'Capacity: 300. Provides ample storage space. Common in wealthy homes and guild quarters.'
			},
			['closet'] = {
				'Closet',
				'Standing wardrobe or storage cabinet.',
				'Capacity: 300. Used for storing clothes and personal belongings. Found in residences and inns.'
			},
			['cloth_sack'] = {
				'Cloth Sack',
				'Small fabric bag.',
				'Capacity: 50. Lightweight and portable. Used for carrying small quantities of goods.'
			},
			['crate_01_random_pos'] = {
				'Crate',
				'Sturdy wooden crate.',
				'Capacity: 200. Used for shipping and storage. Found in ports, warehouses, and shops.'
			},
			['crate_02_random_pos'] = {
				'Crate',
				'Sturdy wooden crate.',
				'Capacity: 200. Used for shipping and storage. Found in ports, warehouses, and shops.'
			},
			['cupboard'] = {
				'Cupboard',
				'Kitchen cabinet with shelves.',
				'Capacity: 100. Stores food, dishes, and kitchen supplies. Found in homes and taverns.'
			},
			['desk'] = {
				'Desk',
				'Writing desk with drawers.',
				'Capacity: 75. Contains scrolls, books, and office supplies. Found in guild halls and official buildings.'
			},
			['drawers'] = {
				'Drawers',
				'Set of wooden drawers.',
				'Capacity: 300. Offers extensive storage for personal items. Common in residences.'
			},
			['heavy_dwemer_chest'] = {
				'Heavy Dwemer Chest',
				'Massive metal chest of Dwemer design.',
				'Capacity: 200. Extremely durable. Found in Dwemer ruins. May contain ancient artifacts.'
			},
			['heavy_dwemer_desk'] = {
				'Heavy Dwemer Desk',
				'Metal desk with Dwemer craftsmanship.',
				'Capacity: 50. Rare and valuable. Found only in Dwemer ruins.'
			},
			['large_chest'] = {
				'Large Chest',
				'Oversized storage chest.',
				'Capacity: 200. Provides more space than a standard chest. Found in merchant houses and guilds.'
			},
			['ornate_dwemer_chest'] = {
				'Ornate Dwemer Chest',
				'Decorated metal chest of ancient Dwemer make.',
				'Capacity: 200. Features intricate gears and springs. Found in high‑status Dwemer sites.'
			},
			['sack'] = {
				'Sack',
				'Fabric bag for carrying goods.',
				'Capacity: 50. Common among travelers and merchants. Lightweight and easy to transport.'
			},
			['small_chest'] = {
				'Small Chest',
				'Compact wooden chest.',
				'Capacity: 25. Limited storage space. Found in humble homes and small shops.'
			},
			['table'] = {
				'Table',
				'Wooden table with surface storage.',
				'Capacity: 25. Used for temporary storage. Found in taverns, homes, and workshops.'
			},
			['urn'] = {
				'Urn',
				'Ceramic or metal vessel.',
				'Capacity: 100. Often used for storing ashes or offerings. Common in tombs and temples.'
			},
			['wooden_barrel'] = {
				'Wooden Barrel',
				'Standard barrel made of planks.',
				'Capacity: 50. Identical to regular barrels. Used for liquids and bulk goods.'
			},
			['wooden_chest'] = {
				'Wooden Chest',
				'Plain wooden chest.',
				'Capacity: 150. Basic storage container. Found in most settlements across Vvardenfell.'
			},
			['worn_chest'] = {
				'Worn Chest',
				'Damaged and weathered chest.',
				'Capacity: 150. Shows signs of age and use. Found in abandoned buildings and ruins.'
			},
			['bonemeal_urn'] = {
				'Bonemeal Urn',
				'Small urn containing ground bone.',
				'Capacity: 10. Found in tombs across Vvardenfell. Contains a small amount of bonemeal.'
			},
			['ebony_vein'] = {
				'Ebony Vein',
				'Mineral deposit of black ebony ore.',
				'Organic container (cannot store items). Respawns ebony ore over time. Found in mines and caves.'
			},
			['gold_ore_vein'] = {
				'Gold Ore Vein',
				'Mineral deposit of precious gold.',
				'Organic container (cannot store items). Respawns gold ore. Found in rich mining areas.'
			},
			['iron_ore_vein'] = {
				'Iron Ore Vein',
				'Mineral deposit of common iron.',
				'Organic container (cannot store items). Respawns iron ore. Abundant across Vvardenfell.'
			},
			['mushroom_cluster'] = {
				'Mushroom Cluster',
				'Group of giant mushrooms.',
				'Organic container (cannot store items). May respawn edible or alchemical mushrooms. Common in caves and swamps.'
			},
			['silver_ore_vein'] = {
				'Silver Ore Vein',
				'Mineral deposit of silver.',
				'Organic container (cannot store items). Respawns silver ore. Found in mountainous regions.'
			}
        }
    }
}