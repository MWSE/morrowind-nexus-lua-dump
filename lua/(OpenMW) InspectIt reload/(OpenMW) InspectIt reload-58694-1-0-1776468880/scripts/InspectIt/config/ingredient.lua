local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Ingredient] = {
        title = 'Ingredient',
        color = util.color.rgb(0.3, 0.7, 0.3),
        showWeight = true,
        showValue = true,
        uniqueDescriptions = {
			['ingred_dreugh_wax_01'] = {
				'Dreugh Wax',
				'Secretion from dreughs.',
				'Type: Alchemical Ingredient',
				'Location: Dreugh lairs, coastal areas',
				'Description: Thick, oily substance',
				'harvested from dreughs.',
				'Used in powerful potions.',
				'Effects: Fortify Strength,',
				'Fortify Endurance,', 
				'Drain Fatigue, Water Breathing'
			},

			['food_kwama_egg_01'] = {
				'Kwama Egg',
				'Egg harvested from kwama nests.',
				'Type: Food/Ingredient',
				'Location: Kwama mines, nests',
				'Description: Nutritious egg used',
				'both as food and alchemical ingredient.',
				'Effects: Restore Fatigue, Restore Health'
			},

			['food_kwama_egg_02'] = {
				'Mature Kwama Egg',
				'Ripe kwama egg with enhanced properties.',
				'Type: Food/Ingredient',
				'Location: Deep kwama mines',
				'Description: More developed egg with',
				'stronger alchemical properties.',
				'Effects: Restore Fatigue, Restore Health,',
				'Fortify Endurance'
			},

			['ingred_kwama_cuttle_01'] = {
				'Kwama Cuttle',
				'Secretion from kwama.',
				'Type: Alchemical Ingredient',
				'Location: Kwama mines',
				'Description: Special secretion used in', 
				'water-based potions.',
				'Effects: Resist Poison, Drain Fatigue,', 
				'Water Walking, Water Breathing'
			},

			['ingred_marshmerrow_01'] = {
				'Marshmerrow',
				'Plant found in swamps.',
				'Type: Alchemical Ingredient',
				'Location: Swampy regions',
				'Description: Marsh plant used in healing potions.',
				'Effects: Restore Health, Cure Poison'
			},

			['ingred_saltrice_01'] = {
				'Saltrice',
				'Salt-resistant grain.',
				'Type: Alchemical Ingredient',
				'Location: Coastal regions',
				'Description: Grain grown in salty soils,',
				'used in stamina potions.',
				'Effects: Restore Fatigue, Fortify Endurance'
			},

			['ingred_diamond_01'] = {
				'Diamond',
				'Precious gemstone.',
				'Type: Alchemical Ingredient',
				'Location: Mines, gem traders',
				'Description: Pure crystal used in', 
				'powerful enchantments.',
				'Effects: Drain Agility, Invisibility,', 
				'Reflect, Detect Key'
			},

			['ingred_emerald_01'] = {
				'Emerald',
				'Green gemstone.',
				'Type: Alchemical Ingredient',
				'Location: Mines, gem traders',
				'Description: Valuable gem with', 
				'magical properties.',
				'Effects: Fortify Intelligence,', 
				'Restore Magicka,', 
				'Drain Speed, Resist Magic'
			},

			['ingred_pearl_01'] = {
				'Pearl',
				'Gleaming gem from oysters.',
				'Type: Alchemical Ingredient',
				'Location: Coastal waters, traders',
				'Description: Rare gem used in', 
				'water-based potions.',
				'Effects: Water Breathing,', 
				'Fortify Personality,', 
				'Drain Luck, Cure Paralysis'
			},

			['ingred_raw_ebony_01'] = {
				'Raw Ebony',
				'Unprocessed ebony ore.',
				'Type: Alchemical Ingredient',
				'Location: Ebony mines',
				'Description: Pure ebony ore with', 
				'magical properties.',
				'Effects: Fortify Health, Resist Magic,', 
				'Drain Speed, Damage Health'
			},

			['ingred_ruby_01'] = {
				'Ruby',
				'Precious red gemstone.',
				'Type: Alchemical Ingredient',
				'Location: Ruby mines, gem traders',
				'Description: Fiery gem used in', 
				'offensive potions.',
				'Effects: Fortify Magicka, Fire Shield,', 
				'Drain Fatigue, Reflect Damage'
			},

			['ingred_ash_salts_01'] = {
				'Ash Salts',
				'Mineral deposit from volcanic regions.',
				'Type: Alchemical Ingredient',
				'Location: Volcanic areas',
				'Description: Crystalline salts with', 
				'magical properties.',
				'Effects: Drain Magicka, Fortify Endurance,', 
				'Resist Fire, Light'
			},

			['ingred_corprus_weepings_01'] = {
				'Corprus Weepings',
				'Secretion from corprus-infected creatures.',
				'Type: Alchemical Ingredient',
				'Location: Corprus-infected areas',
				'Description: Unnatural secretion with', 
				'dangerous properties.',
				'Effects: Drain Health, Cure Disease,', 
				'Fortify Strength, Paralyze'
			},

			['ingred_crab_meat_01'] = {
				'Crab Meat',
				'Harvested from crabs.',
				'Type: Alchemical Ingredient',
				'Location: Coastal waters',
				'Description: Meat used in shock-resistant potions.',
				'Effects: Restore Fatigue, Resist Shock,э Lightning Shield,', 
				'Restore Luck',
				'Notes: Weight: 0.50, Value: 1'
			},

			['ingred_daedras_heart_01'] = {
				"Daedra's Heart",
				'Rare organ of Daedra.',
				'Type: Alchemical Ingredient',
				'Location: Daedric ruins, battles',
				'Description: Powerful organ with mystical properties.',
				'Effects: Restore Magicka, Fortify Endurance, Drain Agility,', 
				'Night Eye',
				'Notes: Weight: 1.00, Value: 200'
			},

			['ingred_daedra_skin_01'] = {
				'Daedra Skin',
				'Harvested from Daedra.',
				'Type: Alchemical Ingredient',
				'Location: Daedric ruins, battles',
				'Description: Tough hide with magical properties.',
				'Effects: Fortify Strength, Cure Common Disease,', 
				'Paralyze, Swift Swim',
				'Notes: Weight: 0.20, Value: 200'
			},

			['ingred_resin_01'] = {
				'Resin',
				'Sticky substance from trees and plants.',
				'Type: Alchemical Ingredient',
				'Location: Forests, swamps',
				'Description: Natural adhesive with healing properties.',
				'Effects: Restore Fatigue, Resist Poison, Drain Intelligence,', 
				'Cure Common Disease',
				'Notes: Weight: 0.10, Value: 3'
			},

			['ingred_alit_hide_01'] = {
				'Alit Hide',
				'Leather from alit creatures.',
				'Type: Alchemical Ingredient',
				'Location: Alit habitats',
				'Description: Tough hide used in protective potions.',
				'Effects: Fortify Endurance, Drain Agility, Resist Shock,', 
				'Restore Health',
				'Notes: Weight: 1.00, Value: 10'
			},

			['ingred_ash_yam_01'] = {
				'Ash Yam',
				'Tough tuberous root vegetable.',
				'Type: Alchemical Ingredient',
				'Location: Ashy soils, farms, Ascadian Isles',
				'Description: Hardy root vegetable with modest magical properties.',
				'Effects: Fortify Intelligence, Fortify Strength, Resist Common', 
				'Disease, Detect Key',
				'Notes: Weight: 0.50, Value: 1'
			},

			['ingred_bittergreen_petals_01'] = {
				'Bittergreen Petals',
				'Petals from bittergreen plants.',
				'Type: Alchemical Ingredient',
				'Location: Bittergreen plantations',
				'Description: Bitter petals used in intelligence-boosting potions.',
				'Effects: Restore Intelligence, Invisibility, Drain Endurance,', 
				'Drain Magicka',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_black_anther_01'] = {
				'Black Anther',
				'Found on Black Anther plants.',
				'Type: Alchemical Ingredient',
				'Location: Black Anther plantations',
				'Description: Dark flowers with fire-resistant properties.',
				'Effects: Drain Agility, Resist Fire, Drain Endurance, Light',
				'Notes: Weight: 0.10, Value: 2'
			},

			['ingred_black_lichen_01'] = {
				'Black Lichen',
				'Found on rocks in cold areas.',
				'Type: Alchemical Ingredient',
				'Location: Cold rock formations',
				'Description: Dark lichen with frost-related properties.',
				'Effects: Drain Strength, Resist Frost, Drain Speed, Cure Poison',
				'Notes: Weight: 0.10, Value: 2'
			},

			['ingred_bloat_01'] = {
				'Bloat',
				'Found near water and swamps.',
				'Type: Alchemical Ingredient',
				'Location: Swampy areas',
				'Description: Swamp growth with magical properties.',
				'Effects: Drain Magicka, Fortify Intelligence, Fortify Willpower,', 
				'Detect Animal',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_bonemeal_01'] = {
				'Bonemeal',
				'Made from ground bones.',
				'Type: Alchemical Ingredient',
				'Location: Bone processing areas',
				'Description: Ground bone material with mystical properties.',
				'Effects: Restore Agility, Telekinesis, Drain Fatigue, Drain', 
				'Personality',
				'Notes: Weight: 0.20, Value: 2'
			},

			['ingred_comberry_01'] = {
				'Comberry',
				'Berry found in forests.',
				'Type: Alchemical Ingredient',
				'Location: Forested areas',
				'Description: Small berry with healing properties.',
				'Effects: Restore Health, Fortify Agility, Drain Endurance, Cure', 
				'Common Disease',
				'Notes: Weight: 0.10, Value: 3'
			},

			['ingred_chokeweed_01'] = {
				'Chokeweed',
				'Toxic plant found in swamps.',
				'Type: Alchemical Ingredient',
				'Location: Swampy regions',
				'Description: Poisonous plant with protective properties.',
				'Effects: Drain Luck, Restore Fatigue, Cure Common Disease,', 
				'Drain Willpower',
				'Notes: Weight: 0.10, Value: 4'
			},

			['ingred_corkbulb_root_01'] = {
				'Corkbulb Root',
				'Root from corkbulb plants.',
				'Type: Alchemical Ingredient',
				'Location: Corkbulb plantations',
				'Description: Resilient root with restorative properties.',
				'Effects: Restore Health, Fortify Speed, Drain Endurance,', 
				'Cure Poison',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_ectoplasm_01'] = {
				'Ectoplasm',
				'Residue from ghosts and wraiths.',
				'Type: Alchemical Ingredient',
				'Location: Haunted areas, ghostly encounters',
				'Description: Ethereal substance with mystical properties.',
				'Effects: Fortify Magicka, Resist Shock, Drain Speed,', 
				'Detect Enchantment',
				'Notes: Weight: 0.20, Value: 125'
			},

			['ingred_fire_salts_01'] = {
				'Fire Salts',
				'Mineral deposit with fiery properties.',
				'Type: Alchemical Ingredient',
				'Location: Volcanic regions, fire mines',
				'Description: Crystalline salts with pyromantic properties.',
				'Effects: Fortify Magicka, Fire Shield, Drain Speed, Resist Frost',
				'Notes: Weight: 0.10, Value: 75'
			},

			['ingred_frost_salts_01'] = {
				'Frost Salts',
				'Mineral deposit with frost properties.',
				'Type: Alchemical Ingredient',
				'Location: Cold regions, ice caves',
				'Description: Crystalline salts with cryomantic properties.',
				'Effects: Drain Speed, Restore Magicka, Frost Shield, Resist Fire',
				'Notes: Weight: 0.10, Value: 75'
			},

			['ingred_ghoul_heart_01'] = {
				'Ghoul Heart',
				'Harvested from ghouls.',
				'Type: Alchemical Ingredient',
				'Location: Ghoul-infested areas',
				'Description: Dark organ with necromantic properties.',
				'Effects: Paralyze, Cure Poison, Fortify Attack',
				'Notes: Weight: 0.50, Value: 150'
			},

			['ingred_gold_kanet_01'] = {
				'Gold Kanet',
				'Flower found in sunny areas.',
				'Type: Alchemical Ingredient',
				'Location: Sunny fields, gardens',
				'Description: Golden flower with metallic properties.',
				'Effects: Drain Health, Burden, Drain Luck, Restore Strength',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_gravedust_01'] = {
				'Gravedust',
				'Dust from ancient tombs.',
				'Type: Alchemical Ingredient',
				'Location: Ancient tombs, crypts',
				'Description: Mystical dust with necromantic properties.',
				'Effects: Drain Intelligence, Cure Common Disease, Drain Magicka,', 
				'Restore Endurance',
				'Notes: Weight: 0.10, Value: 1'
			},

			['ingred_green_lichen_01'] = {
				'Green Lichen',
				'Found on rocks and trees.',
				'Type: Alchemical Ingredient',
				'Location: Forested areas, rocky terrain',
				'Description: Green lichen with restorative properties.',
				'Effects: Fortify Personality, Cure Common Disease, Drain Strength,', 
				'Drain Health',
				'Notes: Weight: 0.10, Value: 1'
			},

			['ingred_guar_hide_01'] = {
				'Guar Hide',
				'Leather from domesticated guars.',
				'Type: Alchemical Ingredient',
				'Location: Guar farms, ranches',
				'Description: Thick hide with protective properties.',
				'Effects: Drain Fatigue, Fortify Endurance, Restore Personality,', 
				'Fortify Luck',
				'Notes: Weight: 1.00, Value: 5'
			},

			['ingred_hackle-lo_leaf_01'] = {
				'Hackle-Lo Leaf',
				'Leaf from hackle-lo trees.',
				'Type: Alchemical Ingredient',
				'Location: Hackle-lo forests',
				'Description: Poisonous leaf with protective properties.',
				'Effects: Fortify Agility, Resist Poison, Drain Intelligence,', 
				'Restore Fatigue',
				'Notes: Weight: 0.10, Value: 3'
			},

			['ingred_heather_01'] = {
				'Heather',
				'Flower found in highlands.',
				'Type: Alchemical Ingredient',
				'Location: Highland regions, mountainous areas',
				'Description: Hardy flower with restorative properties.',
				'Effects: Fortify Agility, Cure Common Disease, Drain Personality,', 
				'Restore Fatigue',
				'Notes: Weight: 0.10, Value: 3'
			},

			['ingred_hound_meat_01'] = {
				'Hound Meat',
				'Obtained from hounds.',
				'Type: Alchemical Ingredient',
				'Location: Hound habitats, hunting grounds',
				'Description: Meat with protective properties.',
				'Effects: Restore Fatigue, Resist Shock, Fortify Endurance,', 
				'Restore Health',
				'Notes: Weight: 0.50, Value: 3'
			},

			['ingred_kagouti_hide_01'] = {
				'Kagouti Hide',
				'Leather from kagoutis.',
				'Type: Alchemical Ingredient',
				'Location: Kagouti territories',
				'Description: Thick hide with beneficial properties.',
				'Effects: Drain Fatigue, Fortify Speed, Resist Common Disease,', 
				'Night Eye',
				'Notes: Weight: 1.00, Value: 2'
			},

			['ingred_kresh_fiber_01'] = {
				'Kresh Fiber',
				'Fiber from kresh plants.',
				'Type: Alchemical Ingredient',
				'Location: Kresh plantations',
				'Description: Strong fiber with restorative properties.',
				'Effects: Fortify Agility, Drain Strength, Restore Fatigue,', 
				'Cure Poison',
				'Notes: Weight: 0.10, Value: 4'
			},

			['ingred_moon_sugar_01'] = {
				'Moon Sugar',
				'Exotic sweet substance.',
				'Type: Alchemical Ingredient',
				'Location: Moon Sugar plantations',
				'Description: Rare substance with addictive properties.',
				'Effects: Fortify Speed, Dispel, Drain Endurance, Drain Luck',
				'Notes: Weight: 0.10, Value: 50'
			},

			['ingred_muck_01'] = {
				'Muck',
				'Swampy organic matter.',
				'Type: Alchemical Ingredient',
				'Location: Swamps, marshy areas',
				'Description: Organic material with magical properties.',
				'Effects: Drain Intelligence, Detect Key, Drain Personality,', 
				'Cure Common Disease',
				'Notes: Weight: 0.10, Value: 1'
			},

			['ingred_netch_leather_01'] = {
				'Netch Leather',
				'Harvested from netch creatures.',
				'Type: Alchemical Ingredient',
				'Location: Netch farms, wild netch territories',
				'Description: Tough leather with protective qualities.',
				'Effects: Fortify Endurance, Resist Poison, Drain Fatigue,', 
				'Restore Health',
				'Notes: Weight: 1.00, Value: 10'
			},

			['ingred_racer_plumes_01'] = {
				'Racer Plumes',
				'Feathers from racer creatures.',
				'Type: Alchemical Ingredient',
				'Location: Racer habitats',
				'Description: Lightweight feathers with magical properties.',
				'Effects: Fortify Speed, Drain Endurance, Restore Fatigue,', 
				'Water Walking',
				'Notes: Weight: 0.20, Value: 7'
			},

			['ingred_rat_meat_01'] = {
				'Rat Meat',
				'Meat from rats.',
				'Type: Alchemical Ingredient',
				'Location: Urban areas, sewers',
				'Description: Common meat with basic properties.',
				'Effects: Restore Fatigue, Drain Health, Cure Common Disease,', 
				'Fortify Luck',
				'Notes: Weight: 0.30, Value: 1'
			},

			['ingred_raw_glass_01'] = {
				'Raw Glass',
				'Unrefined glass ore.',
				'Type: Alchemical Ingredient',
				'Location: Glass mines, quarries',
				'Description: Pure glass material with reflective properties.',
				'Effects: Reflect Damage, Fortify Magicka, Drain Luck, Light',
				'Notes: Weight: 50.0, Value: 400'
			},

			['ingred_red_lichen_01'] = {
				'Red Lichen',
				'Found in warm areas.',
				'Type: Alchemical Ingredient',
				'Location: Warm climates, rocky surfaces',
				'Description: Vibrant lichen with magical properties.',
				'Effects: Drain Speed, Light, Cure Common Disease, Drain Magicka',
				'Notes: Weight: 0.10, Value: 25'
			},

			['ingred_roobrush_01'] = {
				'Roobrush',
				'Herb found in damp areas.',
				'Type: Alchemical Ingredient',
				'Location: Damp environments',
				'Description: Moisture-loving herb with healing properties.',
				'Effects: Cure Poison, Restore Fatigue, Drain Magicka, Fortify Luck',
				'Notes: Weight: 0.10, Value: 6'
			},

			['ingred_scales_01'] = {
				'Scales',
				'Harvested from scaled creatures.',
				'Type: Alchemical Ingredient',
				'Location: Aquatic environments, reptile habitats',
				'Description: Tough scales with protective qualities.',
				'Effects: Resist Poison, Fortify Endurance, Drain Fatigue,', 
				'Water Breathing',
				'Notes: Weight: 0.20, Value: 8'
			},

			['ingred_scamp_skin_01'] = {
				'Scamp Skin',
				'Harvested from scamps.',
				'Type: Alchemical Ingredient',
				'Location: Scamp territories',
				'Description: Dark skin with mystical properties.',
				'Effects: Fortify Intelligence, Drain Health, Resist Magic,', 
				'Detect Life',
				'Notes: Weight: 0.30, Value: 150'
			},

			['ingred_scathecraw_01'] = {
				'Scathecraw',
				'Plant found in volcanic regions.',
				'Type: Alchemical Ingredient',
				'Location: Volcanic areas',
				'Description: Hardy plant with fire-resistant properties.',
				'Effects: Resist Fire, Fortify Willpower, Drain Intelligence,', 
				'Cure Disease',
				'Notes: Weight: 0.10, Value: 15'
			},

			['ingred_scrap_metal_01'] = {
				'Scrap Metal',
				'Junk metal found in ruins.',
				'Type: Alchemical Ingredient',
				'Location: Ancient ruins, battlefields',
				'Description: Recycled metal with basic properties.',
				'Effects: Fortify Willpower, Drain Intelligence, Damage Health,', 
				'Cure Disease',
				'Notes: Weight: 1.00, Value: 2'
			},

			['ingred_scrib_jelly_01'] = {
				'Scrib Jelly',
				'Secretion from scribs.',
				'Type: Alchemical Ingredient',
				'Location: Scrib farms, nests',
				'Description: Gelatinous substance with magical properties.',
				'Effects: Restore Magicka, Resist Shock, Drain Fatigue, Light',
				'Notes: Weight: 0.20, Value: 10'
			},

			['ingred_scuttle_01'] = {
				'Scuttle',
				'Marine organism.',
				'Type: Alchemical Ingredient',
				'Location: Coastal waters',
				'Description: Sea creature with protective qualities.',
				'Effects: Resist Poison, Fortify Endurance, Drain Fatigue,', 
				'Water Breathing',
				'Notes: Weight: 0.20, Value: 7'
			},

			['ingred_shalk_resin_01'] = {
				'Shalk Resin',
				'Secretion from shalks.',
				'Type: Alchemical Ingredient',
				'Location: Shalk habitats',
				'Description: Sticky resin with magical properties.',
				'Effects: Restore Health, Fortify Endurance, Drain Intelligence,', 
				'Cure Poison',
				'Notes: Weight: 0.10, Value: 12'
			},

			['ingred_sload_soap_01'] = {
				'Sload Soap',
				'Unusual soap made by sloads.',
				'Type: Alchemical Ingredient',
				'Location: Sload settlements',
				'Description: Foul-smelling soap with unique properties.',
				'Effects: Cure Disease, Drain Personality, Fortify Willpower,', 
				'Detect Life',
				'Notes: Weight: 0.20, Value: 15'
			},

			['ingred_stoneflower_petals_01'] = {
				'Stoneflower Petals',
				'Petals from stoneflowers.',
				'Type: Alchemical Ingredient',
				'Location: Rocky terrain',
				'Description: Petals with earth-based properties.',
				'Effects: Fortify Endurance, Resist Poison, Drain Agility,', 
				'Cure Disease',
				'Notes: Weight: 0.10, Value: 6'
			},

			['ingred_trama_root_01'] = {
				'Trama Root',
				'Root plant found in swamps.',
				'Type: Alchemical Ingredient',
				'Location: Swampy regions',
				'Description: Root with healing properties.',
				'Effects: Cure Paralysis, Fortify Endurance, Drain Luck,', 
				'Restore Fatigue',
				'Notes: Weight: 0.10, Value: 10'
			},

			['ingred_vampire_dust_01'] = {
				'Vampire Dust',
				'Remains of vampires.',
				'Type: Alchemical Ingredient',
				'Location: Vampire lairs',
				'Description: Ethereal dust with dark magic.',
				'Effects: Drain Health, Fortify Magicka, Night Eye, Detect Life',
				'Notes: Weight: 0.10, Value: 200'
			},

			['ingred_void_salts_01'] = {
				'Void Salts',
				'Mysterious mineral deposit.',
				'Type: Alchemical Ingredient',
				'Location: Ancient ruins',
				'Description: Strange salts with arcane properties.',
				'Effects: Drain Intelligence, Fortify Willpower, Detect Life, Light',
				'Notes: Weight: 0.10, Value: 100'
			},

			['ingred_wickwheat_01'] = {
				'Wickwheat',
				'Flammable plant.',
				'Type: Alchemical Ingredient',
				'Location: Dry regions',
				'Description: Plant with fire-based properties.',
				'Effects: Fire Damage, Drain Health, Fortify Intelligence, Light',
				'Notes: Weight: 0.10, Value: 8'
			},

			['ingred_willow_anther_01'] = {
				'Willow Anther',
				'Part of willow plants.',
				'Type: Alchemical Ingredient',
				'Location: Willow forests',
				'Description: Plant part with healing properties.',
				'Effects: Restore Health, Cure Disease, Drain Magicka, Light',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_scrib_jerky_01'] = {
				'Scrib Jerky',
				'Dried scrib meat.',
				'Type: Alchemical Ingredient',
				'Location: Scrib farms',
				'Description: Preserved meat with basic properties.',
				'Effects: Restore Fatigue, Restore Health, Drain Intelligence',
				'Notes: Weight: 0.30, Value: 5'
			},

			['ingred_fire_petal_01'] = {
				'Fire Petal',
				'Petal from fire-blooming flowers.',
				'Type: Alchemical Ingredient',
				'Location: Volcanic regions, fire-resistant flora',
				'Description: Fiery petals with pyromantic properties.',
				'Effects: Fire Shield, Resist Fire, Drain Intelligence,', 
				'Cure Paralysis',
				'Notes: Weight: 0.10, Value: 25'
			},

			['ingred_bread_01'] = {
				'Bread',
				'Basic food item.',
				'Type: Food/Alchemical Ingredient',
				'Location: Bakeries, markets, homes',
				'Description: Common bread used for basic sustenance.',
				'Effects: Restore Fatigue',
				'Notes: Weight: 0.20, Value: 1'
			},

			['ingred_coprinus_01'] = {
				'Coprinus Mushroom',
				'Common mushroom found in forests.',
				'Type: Alchemical Ingredient',
				'Location: Forested areas, damp environments',
				'Description: Edible mushroom with basic properties.',
				'Effects: Restore Health, Cure Poison',
				'Notes: Weight: 0.10, Value: 2'
			},

			['ingred_russula_01'] = {
				'Russula Mushroom',
				'Brightly colored forest mushroom.',
				'Type: Alchemical Ingredient',
				'Location: Forest clearings',
				'Description: Poisonous mushroom with magical properties.',
				'Effects: Drain Health, Fortify Intelligence, Light',
				'Notes: Weight: 0.10, Value: 3'
			},

			['ingred_bc_ampoule_pod'] = {
				'Ampoule Pod',
				'Unique plant growth.',
				'Type: Alchemical Ingredient',
				'Location: Special plantations',
				'Description: Rare pod with potent alchemical properties.',
				'Effects: Fortify Magicka, Restore Health, Light',
				'Notes: Weight: 0.15, Value: 50'
			},

			["ingred_bc_bunglers_bane"] = {
				"Bunglers Bane",
				'Toxic plant.',
				'Type: Alchemical Ingredient',
				'Location: Poisonous gardens',
				'Description: Deadly plant with powerful effects.',
				'Effects: Damage Health, Fortify Willpower, Drain Luck',
				'Notes: Weight: 0.10, Value: 40'
			},

			['ingred_bc_hypha_facia'] = {
				'Hypha Facia',
				'Fungal growth.',
				'Type: Alchemical Ingredient',
				'Location: Fungal regions',
				'Description: Strange fungus with unique properties.',
				'Effects: Restore Magicka, Drain Health, Light',
				'Notes: Weight: 0.10, Value: 35'
			},

			['ingred_bc_spore_pod'] = {
				'Spore Pod',
				'Fungal spore container.',
				'Type: Alchemical Ingredient',
				'Location: Fungal areas',
				'Description: Pod filled with magical spores.',
				'Effects: Fortify Endurance, Drain Intelligence, Cure Disease',
				'Notes: Weight: 0.10, Value: 45'
			},

			['ingred_bc_coda_flower'] = {
				'Coda Flower',
				'Rare flowering plant.',
				'Type: Alchemical Ingredient',
				'Location: Special flower beds',
				'Description: Exotic flower with potent effects.',
				'Effects: Restore Health, Fortify Agility, Light',
				'Notes: Weight: 0.10, Value: 55'
			},

			['ingred_guar_hide_girith'] = {
				'Special Guar Hide',
				'Unique guar leather variant.',
				'Type: Alchemical Ingredient',
				'Location: Special guar herds',
				'Description: Premium quality guar hide.',
				'Effects: Fortify Endurance, Resist Poison, Restore Health',
				'Notes: Weight: 1.20, Value: 20'
			},

			['ingred_guar_hide_marsus'] = {
				'Marsus Guar Hide',
				'Rare variant of guar leather.',
				'Type: Alchemical Ingredient',
				'Location: Elite guar herds',
				'Description: Extraordinarily tough guar hide.',
				'Effects: Fortify Strength, Resist Shock, Restore Endurance',
				'Notes: Weight: 1.50, Value: 30'
			},

			['ingred_raw_glass_tinos'] = {
				'Tinos Raw Glass',
				'High-quality glass ore.',
				'Type: Alchemical Ingredient',
				'Location: Tinos mines',
				'Description: Pristine glass material with enhanced properties.',
				'Effects: Reflect Damage, Fortify Magicka, Light',
				'Notes: Weight: 50.0, Value: 500'
			},

			['ingred_treated_bittergreen_uniq'] = {
				'Treated Bittergreen',
				'Processed bittergreen plant.',
				'Type: Alchemical Ingredient',
				'Location: Alchemical labs',
				'Description: Enhanced bittergreen with potent effects.',
				'Effects: Fortify Intelligence, Invisibility, Drain Magicka',
				'Notes: Weight: 0.15, Value: 75'
			},

			['ingred_gold_kanet_unique'] = {
				'Unique Gold Kanet',
				'Rare variant of the gold kanet flower.',
				'Type: Alchemical Ingredient',
				'Location: Sacred gardens',
				'Description: Extraordinary flower with powerful properties.',
				'Effects: Fortify Health, Drain Luck, Restore Strength',
				'Notes: Weight: 0.15, Value: 100'
			},

			['ingred_bread_01_UNI2'] = {
				'Special Bread',
				'Enhanced bread variant.',
				'Type: Food/Alchemical Ingredient',
				'Location: Elite bakeries',
				'Description: Superior bread with additional benefits.',
				'Effects: Restore Fatigue, Fortify Endurance',
				'Notes: Weight: 0.25, Value: 5'
			},

			['poison_goop00'] = {
				'Poison Goop',
				'Viscous toxic substance.',
				'Type: Alchemical Ingredient',
				'Location: Poisonous environments',
				'Description: Thick, dangerous substance with potent effects.',
				'Effects: Damage Health, Poison, Drain Magicka',
				'Notes: Weight: 0.20, Value: 25'
			},

			['ingred_Dae_cursed_emerald_01'] = {
				'Cursed Daedric Emerald',
				'Corrupted daedric gem.',
				'Type: Alchemical Ingredient',
				'Location: Daedric ruins',
				'Description: Twisted emerald with dark magic.',
				'Effects: Drain Health, Curse, Fortify Magicka',
				'Notes: Weight: 0.25, Value: 500'
			},

			['ingred_Dae_cursed_pearl_01'] = {
				'Cursed Daedric Pearl',
				'Darkened pearl with daedric influence.',
				'Type: Alchemical Ingredient',
				'Location: Corrupted waters',
				'Description: Malevolent pearl with sinister properties.',
				'Effects: Drain Personality, Curse, Water Breathing',
				'Notes: Weight: 0.25, Value: 450'
			},

			['ingred_cursed_daedras_heart_01'] = {
				"Cursed Daedra's Heart",
				'Corrupted daedric organ.',
				'Type: Alchemical Ingredient',
				'Location: Dark ritual sites',
				'Description: Twisted heart with dark magic.',
				'Effects: Drain Health, Curse, Fortify Magicka',
				'Notes: Weight: 1.25, Value: 600'
			},

			['ingred_Dae_cursed_diamond_01'] = {
				'Cursed Daedric Diamond',
				'Twisted diamond imbued with dark energy.',
				'Type: Alchemical Ingredient',
				'Location: Forbidden daedric temples',
				'Description: Diamond corrupted by daedric forces.',
				'Effects: Drain Agility, Curse, Reflect Damage',
				'Notes: Weight: 0.25, Value: 700'
			},

			['ingred_Dae_cursed_ruby_01'] = {
				'Cursed Daedric Ruby',
				'Ruby tainted by daedric magic.',
				'Type: Alchemical Ingredient',
				'Location: Ancient daedric altars',
				'Description: Ruby infused with dark power.',
				'Effects: Drain Fatigue, Curse, Fire Shield',
				'Notes: Weight: 0.25, Value: 650'
			},

			['ingred_Dae_cursed_raw_ebony_01'] = {
				'Cursed Daedric Ebony',
				'Ebony ore corrupted by dark forces.',
				'Type: Alchemical Ingredient',
				'Location: Forbidden ebony mines',
				'Description: Ebony imbued with daedric energy.',
				'Effects: Drain Health, Curse, Fortify Health',
				'Notes: Weight: 55.0, Value: 800'
			},

			['ingred_human_meat_01'] = {
				'Human Meat',
				'Harvested from human remains.',
				'Type: Alchemical Ingredient',
				'Location: Battlefields, crypts',
				'Description: Taboo ingredient with dark properties.',
				'Effects: Drain Health, Fortify Magicka, Curse',
				'Notes: Weight: 0.75, Value: 150'
			},

			['ingred_6th_corprusmeat_01'] = {
				'Corprus Meat (Stage 1)',
				'Meat from corprus-infected creature.',
				'Type: Alchemical Ingredient',
				'Location: Corprus-infected zones',
				'Description: Infected meat with dangerous properties.',
				'Effects: Drain Health, Corprus Disease, Fortify Strength',
				'Notes: Weight: 0.80, Value: 200'
			},

			['ingred_6th_corprusmeat_02'] = {
				'Corprus Meat (Stage 2)',
				'Advanced corprus-infected meat.',
				'Type: Alchemical Ingredient',
				'Location: Severely infected areas',
				'Description: More potent corprus-tainted meat.',
				'Effects: Drain Health, Corprus Disease, Fortify Endurance',
				'Notes: Weight: 0.90, Value: 250'
			},

			['ingred_6th_corprusmeat_03'] = {
				'Corprus Meat (Stage 3)',
				'Highly infected corprus meat.',
				'Type: Alchemical Ingredient',
				'Location: Terminal corprus zones',
				'Description: Extremely dangerous corprus meat.',
				'Effects: Drain Health, Corprus Disease, Fortify Health',
				'Notes: Weight: 1.00, Value: 300'
			},

			['ingred_scrib_jelly_02'] = {
				'Enhanced Scrib Jelly',
				'Refined scrib secretion.',
				'Type: Alchemical Ingredient',
				'Location: Specialized scrib farms',
				'Description: Processed jelly with enhanced effects.',
				'Effects: Restore Magicka, Resist Shock, Light',
				'Notes: Weight: 0.25, Value: 15'
			},

			['ingred_bread_01_UNI3'] = {
				'Elite Bread',
				'Highest quality bread variant.',
				'Type: Food/Alchemical Ingredient',
				'Location: Royal bakeries, elite markets',
				'Description: Superior bread crafted with rare ingredients.',
				'Effects: Restore Fatigue, Fortify Endurance, Restore Health',
				'Notes: Weight: 0.30, Value: 10'
			},

			['Ingred_horn_lily_bulb_01'] = {
				'Horn Lily Bulb',
				'Bulb from horn lily plants.',
				'Type: Alchemical Ingredient',
				'Location: Noble gardens, planters',
				'Description: Bulb with protective properties.',
				'Effects: Resist Paralysis, Drain Health, Restore Strength',
				'Notes: Weight: 1.00, Value: 1'
			},

			['Ingred_nirthfly_stalks_01'] = {
				'Nirthfly Stalks',
				'Stalks from nirthfly plants.',
				'Type: Alchemical Ingredient',
				'Location: Mournhold gardens',
				'Description: Stalks with healing properties.',
				'Effects: Damage Health, Fortify Speed, Restore Speed',
				'Notes: Weight: 1.00, Value: 1'
			},

			['Ingred_timsa-come-by_01'] = {
				'Timsa-Come-By',
				'Rare plant from Mournhold.',
				'Type: Alchemical Ingredient',
				'Location: Secret gardens',
				'Description: Mysterious plant with unique effects.',
				'Effects: Fortify Intelligence, Restore Magicka',
				'Notes: Weight: 0.10, Value: 5'
			},

			['Ingred_meadow_rye_01'] = {
				'Meadow Rye',
				'Grain plant from Mournhold.',
				'Type: Alchemical Ingredient',
				'Location: Noble districts',
				'Description: Grain with restorative properties.',
				'Effects: Fortify Speed, Restore Fatigue',
				'Notes: Weight: 1.00, Value: 1'
			},

			['Ingred_sweetpulp_01'] = {
				'Sweetpulp',
				'Juicy plant material.',
				'Type: Alchemical Ingredient',
				'Location: Tropical regions',
				'Description: Sweet plant with healing effects.',
				'Effects: Restore Health, Cure Disease',
				'Notes: Weight: 0.20, Value: 3'
			},

			['Ingred_scrib_cabbage_01'] = {
				'Scrib Cabbage',
				'Unique vegetable.',
				'Type: Alchemical Ingredient',
				'Location: Special farms',
				'Description: Vegetable with magical properties.',
				'Effects: Restore Fatigue, Cure Poison',
				'Notes: Weight: 0.50, Value: 4'
			},

			['Ingred_lloramor_spines_01'] = {
				'Lloramor Spines',
				'Spines from decorative plants.',
				'Type: Alchemical Ingredient',
				'Location: Noble estates',
				'Description: Spiky plant material with arcane effects.',
				'Effects: Spell Absorption, Invisibility',
				'Notes: Weight: 0.10, Value: 2'
			},

			['Ingred_golden_sedge_01'] = {
				'Golden Sedge',
				'Golden-hued plant.',
				'Type: Alchemical Ingredient',
				'Location: Royal gardens',
				'Description: Precious plant with fortifying properties.',
				'Effects: Fortify Strength, Restore Endurance',
				'Notes: Weight: 0.10, Value: 3'
			},

			['Ingred_noble_sedge_01'] = {
				'Noble Sedge',
				'Decorative plant of high quality.',
				'Type: Alchemical Ingredient',
				'Location: Elite districts',
				'Description: Noble plant with beneficial effects.',
				'Effects: Fortify Personality, Restore Fatigue',
				'Notes: Weight: 0.10, Value: 2'
			},

			['ingred_adamantium_ore_01'] = {
				'Adamantium Ore',
				'Rare metallic ore.',
				'Type: Alchemical Ingredient',
				'Location: Deep mines',
				'Description: Pristine adamantium with powerful properties.',
				'Effects: Burden, Restore Magicka, Poison, Reflect',
				'Notes: Weight: 50.0, Value: 300'
			},

			['ingred_durzog_meat_01'] = {
				'Durzog Meat',
				'Meat from durzog creatures.',
				'Type: Alchemical Ingredient',
				'Location: Mournhold regions',
				'Description: Meat with unique magical properties.',
				'Effects: Fortify Agility, Fortify Strength, Blind, Damage Magicka',
				'Notes: Weight: 2.0, Value: 7'
			},

			['ingred_emerald_pinetear'] = {
				'Emerald Pine Tear',
				'Resin from ancient pines.',
				'Type: Alchemical Ingredient',
				'Location: Ancient pine forests',
				'Description: Rare resin with emerald properties.',
				'Effects: Fortify Intelligence, Restore Health',
				'Notes: Weight: 0.10, Value: 100'
			},

			['ingred_raw_Stalhrim_01'] = {
				'Raw Stalhrim',
				'Unique icy material.',
				'Type: Alchemical Ingredient',
				'Location: Frozen regions',
				'Description: Rare frost material with magical properties.',
				'Effects: Frost Damage, Fortify Health',
				'Notes: Weight: 50.0, Value: 400'
			},

			['ingred_blood_innocent_unique'] = {
				'Innocent Blood',
				'Special blood ingredient.',
				'Type: Alchemical Ingredient',
				'Location: Secret locations',
				'Description: Pure blood with potent effects.',
				'Effects: Restore Health, Fortify Magicka',
				'Notes: Weight: 0.10, Value: 500'
			},

			['ingred_snowwolf_pelt_unique'] = {
				'Unique Snowwolf Pelt',
				'Rare snowwolf hide.',
				'Type: Alchemical Ingredient',
				'Location: Extreme northern regions',
				'Description: Extraordinary pelt with magical properties.',
				'Effects: Fortify Endurance, Resist Frost',
				'Notes: Weight: 3.0, Value: 300'
			},

			['ingred_snowbear_pelt_unique'] = {
				'Unique Snowbear Pelt',
				'Special snowbear hide.',
				'Type: Alchemical Ingredient',
				'Location: Frozen wilderness',
				'Description: Premium quality pelt with protective qualities.',
				'Effects: Fortify Strength, Resist Frost',
				'Notes: Weight: 4.0, Value: 400'
			},

			['ingred_udyrfrykte_heart'] = {
				'Udyrfrykte Heart',
				'Heart of a mythical creature.',
				'Type: Alchemical Ingredient',
				'Location: Ancient forests',
				'Description: Mysterious heart with powerful magic.',
				'Effects: Restore Health, Fortify Magicka',
				'Notes: Weight: 1.0, Value: 600'
			},

			['ingred_belladonna_01'] = {
				'Belladonna',
				'Poisonous plant.',
				'Type: Alchemical Ingredient',
				'Location: Shady forests',
				'Description: Deadly plant with potent effects.',
				'Effects: Drain Health, Fortify Intelligence',
				'Notes: Weight: 0.10, Value: 15'
			},

			['ingred_wolfsbane_01'] = {
				'Wolfsbane',
				'Toxic herb.',
				'Type: Alchemical Ingredient',
				'Location: Forest clearings, mountainous regions',
				'Description: Poisonous herb with magical properties.',
				'Effects: Drain Health, Fortify Intelligence, Cure Disease',
				'Notes: Weight: 0.10, Value: 20'
			},

			['ingred_holly_01'] = {
				'Holly',
				'Evergreen plant.',
				'Type: Alchemical Ingredient',
				'Location: Forested areas, winter regions',
				'Description: Hardy plant with protective qualities.',
				'Effects: Resist Frost, Restore Health',
				'Notes: Weight: 0.10, Value: 5'
			},

			['ingred_belladonna_02'] = {
				'Belladonna (Advanced)',
				'Mature poisonous plant.',
				'Type: Alchemical Ingredient',
				'Location: Dark forests, swamps',
				'Description: Fully grown belladonna with enhanced effects.',
				'Effects: Drain Health, Fortify Intelligence, Paralyze',
				'Notes: Weight: 0.15, Value: 30'
			},

			['ingred_bear_pelt'] = {
				'Bear Pelt',
				'Thick bear hide.',
				'Type: Alchemical Ingredient',
				'Location: Bear habitats, hunting grounds',
				'Description: Durable pelt with protective properties.',
				'Effects: Fortify Strength, Resist Frost',
				'Notes: Weight: 5.0, Value: 100'
			},

			['ingred_wolf_pelt'] = {
				'Wolf Pelt',
				'Wolf hide.',
				'Type: Alchemical Ingredient',
				'Location: Wolf territories, hunting camps',
				'Description: Sturdy pelt with magical properties.',
				'Effects: Fortify Agility, Resist Poison',
				'Notes: Weight: 3.0, Value: 80'
			},

			['ingred_innocent_heart'] = {
				'Innocent Heart',
				'Special heart ingredient.',
				'Type: Alchemical Ingredient',
				'Location: Secret locations',
				'Description: Pure heart with potent effects.',
				'Effects: Restore Health, Fortify Magicka',
				'Notes: Weight: 1.0, Value: 500'
			},

			['ingred_wolf_heart'] = {
				'Wolf Heart',
				'Heart of a mighty wolf.',
				'Type: Alchemical Ingredient',
				'Location: Wolf lairs, hunting grounds',
				'Description: Powerful organ with magical properties.',
				'Effects: Fortify Agility, Restore Health',
				'Notes: Weight: 0.5, Value: 150'
			},

			['ingred_heartwood_01'] = {
				'Heartwood',
				'Special wood from ancient trees.',
				'Type: Alchemical Ingredient',
				'Location: Ancient forests',
				'Description: Heart of an ancient tree with magical properties.',
				'Effects: Restore Health, Fortify Endurance',
				'Notes: Weight: 1.0, Value: 75'
			},

			['ingred_boar_leather'] = {
				'Boar Leather',
				'Tough boar hide.',
				'Type: Alchemical Ingredient',
				'Location: Boar habitats',
				'Description: Durable leather with protective qualities.',
				'Effects: Fortify Endurance, Resist Shock',
				'Notes: Weight: 2.0, Value: 60'
			},

			['ingred_horker_tusk_01'] = {
				'Horker Tusk',
				'Tusk from a horker.',
				'Type: Alchemical Ingredient',
				'Location: Coastal regions',
				'Description: Sturdy tusk with unique properties.',
				'Effects: Fortify Strength, Restore Health',
				'Notes: Weight: 1.0, Value: 40'
			},

			['ingred_gravetar_01'] = {
				'Gravetar',
				'Strange substance from ancient tombs.',
				'Type: Alchemical Ingredient',
				'Location: Ancient ruins, crypts',
				'Description: Mysterious material with dark magic.',
				'Effects: Drain Health, Fortify Magicka, Curse',
				'Notes: Weight: 0.50, Value: 200'
			},

			['ingred_eyeball'] = {
				'Eyeball',
				'Harvested eyeball.',
				'Type: Alchemical Ingredient',
				'Location: Dark ritual sites',
				'Description: Unsettling ingredient with magical properties.',
				'Effects: Night Eye, Detect Life, Drain Personality',
				'Notes: Weight: 0.10, Value: 150'
			},

			['ingred_eyeball_unique'] = {
				'Unique Eyeball',
				'Specialized magical eyeball.',
				'Type: Alchemical Ingredient',
				'Location: Forbidden ritual grounds',
				'Description: Extraordinary eyeball with enhanced effects.',
				'Effects: Night Eye, Detect Life, Drain Personality,', 
				'Fortify Intelligence',
				'Notes: Weight: 0.15, Value: 300'
			}
        }
    }
}