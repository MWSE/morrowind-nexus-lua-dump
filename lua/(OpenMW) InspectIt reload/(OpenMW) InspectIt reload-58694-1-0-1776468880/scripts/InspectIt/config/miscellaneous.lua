local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Miscellaneous] = {
        title = 'Misc. Item',
        color = util.color.rgb(0.7, 0.7, 0.7),
        showWeight = true,
        showValue = true,
        uniqueDescriptions = {
			['Gold_100'] = {
				'Stack of Gold Coins',
				'Heavy and clinking stack of coins.',
				'Universal currency used throughout Tamriel.'
			},

			['Misc_SoulGem_Petty'] = {
				'Petty Soul Gem',
				'Small gem capable of containing weak souls.',
				'Used for basic enchanting and soul trapping.'
			},

			['Misc_SoulGem_Lesser'] = {
				'Lesser Soul Gem',
				'Medium-sized gem for holding lesser souls.',
				'Ideal for mid-level enchantments.'
			},

			['Misc_SoulGem_Common'] = {
				'Common Soul Gem',
				'Standard-sized gem for common souls.',
				'Versatile for most enchanting tasks.'
			},

			['Misc_SoulGem_Greater'] = {
				'Greater Soul Gem',
				'Large gem designed for powerful souls.',
				'Used for high-level enchantments.'
			},

			['Misc_SoulGem_Grand'] = {
				'Grand Soul Gem',
				'Largest soul gem available.',
				'Capable of holding the most powerful souls.'
			},

			['Misc_SoulGem_Azura'] = {
				"Azura's Soul Gem",
				'Rare soul gem blessed by Azura.',
				'Can hold any type of soul.'
			},

			['misc_vivec_ashmask_01'] = {
				'Vivec Ash Mask',
				'Ceremonial mask made of ash.',
				'Used in traditional Vivec rituals.'
			},

			['misc_com_basket_01'] = {
				'Woven Basket',
				'Sturdy basket made of woven materials.',
				'Used for carrying and storing items.'
			},

			['misc_com_basket_02'] = {
				'Reinforced Basket',
				'Durable basket with reinforced handles.',
				'Designed for heavy loads.'
			},

			['misc_com_broom_01'] = {
				'Standard Broom',
				'Basic cleaning tool.',
				'Used for sweeping floors.'
			},

			['misc_com_bucket_01'] = {
				'Metal Bucket',
				'Sturdy metal container.',
				'Used for carrying liquids.'
			},

			['misc_com_iron_ladle'] = {
				'Iron Ladle',
				'Durable ladle made of iron.',
				'Used for serving and stirring.'
			},

			['Misc_Com_Pitcher_Metal_01'] = {
				'Metal Pitcher',
				'Metal container with a pouring spout.',
				'Used for serving drinks.'
			},

			['misc_com_silverware_fork'] = {
				'Silverware Fork',
				'Dining fork made of silverware metal.',
				'Used for eating meals.'
			},

			['misc_com_silverware_knife'] = {
				'Silverware Knife',
				'Dining knife crafted from silverware metal.',
				'Used for cutting food.'
			},

			['misc_com_silverware_spoon'] = {
				'Silverware Spoon',
				'Spoon made of silverware metal.',
				'Used for eating and serving.'
			},

			['misc_com_tankard_01'] = {
				'Metal Tankard',
				'Sturdy drinking vessel.',
				'Used for ale and other beverages.'
			},

			['misc_com_wood_fork'] = {
				'Wooden Fork',
				'Fork made of wood.',
				'Basic dining utensil.'
			},

			['misc_com_wood_knife'] = {
				'Wooden Knife',
				'Simple knife made of wood.',
				'Used for basic cutting tasks.'
			},

			['misc_com_wood_spoon_01'] = {
				'Wooden Spoon',
				'Spoon crafted from wood.',
				'Used for eating and stirring.'
			},

			['misc_com_wood_spoon_02'] = {
				'Decorative Wooden Spoon',
				'Wooden spoon with unique design.',
				'Both functional and decorative.'
			},

			['key_standard_01'] = {
				'Standard Key',
				'Basic key for locking and unlocking.',
				'Fits standard locks.'
			},

			['key_temple_01'] = {
				'Temple Key',
				'Special key designed for temple doors and chambers.',
				'Used to access restricted temple areas.'
			},

			['misc_com_plate_05'] = {
				'Dining Plate',
				'Standard-sized plate for serving meals.',
				'Common dining ware.'
			},

			['misc_com_metal_plate_04'] = {
				'Metal Plate',
				'Sturdy metal plate with decorative edges.',
				'Durable serving dish.'
			},

			['misc_com_metal_plate_05'] = {
				'Decorative Metal Plate',
				'Metal plate with intricate design.',
				'Used for special occasions.'
			},

			['misc_com_plate_01'] = {
				'Basic Plate',
				'Simple dinner plate.',
				'Everyday dining ware.'
			},

			['misc_com_plate_02'] = {
				'Medium Plate',
				'Slightly larger plate with simple design.',
				'Versatile serving dish.'
			},

			['misc_com_plate_03'] = {
				'Patterned Plate',
				'Plate with unique decorative pattern.',
				'Adds style to meals.'
			},

			['misc_com_plate_04'] = {
				'Reinforced Plate',
				'Durable plate with strengthened edges.',
				'Built to last.'
			},

			['misc_com_metal_plate_03'] = {
				'Finely Crafted Metal Plate',
				'Metal plate with polished finish.',
				'High-quality dining ware.'
			},

			['misc_com_plate_06'] = {
				'Ornate Plate',
				'Plate with decorative rim design.',
				'Formal dining piece.'
			},

			['Misc_Com_Wood_Bowl_01'] = {
				'Wooden Bowl',
				'Natural bowl crafted from wood.',
				'Multi-purpose container.'
			},

			['misc_com_wood_bowl_02'] = {
				'Large Wooden Bowl',
				'Generous-sized wooden bowl.',
				'Perfect for serving groups.'
			},

			['misc_com_wood_bowl_03'] = {
				'Smooth Wood Bowl',
				'Bowl with polished wooden surface.',
				'Comfortable to hold.'
			},

			['misc_com_plate_07'] = {
				'Elaborate Plate',
				'Plate with intricate design work.',
				'Special occasion piece.'
			},

			['misc_com_plate_08'] = {
				'Serving Plate',
				'Large plate for main courses.',
				'Ideal for presentation.'
			},

			['misc_com_wood_bowl_04'] = {
				'Carved Wood Bowl',
				'Bowl with decorative carvings.',
				'Artistic and functional.'
			},

			['Misc_Com_Wood_Bowl_05'] = {
				'Detailed Wood Bowl',
				'Bowl with intricate woodwork.',
				'Collectors item.'
			},

			['misc_com_wood_cup_01'] = {
				'Simple Wooden Cup',
				'Basic drinking vessel made of wood.',
				'Eco-friendly container.'
			},

			['misc_com_wood_cup_02'] = {
				'Ergonomic Wood Cup',
				'Wooden cup with comfortable grip.',
				'Designed for ease of use.'
			},

			['misc_com_bottle_01'] = {
				'Glass Bottle',
				'Standard glass container.',
				'Used for storing liquids.'
			},

			['misc_com_bottle_02'] = {
				'Narrow-Neck Bottle',
				'Bottle with slim opening.',
				'Ideal for precise pouring.'
			},

			['misc_com_bottle_03'] = {
				'Stoppered Bottle',
				'Bottle with sealing stopper.',
				'Keeps contents fresh.'
			},

			['Misc_Com_Bottle_04'] = {
				'Large Storage Bottle',
				'Sizable container for bulk storage.',
				'Durable glass construction.'
			},

			['misc_com_bottle_05'] = {
				'Decorative Bottle',
				'Ornately designed glass bottle.',
				'Collectors item.'
			},

			['misc_com_bottle_05'] = {
				'Decorative Bottle',
				'Ornately designed glass bottle with intricate patterns.',
				'Suitable for special occasions and storage.'
			},

			['misc_com_metal_goblet_01'] = {
				'Metal Goblet',
				'Elegant drinking vessel made of polished metal.',
				'Used for fine beverages.'
			},

			['misc_com_metal_goblet_02'] = {
				'Ornate Metal Goblet',
				'Goblet with decorative rim and design.',
				'Formal dining accessory.'
			},

			['misc_com_bottle_06'] = {
				'Basic Stoppered Bottle',
				'Simple glass bottle with cork stopper.',
				'General-purpose container.'
			},

			['misc_com_bottle_07'] = {
				'Unique Shape Bottle',
				'Glass bottle with distinctive design.',
				'Eye-catching storage solution.'
			},

			['Misc_Com_Bottle_08'] = {
				'Tall Slender Bottle',
				'Elongated glass bottle with narrow profile.',
				'Prestigious appearance.'
			},

			['misc_com_bottle_09'] = {
				'Wide-Base Bottle',
				'Sturdy glass bottle with broad base.',
				'Stable storage container.'
			},

			['misc_com_bottle_10'] = {
				'Embossed Bottle',
				'Glass bottle with raised designs.',
				'Decorative storage vessel.'
			},

			['misc_com_bottle_11'] = {
				'Textured Bottle',
				'Glass bottle with tactile surface patterns.',
				'Unique feel and appearance.'
			},

			['misc_com_bottle_12'] = {
				'Minimalist Bottle',
				'Simple glass bottle with clean lines.',
				'Modern design.'
			},

			['Misc_Com_Bottle_14'] = {
				'Labeled Bottle',
				'Glass bottle with decorative label.',
				'Marked for specific contents.'
			},

			['misc_com_bottle_15'] = {
				'Corked Bottle',
				'Glass bottle with traditional cork closure.',
				'Classic design.'
			},

			['key_standard_01_pel_guard_tower'] = {
				'Guard Tower Key',
				'Key specifically for Pel guard tower doors.',
				'Access to guard tower facilities.'
			},

			['key_kagouti_colony'] = {
				'Kagouti Colony Key',
				'Key to access Kagouti colony areas.',
				'Entry to restricted Kagouti territory.'
			},

			['key_obscure_alit_warren'] = {
				'Alit Warren Key',
				'Key for accessing obscure Alit warren passages.',
				'Opens hidden Alit paths.'
			},

			['key_fetid_dreugh_grotto'] = {
				'Dreugh Grotto Key',
				'Key to the fetid Dreugh grotto entrance.',
				'Access to Dreugh lair.'
			},

			['misc_de_basket_01'] = {
				'Decorative Basket',
				'Ornamental basket with intricate weaving.',
				'Display and storage item.'
			},

			['misc_de_bowl_01'] = {
				'Decorative Bowl',
				'Bowl with artistic design.',
				'Both functional and decorative.'
			},

			['misc_de_goblet_01'] = {
				'Festive Goblet',
				'Goblet designed for special occasions.',
				'Celebratory drinking vessel.'
			},

			['misc_de_goblet_02'] = {
				'Patterned Goblet',
				'Goblet with unique design work.',
				'Elegant drinking accessory.'
			},

			['misc_de_goblet_03'] = {
				'Floral Goblet',
				'Goblet adorned with floral motifs.',
				'Nature-inspired design.'
			},

			['misc_de_goblet_04'] = {
				'Geometric Goblet',
				'Goblet featuring geometric patterns.',
				'Modern design aesthetic.'
			},

			['misc_de_goblet_05'] = {
				'Engraved Goblet',
				'Goblet with subtle etchings and designs.',
				'Fine craftsmanship.'
			},

			['misc_de_goblet_06'] = {
				'Glossy Goblet',
				'Goblet with polished, shiny finish.',
				'Luxurious appearance.'
			},

			['misc_de_goblet_07'] = {
				'Textured Goblet',
				'Goblet with unique surface texture.',
				'Distinctive feel.'
			},

			['misc_de_goblet_08'] = {
				'Ornate Base Goblet',
				'Goblet with decorative base design.',
				'Sturdy and elegant.'
			},

			['misc_de_goblet_09'] = {
				'Unique Shape Goblet',
				'Goblet with unusual design.',
				'Artistic statement piece.'
			},

			['misc_de_pitcher_01'] = {
				'Decorative Pitcher',
				'Pitcher with artistic design.',
				'Serving vessel.'
			},

			['misc_de_tankard_01'] = {
				'Festive Tankard',
				'Tankard designed for celebrations.',
				'Sturdy drinking vessel.'
			},

			['misc_uni_pillow_01'] = {
				'Standard Pillow',
				'Basic pillow for comfort.',
				'Everyday use.'
			},

			['misc_de_pot_redware_01'] = {
				'Redware Pot',
				'Pot made of durable red clay.',
				'Cooking and storage.'
			},

			['misc_de_bowl_orange_green_01'] = {
				'Two-Tone Bowl',
				'Bowl with orange and green design.',
				'Vibrant colors.'
			},

			['misc_de_bowl_redware_03'] = {
				'Redware Bowl',
				'Bowl made of red clay.',
				'Durable and practical.'
			},

			['Misc_DE_glass_green_01'] = {
				'Green Glass Item',
				'Glass piece in green hue.',
				'Decorative use.'
			},

			['misc_de_glass_yellow_01'] = {
				'Yellow Glass Item',
				'Glass piece in yellow color.',
				'Ornamental purpose.'
			},

			['misc_de_muck_shovel_01'] = {
				'Muck Shovel',
				'Shovel designed for digging through muck.',
				'Utility tool.'
			},

			['misc_de_pot_glass_peach_01'] = {
				'Peach Glass Pot',
				'Pot made of peach-colored glass.',
				'Decorative storage.'
			},

			['misc_de_pot_glass_peach_02'] = {
				'Large Peach Glass Pot',
				'Larger version of peach glass pot.',
				'Increased capacity.'
			},

			['misc_de_pot_redware_02'] = {
				'Second Redware Pot',
				'Additional red clay pot.',
				'Practical use.'
			},

			['misc_de_pot_redware_04'] = {
				'Fourth Redware Pot',
				'Another red clay pot variant.',
				'Cooking and storage.'
			},

			['misc_de_bowl_white_01'] = {
				'White Bowl',
				'Bowl in pure white color.',
				'Classic design.'
			},

			['misc_de_bellows10'] = {
				'Bellows',
				'Tool for blowing air.',
				'Used in blacksmithing.'
			},

			['misc_imp_silverware_plate_01'] = {
				'Imperial Silverware Plate',
				'Plate made of imperial silverware.',
				'High-quality dining ware.'
			},

			['misc_imp_silverware_plate_02'] = {
				'Imperial Silverware Plate',
				'Second variant of imperial silverware plate.',
				'Fine craftsmanship.'
			},

			['misc_imp_silverware_plate_03'] = {
				'Imperial Silverware Plate',
				'Third variant of imperial silverware plate.',
				'Elegant design.'
			},

			['misc_com_redware_bowl'] = {
				'Redware Bowl',
				'Bowl made of durable red clay.',
				'Practical kitchen item.'
			},

			['misc_com_redware_bowl_01'] = {
				'Redware Bowl Variant',
				'First variant of redware bowl.',
				'Sturdy construction.'
			},

			['Misc_Com_Redware_Cup'] = {
				'Redware Cup',
				'Cup made of red clay.',
				'Durable drinking vessel.'
			},

			['misc_com_redware_flask'] = {
				'Redware Flask',
				'Flask crafted from red clay.',
				'Storage container.'
			},

			['misc_com_redware_pitcher'] = {
				'Redware Pitcher',
				'Pitcher made of red clay.',
				'Serving vessel.'
			},

			['misc_com_redware_plate'] = {
				'Redware Plate',
				'Plate crafted from red clay.',
				'Durable dining ware.'
			},

			['misc_com_redware_platter'] = {
				'Redware Platter',
				'Large serving platter made of red clay.',
				'Ideal for presentation.'
			},

			['misc_com_redware_vase'] = {
				'Redware Vase',
				'Vase crafted from red clay.',
				'Decorative and functional.'
			},

			['Misc_Imp_Silverware_Cup_01'] = {
				'Imperial Silverware Cup',
				'Cup made of imperial silverware.',
				'High-quality craftsmanship.'
			},

			['misc_imp_silverware_cup'] = {
				'Silverware Cup',
				'Cup crafted from silverware metal.',
				'Elegant design.'
			},

			['Misc_Imp_Silverware_Bowl'] = {
				'Imperial Silverware Bowl',
				'Bowl made of imperial silverware.',
				'Luxurious dining item.'
			},

			['misc_imp_silverware_pitcher'] = {
				'Imperial Silverware Pitcher',
				'Pitcher crafted from silverware metal.',
				'Fine serving vessel.'
			},

			['key_redoran_basic'] = {
				'Redoran Basic Key',
				'Basic key used by Redoran clan.',
				'Access to Redoran facilities.'
			},

			['key_chest_aryniorethi_01'] = {
				'Chest Key - Aryniorethi',
				"Key to Aryniorethi's chest.",
				'Personal chest access.'
			},

			['key_chest_coduscallonus_01'] = {
				'Chest Key - Coduscallonus',
				"Key to Coduscallonus's chest.",
				'Private storage access.'
			},

			['key_chest_drinarvaryon_01'] = {
				'Chest Key - Drinarvaryon',
				"Key to Drinarvaryon's chest.",
				'Secure storage access.'
			},

			['key_standard_01_pel_fort_prison'] = {
				'Pel Fort Prison Key',
				'Key to Pel Fort prison cells.',
				'Access to prison areas.'
			},

			['key_falas tomb keepers'] = {
				'Falas Tomb Keepers Key',
				'Key for Falas tomb keepers.',
				'Access to tomb areas.'
			},

			['key_falas tomb keepers_2'] = {
				'Falas Tomb Keepers Key 2',
				'Second key for Falas tomb keepers.',
				'Additional access.'
			},

			['key_assarnud'] = {
				'Assarnud Key',
				'Key related to Assarnud.',
				'Access to specific areas.'
			},

			['key_pellecia aurrus'] = {
				'Pellecia Aurrus Key',
				'Key associated with Pellecia Aurrus.',
				'Personal access key.'
			},

			['key_bivaleteneran_01'] = {
				'Bivaleteneran Key',
				'Key for Bivaleteneran areas.',
				'Restricted access.'
			},

			['key_hlormarenslaves_01'] = {
				'Hlormaren Slaves Key',
				'Key to Hlormaren slaves quarters.',
				'Access to slave holding areas.'
			},

			['key_chest_avonravel_01'] = {
				'Chest Key - Avonravel',
				"Key to Avonravel's chest.",
				'Personal storage access.'
			},

			['key_chest_brilnosullarys_01'] = {
				'Chest Key - Brilnosullarys',
				"Key to Brilnosullarys's chest.",
				'Secure chest access.'
			},

			['key_llethervari_01'] = {
				'Llethervari Key',
				'Key related to Llethervari.',
				'Access to specific locations.'
			},

			['key_llethrimanor_01'] = {
				'Llethrimanor Key',
				'Key to Llethrimanor estate.',
				'Manor access key.'
			},

			['key_standard_darius_chest'] = {
				'Darius Chest Key',
				"Key to Darius's chest.",
				'Personal storage key.'
			},

			['key_tukushapal_1'] = {
				'Tukushapal Key',
				'Key related to Tukushapal.',
				'Access to specific areas.'
			},

			['key_sarethimanor_01'] = {
				'Sarethi Manor Key',
				'Key to Sarethi manor.',
				'Manor access key.'
			},

			['key_tuvesobeleth_01'] = {
				'Tuvesobeleth Key',
				'Key related to Tuvesobeleth.',
				'Access to specific locations.'
			},

			['key_malpenixblonia_01'] = {
				'Malpenixblonia Key',
				'Key related to Malpenixblonia.',
				'Access to specific areas.'
			},

			['key_arobarmanor_01'] = {
				'Arobar Manor Key',
				'Key to Arobar manor.',
				'Manor access key.'
			},

			['key_arobarmanorguard_01'] = {
				'Arobar Manor Guard Key',
				'Guard key for Arobar manor.',
				'Restricted access key.'
			},

			['key_ciennesintieve_01'] = {
				'Ciennesintieve Key',
				'Key related to Ciennesintieve.',
				'Access to specific areas.'
			},

			['key_dumbuk_strongbox'] = {
				'Dumbuk Strongbox Key',
				'Key to Dumbuk strongbox.',
				'Secure storage access.'
			},

			['key_gnisis_eggmine'] = {
				'Gnisis Eggmine Key',
				'Key to Gnisis eggmine.',
				'Access to mining area.'
			},

			['key_madach_room'] = {
				'Madach Room Key',
				'Key to Madachs room.',
				'Private room access.'
			},

			['key_arvs-drelen_cell'] = {
				'Arvs-Drelen Cell Key',
				'Key to Arvs-Drelen cell.',
				'Prison cell access.'
			},

			['key_summoning_room'] = {
				'Summoning Room Key',
				'Key to summoning room.',
				'Access to ritual chamber.'
			},

			['misc_vivec_ashmask_01_fake'] = {
				'Fake Vivec Ash Mask',
				'Counterfeit ash mask from Vivec.',
				'Imitation ceremonial mask.'
			},

			['key_standard_01_darvam hlaren'] = {
				'Darvam Hlaren Key',
				'Key related to Darvam Hlaren.',
				'Access to specific areas.'
			},

			['key_standard_01_hassour zainsub'] = {
				'Hassour Zainsub Key',
				'Key related to Hassour Zainsub.',
				'Access to specific locations.'
			},

			['key_hinnabi'] = {
				'Hinnabi Key',
				'Key related to Hinnabi.',
				'Access to specific locations.'
			},

			['key_minabi'] = {
				'Minabi Key',
				'Key related to Minabi.',
				'Access to restricted areas.'
			},

			['misc_dwrv_artifact00'] = {
				'Dwemer Artifact',
				'Ancient Dwemer relic.',
				'Of historical significance.'
			},

			['misc_dwrv_bowl00'] = {
				'Dwemer Bowl',
				'Bowl crafted by Dwemer artisans.',
				'Ancient design.'
			},

			['misc_dwrv_goblet00'] = {
				'Dwemer Goblet',
				'Goblet made by Dwemer craftsmen.',
				'Unique construction.'
			},

			['misc_dwrv_goblet10'] = {
				'Dwemer Goblet Variant',
				'Second variant of Dwemer goblet.',
				'Distinctive design.'
			},

			['misc_dwrv_mug00'] = {
				'Dwemer Mug',
				'Mug crafted by Dwemer.',
				'Ancient utility item.'
			},

			['misc_dwrv_pitcher00'] = {
				'Dwemer Pitcher',
				'Pitcher made by Dwemer artisans.',
				'Unique construction.'
			},

			['misc_dwrv_artifact10'] = {
				'Dwemer Artifact Variant',
				'Another Dwemer relic.',
				'Historical importance.'
			},

			['misc_dwrv_artifact20'] = {
				'Dwemer Artifact Piece',
				'Fragment of Dwemer artifact.',
				'Of archaeological interest.'
			},

			['misc_dwrv_artifact30'] = {
				'Dwemer Artifact Fragment',
				'Ancient Dwemer artifact piece.',
				'Valuable for research.'
			},

			['misc_dwrv_artifact40'] = {
				'Dwemer Artifact Component',
				'Part of a larger Dwemer device.',
				'Mechanically complex.'
			},

			['misc_dwrv_artifact50'] = {
				'Dwemer Artifact Remnant',
				'Remains of Dwemer technology.',
				'Enigmatic purpose.'
			},

			['misc_dwrv_artifact60'] = {
				'Dwemer Artifact Core',
				'Central component of Dwemer device.',
				'Highly advanced.'
			},

			['misc_dwrv_coin00'] = {
				'Dwemer Coin',
				'Ancient Dwemer currency.',
				'Historical value.'
			},

			['misc_dwrv_ark_key00'] = {
				'Dwemer Ark Key',
				'Key to Dwemer ark mechanisms.',
				'Unlocks ancient technology.'
			},

			['misc_dwrv_gear00'] = {
				'Dwemer Gear',
				'Mechanical component of Dwemer devices.',
				'Precision engineering.'
			},

			['misc_dwrv_ark_cube00'] = {
				'Dwemer Ark Cube',
				'Mystical Dwemer artifact.',
				'Unknown purpose.'
			},

			['misc_skull00'] = {
				'Ancient Skull',
				'Preserved skeletal remains.',
				'Of historical interest.'
			},

			['misc_skull10'] = {
				'Decorative Skull',
				'Ornamental skull display.',
				'Artistic value.'
			},

			['key_hasphat_antabolis'] = {
				'Hasphat Antabolis Key',
				'Key related to Hasphat Antabolis.',
				'Access to specific areas.'
			},

			['key_hasphat_antabolis2'] = {
				'Hasphat Antabolis Key 2',
				'Second key for Hasphat Antabolis.',
				'Additional access.'
			},

			['misc_de_fishing_pole'] = {
				'Fishing Pole',
				'Tool for fishing.',
				'Fishing equipment.'
			},

			['key_shushishi'] = {
				'Shushishi Key',
				'Key related to Shushishi.',
				'Access to specific locations.'
			},

			['mamaea cell key'] = {
				'Mamaea Cell Key',
				'Key to Mamaea cell.',
				'Prison access.'
			},

			['mamaea quarters key'] = {
				'Mamaea Quarters Key',
				'Key to Mamaea quarters.',
				'Residential access.'
			},

			['misc_6th_ash_statue_01'] = {
				'Sixth Ash Statue',
				'Statue made of ash material.',
				'Ceremonial purpose.'
			},

			["key_huleen's_hut"] = {
				"Huleen's Hut Key",
				"Key to Huleen's hut.",
				'Access to personal dwelling.'
			},

			['key_assemanu_01'] = {
				'Assemanu Key',
				'Key related to Assemanu.',
				'Access to specific areas.'
			},

			['key_assemanu_02'] = {
				'Assemanu Key 2',
				'Second key for Assemanu.',
				'Additional access.'
			},
			['key_nund'] = {
				'Nund Key',
				'Key related to Nund.',
				'Access to specific locations.'
			},

			['key_divayth_fyr'] = {
				'Divayth Fyr Key',
				'Key associated with Divayth Fyr.',
				'Access to personal chambers.'
			},

			['misc_6th_ash_hrcs'] = {
				'Sixth Ash HRC System',
				'Ancient ash-based mechanism.',
				'Unknown purpose.'
			},

			['misc_6th_ash_hrmm'] = {
				'Sixth Ash HRMM Component',
				'Part of ash-based machinery.',
				'Mechanical artifact.'
			},

			['misc_de_goblet_01_redas'] = {
				'Redas Goblet',
				'Goblet with unique redas design.',
				'Decorative vessel.'
			},

			['key_arrile'] = {
				'Arrile Key',
				'Key related to Arrile.',
				'Access to specific areas.'
			},

			["key_ra'zhid"] = {
				"Ra'zhid Key",
				"Key associated with Ra'zhid.",
				'Access to restricted areas.'
			},

			['key_ministry_cells'] = {
				'Ministry Cells Key',
				'Key to ministry prison cells.',
				'Access to detention areas.'
			},

			['key_ministry_sectors'] = {
				'Ministry Sectors Key',
				'Key to ministry sector doors.',
				'Access to ministry sections.'
			},

			['key_rothran'] = {
				'Rothran Key',
				'Key related to Rothran.',
				'Access to specific locations.'
			},

			['key_aldsotha'] = {
				'Aldsotha Key',
				'Key associated with Aldsotha.',
				'Access to personal areas.'
			},

			['key_kogoruhn_sewer'] = {
				'Kogoruhn Sewer Key',
				'Key to sewer access points.',
				'Access to underground tunnels.'
			},

			['key_ministry_ext'] = {
				'Ministry Exterior Key',
				'Key to exterior ministry doors.',
				'Access to outer ministry areas.'
			},

			['key_persius_mercius'] = {
				'Persius Mercius Key',
				'Key related to Persius Mercius.',
				'Access to personal chambers.'
			},

			['key_impcomsecrdoor'] = {
				'Imperial Comsec Door Key',
				'Key to imperial command security door.',
				'High-security access.'
			},

			['key_saryoni'] = {
				'Saryoni Key',
				'Key associated with Saryoni.',
				'Access to specific locations.'
			},

			['key_gen_tomb'] = {
				'General Tomb Key',
				'Key to general tomb entrance.',
				'Access to burial grounds.'
			},

			['misc_beaker_01'] = {
				'Laboratory Beaker',
				'Glass beaker for scientific use.',
				'Laboratory equipment.'
			},

			['misc_flask_01'] = {
				'Laboratory Flask',
				'Glass flask for chemical storage.',
				'Scientific tool.'
			},

			['misc_flask_02'] = {
				'Narrow Flask',
				'Flask with narrow neck design.',
				'Precision laboratory tool.'
			},
			['misc_flask_03'] = {
				'Laboratory Flask',
				'Standard flask for scientific use.',
				'Common laboratory equipment.'
			},

			['misc_flask_04'] = {
				'Specialized Flask',
				'Flask designed for specific chemical processes.',
				'Advanced laboratory tool.'
			},

			['key_hodlismod'] = {
				'Hodlismod Key',
				'Key related to Hodlismod.',
				'Access to specific areas.'
			},

			['key_falaanamo'] = {
				'Falaanamo Key',
				'Key associated with Falaanamo.',
				'Access to restricted locations.'
			},

			['key_irgola'] = {
				'Irgola Key',
				'Key related to Irgola.',
				'Access to specific chambers.'
			},

			['key_savilecagekey'] = {
				'Savile Cage Key',
				'Key to unlock savile cages.',
				'Animal enclosure access.'
			},

			['key_dren_manor'] = {
				'Dren Manor Key',
				'Key to Dren manor.',
				'Manor entrance access.'
			},

			['key_helvi'] = {
				'Helvi Key',
				'Key related to Helvi.',
				'Access to personal quarters.'
			},

			['key_dralor'] = {
				'Dralor Key',
				'Key associated with Dralor.',
				'Access to specific areas.'
			},

			['key_ivrosa'] = {
				'Ivrosa Key',
				'Key related to Ivrosa.',
				'Access to restricted locations.'
			},

			['key_dren_storage'] = {
				'Dren Storage Key',
				'Key to Dren storage facilities.',
				'Access to storage areas.'
			},

			['key_orvas_dren'] = {
				'Orvas Dren Key',
				'Key related to Orvas Dren.',
				'Access to specific chambers.'
			},

			['key_nelothtelnaga'] = {
				'Neloth Telnaga Key',
				'Key associated with Neloth Telnaga.',
				'Access to personal chambers.'
			},

			['key_keelraniur'] = {
				'Keelraniur Key',
				'Key related to Keelraniur.',
				'Access to specific areas.'
			},

			['key_nedhelas'] = {
				'Nedhelas Key',
				'Key associated with Nedhelas.',
				'Access to restricted locations.'
			},

			['key_fedar'] = {
				'Fedar Key',
				'Key related to Fedar.',
				'Access to personal chambers.'
			},

			['key_sethan'] = {
				'Sethan Key',
				'Key associated with Sethan.',
				'Access to specific areas.'
			},

			['key_telbranoratower'] = {
				'Telbrano Tower Key',
				'Key to Telbrano tower.',
				'Access to tower chambers.'
			},

			['ministry_truth_ext'] = {
				'Ministry Truth Exterior Key',
				'Key to exterior ministry truth doors.',
				'Access to outer ministry areas.'
			},

			['misc_de_goblet_04_dagoth'] = {
				'Dagoth Goblet',
				'Goblet with unique Dagoth design.',
				'Decorative and ceremonial.'
			},

			['key_tel_aruhn_slave1'] = {
				'Tel Aruhn Slave Key',
				'Key to Tel Aruhn slave quarters.',
				'Access to slave holding areas.'
			},

			['key_savilecagekey02'] = {
				'Savile Cage Key 2',
				'Second key to savile cages.',
				'Additional animal enclosure access.'
			},

			['key_archcanon_private'] = {
				'Archcanon Private Key',
				"Key to archcanon's private chambers.",
				'Access to restricted areas.'
			},

			['key_vivec_secret'] = {
				'Vivec Secret Key',
				'Key to hidden Vivec passages.',
				'Access to secret locations.'
			},

			['misc_wraithguard_no_equip'] = {
				'Wraithguard Item',
				'Special item with unique properties.',
				'Cannot be equipped normally.'
			},

			['key_gro-bagrat'] = {
				'Gro-Bagrat Key',
				'Key related to Gro-Bagrat.',
				'Access to specific areas.'
			},

			['misc_skooma_vial'] = {
				'Skooma Vial',
				'Vial containing Skooma substance.',
				'Illicit substance container.'
			},

			['key_shipwreck9-11'] = {
				'Shipwreck Key',
				'Key related to shipwreck site.',
				'Access to underwater areas.'
			},

			['key_varostorage'] = {
				'Varo Storage Key',
				'Key to Varo storage facilities.',
				'Access to storage areas.'
			},

			['key_dreynos'] = {
				'Dreynos Key',
				'Key related to Dreynos.',
				'Access to specific locations.'
			},

			['key_ienasa'] = {
				'Ienasa Key',
				'Key associated with Ienasa.',
				'Access to personal chambers.'
			},

			['key_ulvil'] = {
				'Ulvil Key',
				'Key related to Ulvil.',
				'Access to restricted areas.'
			},

			['key_varoprivate'] = {
				'Varo Private Key',
				"Key to Varo's private quarters.",
				'Access to personal chambers.'
			},

			['misc_argonianhead_01'] = {
				'Argonian Head',
				'Statue or decorative head of an Argonian.',
				'Ornamental piece.'
			},

			['artifact_bittercup_01'] = {
				'Bittercup Artifact',
				'Ancient artifact with unique properties.',
				'Of historical significance.'
			},

			['misc_de_lute_01'] = {
				'Decorative Lute',
				'Musical instrument with ornate design.',
				'Used for playing music.'
			},

			['misc_shears_01'] = {
				'Shears',
				'Tool for cutting and trimming.',
				'Gardening or crafting tool.'
			},

			['misc_rollingpin_01'] = {
				'Rolling Pin',
				'Kitchen tool for rolling dough.',
				'Baking accessory.'
			},

			['misc_de_drum_01'] = {
				'Decorative Drum',
				'Musical instrument with artistic design.',
				'Used for percussion.'
			},

			['misc_spool_01'] = {
				'Spool',
				'Tool for winding thread or string.',
				'Crafting accessory.'
			},

			['misc_de_drum_02'] = {
				'Decorative Drum 2',
				'Second variant of ornate drum.',
				'Percussion instrument.'
			},

			['key_mette'] = {
				'Mette Key',
				'Key related to Mette.',
				'Access to specific areas.'
			},

			['key_itar'] = {
				'Itar Key',
				'Key associated with Itar.',
				'Access to restricted locations.'
			},

			['key_anja'] = {
				'Anja Key',
				'Key related to Anja.',
				'Access to personal chambers.'
			},

			['key_cabin'] = {
				'Cabin Key',
				'Key to cabin doors.',
				'Access to cabin interior.'
			},

			['misc_com_bottle_14_float'] = {
				'Floating Bottle',
				'Special bottle with unique properties.',
				'Unusual container.'
			},

			['key_shilipuran'] = {
				'Shilipuran Key',
				'Key related to Shilipuran.',
				'Access to specific areas.'
			},

			['key_assi'] = {
				'Assi Key',
				'Key associated with Assi.',
				'Access to restricted locations.'
			},

			['key_kind'] = {
				'Kind Key',
				'Key related to Kind.',
				'Access to personal chambers.'
			},

			['key_galmis'] = {
				'Galmis Key',
				'Key associated with Galmis.',
				'Access to specific areas.'
			},

			['key_fals'] = {
				'Fals Key',
				'Key related to Fals.',
				'Access to restricted locations.'
			},

			['key_tureynul'] = {
				'Tureynul Key',
				'Key associated with Tureynul.',
				'Access to personal chambers.'
			},

			['key_yagram'] = {
				'Yagram Key',
				'Key related to Yagram.',
				'Access to specific areas.'
			},

			['key_vivec_arena_cell'] = {
				'Vivec Arena Cell Key',
				'Key to Vivec arena cells.',
				'Access to arena holding cells.'
			},

			['key_olms_storage'] = {
				'Olms Storage Key',
				'Key to Olms storage facilities.',
				'Access to storage areas.'
			},

			['key_vorarhelas'] = {
				'Vorarhelas Key',
				'Key related to Vorarhelas.',
				'Access to specific locations.'
			},

			['misc_dwrv_goblet10_tgcp'] = {
				'Dwemer Goblet TGCP',
				'Special variant of Dwemer goblet.',
				'Unique design.'
			},

			['key_tgbt'] = {
				'TGBT Key',
				'Key related to TGBT.',
				'Access to specific areas.'
			},

			['key_neranomanor'] = {
				'Nerano Manor Key',
				'Key to Nerano manor.',
				'Access to manor grounds.'
			},

			['key_ald_redaynia'] = {
				'Ald Redaynia Key',
				'Key related to Ald Redaynia.',
				'Access to specific locations.'
			},

			['key_berandas'] = {
				'Berandas Key',
				'Key related to Berandas.',
				'Access to specific locations.'
			},

			['key_divayth00'] = {
				'Divayth Key 00',
				'First key associated with Divayth.',
				'Access to personal chambers.'
			},

			['key_divayth01'] = {
				'Divayth Key 01',
				'Second key associated with Divayth.',
				'Access to restricted areas.'
			},

			['key_divayth02'] = {
				'Divayth Key 02',
				'Third key associated with Divayth.',
				'Access to additional chambers.'
			},

			['key_divayth03'] = {
				'Divayth Key 03',
				'Fourth key associated with Divayth.',
				'Access to special areas.'
			},

			['key_divayth04'] = {
				'Divayth Key 04',
				'Fifth key associated with Divayth.',
				'Access to hidden chambers.'
			},

			['key_divayth05'] = {
				'Divayth Key 05',
				'Sixth key associated with Divayth.',
				'Access to secret locations.'
			},

			['key_divayth06'] = {
				'Divayth Key 06',
				'Seventh key associated with Divayth.',
				'Access to exclusive areas.'
			},

			['misc_dwrv_artifact70'] = {
				'Dwemer Artifact 70',
				'Advanced Dwemer artifact piece.',
				'Highly valuable relic.'
			},

			['misc_dwrv_artifact80'] = {
				'Dwemer Artifact 80',
				'Rare Dwemer artifact fragment.',
				'Of great historical importance.'
			},

			['key_odros'] = {
				'Odros Key',
				'Key related to Odros.',
				'Access to specific areas.'
			},

			['key_eldrar'] = {
				'Eldrar Key',
				'Key associated with Eldrar.',
				'Access to personal chambers.'
			},

			['key_alvur'] = {
				'Alvur Key',
				'Key related to Alvur.',
				'Access to restricted locations.'
			},

			['index_andra'] = {
				'Andra Index',
				'Index document related to Andra.',
				'Contains important information.'
			},

			['index_beran'] = {
				'Beran Index',
				'Index document related to Beran.',
				'Contains valuable records.'
			},

			['index_falas'] = {
				'Falas Index',
				'Index document related to Falas.',
				'Contains historical data.'
			},

			['index_falen'] = {
				'Falen Index',
				'Index document related to Falen.',
				'Contains important entries.'
			},

			['index_hlor'] = {
				'Hlor Index',
				'Index document related to Hlor.',
				'Contains relevant information.'
			},

			['index_indo'] = {
				'Indo Index',
				'Index document related to Indo.',
				'Contains key records.'
			},

			['index_maran'] = {
				'Maran Index',
				'Index document related to Maran.',
				'Contains essential data.'
			},

			['index_roth'] = {
				'Roth Index',
				'Index document related to Roth.',
				'Contains important records.'
			},

			['index_telas'] = {
				'Telas Index',
				'Index document related to Telas.',
				'Contains historical data.'
			},

			['index_valen'] = {
				'Valen Index',
				'Index document related to Valen.',
				'Contains valuable entries.'
			},

			['key_morvaynmanor'] = {
				'Morvayn Manor Key',
				'Key to Morvayn manor.',
				'Access to manor grounds.'
			},

			['key_gshipwreck'] = {
				'G Shipwreck Key',
				'Key related to shipwreck site.',
				'Access to underwater areas.'
			},

			['misc_uniq_egg_of_gold'] = {
				'Unique Egg of Gold',
				'Rare golden egg artifact.',
				'Of great value.'
			},

			['key_nelothtelnaga2'] = {
				'Neloth Telnaga Key 2',
				'Second key related to Neloth Telnaga.',
				'Access to additional chambers.'
			},

			['key_nelothtelnaga3'] = {
				'Neloth Telnaga Key 3',
				'Third key related to Neloth Telnaga.',
				'Access to special areas.'
			},

			['key_nelothtelnaga4'] = {
				'Neloth Telnaga Key 4',
				'Fourth key related to Neloth Telnaga.',
				'Access to hidden chambers.'
			},

			['key_adibael'] = {
				'Adibael Key',
				'Key related to Adibael.',
				'Access to specific locations.'
			},

			['key_omani_01'] = {
				'Omani Key',
				'Key associated with Omani.',
				'Access to personal chambers.'
			},

			['key_redoran_treasury'] = {
				'Redoran Treasury Key',
				'Key to Redoran treasury.',
				'Access to valuable storage.'
			},

			['key_ahnassi'] = {
				'Ahnassi Key',
				'Key related to Ahnassi.',
				'Access to personal quarters.'
			},

			['misc_lw_bowl'] = {
				'Lightwood Bowl',
				'Bowl crafted from lightwood.',
				'Durable and lightweight.'
			},

			['misc_lw_cup'] = {
				'Lightwood Cup',
				'Cup made of lightwood material.',
				'Elegant drinking vessel.'
			},

			['misc_lw_flask'] = {
				'Lightwood Flask',
				'Flask crafted from lightwood.',
				'Secure storage container.'
			},

			['misc_lw_platter'] = {
				'Lightwood Platter',
				'Large serving platter made of lightwood.',
				'Ideal for presentation.'
			},

			['key_vivec_hlaalu_cell'] = {
				'Vivec Hlaalu Cell Key',
				'Key to Hlaalu cells in Vivec.',
				'Access to holding cells.'
			},

			['key_vivec_redoran_cell'] = {
				'Vivec Redoran Cell Key',
				'Key to Redoran cells in Vivec.',
				'Access to detention areas.'
			},

			['key_vivec_telvanni_cell'] = {
				'Vivec Telvanni Cell Key',
				'Key to Telvanni cells in Vivec.',
				'Access to prison cells.'
			},

			['key_slave_addamasartus'] = {
				'Addamasartus Slave Key',
				'Key to Addamasartus slave quarters.',
				'Access to slave holding areas.'
			},

			['misc_com_plate_06_tgrc'] = {
				'TGRC Special Plate',
				'Special variant of standard dining plate.',
				'Custom design plate.'
			},

			['misc_com_plate_02_tgrc'] = {
				'TGRC Medium Plate',
				'TGRC variant of medium-sized plate.',
				'Custom utility plate.'
			},

			['misc_hook'] = {
				'Hanging Hook',
				'Metal hook for hanging items.',
				'Utility mounting tool.'
			},

			['misc_de_lute_01_phat'] = {
				'PHAT Decorative Lute',
				'Ornate lute with special design.',
				'Musical instrument.'
			},

			['key_balmorag_tong_01'] = {
				'Balmorag Tong Key 1',
				'First key to Balmorag Tong facilities.',
				'Access to Tong areas.'
			},

			['key_balmorag_tong_02'] = {
				'Balmorag Tong Key 2',
				'Second key to Balmorag Tong facilities.',
				'Additional access key.'
			},

			['misc_dwrv_artifact_ils'] = {
				'Dwemer ILS Artifact',
				'Special Dwemer artifact component.',
				'Mechanical relic.'
			},

			['key_aldruhn_underground'] = {
				'Aldruhn Underground Key',
				'Key to Aldruhn underground areas.',
				'Access to subterranean facilities.'
			},

			['misc_com_bucket_01_float'] = {
				'Floating Bucket',
				'Special bucket with unique properties.',
				'Utility container.'
			},

			['misc_com_bottle_07_float'] = {
				'Floating Bottle 07',
				'Special bottle with floating capability.',
				'Unique storage container.'
			},

			['key_desele'] = {
				'Desele Key',
				'Key related to Desele.',
				'Access to specific areas.'
			},

			['key_Suran_slave'] = {
				'Suran Slave Key',
				'Key to Suran slave quarters.',
				'Access to slave holding areas.'
			},

			['Key_SN_Warehouse'] = {
				'SN Warehouse Key',
				'Key to SN Warehouse.',
				'Access to warehouse facilities.'
			},

			['key_menta_na'] = {
				'Menta Na Key',
				'Key related to Menta Na.',
				'Access to specific locations.'
			},

			['key_marvani_tomb'] = {
				'Marvani Tomb Key',
				'Key to Marvani tomb.',
				'Access to tomb chambers.'
			},
			['misc_com_bucket_boe_UNI'] = {
				'Special BOE Bucket',
				'Unique bucket with special design.',
				'Utility container.'
			},

			['key_minabislaves_01'] = {
				'Minabis Slaves Key',
				'Key to Minabis slave quarters.',
				'Access to slave holding areas.'
			},

			['key_ebon_tomb'] = {
				'Ebon Tomb Key',
				'Key to Ebon Tomb entrance.',
				'Access to tomb chambers.'
			},

			['key_draramu'] = {
				'Draramu Key',
				'Key related to Draramu.',
				'Access to specific locations.'
			},

			['key_oritius'] = {
				'Oritius Key',
				'Key associated with Oritius.',
				'Access to personal chambers.'
			},

			['key_saetring'] = {
				'Saetring Key',
				'Key related to Saetring.',
				'Access to specific areas.'
			},

			['key_molagmarslaves_01'] = {
				'Molagmar Slaves Key',
				'Key to Molagmar slave quarters.',
				'Access to slave holding areas.'
			},

			['key_kudanatslaves_01'] = {
				'Kudanat Slaves Key',
				'Key to Kudanat slave quarters.',
				'Access to slave holding areas.'
			},

			['key_yakanalitslaves_01'] = {
				'Yakanalit Slaves Key',
				'Key to Yakanalit slave quarters.',
				'Access to slave holding areas.'
			},

			['key_GatewayInnslaves_01'] = {
				'Gateway Inn Slaves Key',
				'Key to Gateway Inn slave quarters.',
				'Access to slave holding areas.'
			},

			['key_sinsibadonslaves_01'] = {
				'Sinsibadon Slaves Key',
				'Key to Sinsibadon slave quarters.',
				'Access to slave holding areas.'
			},

			['key_abebaalslaves_01'] = {
				'Abebaa Slaves Key',
				'Key to Abebaa slave quarters.',
				'Access to slave holding areas.'
			},

			['key_zainsipiluslaves_01'] = {
				'Zainsipilus Slaves Key',
				'Key to Zainsipilus slave quarters.',
				'Access to slave holding areas.'
			},

			['key_drenplantationslaves_01'] = {
				'Dren Plantation Slaves Key',
				'Key to Dren Plantation slave quarters.',
				'Access to slave holding areas.'
			},

			['key_aharunartusslaves_01'] = {
				'Aharunartus Slaves Key',
				'Key to Aharunartus slave quarters.',
				'Access to slave holding areas.'
			},

			['key_telvosjailslaves_01'] = {
				'Telvos Jail Slaves Key',
				'Key to Telvos Jail slave quarters.',
				'Access to slave holding areas.'
			},

			['key_sadrithmoraslaves_01'] = {
				'Sadrith Moras Slaves Key',
				'Key to Sadrith Moras slave quarters.',
				'Access to slave holding areas.'
			},

			['key_shushanslaves_01'] = {
				'Shushan Slaves Key',
				'Key to Shushan slave quarters.',
				'Access to slave holding areas.'
			},

			['key_rotheranslaves_01'] = {
				'Rotheran Slaves Key',
				'Key to Rotheran slave quarters.',
				'Access to slave holding areas.'
			},

			['key_addamasartusslaves_01'] = {
				'Addamasartus Slaves Key',
				'Key to Addamasartus slave quarters.',
				'Access to slave holding areas.'
			},

			['key_zebabislaves_01'] = {
				'Zebabis Slaves Key',
				'Key to Zebabis slave quarters.',
				'Access to slave holding areas.'
			},

			['key_hinnabislaves_01'] = {
				'Hinnabis Slaves Key',
				'Key to Hinnabis slave quarters.',
				'Access to slave holding areas.'
			},

			['key_telaruhnslaves_01'] = {
				'Telaruhn Slaves Key',
				'Key to Telaruhn slave quarters.',
				'Access to slave holding areas.'
			},

			['key_calderaslaves_01'] = {
				'Caldera Slaves Key',
				'Key to Caldera slave quarters.',
				'Access to slave holding areas.'
			},

			['key_vivectelvannislaves_01'] = {
				'Vivec Telvanni Slaves Key',
				'Key to Vivec Telvanni slave quarters.',
				'Access to slave holding areas.'
			},

			['key_panatslaves_01'] = {
				'Pana Slaves Key',
				'Key to Pana slave quarters.',
				'Access to slave holding areas.'
			},

			['key_saturanslaves_01'] = {
				'Saturan Slaves Key',
				'Key to Saturan slave quarters.',
				'Access to slave holding areas.'
			},

			['key_shaadniusslaves_01'] = {
				'Shaadnius Slaves Key',
				'Key to Shaadnius slave quarters.',
				'Access to slave holding areas.'
			},

			['key_suranslaves_01'] = {
				'Suran Slaves Key',
				'Key to Suran slave quarters.',
				'Access to slave holding areas.'
			},

			['key_telbranoraslaves_01'] = {
				'Telbranor Slaves Key',
				'Key to Telbranor slave quarters.',
				'Access to slave holding areas.'
			},

			['key_viveclizardheadslave_01'] = {
				'Vivec Lizardhead Slave Key',
				'Key to Lizardhead slave quarters in Vivec.',
				'Access to slave holding areas.'
			},

			['key_habinbaesslaves_01'] = {
				'Habinbaes Slaves Key',
				'Key to Habinbaes slave quarters.',
				'Access to slave holding areas.'
			},

			['key_assarnudslaves_01'] = {
				'Assarnud Slaves Key',
				'Key to Assarnud slave quarters.',
				'Access to slave holding areas.'
			},

			['key_Llethri'] = {
				'Llethri Key',
				'Key related to Llethri.',
				'Access to specific locations.'
			},

			['key_shushishislaves'] = {
				'Shushishi Slaves Key',
				'Key to Shushishi slave quarters.',
				'Access to slave holding areas.'
			},

			['key_shaadnius'] = {
				'Shaadnius Key',
				'Key related to Shaadnius.',
				'Access to specific areas.'
			},

			['misc_Beluelle_silver_bowl'] = {
				'Beluelle Silver Bowl',
				'Ornate silver bowl crafted by Beluelle.',
				'Fine dining ware.'
			},

			['key_eldafire'] = {
				'Eldafire Key',
				'Key related to Eldafire.',
				'Access to specific locations.'
			},

			['key_farusea_salas'] = {
				'Farusea Salas Key',
				'Key related to Farusea Salas.',
				'Access to specific areas.'
			},

			['key_relien_rirne'] = {
				'Relien Rirne Key',
				'Key related to Relien Rirne.',
				'Access to specific locations.'
			},
			['key_sirilonwe'] = {
				'Sirilonwe Key',
				'Key related to Sirilonwe.',
				'Access to specific locations.'
			},

			['key_fg_nchur'] = {
				'FG Nchur Key',
				'Key related to FG Nchur.',
				'Access to specific areas.'
			},

			['misc_Skull_Llevule'] = {
				'Llevule Skull',
				'Skull artifact of Llevule.',
				'Ancient relic.'
			},

			['key_Odibaal'] = {
				'Odibaal Key',
				'Key related to Odibaal.',
				'Access to specific locations.'
			},

			['key_ashurninibi'] = {
				'Ashurninibi Key',
				'Key related to Ashurninibi.',
				'Access to personal chambers.'
			},

			['key_ashurninibi_lost'] = {
				'Lost Ashurninibi Key',
				'Lost key belonging to Ashurninibi.',
				'Recovered access key.'
			},

			['key_ashalmawia_prisoncell'] = {
				'Ashalmawia Prison Cell Key',
				'Key to Ashalmawia prison cell.',
				'Access to detention area.'
			},

			['key_drarayne_thelas'] = {
				'Drarayne Thelas Key',
				'Key related to Drarayne Thelas.',
				'Access to specific areas.'
			},

			['key_dulnea_ralaal'] = {
				'Dulnea Ralaal Key',
				'Key related to Dulnea Ralaal.',
				'Access to personal chambers.'
			},

			['key_ralen_hlaalo'] = {
				'Ralen Hlaalo Key',
				'Key related to Ralen Hlaalo.',
				'Access to specific locations.'
			},

			['key_nileno_dorvayn'] = {
				'Nileno Dorvayn Key',
				'Key related to Nileno Dorvayn.',
				'Access to restricted areas.'
			},

			['devote_Brinne_Dust_00'] = {
				'Brinne Dust',
				'Special dust related to Brinne.',
				'Alchemical component.'
			},

			['devote_Nan_Dust_00'] = {
				'Nan Dust',
				'Special dust related to Nan.',
				'Alchemical ingredient.'
			},

			['key_Ibardad'] = {
				'Ibardad Key',
				'Key related to Ibardad.',
				'Access to specific areas.'
			},

			['key_ibardad_tomb'] = {
				'Ibardad Tomb Key',
				'Key to Ibardad tomb.',
				'Access to burial chambers.'
			},

			['key_hanarai_assutlanipal'] = {
				'Hanarai Assutlanipal Key',
				'Key related to Hanarai Assutlanipal.',
				'Access to specific locations.'
			},

			['misc_com_metal_plate_07_UNI2'] = {
				'Unique Metal Plate 07 Variant 2',
				'Special metal plate variant.',
				'Utility item.'
			},

			['misc_com_metal_plate_07_UNI1'] = {
				'Unique Metal Plate 07 Variant 1',
				'Unique metal plate design.',
				'Decorative plate.'
			},

			['misc_com_wood_fork_UNI1'] = {
				'Unique Wooden Fork Variant 1',
				'Special wooden fork design.',
				'Dining utensil.'
			},

			['misc_com_wood_spoon_01_UNI1'] = {
				'Unique Wooden Spoon Variant 1',
				'Special wooden spoon design.',
				'Dining utensil.'
			},

			['misc_com_wood_knife_UNI1'] = {
				'Unique Wooden Knife Variant 1',
				'Special wooden knife design.',
				'Cutting utensil.'
			},

			['misc_com_wood_knife_UNI2'] = {
				'Unique Wooden Knife Variant 2',
				'Second variant of unique wooden knife.',
				'Cutting tool.'
			},

			['misc_com_wood_spoon_01_UNI2'] = {
				'Unique Wooden Spoon Variant 2',
				'Second variant of unique wooden spoon.',
				'Dining utensil.'
			},

			['misc_com_wood_fork_UNI2'] = {
				'Unique Wooden Fork Variant 2',
				'Second variant of unique wooden fork.',
				'Dining utensil.'
			},

			['Misc_fakesoulgem'] = {
				'Fake Soul Gem',
				'Counterfeit soul gem container.',
				'Imitation magical item.'
			},

			['key_Sandas'] = {
				'Sandas Key',
				'Key related to Sandas.',
				'Access to specific areas.'
			},

			['key_aurane1'] = {
				'Aurane Key 1',
				'First key related to Aurane.',
				'Access to personal chambers.'
			},

			['key_Arenim'] = {
				'Arenim Key',
				'Key related to Arenim.',
				'Access to specific locations.'
			},

			['key_odral_helvi'] = {
				'Odrall Helvi Key',
				'Key related to Odrall Helvi.',
				'Access to restricted areas.'
			},

			['key_assi_serimilk'] = {
				'Assi Serimilk Key',
				'Key related to Assi Serimilk.',
				'Access to personal quarters.'
			},

			['Misc_Uni_Pillow_02'] = {
				'Unique Pillow 02',
				'Special decorative pillow.',
				'Furnishing item.'
			},

			['key_cell_buckmoth_01'] = {
				'Buckmoth Cell Key',
				'Key to Buckmoth cell.',
				'Access to detention area.'
			},

			['key_cell_ebonheart_01'] = {
				'Ebonheart Cell Key',
				'Key to Ebonheart cell.',
				'Access to prison area.'
			},

			['key_hlaalo_manor'] = {
				'Hlaalo Manor Key',
				'Key to Hlaalo manor.',
				'Access to manor grounds.'
			},

			['key_Ashirbadon'] = {
				'Ashirbadon Key',
				'Key related to Ashirbadon.',
				'Access to specific locations.'
			},

			['devote_Lyngas_Dust_00'] = {
				'Lyngas Dust',
				'Special dust related to Lyngas.',
				'Alchemical component.'
			},

			['devote_bone_Pop00'] = {
				'Bone Fragment',
				'Ancient bone fragment.',
				'Alchemical ingredient.'
			},

			['key_Senim_tomb'] = {
				'Senim Tomb Key',
				'Key to Senim tomb.',
				'Access to burial chambers.'
			},

			['key_Gimothran'] = {
				'Gimothran Key',
				'Key related to Gimothran.',
				'Access to specific areas.'
			},

			['Misc_Com_Bucket_Metal'] = {
				'Metal Bucket',
				'Sturdy metal bucket.',
				'Utility container.'
			},

			['key_murudius_01'] = {
				'Murudius Key',
				'Key related to Murudius.',
				'Access to specific locations.'
			},

			['misc_clothbolt_01'] = {
				'Cloth Bolt 01',
				'Standard cloth bolt material.',
				'Crafting component.'
			},

			['misc_clothbolt_02'] = {
				'Cloth Bolt 02',
				'Second variant of cloth bolt.',
				'Crafting material.'
			},

			['misc_clothbolt_03'] = {
				'Cloth Bolt 03',
				'Third variant of cloth bolt.',
				'Textile component.'
			},

			['key_Punsabanit'] = {
				'Punsabanit Key',
				'Key related to Punsabanit.',
				'Access to specific areas.'
			},

			['key_yinglingbasement'] = {
				'Yingling Basement Key',
				'Key to Yingling basement.',
				'Access to lower levels.'
			},

			['key_elmussadamori'] = {
				'Elmussadamori Key',
				'Key related to Elmussadamori.',
				'Access to specific locations.'
			},

			['key_volrina_01'] = {
				'Volrina Key',
				'Key related to Volrina.',
				'Access to personal chambers.'
			},

			['key_FQT'] = {
				'FQT Key',
				'Key related to FQT.',
				'Access to specific areas.'
			},

			['Misc_Inkwell'] = {
				'Inkwell',
				'Container for holding ink.',
				'Writing tool.'
			},

			['Misc_Quill'] = {
				'Quill',
				'Feather used for writing.',
				'Writing implement.'
			},

			['key_skeleton'] = {
				'Skeleton Key',
				'Universal key for basic locks.',
				'Master key variant.'
			},

			['key_hvaults1'] = {
				'HVaults Key 1',
				'Key to first set of vaults.',
				'Access to secure storage.'
			},

			['key_hvaults2'] = {
				'HVaults Key 2',
				'Key to second set of vaults.',
				'Access to additional storage.'
			},

			['misc_dwrv_cursed_coin00'] = {
				'Cursed Dwemer Coin',
				'Ancient Dwemer coin with curse.',
				'Unlucky artifact.'
			},

			['key_Indaren'] = {
				'Indaren Key',
				'Key related to Indaren.',
				'Access to specific areas.'
			},

			['key_Venim'] = {
				'Venim Key',
				'Key related to Venim.',
				'Access to personal chambers.'
			},

			['key_Aralen'] = {
				'Aralen Key',
				'Key related to Aralen.',
				'Access to specific locations.'
			},

			['key_Sarys_chest'] = {
				'Sarys Chest Key',
				'Key to Sarys chest.',
				'Access to locked container.'
			},

			['key_Tharys_chest'] = {
				'Tharys Chest Key',
				'Key to Tharys chest.',
				'Access to locked container.'
			},

			['key_Thelas_chest'] = {
				'Thelas Chest Key',
				'Key to Thelas chest.',
				'Access to locked container.'
			},

			['key_Othrelas_door'] = {
				'Othrelas Door Key',
				'Key to Othrelas door.',
				'Access to restricted area.'
			},

			['Key_Arano_door'] = {
				'Arano Door Key',
				'Key to Arano door.',
				'Access to private quarters.'
			},

			['Key_Arano_chest'] = {
				'Arano Chest Key',
				'Key to Arano chest.',
				'Access to locked container.'
			},

			['key_Andrethi_chest'] = {
				'Andrethi Chest Key',
				'Key to Andrethi chest.',
				'Access to locked container.'
			},

			['key_Heran'] = {
				'Heran Key',
				'Key related to Heran.',
				'Access to specific areas.'
			},

			['key_Lleran_tomb'] = {
				'Lleran Tomb Key',
				'Key to Lleran tomb.',
				'Access to burial chambers.'
			},

			['key_Aran_tomb'] = {
				'Aran Tomb Key',
				'Key to Aran tomb.',
				'Access to burial grounds.'
			},

			['key_Sandas_tomb'] = {
				'Sandas Tomb Key',
				'Key to Sandas tomb.',
				'Access to burial chambers.'
			},

			['key_Sarano_tomb'] = {
				'Sarano Tomb Key',
				'Key to Sarano tomb.',
				'Access to burial grounds.'
			},

			['key_Sarano_chest'] = {
				'Sarano Chest Key',
				'Key to Sarano chest.',
				'Access to locked container.'
			},

			['key_Saren_chest'] = {
				'Saren Chest Key',
				'Key to Saren chest.',
				'Access to locked container.'
			},

			['key_Saren_tomb'] = {
				'Saren Tomb Key',
				'Key to Saren tomb.',
				'Access to burial chambers.'
			},

			['key_Vandus_tomb'] = {
				'Vandus Tomb Key',
				'Key to Vandus tomb.',
				'Access to burial grounds.'
			},

			['key_Maren_tomb'] = {
				'Maren Tomb Key',
				'Key to Maren tomb.',
				'Access to burial chambers.'
			},

			['key_Raviro_tomb'] = {
				'Raviro Tomb Key',
				'Key to Raviro tomb.',
				'Access to burial grounds.'
			},

			['key_Andalen_tomb'] = {
				'Andalen Tomb Key',
				'Key to Andalen tomb.',
				'Access to burial chambers.'
			},

			['key_Andalen_chest'] = {
				'Andalen Chest Key',
				'Key to Andalen chest.',
				'Access to locked container.'
			},

			['key_Arenim_chest'] = {
				'Arenim Chest Key',
				'Key to Arenim chest.',
				'Access to locked container.'
			},

			['key_Ravel_tomb'] = {
				'Ravel Tomb Key',
				'Key to Ravel tomb.',
				'Access to burial chambers.'
			},

			['key_Ravel_chest'] = {
				'Ravel Chest Key',
				'Key to Ravel chest.',
				'Access to locked container.'
			},

			['key_Savel_tomb'] = {
				'Savel Tomb Key',
				'Key to Savel tomb.',
				'Access to burial grounds.'
			},

			['key_Indalen_tomb'] = {
				'Indalen Tomb Key',
				'Key to Indalen tomb.',
				'Access to burial chambers.'
			},

			['key_Norvayn_tomb'] = {
				'Norvayn Tomb Key',
				'Key to Norvayn tomb.',
				'Access to burial grounds.'
			},

			['key_Norvayn_chest'] = {
				'Norvayn Chest Key',
				'Key to Norvayn chest.',
				'Access to locked container.'
			},

			['key_Aryon_chest'] = {
				'Aryon Chest Key',
				'Key to Aryon chest.',
				'Access to locked container.'
			},

			['key_Fadathram_tomb'] = {
				'Fadathram Tomb Key',
				'Key to Fadathram tomb.',
				'Access to burial chambers.'
			},

			['key_Helas_tomb'] = {
				'Helas Tomb Key',
				'Key to Helas tomb.',
				'Access to burial grounds.'
			},

			['key_Thalas_tomb'] = {
				'Thalas Tomb Key',
				'Key to Thalas tomb.',
				'Access to burial chambers.'
			},

			['key_Andas_tomb'] = {
				'Andas Tomb Key',
				'Key to Andas tomb.',
				'Access to burial grounds.'
			},

			['key_Andules_chest'] = {
				'Andules Chest Key',
				'Key to Andules chest.',
				'Access to locked container.'
			},

			['Key_Gimothran_chest'] = {
				'Gimothran Chest Key',
				'Key to Gimothran chest.',
				'Access to locked container.'
			},

			['key_Gimothran_tomb'] = {
				'Gimothran Tomb Key',
				'Key to Gimothran tomb.',
				'Access to burial chambers.'
			},

			['key_Ienith_tomb'] = {
				'Ienith Tomb Key',
				'Key to Ienith tomb.',
				'Access to burial grounds.'
			},

			['key_Ienith_chest'] = {
				'Ienith Chest Key',
				'Key to Ienith chest.',
				'Access to locked container.'
			},

			['key_Thiralas_tomb'] = {
				'Thiralas Tomb Key',
				'Key to Thiralas tomb.',
				'Access to burial chambers.'
			},

			['key_Baram_tomb'] = {
				'Baram Tomb Key',
				'Key to Baram tomb.',
				'Access to burial grounds.'
			},

			['key_Dreloth_tomb'] = {
				'Dreloth Tomb Key',
				'Key to Dreloth tomb.',
				'Access to burial chambers.'
			},

			['key_Omaren_chest'] = {
				'Omaren Chest Key',
				'Key to Omaren chest.',
				'Access to locked container.'
			},

			['key_Sadryon_tomb'] = {
				'Sadryon Tomb Key',
				'Key to Sadryon tomb.',
				'Access to burial chambers.'
			},

			['key_Verelnim_tomb'] = {
				'Verelnim Tomb Key',
				'Key to Verelnim tomb.',
				'Access to burial grounds.'
			},

			['key_Falas_tomb'] = {
				'Falas Tomb Key',
				'Key to Falas tomb.',
				'Access to burial chambers.'
			},

			['key_Falas_chest'] = {
				'Falas Chest Key',
				'Key to Falas chest.',
				'Access to locked container.'
			},

			['key_Llervu'] = {
				'Llervu Key',
				'Key related to Llervu.',
				'Access to specific areas.'
			},

			['key_Rethandus_tomb'] = {
				'Rethandus Tomb Key',
				'Key to Rethandus tomb.',
				'Access to burial grounds.'
			},

			['key_Rethandus_chest'] = {
				'Rethandus Chest Key',
				'Key to Rethandus chest.',
				'Access to locked container.'
			},

			['key_Rothan_tomb'] = {
				'Rothan Tomb Key',
				'Key to Rothan tomb.',
				'Access to burial chambers.'
			},

			['key_Dareleth_tomb'] = {
				'Dareleth Tomb Key',
				'Key to Dareleth tomb.',
				'Access to burial grounds.'
			},

			['key_Salvel_tomb'] = {
				'Salvel Tomb Key',
				'Key to Salvel tomb.',
				'Access to burial chambers.'
			},

			['key_Salvel_chest'] = {
				'Salvel Chest Key',
				'Key to Salvel chest.',
				'Access to locked container.'
			},

			['key_Nerano_chest'] = {
				'Nerano Chest Key',
				'Key to Nerano chest.',
				'Access to locked container.'
			},

			['key_Andavel_tomb'] = {
				'Andavel Tomb Key',
				'Key to Andavel tomb.',
				'Access to burial grounds.'
			},

			['Key_Dralas_tomb'] = {
				'Dralas Tomb Key',
				'Key to Dralas tomb.',
				'Access to burial chambers.'
			},

			['Key_Dralas_chest'] = {
				'Dralas Chest Key',
				'Key to Dralas chest.',
				'Access to locked container.'
			},

			['key_Nelas_chest'] = {
				'Nelas Chest Key',
				'Key to Nelas chest.',
				'Access to locked container.'
			},

			['key_Omalen_tomb'] = {
				'Omalen Tomb Key',
				'Key to Omalen tomb.',
				'Access to burial grounds.'
			},

			['key_Orethi_tomb'] = {
				'Orethi Tomb Key',
				'Key to Orethi tomb.',
				'Access to burial chambers.'
			},

			['key_Sarethi_tomb'] = {
				'Sarethi Tomb Key',
				'Key to Sarethi tomb.',
				'Access to burial grounds.'
			},
			['key_Favel_chest'] = {
				'Favel Chest Key',
				'Key to Favel chest.',
				'Access to locked container.'
			},

			['key_Senim_chest'] = {
				'Senim Chest Key',
				'Key to Senim chest.',
				'Access to locked container.'
			},

			['key_widow_vabdas'] = {
				'Widow Vabdas Key',
				'Key related to Widow Vabdas.',
				'Access to personal chambers.'
			},

			['key_Galom_Daeus'] = {
				'Galom Daeus Key',
				'Key related to Galom Daeus.',
				'Access to specific areas.'
			},

			['key_Ashmelech'] = {
				'Ashmelech Key',
				'Key related to Ashmelech.',
				'Access to personal chambers.'
			},

			['key_Ashmelech_chest'] = {
				'Ashmelech Chest Key',
				'Key to Ashmelech chest.',
				'Access to locked container.'
			},

			['key_Nchuleftingth_chest'] = {
				'Nchuleftingth Chest Key',
				'Key to Nchuleftingth chest.',
				'Access to locked container.'
			},

			['key_Nchuleftingth'] = {
				'Nchuleftingth Key',
				'Key related to Nchuleftingth.',
				'Access to specific areas.'
			},

			['key_Mzahnch_chest'] = {
				'Mzahnch Chest Key',
				'Key to Mzahnch chest.',
				'Access to locked container.'
			},

			['key_Aleft_chest'] = {
				'Aleft Chest Key',
				'Key to Aleft chest.',
				'Access to locked container.'
			},

			['key_Mzanchend_chest'] = {
				'Mzanchend Chest Key',
				'Key to Mzanchend chest.',
				'Access to locked container.'
			},

			['key_Arkngthunch_chest'] = {
				'Arkngthunch Chest Key',
				'Key to Arkngthunch chest.',
				'Access to locked container.'
			},

			['key_Bthanchend_chest'] = {
				'Bthanchend Chest Key',
				'Key to Bthanchend chest.',
				'Access to locked container.'
			},

			['key_Bthuand'] = {
				'Bthuand Key',
				'Key related to Bthuand.',
				'Access to specific areas.'
			},

			['key_Mzuleft'] = {
				'Mzuleft Key',
				'Key related to Mzuleft.',
				'Access to specific locations.'
			},

			['key_Nchardahrk'] = {
				'Nchardahrk Key',
				'Key related to Nchardahrk.',
				'Access to specific areas.'
			},

			['key_Nchardahrk_chest'] = {
				'Nchardahrk Chest Key',
				'Key to Nchardahrk chest.',
				'Access to locked container.'
			},

			['key_venimmanor'] = {
				'Venim Manor Key',
				'Key to Venim manor.',
				'Access to manor grounds.'
			},

			['key_rvaults1'] = {
				'R Vaults Key 1',
				'Key to first set of R vaults.',
				'Access to secure storage.'
			},

			['key_table_Mudan00'] = {
				'Mudan Table Key',
				'Key related to Mudan table.',
				'Access to specific mechanism.'
			},

			['key_door_Mudan00'] = {
				'Mudan Door Key',
				'Key related to Mudan door mechanism.',
				'Access to specific entrance.'
			},

			['key_Mudan_Dragon'] = {
				'Mudan Dragon Key',
				'Key related to Mudan dragon area.',
				'Access to dragon-related area.'
			},

			['key_Odirniran'] = {
				'Odirniran Key',
				'Key related to Odirniran.',
				'Access to specific locations.'
			},

			['key_dawnvault'] = {
				'Dawn Vault Key',
				'Key to Dawn Vault entrance.',
				'Access to vault chambers.'
			},

			['key_duskvault'] = {
				'Dusk Vault Key',
				'Key to Dusk Vault entrance.',
				'Access to vault chambers.'
			},

			["key_j'zhirr"] = {
				"J'zhirr Key",
				"Key related to J'zhirr.",
				'Access to specific areas.'
			},

			['misc_dwarfbone_unique'] = {
				'Unique Dwemer Bone',
				'Special bone artifact from Dwemer.',
				'Ancient relic.'
			},

			['key_tvault'] = {
				'T Vault Key',
				'Key to T Vault entrance.',
				'Access to vault chambers.'
			},

			['key_armigers_stronghold'] = {
				'Armigers Stronghold Key',
				'Key to Armigers stronghold.',
				'Access to fortified area.'
			},

			['key_thorek'] = {
				'Thorek Key',
				'Key related to Thorek.',
				'Access to personal chambers.'
			},

			['key_TV_CT'] = {
				'TV CT Key',
				'Key related to TV CT area.',
				'Access to specific location.'
			},

			['key_Private Quarters'] = {
				'Private Quarters Key',
				'Key to private living quarters.',
				'Access to personal residence.'
			},

			['misc_lw_bowl_chapel'] = {
				'Chapel Lightwood Bowl',
				'Lightwood bowl used in chapel.',
				'Religious artifact.'
			},

			['key_caryarel'] = {
				'Caryarel Key',
				'Key related to Caryarel.',
				'Access to specific areas.'
			},

			['key_Dubdilla'] = {
				'Dubdilla Key',
				'Key related to Dubdilla.',
				'Access to personal chambers.'
			},

			['Gold_Dae_cursed_001'] = {
				'Cursed Gold Dae 001',
				'Cursed gold coin of Dae origin.',
				'Unlucky currency.'
			},

			['Gold_Dae_cursed_005'] = {
				'Cursed Gold Dae 005',
				'Another variant of cursed Dae gold.',
				'Unlucky currency.'
			},

			['key_Forge of Rolamus'] = {
				'Rolamus Forge Key',
				'Key to Rolamus forge.',
				'Access to smithing area.'
			},

			['lucky_coin'] = {
				'Lucky Coin',
				'Fortunate coin with good luck properties.',
				'Charm item.'
			},

			['key_WormLord_tomb'] = {
				'WormLord Tomb Key',
				'Key to WormLord tomb.',
				'Access to burial chambers.'
			},
			['key_mebastien'] = {
				'Mebastien Key',
				'Key related to Mebastien.',
				'Access to personal chambers.'
			},

			['key_miles'] = {
				'Miles Key',
				'Key related to Miles.',
				'Access to specific areas.'
			},

			['key_Palansour'] = {
				'Palansour Key',
				'Key related to Palansour.',
				'Access to personal quarters.'
			},

			['key_miun_gei'] = {
				'Miun Gei Key',
				'Key related to Miun Gei.',
				'Access to specific locations.'
			},

			['key_brallion'] = {
				'Brallion Key',
				'Key related to Brallion.',
				'Access to restricted areas.'
			},

			['key_shashev'] = {
				'Shashev Key',
				'Key related to Shashev.',
				'Access to personal chambers.'
			},

			['key_camp'] = {
				'Camp Key',
				'Key to camp facilities.',
				'Access to camp areas.'
			},

			['key_Dura_gra-Bol'] = {
				'Dura Gra-Bol Key',
				'Key related to Dura Gra-Bol.',
				'Access to specific locations.'
			},

			['key_caius_cosades'] = {
				'Caius Cosades Key',
				'Key related to Caius Cosades.',
				'Access to personal chambers.'
			},

			['key_Rufinus_Alleius'] = {
				'Rufinus Alleius Key',
				'Key related to Rufinus Alleius.',
				'Access to specific areas.'
			},

			['misc_uni_pillow_unique'] = {
				'Unique Pillow',
				'Special decorative pillow.',
				'Furnishing item.'
			},

			['misc_goblet_dagoth'] = {
				'Dagoth Goblet',
				'Goblet associated with Dagoth.',
				'Ceremonial item.'
			},

			['misc_com_bucket_boe_UNIa'] = {
				'Bucket BOE Variant A',
				'Special bucket design A.',
				'Utility container.'
			},

			['misc_com_bucket_boe_UNIb'] = {
				'Bucket BOE Variant B',
				'Special bucket design B.',
				'Utility container.'
			},

			['key_jeanne'] = {
				'Jeanne Key',
				'Key related to Jeanne.',
				'Access to personal chambers.'
			},

			['key_bolayn'] = {
				'Bolayn Key',
				'Key related to Bolayn.',
				'Access to specific areas.'
			},

			['key_gindrala'] = {
				'Gindrala Key',
				'Key related to Gindrala.',
				'Access to personal quarters.'
			},

			['Misc_Potion_Cheap_01'] = {
				'Basic Potion',
				'Basic quality potion.',
				'Consumable item.'
			},

			['Misc_flask_grease'] = {
				'Grease Flask',
				'Flask containing grease.',
				'Utility item.'
			},

			['misc_com_silverware_knife_uni'] = {
				'Unique Silver Knife',
				'Special silver knife.',
				'Dining utensil.'
			},

			['misc_com_silverware_fork_uni'] = {
				'Unique Silver Fork',
				'Special silver fork utensil.',
				'Dining silverware.'
			},

			['misc_com_silverware_spoon_uni'] = {
				'Unique Silver Spoon',
				'Special silver spoon utensil.',
				'Dining silverware.'
			},

			['misc_imp_silverware_pitcher_uni'] = {
				'Unique Impressive Pitcher',
				'Grand silver pitcher vessel.',
				'Serving container.'
			},

			['misc_clothbolt_02_uni'] = {
				'Unique Cloth Bolt 02',
				'Special variant of cloth bolt material.',
				'Textile component.'
			},

			['misc_de_pot_redware_04_uni'] = {
				'Unique Redware Pot 04',
				'Special redware pot vessel.',
				'Decorative container.'
			},

			['misc_com_metal_plate_03_uni'] = {
				'Unique Metal Plate 03',
				'Special metal plate design.',
				'Utility item.'
			},

			['misc_dwrv_goblet00_uni'] = {
				'Unique Dwemer Goblet 00',
				'Special Dwemer-style goblet.',
				'Ancient drinking vessel.'
			},

			['misc_dwrv_goblet10_uni'] = {
				'Unique Dwemer Goblet 10',
				'Another variant of Dwemer goblet.',
				'Ancient drinking vessel.'
			},

			['misc_dwrv_mug00_uni'] = {
				'Unique Dwemer Mug 00',
				'Special Dwemer-style mug.',
				'Drinking container.'
			},

			['misc_dwrv_pitcher00_uni'] = {
				'Unique Dwemer Pitcher 00',
				'Special Dwemer pitcher vessel.',
				'Serving container.'
			},

			['misc_dwrv_bowl00_uni'] = {
				'Unique Dwemer Bowl 00',
				'Special Dwemer-style bowl.',
				'Serving dish.'
			},

			['key_velas'] = {
				'Velas Key',
				'Key related to Velas.',
				'Access to specific areas.'
			},

			['key_Indalen'] = {
				'Indalen Key',
				'Key related to Indalen.',
				'Access to personal chambers.'
			},

			['key_thendas'] = {
				'Thendas Key',
				'Key related to Thendas.',
				'Access to specific locations.'
			},

			['Key_Gatekeeper'] = {
				'Gatekeeper Key',
				'Key related to the Gatekeeper.',
				'Access to gated areas.'
			},

			['ashes_Dwemer'] = {
				'Dwemer Ashes',
				'Ancient ashes of Dwemer origin.',
				'Alchemical component.'
			},

			['key_trib_dwe00'] = {
				'Tribunal Dwemer Key 00',
				'Key related to Tribunal Dwemer ruins.',
				'Access to ancient areas.'
			},

			['key_trib_dwe01'] = {
				'Tribunal Dwemer Key 01',
				'Second key to Tribunal Dwemer ruins.',
				'Access to ancient areas.'
			},

			['key_trib_dwe02'] = {
				'Tribunal Dwemer Key 02',
				'Third key to Tribunal Dwemer ruins.',
				'Access to ancient areas.'
			},

			['dwemer_satchel00'] = {
				'Dwemer Satchel',
				'Ancient Dwemer satchel.',
				'Storage container.'
			},

			['key_dwe_satchel00'] = {
				'Dwemer Satchel Key',
				'Key to Dwemer satchel.',
				'Access to container.'
			},

			['bladepiece_02'] = {
				'Blade Piece 02',
				'Fragment of a broken blade.',
				'Weapon component.'
			},

			['bladepiece_03'] = {
				'Blade Piece 03',
				'Second fragment of a broken blade.',
				'Weapon component.'
			},

			['misc_dwrv_weather'] = {
				'Dwemer Weather Device',
				'Ancient Dwemer weather-related device.',
				'Mechanical artifact.'
			},

			['misc_dwrv_weather2'] = {
				'Dwemer Weather Device 2',
				'Second variant of Dwemer weather device.',
				'Mechanical artifact.'
			},

			['key_durgok'] = {
				'Durgok Key',
				'Key related to Durgok.',
				'Access to specific areas.'
			},

			['key_Bols'] = {
				'Bols Key',
				'Key related to Bols.',
				'Access to personal chambers.'
			},

			['key_gustav_chest'] = {
				'Gustav Chest Key',
				"Key to Gustav's chest.",
				'Access to locked container.'
			},

			['key_Lassnr_well'] = {
				'Lassnr Well Key',
				'Key to Lassnr well area.',
				'Access to water source.'
			},

			['key_nuncius'] = {
				'Nuncius Key',
				'Key related to Nuncius.',
				'Access to specific locations.'
			},

			['key_erich'] = {
				'Erich Key',
				'Key related to Erich.',
				'Access to personal quarters.'
			},

			['key_maryn'] = {
				'Maryn Key',
				'Key related to Maryn.',
				'Access to specific areas.'
			},

			['BM_Seeds_UNIQUE'] = {
				'Unique Seeds',
				'Special seeds with unique properties.',
				'Planting material.'
			},

			['Misc_BM_ClawFang_UNIQUE'] = {
				'Unique Claw Fang',
				'Special fang with unique properties.',
				'Alchemical component.'
			},

			['misc_skull_oddfrid'] = {
				'Oddfrid Skull',
				'Skull of Oddfrid.',
				'Ancient relic.'
			},

			['key_gyldenhul'] = {
				'Gyldenhul Key',
				'Key related to Gyldenhul.',
				'Access to specific areas.'
			},

			['misc_skull_griss'] = {
				'Griss Skull',
				'Skull of Griss.',
				'Ancient relic.'
			},

			['misc_skull_griss_floor'] = {
				'Griss Skull (Floor)',
				'Floor variant of Griss skull.',
				'Ancient relic.'
			},

			['BM_bearheart_UNIQUE'] = {
				'Unique Bear Heart',
				'Special bear heart with unique properties.',
				'Alchemical component.'
			},

			['misc_skull_Skaal'] = {
				'Skaal Skull',
				'Skull of Skaal.',
				'Ancient relic.'
			},

			['key_pirate'] = {
				'Pirate Key',
				'Key related to pirate activities.',
				'Access to hidden areas.'
			},

			['key_hircine1'] = {
				'Hircine Key 1',
				'First key related to Hircine.',
				'Access to specific locations.'
			},

			['key_hircine2'] = {
				'Hircine Key 2',
				'Second key related to Hircine.',
				'Access to additional areas.'
			},

			['key_hircine3'] = {
				'Hircine Key 3',
				'Third key related to Hircine.',
				'Access to special areas.'
			},

			['key_nuncius2'] = {
				'Nuncius Key 2',
				'Second key related to Nuncius.',
				'Access to additional areas.'
			},

			['BM_waterlife_UNIQUE1'] = {
				'Unique Water Life',
				'Special aquatic life form with unique properties.',
				'Alchemical component.'
			}
        }
    }
}