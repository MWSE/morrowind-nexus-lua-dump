local configPath = "Potions Spoil"
local cfg = {}  -- Initialize the cfg table
---@class PotionsSpoil
local defaults = {
    spoilTime = 240,
    blacklist = {
        ["verminous_fabricant_elixir"] = true,
        ["p_drain willpower_q"] = true,
        ["p_drain_agility_q"] = true,
        ["p_drain_endurance_q"] = true,
        ["p_drain_intelligence_q"] = true,
        ["p_drain_luck_q"] = true,
        ["p_drain_magicka_q"] = true,
        ["p_drain_personality_q"] = true,
        ["p_drain_strength_q"] = true,
        ["p_drain_speed_q"] = true,
        ["p_dwemer_lubricant00"] = true,
        ["p_lovepotion_unique"] = true,
        ["p_quarrablood_UNIQUE"] = true,
        ["p_cure_common_unique"] = true,
        ["p_sinyaramen_UNIQUE"] = true,
        ["p_heroism_s"] = true,
        ["p_vintagecomberrybrandy1"] = true,
        ["potion_ancient_brandy"] = true,
        ["potion_comberry_brandy_01"] = true,
        ["potion_comberry_wine_01"] = true,
        ["potion_cyro_brandy_01"] = true,
        ["Potion_Cyro_Whiskey_01"] = true,
        ["Potion_Local_Brew_01"] = true,
        ["potion_local_liquor_01"] = true,
        ["potion_nord_mead"] = true,
        ["potion_skooma_01"] = true,
        ["potion_t_bug_musk_01"] = true,
        ["pyroil_tar_unique"] = true,
        ["hulking_fabricant_elixir"] = true,
        ["p_Imperfect_Elixir"] = true,
        ["AB_alc_GemVoidEssence"] = true,
        ["AB_alc_HealBandage01"] = true,
        ["AB_alc_HealBandage02"] = true,
        ["AB_dri_GuarMilk"] = true,
        ["AB_dri_Musa"] = true,
        ["AB_dri_Sillapi"] = true,
        ["AB_dri_TramaTea"] = true,
        ["AB_dri_Yamuz"] = true,
        ["AB_eff_KwamaPoison"] = true,
        ["T_Bre_Drink_WineWayrest_01"] = true,
        ["T_Cnq_Ngopta"] = true,
        ["T_Com_Potion_DaedricIchor_E"] = true,
        ["T_Com_Potion_DragonBlood"] = true,
        ["T_Com_PotionS_DKey_Blind"] = true,
        ["T_Com_PotionS_DKey_Silence"] = true,
        ["T_Com_PotionS_Dspl_DrainMagic"] = true,
        ["T_Com_PotionS_Dspl_Sound"] = true,
        ["T_Com_PotionS_Jmp_DrainFatigue"] = true,
        ["T_Com_PotionS_Jmp_DrainStr"] = true,
        ["T_Com_PotionS_Lev_Burden"] = true,
        ["T_Com_PotionS_Lev_DrainHP"] = true,
        ["T_Com_PotionS_Sanc_DrainLuck"] = true,
        ["T_Com_PotionS_Sanc_WeakNorm"] = true,
        ["T_Com_SPotion_FAtk_DrainEnduran"] = true,
        ["T_Com_SPotion_FAtk_DrainFatigue"] = true,
        ["T_Com_SPotion_L_Blind"] = true,
        ["T_Com_SPotion_L_DamPerson"] = true,
        ["T_Com_SPotion_PR_DrainFatigue"] = true,
        ["T_Com_SPotion_PR_DrainSpeed"] = true,
        ["T_Com_SPotion_Pro_DrainMagic"] = true,
        ["T_Com_SPotion_Pro_Paralyze"] = true,
        ["T_Com_SPotion_RM_DrainWillpow"] = true,
        ["T_Com_SPotion_RM_MagicWeakness"] = true,
        ["T_Com_Subst_Aqua_Vita_01"] = true,
        ["T_Com_Subst_Perfume_01"] = true,
        ["T_Com_Subst_Perfume_02"] = true,
        ["T_Com_Subst_Perfume_03"] = true,
        ["T_Com_Subst_Perfume_04"] = true,
        ["T_Com_Subst_Perfume_05"] = true,
        ["T_Com_Subst_Perfume_06"] = true,
        ["T_Com_Subst_Phyrric_Acid_01"] = true,
        ["T_Com_Subst_Vitriol_Oil_01"] = true,
        ["T_De_Drink_BourbonGoya_01"] = true,
        ["T_De_Drink_GuarMilk_01"] = true,
        ["T_De_Drink_LiquorLlotham_01"] = true,
        ["T_De_Drink_PunavitJug"] = true,
        ["T_De_Drink_PunavitResin_01"] = true,
        ["T_Imp_Drink_AleAkul_01"] = true,
        ["T_Imp_Drink_CherryBrandy_01"] = true,
        ["T_Imp_Drink_CiderAliyew_01"] = true,
        ["T_Imp_Drink_RicebeerMori_01"] = true,
        ["T_Imp_Drink_WineBattle_01"] = true,
        ["T_Imp_Drink_WineBlackhill_01"] = true,
        ["T_Imp_Drink_WineFreeEstat_01"] = true,
        ["T_Imp_Drink_WinePlalloVin_01"] = true,
        ["T_Imp_Drink_WineRufinoClr_01"] = true,
        ["T_Imp_Drink_WineSour"] = true,
        ["T_Imp_Drink_WineSurilieBr_01"] = true,
        ["T_Imp_Drink_WineSweet"] = true,
        ["T_Imp_Drink_WineTamikaClr_01"] = true,
        ["T_Imp_Drink_WineTwinMoon_01"] = true,
        ["T_Imp_Drink_WineWolfsbl_01"] = true,
        ["T_Imp_Rune_Hestra"] = true,
        ["T_Imp_Rune_Hestra2"] = true,
        ["T_Imp_Rune_Reman"] = true,
        ["T_Imp_Rune_Reman2"] = true,
        ["T_Imp_Rune_Sidri"] = true,
        ["T_Imp_Rune_Sidri2"] = true,
        ["T_Imp_Subst_Aegrotat_01"] = true,
        ["T_Imp_Subst_Blackdrake_01"] = true,
        ["T_Imp_Subst_Incarnadine_01"] = true,
        ["T_Imp_Subst_QuaestoVil_01"] = true,
        ["T_Imp_Subst_QuaestoVil_02"] = true,
        ["T_Imp_Subst_SloadOil_01"] = true,
        ["T_Nor_Drink_Beer_01"] = true,
        ["T_Nor_Drink_BeerLight_01"] = true,
        ["T_Nor_Drink_Bodja_01"] = true,
        ["T_Nor_Drink_Fyrg_01"] = true,
        ["T_Nor_Drink_Gjeche_01"] = true,
        ["T_Nor_Drink_Gjulve_01"] = true,
        ["T_Nor_Drink_Risla_01"] = true,
        ["T_Nor_Drink_SnowberryaleVeig_01"] = true,
        ["T_Nor_Drink_Strmead_01"] = true,
        ["T_Nor_Drink_WineReach_01"] = true,
        ["T_Nor_Potion_DrainAgility_Q"] = true,
        ["T_Nor_Potion_DrainEndurance_Q"] = true,
        ["T_Nor_Potion_DrainIntelli_Q"] = true,
        ["T_Nor_Potion_DrainLuck_Q"] = true,
        ["T_Nor_Potion_DrainMagicka_Q"] = true,
        ["T_Nor_Potion_DrainPersonality_Q"] = true,
        ["T_Nor_Potion_DrainSpeed_Q"] = true,
        ["T_Nor_Potion_DrainStrength_Q"] = true,
        ["T_Nor_Potion_DrainWillpow_Q"] = true,
        ["T_Nor_Subst_WasabiPaste_01"] = true,
        ["T_Orc_Drink_LiquorUngorth_02"] = true,
        ["T_Pi_Drink_PalmWine"] = true,
        ["T_Rea_Drink_LiquorAeli_01"] = true,
        ["T_Rea_Drink_TeaGyrrg_01"] = true,
        ["T_Rga_Drink_Aibe_01"] = true,
        ["T_Rga_Drink_Sift"] = true,
        ["T_Rga_Drink_WineSutchGoNogro_01"] = true,
        ["T_Rga_Drink_WineSutchTalan_01"] = true,
        ["T_We_Drink_MeatJuiceRotmeth_01"] = true,
        ["T_We_Drink_PigmilkbeerJagga_01"] = true,
        ["T_We_Drink_Wine_01"] = true,
        ["T_Yne_Drink_Pudjing"] = true  -- Default blacklisted potions
    }
}

---@class PotionsSpoil
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createSlider({
        label = "How long for potions to spoil in hours.",
        configKey = "spoilTime",
        min = 1, max = 3000, step = 1, jump = 1,
    })

    template:createExclusionsPage({
        label = "Excluded Potions",
        configKey = "blacklist",
        filters = {
            { label = "Potions", callback = cfg.getPotions }
        },
        showReset = true
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

function cfg.getPotions()
    local potions = {}
    for _, item in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if item.objectType == tes3.objectType.alchemy then
            table.insert(potions, item.id)
        end
    end
    table.sort(potions)
    return potions
end

return config