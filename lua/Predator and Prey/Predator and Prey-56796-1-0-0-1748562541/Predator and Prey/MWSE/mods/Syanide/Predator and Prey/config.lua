local configPath = "Predator and Prey"
local cfg = {}  -- Initialize the cfg table

local defaults = {
    checkRadius = 1024,

    predators = {
        -- example predators
        ["alit"] = true,
        ["alit_disease"] = true,
        ["alit_blighted"] = true,
        ["cliff racer"] = true,
        ["cliff racer_diseased"] = true,
        ["cliff racer_blighted"] = true,
        ["dreugh"] = true,
        ["dreugh_koal"] = true,
        ["kagouti"] = true,
        ["kagouti_hrk"] = true,
        ["kagouti_diseased"] = true,
        ["kagouti_blighted"] = true,
        ["mudcrab"] = true,
        ["mudcrab-Diseased"] = true,
        ["mudcrab_hrmudcrabnest"] = true,
        ["nix-hound"] = true,
        ["nix-hound blighted"] = true,
        ["shalk"] = true,
        ["shalk_diseased"] = true,
        ["shalk_diseased_hram"] = true,
        ["shalk_blighted"] = true,
        ["Slaughterfish_Small"] = true,
        ["slaughterfish"] = true,
        ["durzog_wild_weaker"] = true,
        ["durzog_diseased"] = true,
        ["durzog_wild"] = true,
        ["durzog_war_trained"] = true,
        ["durzog_war"] = true,
        ["bm_bear_black"] = true,
        ["bm_bear_black_fat"] = true,
        ["bm_bear_brown"] = true,
        ["bm_bear_snow_unique"] = true,
        ["bm_ice_troll_tough"] = true,
        ["bm_ice_troll"] = true,
        ["bm_icetroll_FG_Uni"] = true,
        ["bm_frost_boar"] = true,
        ["bm_riekling"] = true,
        ["bm_riekling_Dulk_UNIQUE"] = true,
        ["bm_riekling_Krish_UNIQU"] = true,
        ["bm_riekling_be_UNIQUE"] = true,
        ["bm_riekling_boarmaster"] = true,
        ["bm_riekling_mounted"] = true,
        ["bm_wolf_grey_lvl_1"] = true,
        ["bm_wolf_grey"] = true,
        ["bm_wolf_red"] = true,
        ["bm_wolf_snow_unique"] = true,
        ["bm_udyrfrykte"] = true
    },

    prey = {
        -- example prey
        ["rat"] = true,
        ["rat_cave_fgrh"] = true,
        ["rat_cave_fgt"] = true,
        ["rat_telvanni_unique"] = true,
        ["rat_telvanni_unique_2"] = true,
        ["rat_cave_hhte1"] = true,
        ["rat_diseased"] = true,
        ["rat_blighted"] = true,
        ["rat_cave_hhte2"] = true,
        ["kwama forager"] = true,
        ["guar"] = true,
        ["guar_feral"] = true,
        ["guar_pack"] = true,
        ["netch_betty"] = true,
        ["netch_betty_ranched"] = true,
        ["netch_betty_ilgn"] = true,
        ["netch_bull_ilgn"] = true,
        ["netch_bull_ranched"] = true,
        ["netch_bull"] = true,
        ["Kwama Queen"] = true,
        ["Kwama Queen_HHEM"] = true,
        ["kwama queen_mudan_c"] = true,
        ["kwama queen_shurdan_c"] = true,
        ["Kwama Queen_Abaesen"] = true,
        ["kwama queen_maesa"] = true,
        ["kwama queen_ahanibi"] = true,
        ["kwama queen_matus"] = true,
        ["kwama queen_akimaes"] = true,
        ["kwama queen_mudan"] = true,
        ["kwama queen_eluba"] = true,
        ["kwama queen_panabanit"] = true,
        ["kwama queen_eretammus"] = true,
        ["kwama queen_shurdan"] = true,
        ["kwama queen_gnisis"] = true,
        ["kwama queen_sarimisun"] = true,
        ["kwama queen_hairat"] = true,
        ["kwama queen_sinamusa"] = true,
        ["kwama queen_madas"] = true,
        ["kwama queen_zalkin"] = true,
        ["kwama warrior"] = true,
        ["kwama warrior blighted"] = true,
        ["kwama warrior shurdan"] = true,
        ["kwama worker"] = true,
        ["kwama worker entrance"] = true,
        ["kwama worker diseased"] = true,
        ["kwama worker blighted"] = true,
        ["scrib"] = true,
        ["scrib diseased"] = true,
        ["scrib_vaba-amus"] = true,
        ["scrib blighted"] = true,
        ["Rat_plague"] = true,
        ["Rat_plague_hall1"] = true,
        ["Rat_plague_hall1a"] = true,
        ["Rat_plague_hall2"] = true,
        ["bm_horker"] = true,
        ["bm_horker_large"] = true
    }
}

---@class DynamicWeights
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createSideBarPage({ label = "Settings" })
    settings.showReset = true

    settings:createSlider({
        label = "Proximity",
        description = "The radius around creatures to check for targets.",
        configKey = "checkRadius",
        min = 256, max = 8192, step = 1, jump = 1,
    })

    template:createExclusionsPage({
        label = "Predator Creatures",
        configKey = "predators",
        filters = {
            { label = "Creatures", callback = cfg.getAllCreatures }
        },
        showReset = true
    })

    template:createExclusionsPage({
        label = "Prey Creatures",
        configKey = "prey",
        filters = {
            { label = "Creatures", callback = cfg.getAllCreatures }
        },
        showReset = true
    })

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)

function cfg.getAllCreatures()
    local creatureSet = {}
    local creatureList = {}

    for creature in tes3.iterateObjects(tes3.objectType.creature) do
        if creature.baseObject == nil or creature.baseObject == creature then
            local id = creature.id:lower()
            if id and id ~= "" and not creatureSet[id] then
                creatureSet[id] = true
                table.insert(creatureList, id)
            end
        end
    end

    table.sort(creatureList)
    return creatureList
end

return config
