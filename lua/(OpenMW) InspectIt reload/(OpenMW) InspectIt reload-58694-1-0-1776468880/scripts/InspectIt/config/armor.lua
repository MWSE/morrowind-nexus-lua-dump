local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Armor] = {
        title = 'Armor',
        color = util.color.rgb(0.4, 0.6, 0.8),
        showArmorRating = true,
        showCondition = true,
        showValue = true,
        uniqueDescriptions = {
			['chitin cuirass'] = {
				'Chitin Cuirass',
				'Robust armor made from chitin plates.',
				'Provides basic protection with flexibility.',
				'Type: Cuirass'
			},

			['chitin pauldron - left'] = {
				'Chitin Pauldron (Left)',
				'Left shoulder guard made of chitin.',
				'Offers protection for the left shoulder.',
				'Type: Left Pauldron'
			},

			['chitin pauldron - right'] = {
				'Chitin Pauldron (Right)',
				'Right shoulder guard made of chitin.',
				'Provides protection for the right shoulder.',
				'Type: Right Pauldron'
			},

			['chitin boots'] = {
				'Chitin Boots',
				'Lightweight boots crafted from chitin.',
				'Protects the feet while maintaining mobility.',
				'Type: Boots'
			},

			['chitin greaves'] = {
				'Chitin Greaves',
				'Leg guards made from durable chitin.',
				'Offers protection for the lower legs.',
				'Type: Greaves'
			},

			['chitin helm'] = {
				'Chitin Helm',
				'Helmet constructed from chitin plates.',
				'Provides head protection with good visibility.',
				'Type: Helmet'
			},

			['chitin guantlet - left'] = {
				'Chitin Gauntlet (Left)',
				'Left hand guard made of chitin material.',
				'Protects the left hand and wrist.',
				'Type: Left Gauntlet'
			},

			['chitin guantlet - right'] = {
				'Chitin Gauntlet (Right)',
				'Right hand guard made of chitin material.',
				'Offers protection for the right hand and wrist.',
				'Type: Right Gauntlet'
			},

			['indoril shield'] = {
				'Indoril Shield',
				'Sturdy shield crafted by Indoril artisans.',
				'Provides reliable protection in combat.',
				'Type: Shield'
			},

			['templar_pauldron_right'] = {
				'Templar Pauldron (Right)',
				'Right shoulder guard used by templars.',
				'Combines protection with religious symbolism.',
				'Type: Right Pauldron'
			},

			['templar boots'] = {
				'Templar Boots',
				'Boots designed for templar use.',
				'Balances protection and mobility.',
				'Type: Boots'
			},

			['indoril pauldron left'] = {
				'Indoril Pauldron (Left)',
				'Left shoulder guard made by Indoril craftsmen.',
				'Offers substantial protection for the shoulder.',
				'Type: Left Pauldron'
			},

			['indoril pauldron right'] = {
				'Indoril Pauldron (Right)',
				'Right shoulder guard crafted by Indoril.',
				'Provides robust protection for the shoulder.',
				'Type: Right Pauldron'
			},

			['templar bracer left'] = {
				'Templar Bracer (Left)',
				'Left forearm guard used by templars.',
				'Combines defense with religious markings.',
				'Type: Left Bracer'
			},

			['templar bracer right'] = {
				'Templar Bracer (Right)',
				'Right forearm guard used by templars.',
				'Offers protection with templar symbolism.',
				'Type: Right Bracer'
			},

			['templar_pauldron_left'] = {
				'Templar Pauldron (Left)',
				'Left shoulder guard designed for templars.',
				'Provides substantial protection.',
				'Type: Left Pauldron'
			},

			['templar_cuirass'] = {
				'Templar Cuirass',
				'Chest armor used by templar order.',
				'Combines protection with sacred symbols.',
				'Type: Cuirass'
			},

			['imperial left pauldron'] = {
				'Imperial Pauldron (Left)',
				'Left shoulder guard of imperial design.',
				'Standard issue for imperial soldiers.',
				'Type: Left Pauldron'
			},

			['imperial right pauldron'] = {
				'Imperial Pauldron (Right)',
				'Right shoulder guard of imperial design.',
				'Part of imperial military armor.',
				'Type: Right Pauldron'
			},

			['imperial left gauntlet'] = {
				'Imperial Gauntlet (Left)',
				'Left hand guard made of imperial steel.',
				'Provides protection for the left hand.',
				'Type: Left Gauntlet'
			},

			['imperial right gauntlet'] = {
				'Imperial Gauntlet (Right)',
				'Right hand guard made of imperial steel.',
				'Offers protection for the right hand.',
				'Type: Right Gauntlet'
			},

			['imperial boots'] = {
				'Imperial Boots',
				'Sturdy boots crafted for imperial soldiers.',
				'Combines protection and mobility.',
				'Type: Boots'
			},

			['indoril helmet'] = {
				'Indoril Helmet',
				'Helmet crafted by skilled Indoril artisans.',
				'Provides comprehensive head protection.',
				'Type: Helmet'
			},

			['imperial helmet armor'] = {
				'Imperial Helmet Armor',
				'Standard imperial helmet design.',
				'Offers reliable head protection.',
				'Type: Helmet'
			},

			['indoril cuirass'] = {
				'Indoril Cuirass',
				'Chest armor crafted by Indoril мастеров.',
				'Provides excellent chest protection.',
				'Type: Cuirass'
			},

			['indoril left gauntlet'] = {
				'Indoril Gauntlet (Left)',
				'Left hand guard made by Indoril craftsmen.',
				'Offers precise hand protection.',
				'Type: Left Gauntlet'
			},

			['indoril right gauntlet'] = {
				'Indoril Gauntlet (Right)',
				'Right hand guard made by Indoril craftsmen.',
				'Provides reliable hand protection.',
				'Type: Right Gauntlet'
			},

			['indoril boots'] = {
				'Indoril Boots',
				'Boots crafted with Indoril precision.',
				'Combines protection and agility.',
				'Type: Boots'
			},
			['right leather bracer'] = {
				'Right Leather Bracer',
				'Right forearm guard made of leather.',
				'Lightweight arm protection.',
				'Type: Right Bracer'
			},

			['left leather bracer'] = {
				'Left Leather Bracer',
				'Left forearm guard made of leather.',
				'Provides basic arm protection.',
				'Type: Left Bracer'
			},

			['cloth bracer left'] = {
				'Cloth Bracer (Left)',
				'Left forearm guard made of cloth.',
				'Lightweight and flexible protection.',
				'Type: Left Bracer'
			},

			['cloth bracer right'] = {
				'Cloth Bracer (Right)',
				'Right forearm guard made of cloth.',
				'Basic arm protection.',
				'Type: Right Bracer'
			},

			['imperial shield'] = {
				'Imperial Shield',
				'Standard imperial shield design.',
				'Reliable defensive tool.',
				'Type: Shield'
			},

			['netch_leather_helm'] = {
				'Netch Leather Helmet',
				'Helmet made from netch leather.',
				'Flexible head protection.',
				'Type: Helmet'
			},

			['netch_leather_boiled_helm'] = {
				'Boiled Netch Leather Helmet',
				'Hardened netch leather helmet.',
				'Enhanced head protection.',
				'Type: Helmet'
			},

			['netch_leather_pauldron_left'] = {
				'Netch Leather Pauldron (Left)',
				'Left shoulder guard made of netch leather.',
				'Lightweight shoulder protection.',
				'Type: Left Pauldron'
			},

			['netch_leather_cuirass'] = {
				'Netch Leather Cuirass',
				'Chest armor made from netch leather.',
				'Flexible chest protection.',
				'Type: Cuirass'
			},

			['netch_leather_boiled_cuirass'] = {
				'Boiled Netch Leather Cuirass',
				'Hardened netch leather chest armor.',
				'Enhanced protection with flexibility.',
				'Type: Cuirass'
			},

			['netch_leather_gauntlet_left'] = {
				'Netch Leather Gauntlet (Left)',
				'Left hand guard made of netch leather.',
				'Lightweight hand protection.',
				'Type: Left Gauntlet'
			},

			['netch_leather_gauntlet_right'] = {
				'Netch Leather Gauntlet (Right)',
				'Right hand guard made of netch leather.',
				'Flexible hand protection.',
				'Type: Right Gauntlet'
			},

			['netch_leather_greaves'] = {
				'Netch Leather Greaves',
				'Leg guards made from netch leather.',
				'Lightweight leg protection.',
				'Type: Greaves'
			},

			['netch_leather_boots'] = {
				'Netch Leather Boots',
				'Boots crafted from netch leather.',
				'Flexible foot protection.',
				'Type: Boots'
			},

			['netch_leather_shield'] = {
				'Netch Leather Shield',
				'Shield made from netch leather.',
				'Lightweight defensive tool.',
				'Type: Shield'
			},

			['netch_leather_towershield'] = {
				'Netch Leather Tower Shield',
				'Large netch leather shield.',
				'Extensive defensive coverage.',
				'Type: Shield'
			},

			['fur_helm'] = {
				'Fur Helmet',
				'Helmet lined with fur.',
				'Provides warmth and protection.',
				'Type: Helmet'
			},

			['fur_colovian_helm'] = {
				'Colovian Fur Helmet',
				'Traditional Colovian fur helmet.',
				'Combines warmth and defense.',
				'Type: Helmet'
			},

			['fur_pauldron_left'] = {
				'Fur Pauldron (Left)',
				'Left shoulder guard with fur lining.',
				'Offers warmth and protection.',
				'Type: Left Pauldron'
			},

			['fur_cuirass'] = {
				'Fur Cuirass',
				'Chest armor lined with fur.',
				'Provides warmth and defense.',
				'Type: Cuirass'
			},

			['fur_bearskin_cuirass'] = {
				'Bearskin Cuirass',
				'Cuirass made from bear fur.',
				'Heavy insulation and protection.',
				'Type: Cuirass'
			},

			['fur_bracer_left'] = {
				'Fur Bracer (Left)',
				'Left forearm guard with fur lining.',
				'Combines warmth and defense.',
				'Type: Left Bracer'
			},

			['fur_bracer_right'] = {
				'Fur Bracer (Right)',
				'Right forearm guard with fur lining.',
				'Offers warmth and protection.',
				'Type: Right Bracer'
			},

			['fur_greaves'] = {
				'Fur Greaves',
				'Leg guards lined with fur.',
				'Provides warmth and defense.',
				'Type: Greaves'
			},

			['fur_boots'] = {
				'Fur Boots',
				'Boots lined with fur.',
				'Combines warmth and protection.',
				'Type: Boots'
			},

			['nordic_leather_shield'] = {
				'Nordic Leather Shield',
				'Shield crafted in Nordic style.',
				'Balanced defense and mobility.',
				'Type: Shield'
			},

			['dust_adept_helm'] = {
				'Dust Adept Helmet',
				'Helmet used by dust adepts.',
				'Specialized head protection.',
				'Type: Helmet'
			},

			['mole_crab_helm'] = {
				'Mole Crab Helmet',
				'Helmet crafted from mole crab parts.',
				'Unique defensive design.',
				'Type: Helmet'
			},

			['cephalopod_helm'] = {
				'Cephalopod Helmet',
				'Helmet made from cephalopod materials.',
				'Unusual protective design.',
				'Type: Helmet'
			},
			['imperial_studded_cuirass'] = {
				'Imperial Studded Cuirass',
				'Cuirass reinforced with studs.',
				'Enhanced protection for the chest.',
				'Type: Cuirass'
			},

			['imperial_chain_coif_helm'] = {
				'Imperial Chain Coif Helmet',
				'Helmet made of chainmail.',
				'Flexible head protection.',
				'Type: Helmet'
			},

			['imperial_chain_cuirass'] = {
				'Imperial Chain Cuirass',
				'Cuirass made of interlocking chain.',
				'Provides good flexibility and defense.',
				'Type: Cuirass'
			},

			['nordic_ringmail_cuirass'] = {
				'Nordic Ringmail Cuirass',
				'Cuirass made of overlapping rings.',
				'Traditional Nordic armor design.',
				'Type: Cuirass'
			},

			['chitin_mask_helm'] = {
				'Chitin Mask Helmet',
				'Helmet with a mask-like design.',
				'Offers full facial protection.',
				'Type: Helmet'
			},

			['chitin_watchman_helm'] = {
				'Chitin Watchman Helmet',
				'Helmet designed for guard duty.',
				'Provides clear visibility and protection.',
				'Type: Helmet'
			},

			['chitin_shield'] = {
				'Chitin Shield',
				'Shield made from chitin material.',
				'Lightweight defensive tool.',
				'Type: Shield'
			},

			['chitin_towershield'] = {
				'Chitin Tower Shield',
				'Large chitin shield for defense.',
				'Offers extensive coverage.',
				'Type: Shield'
			},

			['newtscale_cuirass'] = {
				'Newtscale Cuirass',
				'Cuirass made from newt scales.',
				'Unique protective qualities.',
				'Type: Cuirass'
			},

			['silver_helm'] = {
				'Silver Helmet',
				'Helmet crafted from silver.',
				'Luxurious and protective.',
				'Type: Helmet'
			},

			['silver_cuirass'] = {
				'Silver Cuirass',
				'Chest armor made of silver.',
				'Combines elegance and defense.',
				'Type: Cuirass'
			},

			['silver_dukesguard_cuirass'] = {
				"Duke's Guard Silver Cuirass",
				'Elite silver cuirass for royal guards.',
				'Symbol of high rank.',
				'Type: Cuirass'
			},

			['imperial_greaves'] = {
				'Imperial Greaves',
				'Leg guards of imperial design.',
				'Standard issue leg protection.',
				'Type: Greaves'
			},

			['nordic_iron_helm'] = {
				'Nordic Iron Helmet',
				'Helmet forged from iron.',
				'Traditional Nordic design.',
				'Type: Helmet'
			},

			['nordic_iron_cuirass'] = {
				'Nordic Iron Cuirass',
				'Iron chest armor in Nordic style.',
				'Sturdy and reliable protection.',
				'Type: Cuirass'
			},

			['templar_greaves'] = {
				'Templar Greaves',
				'Leg guards used by templars.',
				'Combines protection and mobility.',
				'Type: Greaves'
			},

			['steel_helm'] = {
				'Steel Helmet',
				'Helmet forged from steel.',
				'Durable head protection.',
				'Type: Helmet'
			},

			['steel_pauldron_left'] = {
				'Steel Pauldron (Left)',
				'Left shoulder guard made of steel.',
				'Provides solid protection.',
				'Type: Left Pauldron'
			},

			['steel_pauldron_right'] = {
				'Steel Pauldron (Right)',
				'Right shoulder guard made of steel.',
				'Sturdy shoulder protection.',
				'Type: Right Pauldron'
			},

			['steel_cuirass'] = {
				'Steel Cuirass',
				'Chest armor forged from steel.',
				'Reliable protection for the chest.',
				'Type: Cuirass'
			},
			['steel_shield'] = {
				'Steel Shield',
				'Shield forged from steel.',
				'Provides durable defense.',
				'Type: Shield'
			},

			['steel_towershield'] = {
				'Steel Tower Shield',
				'Large steel shield for defense.',
				'Offers extensive coverage.',
				'Type: Shield'
			},

			['steel_gauntlet_left'] = {
				'Steel Gauntlet (Left)',
				'Left hand guard made of steel.',
				'Provides solid hand protection.',
				'Type: Left Gauntlet'
			},

			['steel_gauntlet_right'] = {
				'Steel Gauntlet (Right)',
				'Right hand guard made of steel.',
				'Sturdy protection for the right hand.',
				'Type: Right Gauntlet'
			},

			['steel_greaves'] = {
				'Steel Greaves',
				'Leg guards forged from steel.',
				'Reliable leg protection.',
				'Type: Greaves'
			},

			['iron_pauldron_left'] = {
				'Iron Pauldron (Left)',
				'Left shoulder guard made of iron.',
				'Basic shoulder protection.',
				'Type: Left Pauldron'
			},

			['iron_pauldron_right'] = {
				'Iron Pauldron (Right)',
				'Right shoulder guard made of iron.',
				'Simple yet effective protection.',
				'Type: Right Pauldron'
			},

			['iron_cuirass'] = {
				'Iron Cuirass',
				'Chest armor forged from iron.',
				'Basic but reliable protection.',
				'Type: Cuirass'
			},

			['iron_shield'] = {
				'Iron Shield',
				'Shield made of iron.',
				'Provides basic defense.',
				'Type: Shield'
			},

			['iron_towershield'] = {
				'Iron Tower Shield',
				'Large iron shield for defense.',
				'Offers broad coverage.',
				'Type: Shield'
			},

			['slave_bracer_left'] = {
				'Slave Bracer (Left)',
				'Left forearm guard for slaves.',
				'Basic protection.',
				'Type: Left Bracer'
			},

			['slave_bracer_right'] = {
				'Slave Bracer (Right)',
				'Right forearm guard for slaves.',
				'Minimal protection.',
				'Type: Right Bracer'
			},

			['iron_bracer_left'] = {
				'Iron Bracer (Left)',
				'Left forearm guard made of iron.',
				'Simple arm protection.',
				'Type: Left Bracer'
			},

			['iron_bracer_right'] = {
				'Iron Bracer (Right)',
				'Right forearm guard made of iron.',
				'Basic arm protection.',
				'Type: Right Bracer'
			},

			['iron_greaves'] = {
				'Iron Greaves',
				'Leg guards made of iron.',
				'Basic leg protection.',
				'Type: Greaves'
			},

			['bonemold_gah-julan_helm'] = {
				'Bonemold Gah-Julan Helmet',
				'Helmet crafted from bonemold.',
				'Unique tribal design.',
				'Type: Helmet'
			},

			['bonemold_chuzei_helm'] = {
				'Bonemold Chuzei Helmet',
				'Helmet made in Chuzei style.',
				'Distinctive bonemold craftsmanship.',
				'Type: Helmet'
			},

			['bonemold_armun-an_helm'] = {
				'Bonemold Armun-An Helmet',
				'Helmet of Armun-An design.',
				'Traditional bonemold work.',
				'Type: Helmet'
			},

			['morag_tong_helm'] = {
				'Morag Tong Helmet',
				'Helmet used by the Morag Tong.',
				"Assassin's headgear.",
				'Type: Helmet'
			},

			['bonemold_gah-julan_pauldron_r'] = {
				'Bonemold Gah-Julan Pauldron (Right)',
				'Right shoulder guard in Gah-Julan style.',
				'Unique tribal pauldron.',
				'Type: Right Pauldron'
			},
			['bonemold_armun-an_pauldron_r'] = {
				'Bonemold Armun-An Pauldron (Right)',
				'Right shoulder guard in Armun-An style.',
				'Tribal pauldron design.',
				'Type: Right Pauldron'
			},

			['bonemold_gah-julan_pauldron_l'] = {
				'Bonemold Gah-Julan Pauldron (Left)',
				'Left shoulder guard in Gah-Julan style.',
				'Unique tribal pauldron.',
				'Type: Left Pauldron'
			},

			['bonemold_armun-an_pauldron_l'] = {
				'Bonemold Armun-An Pauldron (Left)',
				'Left shoulder guard in Armun-An style.',
				'Tribal pauldron design.',
				'Type: Left Pauldron'
			},

			['bonemold_gah-julan_cuirass'] = {
				'Bonemold Gah-Julan Cuirass',
				'Cuirass in Gah-Julan style.',
				'Tribal chest armor.',
				'Type: Cuirass'
			},

			['bonemold_armun-an_cuirass'] = {
				'Bonemold Armun-An Cuirass',
				'Cuirass in Armun-An style.',
				'Tribal chest armor design.',
				'Type: Cuirass'
			},

			['bonemold_bracer_left'] = {
				'Bonemold Bracer (Left)',
				'Left forearm guard made of bonemold.',
				'Unique tribal bracer.',
				'Type: Left Bracer'
			},

			['bonemold_bracer_right'] = {
				'Bonemold Bracer (Right)',
				'Right forearm guard made of bonemold.',
				'Tribal bracer design.',
				'Type: Right Bracer'
			},

			['bonemold_greaves'] = {
				'Bonemold Greaves',
				'Leg guards made of bonemold.',
				'Unique tribal leg protection.',
				'Type: Greaves'
			},

			['bonemold_boots'] = {
				'Bonemold Boots',
				'Boots crafted from bonemold.',
				'Tribal foot protection.',
				'Type: Boots'
			},

			['bonemold_shield'] = {
				'Bonemold Shield',
				'Shield made of bonemold material.',
				'Unique tribal defense.',
				'Type: Shield'
			},

			['bonemold_towershield'] = {
				'Bonemold Tower Shield',
				'Large bonemold shield.',
				'Tribal defensive tool.',
				'Type: Shield'
			},

			['trollbone_helm'] = {
				'Trollbone Helmet',
				'Helmet crafted from troll bones.',
				'Heavy and durable protection.',
				'Type: Helmet'
			},

			['trollbone_cuirass'] = {
				'Trollbone Cuirass',
				'Cuirass made from troll bones.',
				'Sturdy chest protection.',
				'Type: Cuirass'
			},

			['trollbone_shield'] = {
				'Trollbone Shield',
				'Shield made of troll bones.',
				'Heavy defensive tool.',
				'Type: Shield'
			},

			['dragonscale_helm'] = {
				'Dragonscale Helmet',
				'Helmet made from dragon scales.',
				'Exceptional head protection.',
				'Type: Helmet'
			},

			['dragonscale_cuirass'] = {
				'Dragonscale Cuirass',
				'Cuirass crafted from dragon scales.',
				'Superior chest armor.',
				'Type: Cuirass'
			},

			['dragonscale_towershield'] = {
				'Dragonscale Tower Shield',
				'Large shield made from dragon scales.',
				'Elite defensive weapon.',
				'Type: Shield'
			},

			['dwemer_helm'] = {
				'Dwemer Helmet',
				'Helmet of Dwemer craftsmanship.',
				'Ancient mechanical design.',
				'Type: Helmet'
			},

			['dwemer_pauldron_right'] = {
				'Dwemer Pauldron (Right)',
				'Right shoulder guard of Dwemer design.',
				'Mechanical and durable protection.',
				'Type: Right Pauldron'
			},

			['dwemer_pauldron_left'] = {
				'Dwemer Pauldron (Left)',
				'Left shoulder guard of Dwemer design.',
				'Mechanical and durable protection.',
				'Type: Left Pauldron'
			},

			['dwemer_cuirass'] = {
				'Dwemer Cuirass',
				'Chest armor of Dwemer craftsmanship.',
				'Advanced mechanical protection.',
				'Type: Cuirass'
			},

			['dwemer_bracer_left'] = {
				'Dwemer Bracer (Left)',
				'Left forearm guard of Dwemer design.',
				'Mechanical arm protection.',
				'Type: Left Bracer'
			},

			['dwemer_bracer_right'] = {
				'Dwemer Bracer (Right)',
				'Right forearm guard of Dwemer design.',
				'Mechanical arm protection.',
				'Type: Right Bracer'
			},

			['dwemer_greaves'] = {
				'Dwemer Greaves',
				'Leg guards of Dwemer craftsmanship.',
				'Mechanical leg protection.',
				'Type: Greaves'
			},

			['dwemer_boots'] = {
				'Dwemer Boots',
				'Boots crafted by Dwemer engineers.',
				'Mechanical foot protection.',
				'Type: Boots'
			},

			['dwemer_shield'] = {
				'Dwemer Shield',
				'Shield of Dwemer design.',
				'Mechanical defensive tool.',
				'Type: Shield'
			},

			['orcish_helm'] = {
				'Orcish Helmet',
				'Helmet forged by orcish craftsmen.',
				'Heavy and durable protection.',
				'Type: Helmet'
			},

			['orcish_pauldron_right'] = {
				'Orcish Pauldron (Right)',
				'Right shoulder guard of orcish design.',
				'Heavy protection.',
				'Type: Right Pauldron'
			},

			['orcish_pauldron_left'] = {
				'Orcish Pauldron (Left)',
				'Left shoulder guard of orcish design.',
				'Heavy protection.',
				'Type: Left Pauldron'
			},

			['orcish_cuirass'] = {
				'Orcish Cuirass',
				'Chest armor forged by orcs.',
				'Heavy and sturdy protection.',
				'Type: Cuirass'
			},

			['orcish_bracer_left'] = {
				'Orcish Bracer (Left)',
				'Left forearm guard of orcish design.',
				'Heavy arm protection.',
				'Type: Left Bracer'
			},

			['orcish_greaves'] = {
				'Orcish Greaves',
				'Leg guards forged by orcs.',
				'Heavy leg protection.',
				'Type: Greaves'
			},

			['orcish_boots'] = {
				'Orcish Boots',
				'Boots crafted by orcish smiths.',
				'Heavy foot protection.',
				'Type: Boots'
			},

			['orcish_towershield'] = {
				'Orcish Tower Shield',
				'Large shield forged by orcs.',
				'Heavy defensive tool.',
				'Type: Shield'
			},

			['dreugh_helm'] = {
				'Dreugh Helmet',
				'Helmet crafted from dreugh materials.',
				'Unique aquatic protection.',
				'Type: Helmet'
			},

			['dreugh_cuirass'] = {
				'Dreugh Cuirass',
				'Chest armor made from dreugh parts.',
				'Specialized protection.',
				'Type: Cuirass'
			},

			['dreugh_shield'] = {
				'Dreugh Shield',
				'Shield made from dreugh materials.',
				'Unique defensive tool.',
				'Type: Shield'
			},

			['redoran_master_helm'] = {
				'Redoran Master Helmet',
				'Helmet of Redoran design.',
				'Master-crafted protection.',
				'Type: Helmet'
			},

			['glass_helm'] = {
				'Glass Helmet',
				'Helmet crafted from glass.',
				'Elegant and protective.',
				'Type: Helmet'
			},

			['glass_cuirass'] = {
				'Glass Cuirass',
				'Chest armor made of glass.',
				'Luxurious protection.',
				'Type: Cuirass'
			},

			['glass_shield'] = {
				'Glass Shield',
				'Shield crafted from glass.',
				'Unique defensive tool.',
				'Type: Shield'
			},

			['glass_towershield'] = {
				'Glass Tower Shield',
				'Large glass shield.',
				'Elegant defense.',
				'Type: Shield'
			},

			['ebony_closed_helm'] = {
				'Ebony Closed Helmet',
				'Helmet forged from ebony.',
				'Superior head protection.',
				'Type: Helmet'
			},

			['ebony_pauldron_right'] = {
				'Ebony Pauldron (Right)',
				'Right shoulder guard of ebony.',
				'Elite protection.',
				'Type: Right Pauldron'
			},

			['ebony_pauldron_left'] = {
				'Ebony Pauldron (Left)',
				'Left shoulder guard of ebony.',
				'Elite protection.',
				'Type: Left Pauldron'
			},

			['ebony_cuirass'] = {
				'Ebony Cuirass',
				'Chest armor forged from ebony.',
				'Superior protection.',
				'Type: Cuirass'
			},

			['ebony_bracer_left'] = {
				'Ebony Bracer (Left)',
				'Left forearm guard of ebony.',
				'Elite arm protection.',
				'Type: Left Bracer'
			},

			['ebony_bracer_right'] = {
				'Ebony Bracer (Right)',
				'Right forearm guard of ebony.',
				'Elite arm protection.',
				'Type: Right Bracer'
			},

			['ebony_greaves'] = {
				'Ebony Greaves',
				'Leg guards forged from ebony.',
				'Superior leg protection.',
				'Type: Greaves'
			},

			['ebony_boots'] = {
				'Ebony Boots',
				'Boots crafted from ebony.',
				'Elite foot protection.',
				'Type: Boots'
			},

			['ebony_shield'] = {
				'Ebony Shield',
				'Shield forged from ebony.',
				'Superior defense.',
				'Type: Shield'
			},

			['ebony_towershield'] = {
				'Ebony Tower Shield',
				'Large ebony shield.',
				'Elite defensive tool.',
				'Type: Shield'
			},

			['daedric_fountain_helm'] = {
				'Daedric Fountain Helmet',
				'Helmet of daedric design.',
				'Dark and powerful protection.',
				'Type: Helmet'
			},

			['daedric_terrifying_helm'] = {
				'Daedric Terrifying Helmet',
				'Intimidating daedric helmet.',
				'Menacing protection.',
				'Type: Helmet'
			},

			['daedric_god_helm'] = {
				'Daedric God Helmet',
				'Divine daedric helmet.',
				'Powerful protection.',
				'Type: Helmet'
			},

			['daedric_pauldron_right'] = {
				'Daedric Pauldron (Right)',
				'Right shoulder guard of daedric design.',
				'Dark and powerful protection.',
				'Type: Right Pauldron'
			},

			['daedric_pauldron_left'] = {
				'Daedric Pauldron (Left)',
				'Left shoulder guard of daedric design.',
				'Dark and powerful protection.',
				'Type: Left Pauldron'
			},

			['daedric_cuirass'] = {
				'Daedric Cuirass',
				'Chest armor of daedric craftsmanship.',
				'Powerful protection.',
				'Type: Cuirass'
			},

			['daedric_gauntlet_left'] = {
				'Daedric Gauntlet (Left)',
				'Left hand guard of daedric design.',
				'Dark and powerful protection.',
				'Type: Left Gauntlet'
			},

			['daedric_gauntlet_right'] = {
				'Daedric Gauntlet (Right)',
				'Right hand guard of daedric design.',
				'Dark and powerful protection.',
				'Type: Right Gauntlet'
			},

			['daedric_greaves'] = {
				'Daedric Greaves',
				'Leg guards of daedric craftsmanship.',
				'Powerful leg protection.',
				'Type: Greaves'
			},

			['daedric_boots'] = {
				'Daedric Boots',
				'Boots forged by daedric artisans.',
				'Powerful foot protection.',
				'Type: Boots'
			},

			['daedric_shield'] = {
				'Daedric Shield',
				'Shield of daedric design.',
				'Powerful defensive tool.',
				'Type: Shield'
			},

			['daedric_towershield'] = {
				'Daedric Tower Shield',
				'Large daedric shield.',
				'Powerful defensive coverage.',
				'Type: Shield'
			},

			['netch_leather_pauldron_right'] = {
				'Netch Leather Pauldron (Right)',
				'Right shoulder guard made of netch leather.',
				'Lightweight shoulder protection.',
				'Type: Right Pauldron'
			},

			['fur_pauldron_right'] = {
				'Fur Pauldron (Right)',
				'Right shoulder guard with fur lining.',
				'Offers warmth and protection.',
				'Type: Right Pauldron'
			},

			['orcish_bracer_right'] = {
				'Orcish Bracer (Right)',
				'Right forearm guard of orcish design.',
				'Heavy arm protection.',
				'Type: Right Bracer'
			},

			['imperial_chain_greaves'] = {
				'Imperial Chain Greaves',
				'Greaves made of interlocking chain.',
				'Provides flexibility and defense.',
				'Type: Greaves'
			},

			['templar_helmet_armor'] = {
				'Templar Helmet Armor',
				'Helmet used by templar order.',
				'Combines protection with symbols.',
				'Type: Helmet'
			},

			['imperial cuirass_armor'] = {
				'Imperial Cuirass Armor',
				'Chest armor of imperial design.',
				'Standard issue protection.',
				'Type: Cuirass'
			},

			['fur_gauntlet_left'] = {
				'Fur Gauntlet (Left)',
				'Left hand guard with fur lining.',
				'Combines warmth and protection.',
				'Type: Left Gauntlet'
			},

			['fur_gauntlet_right'] = {
				'Fur Gauntlet (Right)',
				'Right hand guard with fur lining.',
				'Combines warmth and protection.',
				'Type: Right Gauntlet'
			},

			['imperial_chain_pauldron_right'] = {
				'Imperial Chain Pauldron (Right)',
				'Right shoulder guard of chainmail.',
				'Provides flexibility and defense.',
				'Type: Right Pauldron'
			},

			['imperial_chain_pauldron_left'] = {
				'Imperial Chain Pauldron (Left)',
				'Left shoulder guard of chainmail.',
				'Provides flexibility and defense.',
				'Type: Left Pauldron'
			},

			['iron_gauntlet_left'] = {
				'Iron Gauntlet (Left)',
				'Left hand guard made of iron.',
				'Basic hand protection.',
				'Type: Left Gauntlet'
			},

			['iron_gauntlet_right'] = {
				'Iron Gauntlet (Right)',
				'Right hand guard made of iron.',
				'Basic hand protection.',
				'Type: Right Gauntlet'
			},

			['iron_helmet'] = {
				'Iron Helmet',
				'Standard helmet forged from iron.',
				'Basic head protection.',
				'Type: Helmet'
			},

			['bonemold_tshield_hlaaluguard'] = {
				'Bonemold Tower Shield of Hlaalu Guard',
				'Large shield crafted from bonemold.',
				'Guard-issued defensive tool.',
				'Type: Shield'
			},

			['bonemold_tshield_redoranguard'] = {
				'Bonemold Tower Shield of Redoran Guard',
				'Tower shield made of bonemold.',
				'Guard-issued protection.',
				'Type: Shield'
			},

			['bonemold_tshield_telvanniguard'] = {
				'Bonemold Tower Shield of Telvanni Guard',
				'Guard-issued tower shield.',
				'Sturdy defensive weapon.',
				'Type: Shield'
			},

			['bonemold_founders_helm'] = {
				"Bonemold Founders Helmet",
				"Helmet of founders design.",
				'Traditional bonemold craftsmanship.',
				'Type: Helmet'
			},

			['glass_pauldron_left'] = {
				'Glass Pauldron (Left)',
				'Left shoulder guard made of glass.',
				'Elegant and protective.',
				'Type: Left Pauldron'
			},

			['glass_pauldron_right'] = {
				'Glass Pauldron (Right)',
				'Right shoulder guard made of glass.',
				'Elegant and protective.',
				'Type: Right Pauldron'
			},

			['ebony_closed_helm_fghl'] = {
				'Ebony Closed Helmet FGH-L',
				'Special variant of ebony helmet.',
				'Enhanced protection.',
				'Type: Helmet'
			},

			['merisan_cuirass'] = {
				'Merisan Cuirass',
				'Cuirass of Merisan design.',
				'Custom-crafted armor.',
				'Type: Cuirass'
			},

			['shield_of_light'] = {
				'Shield of Light',
				'Sacred shield imbued with light.',
				'Holy defensive weapon.',
				'Type: Shield'
			},

			['the_chiding_cuirass'] = {
				'Chiding Cuirass',
				'Cuirass with mystical properties.',
				'Unique enchanted armor.',
				'Type: Cuirass'
			},

			['velothian_helm'] = {
				'Velothian Helmet',
				'Traditional Velothian headgear.',
				'Cultural and protective.',
				'Type: Helmet'
			},

			['feather_shield'] = {
				'Feather Shield',
				'Shield decorated with feathers.',
				'Lightweight defense.',
				'Type: Shield'
			},

			['velothis_shield'] = {
				'Velothis Shield',
				'Shield of Velothi design.',
				'Traditional protection.',
				'Type: Shield'
			},

			['holy_shield'] = {
				'Holy Shield',
				'Blessed shield of faith.',
				'Divine protection.',
				'Type: Shield'
			},

			['blessed_shield'] = {
				'Blessed Shield',
				'Sacred defensive weapon.',
				'Sanctified protection.',
				'Type: Shield'
			},

			['veloths_tower_shield'] = {
				'Veloths Tower Shield',
				'Large tower shield of Velothi design.',
				'Sturdy defense.',
				'Type: Shield'
			},

			['holy_tower_shield'] = {
				'Holy Tower Shield',
				'Tower shield blessed by faith.',
				'Divine defensive tool.',
				'Type: Shield'
			},

			['demon helm'] = {
				'Demon Helmet',
				'Helmet with demonic design.',
				'Sinister protection.',
				'Type: Helmet'
			},

			['demon mole crab'] = {
				'Demon Mole Crab Helmet',
				'Helmet crafted from demonic parts.',
				'Unholy protection.',
				'Type: Helmet'
			},

			['demon cephalopod'] = {
				'Demon Cephalopod Helmet',
				'Helmet with cephalopod features.',
				'Dark and powerful.',
				'Type: Helmet'
			},
			['right horny fist gauntlet'] = {
				'Right Horny Fist Gauntlet',
				'Right hand guard with horned design.',
				'Aggressive and powerful protection.',
				'Type: Right Gauntlet'
			},

			['left_horny_fist_gauntlet'] = {
				'Left Horny Fist Gauntlet',
				'Left hand guard with horned design.',
				'Aggressive and powerful protection.',
				'Type: Left Gauntlet'
			},

			['helm of wounding'] = {
				'Helm of Wounding',
				'Cursed helmet with dark powers.',
				'Inflicts suffering on enemies.',
				'Type: Helmet'
			},

			['shield of wounds'] = {
				'Shield of Wounds',
				'Cursed shield with dark magic.',
				'Deals damage to foes.',
				'Type: Shield'
			},

			['storm helm'] = {
				'Storm Helm',
				'Helmet imbued with storm energy.',
				'Controls elemental forces.',
				'Type: Helmet'
			},

			['heart wall'] = {
				'Heart Wall',
				'Unique defensive cuirass.',
				'Protects vital organs.',
				'Type: Cuirass'
			},

			['right gauntlet of horny fist'] = {
				'Right Gauntlet of Horny Fist',
				'Right hand guard with horned spikes.',
				'Deadly close combat weapon.',
				'Type: Right Gauntlet'
			},

			['left gauntlet of the horny fist'] = {
				'Left Gauntlet of Horny Fist',
				'Left hand guard with horned spikes.',
				'Deadly close combat weapon.',
				'Type: Left Gauntlet'
			},

			['velothian shield'] = {
				'Velothian Shield',
				'Traditional shield of Veloth.',
				'Sturdy and reliable defense.',
				'Type: Shield'
			},

			['succour of indoril'] = {
				'Succour of Indoril',
				'Indoril-crafted shield.',
				'Symbol of protection.',
				'Type: Shield'
			},

			['merisan helm'] = {
				'Merisan Helmet',
				'Helmet of Merisan design.',
				'Custom-crafted headgear.',
				'Type: Helmet'
			},

			['chest of fire'] = {
				'Chest of Fire',
				'Cuirass with fiery properties.',
				'Resists cold damage.',
				'Type: Cuirass'
			},

			['lbonemold brace of horny fist'] = {
				'Left Bonemold Brace of Horny Fist',
				'Left forearm guard with horns.',
				'Aggressive design.',
				'Type: Left Bracer'
			},

			['rbonemold bracer of horny fist'] = {
				'Right Bonemold Bracer of Horny Fist',
				'Right forearm guard with horns.',
				'Aggressive design.',
				'Type: Right Bracer'
			},

			['helm of holy fire'] = {
				'Helm of Holy Fire',
				'Blessed helmet with holy flames.',
				'Divine protection.',
				'Type: Helmet'
			},

			['spirit of indoril'] = {
				'Spirit of Indoril',
				'Indoril-blessed shield.',
				'Spiritual defense.',
				'Type: Shield'
			},

			["saint's shield"] = {
				"Saint's Shield",
				'Holy shield of a saint.',
				'Sacred protection.',
				'Type: Shield'
			},

			["azura's servant"] = {
				"Azura's Servant",
				'Blessed shield of Azura.',
				'Divine favor.',
				'Type: Shield'
			},

			['bound_cuirass'] = {
				'Bound Cuirass',
				'Magically bound chest armor.',
				'Ethereal protection.',
				'Type: Cuirass'
			},

			['bound_helm'] = {
				'Bound Helmet',
				'Magically bound headgear.',
				'Ethereal protection.',
				'Type: Helmet'
			},

			['bound_boots'] = {
				'Bound Boots',
				'Magically bound footwear.',
				'Ethereal protection.',
				'Type: Boots'
			},

			['bound_shield'] = {
				'Bound Shield',
				'Magically bound defensive shield.',
				'Ethereal protection.',
				'Type: Shield'
			},

			['fiend helm'] = {
				'Fiend Helm',
				'Helmet forged from dark materials.',
				'Sinister and powerful.',
				'Type: Helmet'
			},

			['devil helm'] = {
				'Devil Helm',
				'Helmet with demonic influence.',
				'Cursed head protection.',
				'Type: Helmet'
			},

			['devil mole crab helm'] = {
				'Devil Mole Crab Helmet',
				'Helmet with dark crab features.',
				'Unholy design.',
				'Type: Helmet'
			},

			['devil cephalopod helm'] = {
				'Devil Cephalopod Helmet',
				'Helmet with demonic tentacles.',
				'Dark and twisted.',
				'Type: Helmet'
			},

			['right cloth horny fist bracer'] = {
				'Right Cloth Horny Fist Bracer',
				'Right forearm guard with cloth and horns.',
				'Light but deadly.',
				'Type: Right Bracer'
			},

			['left cloth horny fist bracer'] = {
				'Left Cloth Horny Fist Bracer',
				'Left forearm guard with cloth and horns.',
				'Light but deadly.',
				'Type: Left Bracer'
			},

			['steel_boots'] = {
				'Steel Boots',
				'Boots forged from solid steel.',
				'Durable foot protection.',
				'Type: Boots'
			},

			['bonemold_tshield_hrlb'] = {
				'Bonemold Tower Shield HRLB',
				'Large bonemold shield variant.',
				'Sturdy defensive tool.',
				'Type: Shield'
			},

			['bonemold_gah-julan_hhda'] = {
				'Bonemold Gah-Julan HHDA',
				'Special Gah-Julan helmet variant.',
				'Tribal craftsmanship.',
				'Type: Helmet'
			},

			['dwemer_boots of flying'] = {
				'Dwemer Boots of Flying',
				'Mechanical boots with flight capability.',
				'Ancient technology.',
				'Type: Boots'
			},

			['bonemold_helm'] = {
				'Bonemold Helmet',
				'Standard bonemold headgear.',
				'Traditional design.',
				'Type: Helmet'
			},

			['bonemold_pauldron_r'] = {
				'Bonemold Pauldron (Right)',
				'Right shoulder guard of bonemold.',
				'Tribal protection.',
				'Type: Right Pauldron'
			},

			['bonemold_pauldron_l'] = {
				'Bonemold Pauldron (Left)',
				'Left shoulder guard of bonemold.',
				'Tribal protection.',
				'Type: Left Pauldron'
			},

			['bonemold_cuirass'] = {
				'Bonemold Cuirass',
				'Standard bonemold chest armor.',
				'Tribal design.',
				'Type: Cuirass'
			},

			['iron boots'] = {
				'Iron Boots',
				'Basic boots made of iron.',
				'Simple protection.',
				'Type: Boots'
			},

			['heavy_leather_boots'] = {
				'Heavy Leather Boots',
				'Reinforced leather footwear.',
				'Durable protection.',
				'Type: Boots'
			},

			['daedric_cuirass_htab'] = {
				'Daedric Cuirass HTAB',
				'Special daedric chest armor variant.',
				'Dark power.',
				'Type: Cuirass'
			},

			['daedric_greaves_htab'] = {
				'Daedric Greaves HTAB',
				'Special daedric leg guards.',
				'Dark power.',
				'Type: Greaves'
			},

			['shadow_shield'] = {
				'Shadow Shield',
				'Shield imbued with shadow magic.',
				'Stealthy protection.',
				'Type: Shield'
			},

			['wraithguard'] = {
				'Wraithguard',
				'Ghostly gauntlet for defense.',
				'Ethereal protection.',
				'Type: Right Gauntlet'
			},

			['wraithguard_jury_rig'] = {
				'Wraithguard Jury-Rig',
				'Makeshift left gauntlet constructed from various materials.',
				'Provides basic protection with limited functionality.',
				'Type: Left Gauntlet'
			},

			['tenpaceboots'] = {
				'Ten Pace Boots',
				'Lightweight boots designed for quick movement.',
				'Enhances mobility and agility.',
				'Type: Boots'
			},

			['glass_boots'] = {
				'Glass Boots',
				'Elegant boots crafted from tempered glass.',
				'Combines protection with aesthetic appeal.',
				'Type: Boots'
			},

			['glass_greaves'] = {
				'Glass Greaves',
				'Leg guards made from reinforced glass.',
				'Offers flexible protection for the legs.',
				'Type: Greaves'
			},

			['dreugh_cuirass_ttrm'] = {
				'Dreugh Cuirass TTRM',
				'Chest armor made from specialized dreugh materials.',
				'Provides unique aquatic protection.',
				'Type: Cuirass'
			},

			['ebony_shield_auriel'] = {
				'Ebony Shield of Auriel',
				'Ebony shield blessed by the goddess Auriel.',
				'Offers divine protection.',
				'Type: Shield'
			},

			['daedric_helm_clavicusvile'] = {
				'Daedric Helm of Clavicus Vile',
				'Daedric helmet imbued with dark magic.',
				'Associated with the Daedric Prince Clavicus Vile.',
				'Type: Helmet'
			},

			['bound_gauntlet_right'] = {
				'Bound Right Gauntlet',
				'Magically bound right gauntlet.',
				'Provides ethereal protection.',
				'Type: Right Gauntlet'
			},

			['bound_gauntlet_left'] = {
				'Bound Left Gauntlet',
				'Magically bound left gauntlet.',
				'Provides ethereal protection.',
				'Type: Left Gauntlet'
			},

			['ebony_bracer_left_tgeb'] = {
				'Ebony Left Bracer TGEB',
				'Left bracer forged from ebony.',
				'Offers superior arm protection.',
				'Type: Left Bracer'
			},

			['ebony_bracer_right_tgeb'] = {
				'Ebony Right Bracer TGEB',
				'Right bracer forged from ebony.',
				'Offers superior arm protection.',
				'Type: Right Bracer'
			},

			['boots_of_blinding_speed'] = {
				'Boots of Blinding Speed',
				'Unique boots enhancing movement speed.',
				'Provides significant agility boost.',
				'Type: Boots'
			},

			['veloths_shield'] = {
				"Veloths Shield",
				'Traditional shield of Veloth design.',
				'Sturdy and reliable defense.',
				'Type: Shield'
			},

			['gauntlet_horny_fist_r'] = {
				'Right Gauntlet of Horny Fist',
				'Right gauntlet with horned design.',
				'Aggressive and powerful protection.',
				'Type: Right Gauntlet'
			},

			['gauntlet_horny_fist_l'] = {
				'Left Gauntlet of Horny Fist',
				'Left gauntlet with horned design.',
				'Aggressive and powerful protection.',
				'Type: Left Gauntlet'
			},

			['blessed_tower_shield'] = {
				'Blessed Tower Shield',
				'Large shield blessed with holy power.',
				'Provides divine protection.',
				'Type: Shield'
			},

			['lords_cuirass_unique'] = {
				"Lord's Cuirass",
				'Unique chest armor for nobility.',
				'Symbol of high status.',
				'Type: Cuirass'
			},

			['ebon_plate_cuirass_unique'] = {
				'Ebon Plate Cuirass',
				'Unique ebony plate chest armor.',
				'Provides elite protection.',
				'Type: Cuirass'
			},

			['spell_breaker_unique'] = {
				'Spell Breaker',
				'Unique shield designed to counter magic.',
				'Resists magical attacks and provides protection.',
				'Type: Shield'
			},

			['cuirass_savior_unique'] = {
				'Cuirass of the Savior',
				'Unique chest armor with protective properties.',
				'Offers enhanced defense.',
				'Type: Cuirass'
			},

			['gauntlet_fists_l_unique'] = {
				'Left Gauntlet of Fists',
				'Unique left gauntlet for combat.',
				'Provides superior hand protection.',
				'Type: Left Gauntlet'
			},

			['gauntlet_fists_r_unique'] = {
				'Right Gauntlet of Fists',
				'Unique right gauntlet for combat.',
				'Provides superior hand protection.',
				'Type: Right Gauntlet'
			},

			['towershield_eleidon_unique'] = {
				'Tower Shield of Eleidon',
				'Unique large shield with special properties.',
				'Offers extensive defensive coverage.',
				'Type: Shield'
			},

			['dragonbone_cuirass_unique'] = {
				'Dragonbone Cuirass',
				'Unique chest armor made from dragon bones.',
				'Provides exceptional protection.',
				'Type: Cuirass'
			},

			['helm_bearclaw_unique'] = {
				'Helm of Bearclaw',
				'Unique helmet with bear motifs.',
				'Symbol of strength and power.',
				'Type: Helmet'
			},

			['boots_apostle_unique'] = {
				'Boots of the Apostle',
				'Unique boots with special properties.',
				'Enhances movement and protection.',
				'Type: Boots'
			},

			['shield_of_the_undaunted'] = {
				'Shield of the Undaunted',
				'Special shield for the brave.',
				'Provides courage and protection.',
				'Type: Shield'
			},

			['imperial_helm_frald_uniq'] = {
				'Imperial Helm of Frald',
				'Unique imperial helmet.',
				'Mark of imperial authority.',
				'Type: Helmet'
			},

			['erur_dan_cuirass_unique'] = {
				'Erur Dan Cuirass',
				'Unique chest armor with special qualities.',
				'Offers superior protection.',
				'Type: Cuirass'
			},

			['conoon_chodala_boots_unique'] = {
				'Conoon Chodala Boots',
				'Unique boots with mystical properties.',
				'Provides enhanced mobility.',
				'Type: Boots'
			},

			['icecap_unique'] = {
				'Icecap',
				'Unique helmet with frost properties.',
				'Offers cold resistance.',
				'Type: Helmet'
			},

			['boneweave_gauntlet'] = {
				'Boneweave Gauntlet',
				'Gauntlet woven from bone materials.',
				'Provides unique protection.',
				'Type: Left Gauntlet'
			},

			['bonedancer_gauntlet'] = {
				'Bonedancer Gauntlet',
				'Gauntlet crafted for agility.',
				'Enhances movement and defense.',
				'Type: Right Gauntlet'
			},

			['mountain_spirit'] = {
				'Mountain Spirit Cuirass',
				'Cuirass inspired by mountain strength.',
				'Provides sturdy protection.',
				'Type: Cuirass'
			},

			['darksun_shield_unique'] = {
				'Darksun Shield',
				'Unique shield with dark magic.',
				'Offers special defensive abilities.',
				'Type: Shield'
			},

			['bloodworm_helm_unique'] = {
				'Bloodworm Helm',
				'Unique helmet with blood magic.',
				'Provides special abilities.',
				'Type: Helmet'
			},

			['cephalopod_helm_HTNK'] = {
				'Cephalopod Helm HTNK',
				'Helmet with cephalopod features.',
				'Offers unique protection.',
				'Type: Helmet'
			},

			['blood_feast_shield'] = {
				'Blood Feast Shield',
				'Shield with blood-themed design.',
				'Provides special properties.',
				'Type: Shield'
			},

			['gauntlet_of_glory_left'] = {
				'Gauntlet of Glory (Left)',
				'Left gauntlet imbued with heroic energy.',
				'Provides strength and protection.',
				'Type: Left Gauntlet'
			},

			['gauntlet_of_glory_right'] = {
				'Gauntlet of Glory (Right)',
				'Right gauntlet imbued with heroic energy.',
				'Provides strength and protection.',
				'Type: Right Gauntlet'
			},

			['gondolier_helm'] = {
				'Gondolier Helm',
				'Helmet designed for boatmen.',
				'Practical head protection.',
				'Type: Helmet'
			},

			['imperial_helmet_armor_dae_curse'] = {
				'Imperial Helmet Armor of Dae Curse',
				'Imperial helmet with dark curse.',
				'Cursed imperial headgear.',
				'Type: Helmet'
			},

			['glass_bracer_left'] = {
				'Glass Bracer (Left)',
				'Left bracer made from tempered glass.',
				'Elegant and protective.',
				'Type: Left Bracer'
			},

			['glass_bracer_right'] = {
				'Glass Bracer (Right)',
				'Right bracer made from tempered glass.',
				'Elegant and protective.',
				'Type: Right Bracer'
			},

			['towershield_eleidon_unique_x'] = {
				'Tower Shield of Eleidon X',
				"Special variant of Eleidon's tower shield.",
				'Enhanced defensive capabilities.',
				'Type: Shield'
			},

			['lords_cuirass_unique_x'] = {
				"Lord's Cuirass X",
				"Special variant of the Lord's cuirass.",
				'Enhanced protection.',
				'Type: Cuirass'
			},

			['cuirass_savior_unique_x'] = {
				'Cuirass of the Savior X',
				'Special variant of the Saviors cuirass.',
				'Enhanced defensive properties.',
				'Type: Cuirass'
			},

			['tenpaceboots_x'] = {
				'Ten Pace Boots X',
				'Special variant of the Ten Pace boots.',
				'Enhanced mobility.',
				'Type: Boots'
			},

			['ebon_plate_cuirass_unique_x'] = {
				'Ebon Plate Cuirass X',
				'Special variant of the ebon plate cuirass.',
				'Superior protection.',
				'Type: Cuirass'
			},

			['boots_apostle_unique_x'] = {
				'Boots of the Apostle X',
				"Special variant of the Apostle's boots.",
				'Enhanced movement abilities.',
				'Type: Boots'
			},

			['ebony_shield_auriel_x'] = {
				'Ebony Shield of Auriel X',
				"Special variant of Auriel's ebony shield.",
				'Divine protection.',
				'Type: Shield'
			},

			['boots_of_blinding_speed_x'] = {
				'Boots of Blinding Speed X',
				'Special variant of the speed boots.',
				'Enhanced agility.',
				'Type: Boots'
			},

			['dragonbone_cuirass_unique_x'] = {
				'Dragonbone Cuirass X',
				'Special variant of the dragonbone cuirass.',
				'Superior defensive qualities.',
				'Type: Cuirass'
			},

			['helm_bearclaw_unique_x'] = {
				'Helm of Bearclaw X',
				'Special variant of the Bearclaw helm.',
				'Enhanced strength properties.',
				'Type: Helmet'
			},

			['spell_breaker_unique_x'] = {
				'Spell Breaker X',
				'Special variant of the spell-breaking shield.',
				'Improved magic resistance.',
				'Type: Shield'
			},

			['bloodworm_helm_unique_x'] = {
				'Bloodworm Helm X',
				'Special variant of the bloodworm helm.',
				'Enhanced blood magic properties.',
				'Type: Helmet'
			},

			['ebony_cuirass_soscean'] = {
				'Ebony Cuirass of Soscean',
				'Ebony chest armor with unique properties.',
				'Provides superior protection.',
				'Type: Cuirass'
			},

			['silver_helm_uvenim'] = {
				'Silver Helm of Uvenim',
				'Silver helmet with mystical qualities.',
				'Offers special protection.',
				'Type: Helmet'
			},

			['Indoril_Almalexia_helmet'] = {
				'Indoril Almalexia Helmet',
				'Helmet of royal design.',
				'Symbol of Indoril lineage.',
				'Type: Helmet'
			},

			['Indoril_Almalexia_boots'] = {
				'Indoril Almalexia Boots',
				'Boots of royal craftsmanship.',
				'Provides noble protection.',
				'Type: Boots'
			},

			['Indoril_Almalexia_Cuirass'] = {
				'Indoril Almalexia Cuirass',
				'Royal chest armor.',
				'Mark of high status.',
				'Type: Cuirass'
			},

			['Indoril_Almalexia_Greaves'] = {
				'Indoril Almalexia Greaves',
				'Leg guards of royal design.',
				'Provides noble protection.',
				'Type: Greaves'
			},

			['Indoril_Almalexia_Pauldron_L'] = {
				'Indoril Almalexia Pauldron (Left)',
				'Left shoulder guard of royal lineage.',
				'Symbol of nobility.',
				'Type: Left Pauldron'
			},

			['Indoril_Almalexia_Pauldron_R'] = {
				'Indoril Almalexia Pauldron (Right)',
				'Right shoulder guard of royal lineage.',
				'Symbol of nobility.',
				'Type: Right Pauldron'
			},

			['Indoril_Almalexia_gauntlet_R'] = {
				'Indoril Almalexia Gauntlet (Right)',
				'Right gauntlet of royal design.',
				'Provides noble protection.',
				'Type: Right Gauntlet'
			},

			['Indoril_Almalexia_gauntlet_L'] = {
				'Indoril Almalexia Gauntlet (Left)',
				'Left gauntlet of royal design.',
				'Provides noble protection.',
				'Type: Left Gauntlet'
			},

			['Helsethguard_Helmet'] = {
				'Helsethguard Helmet',
				'Sturdy helmet of Helseth design.',
				'Provides reliable protection.',
				'Type: Helmet'
			},

			['Helsethguard_boots'] = {
				'Helsethguard Boots',
				'Boots of Helseth craftsmanship.',
				'Provides solid foot protection.',
				'Type: Boots'
			},

			['Helsethguard_cuirass'] = {
				'Helsethguard Cuirass',
				'Chest armor of Helseth design.',
				'Offers reliable protection.',
				'Type: Cuirass'
			},

			['Helsethguard_greaves'] = {
				'Helsethguard Greaves',
				'Leg guards of Helseth craftsmanship.',
				'Provides solid leg protection.',
				'Type: Greaves'
			},

			['Helsethguard_gauntlet_left'] = {
				'Helsethguard Gauntlet (Left)',
				'Left gauntlet of Helseth design.',
				'Provides reliable hand protection.',
				'Type: Left Gauntlet'
			},

			['Helsethguard_gauntlet_right'] = {
				'Helsethguard Gauntlet (Right)',
				'Right gauntlet of Helseth design.',
				'Provides reliable hand protection.',
				'Type: Right Gauntlet'
			},

			['Helsethguard_pauldron_left'] = {
				'Helsethguard Pauldron (Left)',
				'Left shoulder guard of Helseth design.',
				'Provides solid shoulder protection.',
				'Type: Left Pauldron'
			},

			['Helsethguard_pauldron_right'] = {
				'Helsethguard Pauldron (Right)',
				'Right shoulder guard of Helseth design.',
				'Provides solid shoulder protection.',
				'Type: Right Pauldron'
			},

			['DarkBrotherhood_Helm'] = {
				'DarkBrotherhood Helmet',
				'Helmet of the DarkBrotherhood faction.',
				'Symbol of the guild.',
				'Type: Helmet'
			},

			['DarkBrotherhood_Cuirass'] = {
				'DarkBrotherhood Cuirass',
				'Chest armor of the DarkBrotherhood.',
				'Provides stealth protection.',
				'Type: Cuirass'
			},

			['DarkBrotherhood_greaves'] = {
				'DarkBrotherhood Greaves',
				'Leg guards of the DarkBrotherhood.',
				'Offers silent movement.',
				'Type: Greaves'
			},

			['DarkBrotherhood_pauldron_L'] = {
				'DarkBrotherhood Pauldron (Left)',
				'Left shoulder guard of the DarkBrotherhood.',
				"Part of the assassin's armor.",
				'Type: Left Pauldron'
			},

			['DarkBrotherhood_pauldron_R'] = {
				'DarkBrotherhood Pauldron (Right)',
				'Right shoulder guard of the DarkBrotherhood.',
				"Part of the assassin's armor.",
				'Type: Right Pauldron'
			},

			['DarkBrotherhood_gauntlet_L'] = {
				'DarkBrotherhood Gauntlet (Left)',
				'Left gauntlet of the DarkBrotherhood.',
				'Provides stealthy protection.',
				'Type: Left Gauntlet'
			},

			['DarkBrotherhood_gauntlet_R'] = {
				'DarkBrotherhood Gauntlet (Right)',
				'Right gauntlet of the DarkBrotherhood.',
				'Provides stealthy protection.',
				'Type: Right Gauntlet'
			},

			['DarkBrotherhood_Boots'] = {
				'DarkBrotherhood Boots',
				'Boots of the DarkBrotherhood.',
				'Allows silent movement.',
				'Type: Boots'
			},

			['adamantium_boots'] = {
				'Adamantium Boots',
				'Boots made from adamantium alloy.',
				'Provides superior foot protection.',
				'Type: Boots'
			},

			['adamantium_bracer_left'] = {
				'Adamantium Bracer (Left)',
				'Left bracer made from adamantium.',
				'Offers elite arm protection.',
				'Type: Left Bracer'
			},

			['adamantium_bracer_right'] = {
				'Adamantium Bracer (Right)',
				'Right bracer made from adamantium.',
				'Offers elite arm protection.',
				'Type: Right Bracer'
			},

			['adamantium_cuirass'] = {
				'Adamantium Cuirass',
				'Chest armor made from adamantium.',
				'Provides elite protection.',
				'Type: Cuirass'
			},

			['adamantium_greaves'] = {
				'Adamantium Greaves',
				'Leg guards made from adamantium.',
				'Offers superior leg protection.',
				'Type: Greaves'
			},

			['adamantium_pauldron_right'] = {
				'Adamantium Pauldron (Right)',
				'Right shoulder guard of adamantium.',
				'Provides elite shoulder protection.',
				'Type: Right Pauldron'
			},

			['adamantium_pauldron_left'] = {
				'Adamantium Pauldron (Left)',
				'Left shoulder guard of adamantium.',
				'Provides elite shoulder protection.',
				'Type: Left Pauldron'
			},

			['addamantium_helm'] = {
				'Addamantium Helmet',
				'Helmet made from addamantium alloy.',
				'Provides superior head protection.',
				'Type: Helmet'
			},

			['goblin_shield'] = {
				'Goblin Shield',
				'Shield crafted by goblins.',
				'Basic defensive tool.',
				'Type: Shield'
			},

			['Indoril_Almalexia_shield'] = {
				'Indoril Almalexia Shield',
				'Shield of royal lineage.',
				'Symbol of noble protection.',
				'Type: Shield'
			},

			['dwemer_shield_battle_unique'] = {
				'Dwemer Battle Shield (Unique)',
				'Ancient mechanical shield of Dwemer design.',
				'Unique battle capabilities.',
				'Type: Shield'
			},

			['Indoril_MH_Guard_boots'] = {
				'Indoril MH Guard Boots',
				'Boots of the Indoril Guard.',
				'Provides reliable foot protection.',
				'Type: Boots'
			},

			['Indoril_MH_Guard_Cuirass'] = {
				'Indoril MH Guard Cuirass',
				'Chest armor of the Indoril Guard.',
				'Offers solid protection.',
				'Type: Cuirass'
			},

			['Indoril_MH_Guard_gauntlet_L'] = {
				'Indoril MH Guard Gauntlet (Left)',
				'Left gauntlet of the Indoril Guard.',
				'Provides hand protection.',
				'Type: Left Gauntlet'
			},

			['Indoril_MH_Guard_gauntlet_R'] = {
				'Indoril MH Guard Gauntlet (Right)',
				'Right gauntlet of the Indoril Guard.',
				'Provides hand protection.',
				'Type: Right Gauntlet'
			},

			['Indoril_MH_Guard_Greaves'] = {
				'Indoril MH Guard Greaves',
				'Leg guards of the Indoril Guard.',
				'Offers leg protection.',
				'Type: Greaves'
			},

			['Indoril_MH_Guard_helmet'] = {
				'Indoril MH Guard Helmet',
				'Helmet of the Indoril Guard.',
				'Provides head protection.',
				'Type: Helmet'
			},

			['Indoril_MH_Guard_Pauldron_L'] = {
				'Indoril MH Guard Pauldron (Left)',
				'Left shoulder guard of the Indoril Guard.',
				'Provides shoulder protection.',
				'Type: Left Pauldron'
			},

			['Indoril_MH_Guard_Pauldron_R'] = {
				'Indoril MH Guard Pauldron (Right)',
				'Right shoulder guard of the Indoril Guard.',
				'Provides shoulder protection.',
				'Type: Right Pauldron'
			},

			['Indoril_MH_Guard_shield'] = {
				'Indoril MH Guard Shield',
				'Shield of the Indoril Guard.',
				'Provides defensive capabilities.',
				'Type: Shield'
			},

			['goblin_shield_durgok_uni'] = {
				'Goblin Shield of Durgok (Unique)',
				'Special goblin-crafted shield.',
				'Unique defensive properties.',
				'Type: Shield'
			},

			['adamantium_helm'] = {
				'Adamantium Helmet',
				'Helmet forged from adamantium.',
				'Provides elite head protection.',
				'Type: Helmet'
			},

			['BM bear boots'] = {
				'BM Bear Boots',
				'Boots crafted in bear style.',
				'Provide reliable foot protection.',
				'Type: Boots'
			},

			['BM bear cuirass'] = {
				'BM Bear Cuirass',
				'Cuirass designed with bear motifs.',
				'Offers solid chest protection.',
				'Type: Cuirass'
			},

			['bm bear left gauntlet'] = {
				'bm bear left gauntlet',
				'Left gauntlet with bear design.',
				'Provides hand protection.',
				'Type: Left Gauntlet'
			},

			['BM bear right gauntlet'] = {
				'BM bear right gauntlet',
				'Right gauntlet featuring bear elements.',
				'Protects the right hand.',
				'Type: Right Gauntlet'
			},

			['BM bear greaves'] = {
				'BM bear greaves',
				'Greaves inspired by bear theme.',
				'Protects the legs.',
				'Type: Greaves'
			},

			['BM Bear Helmet'] = {
				'BM Bear Helmet',
				'Helmet with bear characteristics.',
				'Provides head protection.',
				'Type: Helmet'
			},

			['BM bear right pauldron'] = {
				'BM bear right pauldron',
				'Right pauldron in bear style.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['BM Bear left Pauldron'] = {
				'BM Bear left Pauldron',
				'Left pauldron with bear design.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['BM wolf cuirass'] = {
				'BM wolf cuirass',
				'Cuirass with wolf motifs.',
				'Provides chest protection.',
				'Type: Cuirass'
			},

			['BM wolf greaves'] = {
				'BM wolf greaves',
				'Greaves designed with wolf theme.',
				'Protects the legs.',
				'Type: Greaves'
			},

			['BM Wolf Helmet'] = {
				'BM Wolf Helmet',
				'Helmet featuring wolf design.',
				'Provides head protection.',
				'Type: Helmet'
			},

			['bm wolf left gauntlet'] = {
				'bm wolf left gauntlet',
				'Left gauntlet with wolf elements.',
				'Protects the left hand.',
				'Type: Left Gauntlet'
			},

			['BM Wolf Left Pauldron'] = {
				'BM Wolf Left Pauldron',
				'Left pauldron in wolf style.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['BM wolf right gauntlet'] = {
				'BM wolf right gauntlet',
				'Right gauntlet with wolf design.',
				'Protects the right hand.',
				'Type: Right Gauntlet'
			},

			['BM Wolf right pauldron'] = {
				'BM Wolf right pauldron',
				'Right pauldron featuring wolf theme.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['steel_boots_ancient'] = {
				'steel_boots_ancient',
				'Ancient steel boots.',
				'Provides durable foot protection.',
				'Type: Boots'
			},

			['steel_cuirass_ancient'] = {
				'steel_cuirass_ancient',
				'Ancient steel cuirass.',
				'Offers chest protection.',
				'Type: Cuirass'
			},

			['steel_gauntlet_left_ancient'] = {
				'steel_gauntlet_left_ancient',
				'Left ancient steel gauntlet.',
				'Protects the left hand.',
				'Type: Left Gauntlet'
			},

			['steel_gauntlet_right_ancient'] = {
				'steel_gauntlet_right_ancient',
				'Right ancient steel gauntlet.',
				'Protects the right hand.',
				'Type: Right Gauntlet'
			},

			['steel_greaves_ancient'] = {
				'steel_greaves_ancient',
				'Ancient steel greaves.',
				'Provides leg protection.',
				'Type: Greaves'
			},

			['steel_helm_ancient'] = {
				'steel_helm_ancient',
				'Ancient steel helmet.',
				'Provides durable head protection.',
				'Type: Helmet'
			},

			['steel_pauldron_left_ancient'] = {
				'steel_pauldron_left_ancient',
				'Left ancient steel pauldron.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['steel_pauldron_right_ancient'] = {
				'steel_pauldron_right_ancient',
				'Right ancient steel pauldron.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['steel_towershield_ancient'] = {
				'steel_towershield_ancient',
				'Ancient steel tower shield.',
				'Provides extensive defensive coverage.',
				'Type: Shield'
			},

			['BM_wolf_boots'] = {
				'BM_wolf_boots',
				'Wolf-themed boots.',
				'Provides foot protection.',
				'Type: Boots'
			},

			['fur_colovian_helm_red'] = {
				'fur_colovian_helm_red',
				'Red Colovian fur helmet.',
				'Combines protection and warmth.',
				'Type: Helmet'
			},

			['fur_colovian_helm_white'] = {
				'fur_colovian_helm_white',
				'White Colovian fur helmet.',
				'Offers insulation and protection.',
				'Type: Helmet'
			},

			['BM_Ice_minion_Shield1'] = {
				'BM_Ice_minion_Shield1',
				'Ice minion shield.',
				'Provides defensive capabilities.',
				'Type: Shield'
			},

			['BM_wolf_cuirass_snow'] = {
				'BM_wolf_cuirass_snow',
				'Snow variant of wolf cuirass.',
				'Offers chest protection.',
				'Type: Cuirass'
			},

			['BM_wolf_greaves_snow'] = {
				'BM_wolf_greaves_snow',
				'Snow wolf greaves.',
				'Protects the legs.',
				'Type: Greaves'
			},

			['BM_wolf_helmet_snow'] = {
				'BM_wolf_helmet_snow',
				'Snow wolf helmet.',
				'Provides head protection.',
				'Type: Helmet'
			},

			['BM_wolf_left_gauntlet_snow'] = {
				'BM_wolf_left_gauntlet_snow',
				'Left snow wolf gauntlet.',
				'Protects the left hand.',
				'Type: Left Gauntlet'
			},

			['BM_wolf_left_pauldron_snow'] = {
				'BM_wolf_left_pauldron_snow',
				'Left snow wolf pauldron.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['BM_wolf_right_gauntlet_snow'] = {
				'BM_wolf_right_gauntlet_snow',
				'Right snow wolf gauntlet.',
				'Protects the right hand.',
				'Type: Right Gauntlet'
			},

			['BM_wolf_right_pauldron_snow'] = {
				'BM_wolf_right_pauldron_snow',
				'Right snow wolf pauldron.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['BM_bear_boots_snow'] = {
				'BM_bear_boots_snow',
				'Snow bear boots.',
				'Provides foot protection.',
				'Type: Boots'
			},

			['BM_bear_cuirass_snow'] = {
				'BM_bear_cuirass_snow',
				'Snow bear cuirass.',
				'Offers chest protection.',
				'Type: Cuirass'
			},

			['BM_bear_greaves_snow'] = {
				'BM_bear_greaves_snow',
				'Snow bear greaves.',
				'Protects the legs.',
				'Type: Greaves'
			},

			['BM_bear_helmet_snow'] = {
				'BM_bear_helmet_snow',
				'Helmet crafted from snow bear materials.',
				'Provides head protection with frost resistance.',
				'Type: Helmet'
			},

			['BM_bear_left_gauntlet_snow'] = {
				'BM_bear_left_gauntlet_snow',
				'Left gauntlet made from snow bear parts.',
				'Protects the left hand against cold.',
				'Type: Left Gauntlet'
			},

			['BM_bear_right_gauntlet_snow'] = {
				'BM_bear_right_gauntlet_snow',
				'Right gauntlet crafted from snow bear materials.',
				'Protects the right hand against cold.',
				'Type: Right Gauntlet'
			},

			['BM_bear_left_pauldron_snow'] = {
				'BM_bear_left_pauldron_snow',
				'Left pauldron made from snow bear parts.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['BM_bear_right_pauldron_snow'] = {
				'BM_bear_right_pauldron_snow',
				'Right pauldron crafted from snow bear materials.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['BM_wolf_boots_snow'] = {
				'BM_wolf_boots_snow',
				'Snow wolf boots.',
				'Provides foot protection against cold.',
				'Type: Boots'
			},

			['BM Bear Helmet eddard'] = {
				'BM Bear Helmet eddard',
				'Special bear helmet variant.',
				'Offers head protection.',
				'Type: Helmet'
			},

			['BM_NordicMail_Boots'] = {
				'BM_NordicMail_Boots',
				'Nordic mail boots.',
				'Provides foot protection.',
				'Type: Boots'
			},

			['BM_NordicMail_cuirass'] = {
				'BM_NordicMail_cuirass',
				'Nordic mail cuirass.',
				'Offers chest protection.',
				'Type: Cuirass'
			},

			['BM_NordicMail_PauldronL'] = {
				'BM_NordicMail_PauldronL',
				'Left Nordic mail pauldron.',
				'Protects the left shoulder.',
				'Type: Left Pauldron'
			},

			['BM_NordicMail_PauldronR'] = {
				'BM_NordicMail_PauldronR',
				'Right Nordic mail pauldron.',
				'Protects the right shoulder.',
				'Type: Right Pauldron'
			},

			['BM_NordicMail_gauntletL'] = {
				'BM_NordicMail_gauntletL',
				'Left Nordic mail gauntlet.',
				'Protects the left hand.',
				'Type: Left Gauntlet'
			},

			['BM_NordicMail_gauntletR'] = {
				'BM_NordicMail_gauntletR',
				'Right Nordic mail gauntlet.',
				'Protects the right hand.',
				'Type: Right Gauntlet'
			},

			['BM_NordicMail_Helmet'] = {
				'BM_NordicMail_Helmet',
				'Nordic mail helmet.',
				'Provides head protection.',
				'Type: Helmet'
			},

			['BM_NordicMail_greaves'] = {
				'BM_NordicMail_greaves',
				'Nordic mail greaves.',
				'Protects the legs.',
				'Type: Greaves'
			},

			['BM_Ice_Boots'] = {
				'BM_Ice_Boots',
				'Ice boots.',
				'Provides foot protection.',
				'Type: Boots'
			},

			['BM_Ice_cuirass'] = {
				'BM_Ice_cuirass',
				'Ice cuirass.',
				'Offers chest protection.',
				'Type: Cuirass'
			},

			['BM_Ice_gauntletL'] = {
				'BM_Ice_gauntletL',
				'Left ice gauntlet.',
				'Provides cold resistance and hand protection.',
				'Type: Left Gauntlet'
			},

			['BM_Ice_gauntletR'] = {
				'BM_Ice_gauntletR',
				'Right ice gauntlet.',
				'Provides cold resistance and hand protection.',
				'Type: Right Gauntlet'
			},

			['BM_Ice_greaves'] = {
				'BM_Ice_greaves',
				'Ice greaves.',
				'Offers leg protection with cold resistance.',
				'Type: Greaves'
			},

			['BM_Ice_Helmet'] = {
				'BM_Ice_Helmet',
				'Ice helmet.',
				'Provides head protection and cold resistance.',
				'Type: Helmet'
			},

			['BM_Ice_PauldronL'] = {
				'BM_Ice_PauldronL',
				'Left ice pauldron.',
				'Protects the left shoulder with cold resistance.',
				'Type: Left Pauldron'
			},

			['BM_Ice_PauldronR'] = {
				'BM_Ice_PauldronR',
				'Right ice pauldron.',
				'Protects the right shoulder with cold resistance.',
				'Type: Right Pauldron'
			},

			['BM Bear Helmet_ber'] = {
				'BM Bear Helmet_ber',
				'Special bear helmet variant.',
				'Provides enhanced head protection.',
				'Type: Helmet'
			},

			['BM_NordicMail_Shield'] = {
				'BM_NordicMail_Shield',
				'Nordic mail shield.',
				'Offers defensive capabilities.',
				'Type: Shield'
			},

			['BM_Ice_Shield'] = {
				'BM_Ice_Shield',
				'Ice shield.',
				'Provides cold resistance and defense.',
				'Type: Shield'
			},

			['BM wolf shield'] = {
				'BM wolf shield',
				'Wolf-themed shield.',
				'Offers defensive protection.',
				'Type: Shield'
			},

			['BM bear shield'] = {
				'BM bear shield',
				'Bear-themed shield.',
				'Provides defensive capabilities.',
				'Type: Shield'
			},

			['BM Wolf Helmet_heartfang'] = {
				'BM Wolf Helmet_heartfang',
				'Wolf helmet with heartfang design.',
				'Offers head protection.',
				'Type: Helmet'
			},

			['wolfwalkers'] = {
				'wolfwalkers',
				'Special boots for wolf-like movement.',
				'Enhances agility and speed.',
				'Type: Boots'
			}
        },
        materialDescriptions = { 
                iron = {
        conditionGood = {
            'Iron armor.',
            'Sturdy and reliable.',
            'Provides good protection.'
        },
        conditionBad = {
            'Worn iron armor.',
            'Shows signs of battle.',
            'Needs repair.'
        },
        conditionBroken = {
            'Broken iron armor.',
			'Nearly useless.',
			'Should be replaced.'
				}
			}
		}
	}
}