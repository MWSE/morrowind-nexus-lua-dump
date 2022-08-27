local defaultConfig = {
	modEnabled = true,
    gmstValue = 15,
	sameIngred = {
		food_kwama_egg_01 = {
			food_kwama_egg_02 = true,
		},
		ingred_6th_corprusmeat_01 = {
			ingred_6th_corprusmeat_02 = true,
			ingred_6th_corprusmeat_03 = true,
			ingred_6th_corprusmeat_04 = true,
			ingred_6th_corprusmeat_05 = true,
			ingred_6th_corprusmeat_06 = true,
			ingred_6th_corprusmeat_07 = true,
		},
		AB_IngFood_KwamaEggCentCut ={
			AB_IngFood_KwamaEggCentWrap = true,
		},
	},
	nonEdible = {
		ingred_raw_ebony_01 = true,
		ingred_dae_cursed_raw_ebony_01 = true,
		ingred_emerald_01 = true,
		ingred_emerald_pinetear = true,
		ingred_dae_cursed_emerald_01 = true,
		ingred_raw_glass_01 = true,
		ingred_raw_glass_tinos = true,
		ingred_ruby_01 = true,
		ingred_dae_cursed_ruby_01 = true,
		ingred_adamantium_ore_01 = true,
		ingred_diamond_01 = true,
		ingred_dae_cursed_diamond_01 = true,
		ingred_pearl_01 = true,
		ingred_dae_cursed_pearl_01 = true,
		ingred_raw_stalhrim_01 = true,
		ingred_scrap_metal_01 = true,
		ab_ingmine_amber_01 = true,
		ab_ingmine_amethyst_01 = true,
		ab_ingmine_blackpearl_01 = true,
		ab_ingmine_blacktourmaline_01 = true,
		ab_ingmine_bluediamond = true,
		ab_ingmine_diopside_01 = true,
		ab_ingmine_firejade_01 = true,
		ab_ingmine_garnet_01 = true,
		ab_ingmine_goldpearl_01 = true,
		ab_ingmine_obsidian_01 = true,
		ab_ingmine_peridot_01 = true,
		ab_ingmine_reddiamond = true,
		ab_ingmine_sapphire_01 = true,
		ab_ingmine_topaz_01 = true,
		ab_ingmine_tourmaline_01 = true,
		T_IngMine_Alexandrite_01 = true,
		t_ingmine_alexandritedae_01 = true,
		t_ingmine_amber_01 = true,
		t_ingmine_amberdae_01 = true,
		t_ingmine_amethyst_01 = true,
		t_ingmine_amethystdae_01 = true,
		t_ingmine_aquamarine_01 = true,
		t_ingmine_aquamarinedae_01 = true,
		t_ingmine_bloodstone_01 = true,
		t_ingmine_bloodstonedae_01 = true,
		t_ingmine_charcoal_01 = true,
		t_ingmine_coal_01 = true,
		t_ingmine_diamonddetomb_01 = true,
		t_ingmine_emeralddetomb_01 = true,
		t_ingmine_garnet_01 = true,
		t_ingmine_garnetdae_01 = true,
		t_ingmine_jet_01 = true,
		t_ingmine_jetdae_01 = true,
		t_ingmine_khajiiteye_01 = true,
		t_ingmine_khajiiteyedae_01 = true,
		t_ingmine_lodestone_01 = true,
		t_ingmine_malouchite_01 = true,
		t_ingmine_moonstone_01 = true,
		t_ingmine_moonstonedae_01 = true,
		t_ingmine_opal_01 = true,
		t_ingmine_opaldae_01 = true,
		t_ingmine_orecopper_01 = true,
		t_ingmine_oregold_01 = true,
		t_ingmine_oregolddae_01 = true,
		t_ingmine_oreiron_01 = true,
		t_ingmine_oreorichalcum_01 = true,
		t_ingmine_orequicksilver_01 = true,
		t_ingmine_oresilver_01 = true,
		t_ingmine_pearlblack_01 = true,
		t_ingmine_pearlblackdae_01 = true,
		t_ingmine_pearldetomb_01 = true,
		t_ingmine_pearlkardesh_01 = true,
		t_ingmine_rockcrystal_01 = true,
		t_ingmine_rockcrystaldae_01 = true,
		t_ingmine_rubydetomb_01 = true,
		t_ingmine_sapphire_01 = true,
		t_ingmine_sapphiredae_01 = true,
		t_ingmine_spellstone_01 = true,
		t_ingmine_spinel_01 = true,
		t_ingmine_spineldae_01 = true,
		t_ingmine_tektite_01 = true,
		t_ingmine_tektitedae_01 = true,
		t_ingmine_topaz_01 = true,
		t_ingmine_topazdae_01 = true,
		t_ingmine_turquoise_01 = true,
		t_ingmine_topazdae_01 = true,
	}
}

for ingred1 in tes3.iterateObjects(tes3.objectType.ingredient) do
	for ingred2 in tes3.iterateObjects(tes3.objectType.ingredient) do
		local similarity = 0
		local sameEffects = 0
		if ingred1.id ~= ingred2.id then
			if ingred1.name == ingred2.name then
				similarity = similarity + 1
			elseif ingred1.icon == ingred2.icon then
				similarity = similarity + 1
			--elseif string.gsub(ingred1.id, "_[^_]+$", "_") == string.gsub(ingred2.id, "_[^_]+$", "_") then
			--	similarity = similarity + 1
			end
			if similarity > 0 then 
				for i = 1,4 do
					if ingred1.effects[i] == ingred2.effects[i] then
						local magicEffect = tes3.getMagicEffect(ingred1.effects[i])
						if magicEffect then
							if magicEffect.targetsAttributes then
								if ingred1.effectAttributeIds[i] == ingred2.effectAttributeIds[i] then 
									sameEffects = sameEffects + 1
								else
									sameEffects = 0
								end
							elseif magicEffect.targetsSkills then
								if ingred1.effectSkillIds[i] == ingred2.effectSkillIds[i] then
									sameEffects = sameEffects + 1
								else
									sameEffects = 0
								end
							else
								sameEffects = sameEffects + 1
							end
						end
					else
						sameEffects = 0
					end
				end
				if sameEffects > 0 then
					defaultConfig.sameIngred[ingred1.id] = defaultConfig.sameIngred[ingred1.id] or {}
					defaultConfig.sameIngred[ingred1.id][ingred2.id] = true
				end
			end
		end
	end
end

local mwseConfig = mwse.loadConfig("alchemyKnowledge", defaultConfig)

return mwseConfig