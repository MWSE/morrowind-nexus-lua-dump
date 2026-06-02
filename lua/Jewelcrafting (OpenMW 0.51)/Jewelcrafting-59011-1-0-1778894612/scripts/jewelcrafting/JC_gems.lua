local gemRarity = {
	common = {
		-- vanilla + tamriel rebuilt
		"ingred_diamond_01",
		"ingred_emerald_01",
		"ingred_ruby_01",
		"t_ingmine_amethyst_01",
		"t_ingmine_sapphire_01",
		"t_ingmine_garnet_01",
		"t_ingmine_topaz_01",
		"t_ingmine_citrine_01",
		"t_ingmine_jade_01",
		"t_ingmine_turquoise_01",
		"t_ingmine_agate_01",
		"t_ingmine_agate_03",
		"t_ingmine_amber_01",
		"t_ingmine_smokyquartz_01",
		"t_ingmine_rosequartz_01",
		"t_ingmine_bloodstone_01",
		"t_ingmine_onyx_01",
		-- oaab
		"ab_ingmine_amethyst_01",
		"ab_ingmine_garnet_01",
		"ab_ingmine_topaz_01",
		"ab_ingmine_sapphire_01",
		"ab_ingmine_blacktourmaline_01",
		"ab_ingmine_tourmaline_01",
		"ab_ingmine_peridot_01",
		"ab_ingmine_lodestone",
	},
	uncommon = {
		-- vanilla + tamriel rebuilt
		"t_ingmine_aquamarine_01",
		"t_ingmine_ametrine_01",
		"t_ingmine_spinel_01",
		"t_ingmine_lapislazuli_01",
		"t_ingmine_moonstone_01",
		"t_ingmine_opal_01",
		"t_ingmine_topazblue_01",
		"t_ingmine_agate_02",
		"t_ingmine_agate_04",
		"t_ingmine_khajiiteye_01",
		"t_ingmine_tektite_01",
		"t_ingmine_foolsgold_01",
		"t_ingmine_salt_01",
		-- oaab
		"ab_ingmine_diopside_01",
		"ab_ingmine_firejade_01",
	},
	rare = {
		-- vanilla + tamriel rebuilt
		"t_ingmine_diamondblue_01",
		"t_ingmine_diamondred_01",
		"t_ingmine_fireopal_01",
		"t_ingmine_spellstone_01",
		"t_ingmine_flashgrit_01",
		-- oaab
		"ab_ingmine_bluediamond",
		"ab_ingmine_reddiamond",
	},
}

------------------------------ build rollable lists ------------------------------

-- keep only ids whose record exists in this load order and isn't mwscript-gated
G_gems = { common = {}, uncommon = {}, rare = {} }
for tierName, ids in pairs(gemRarity) do
	for _, id in ipairs(ids) do
		local lower = id:lower()
		local rec = types.Ingredient.records[lower]
		if rec and (not rec.mwscript or rec.mwscript == "") then
			G_gems[tierName][#G_gems[tierName] + 1] = lower
		end
	end
end

--[[
T_IngMine_Agate_01	Rainbow Agate
T_IngMine_Agate_02	Fire Agate
T_IngMine_Agate_03	Midnight Agate
T_IngMine_Agate_04	White Agate
T_IngMine_Amber_01	Amber
T_IngMine_Amethyst_01	Amethyst
T_IngMine_Ametrine_01	Ametrine
#T_IngMine_Antimony_01	Antimony Ore
T_IngMine_Aquamarine_01	Aquamarine
#T_IngMine_Arsenic_01	Raw Arsenic
T_IngMine_Bloodstone_01	Bloodstone
T_IngMine_CaputMortuum_01	Caput Mortuum
#T_IngMine_Chalk_01	Chalk
T_IngMine_Charcoal_01	Charcoal
T_IngMine_Citrine_01	Citrine
T_IngMine_Coal_01	Coal
T_IngMine_DiamondBlue_01	Blue Diamond
T_IngMine_DiamondRed_01	Red Diamond
T_IngMine_FireOpal_01	Fire Opal
T_IngMine_Flashgrit_01	Flashgrit
T_IngMine_FoolsGold_01	Fool's Gold
T_IngMine_Garnet_01	Garnet
T_IngMine_IceCrystal_01	Ice Crystal
T_IngMine_Jade_01	Jade
T_IngMine_Jet_01	Jet
T_IngMine_KhajiitEye_01	Khajiit-Eye
T_IngMine_LapisLazuli_01	Lapis Lazuli
#T_IngMine_Lodestone_01	Lodestone
#T_IngMine_LunarCaustic_01	Lunar Caustic
#T_IngMine_Malouchite_01	Malachite
T_IngMine_Moonstone_01	Moonstone
T_IngMine_Onyx_01	Onyx
T_IngMine_Opal_01	Opal
#T_IngMine_OreBitterstone_01	Bitterstone Ore
#T_IngMine_OreBrass_01	Brass Ore
#T_IngMine_OreCobalt_01	Cobalt Ore
#T_IngMine_OreCopper_01	Copper Ore
#T_IngMine_OreGold_01	Gold Ore
#T_IngMine_OreIron_01	Iron Ore
#T_IngMine_OreLead_01	Lead Ore
#T_IngMine_OreMercury_01	Mercury
#T_IngMine_OreOrichalcum_01	Orichalcum Ore
#T_IngMine_OreOrichalcum_02	Orichalc Grains
#T_IngMine_OrePlatinum_01	Platinum Ore
#T_IngMine_OreQuicksilver_01	Quicksilver Ore
#T_IngMine_OreSilver_01	Silver Ore
#T_IngMine_OreSulfur_01	Sulphur
#T_IngMine_OreTin_01	Raw Tin
#T_IngMine_OreZinc_01	Raw Zinc
#T_IngMine_PearlBlack_01	Black Pearl
#T_IngMine_PearlBlue_01	Blue Pearl
#T_IngMine_PearlKardesh_01	Kardesh Pearl
#T_IngMine_PearlPink_01	Pink Pearl
#T_IngMine_Peridot_01	Peridot
#T_IngMine_Realgar_01	Realgar
#T_IngMine_Rockcrystal_01	Rock Crystal
T_IngMine_RoseQuartz_01	Rose Quartz
T_IngMine_Salt_01	Salt
T_IngMine_Sapphire_01	Sapphire
T_IngMine_SmokyQuartz_01	Smoky Quartz
T_IngMine_Spellstone_01	Spellstone
T_IngMine_Spinel_01	Spinel
T_IngMine_Tektite_01	Tektite
T_IngMine_TopazBlue_01	Blue Topaz
T_IngMine_Topaz_01	Topaz
T_IngMine_Turquoise_01	Turquoise]]