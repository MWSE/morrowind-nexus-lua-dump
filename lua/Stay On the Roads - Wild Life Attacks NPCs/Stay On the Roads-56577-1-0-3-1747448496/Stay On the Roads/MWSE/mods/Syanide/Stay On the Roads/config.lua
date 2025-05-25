local configPath = "Stay On the Roads"
local cfg = {}  -- Initialize the cfg table
local defaults = {
    fightThreshold = 90,
    checkRadius = 1024,
    blacklist = {
        ["OJ_ME_SummAlfiqCrea"] = true,
        ["bonelord_summon"] = true,
        ["atronach_frost_summon"] = true,
        ["slaughterfish00000006"] = true,
        ["bm_wolf_grey_summon"] = true,
        ["bonewalker_greater_summ"] = true,
        ["dremora_summon"] = true,
        ["centurion_sphere_summon"] = true,
        ["ab_dae_darkseducersumm"] = true,
        ["slaughterfish00000007"] = true,
        ["ancestor_ghost_summon"] = true,
        ["BM_spriggan_summon"] = true,
        ["skeleton_summon"] = true,
        ["oj_me_summalfiqcrea"] = true,
        ["daedroth_summon"] = true,
        ["winged twilight_summon"] = true,
        ["scamp_summon"] = true,
        ["bm_draugr_summon"] = true,
        ["BM_wolf_bone_summon"] = true,
        ["bm_bear_black_summon"] = true,
        ["bonewalker_summon"] = true,
        ["skeleton_wiz_summon"] = true,
        ["atronach_flame_summon"] = true,
        ["slaughterfish_hr_sfavd"] = true,
        ["atronach_storm_summon"] = true,
        ["fabricant_summon"] = true,
        ["hunger_summon"] = true,
        ["BM_draugr_summon"] = true,
        ["golden saint_summon"] = true,
        ["clannfear_summon"] = true,
        ["bm_spriggan_summon"] = true,
        ["Bonewalker_Greater_summ"] = true,
        ["BM_bear_black_summon"] = true,
        ["BM_wolf_grey_summon"] = true,
        ["AB_Dae_DarkSeducerSumm"] = true,
        ["bm_wolf_bone_summon"] = true,
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
        label = "Fight Value",
        description = "The fight value a creature must have to attack NPCs.",
        configKey = "fightThreshold",
        min = 40, max = 100, step = 1, jump = 1,
    })

        settings:createSlider({
        label = "Proximity",
        description = "The proximity a creature must have to attack NPCs.",
        configKey = "checkRadius",
        min = 256, max = 8192, step = 1, jump = 1,
    })

    template:createExclusionsPage({
        label = "Excluded Creatures",
        configKey = "blacklist",
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
        -- Skip if the creature is not a base object (i.e., it has a base object that isn't itself)
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