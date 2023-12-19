---@class PPE_Level_Modifiers
---@field enable boolean should these modifiers be enabled?
---@field modifiers table<integer, number> the modifier for each level

---@class PPE_Skill_Modifiers
---@field enable boolean should these modifiers be enabled?
---@field modifiers table<tes3skill, number> the modifier for each skill

---@class PPE_Config
local PPE_Config = {
    scale = 1,                              ---@type number
    specialization_modifier = 1,            ---@type number
    major_skill_modifier = 1,               ---@type number
    minor_skill_modifier = 1,               ---@type number
    misc_skill_modifier = 1,                ---@type number
    slider_min = .1,                        ---@type number
    slider_max = 5,                         ---@type number
    interpolate_level_modifiers = false,    ---@type boolean
    -- enable the sidebars in the modifier pages. disabled because i think the main page explaisn them well enough,
    -- and the extra space lets you have more control over the sliders
    enable_sidebars = false,                ---@type boolean
    lvl_delta = 10,                         ---@type integer
    max_lvl = 100,                          ---@type integer
    log_level = 1,                          ---@type integer
    --[[ keeps track of whether this is the first time the mod has ever been launched by the user.
    this is used for determining whether we should try to import the old config into the new version of the mod.
    it is only checked when the game is launched.
    ]]
    first_time = true,
    ---@type PPE_Skill_Modifiers
    skill = {
        enable = false,
        modifiers = {
            acrobatics = 1,
            alchemy = 1,
            alteration = 1,
            armorer = 1,
            athletics = 1,
            axe = 1,
            block = 1,
            bluntWeapon = 1,
            conjuration = 1,
            destruction = 1,
            enchant = 1,
            handToHand = 1,
            heavyArmor = 1,
            illusion = 1,
            lightArmor = 1,
            longBlade = 1,
            marksman = 1,
            mediumArmor = 1,
            mercantile = 1,
            mysticism = 1,
            restoration = 1,
            security = 1,
            shortBlade = 1,
            sneak = 1,
            spear = 1,
            speechcraft = 1,
            unarmored = 1
        }
    },
    ---@type PPE_Level_Modifiers
    level = {
        enable = false,
        modifiers = {
            [0] = 1,
            [10] = 1,
            [20] = 1,
            [30] = 1,
            [40] = 1,
            [50] = 1,
            [60] = 1,
            [70] = 1,
            [80] = 1,
            [90] = 1,
            [100] = 1
        }
    },
    ---@type PPE_Level_Modifiers
    skill_level = {
        enable = false,
        modifiers = {
            [0] = 1,
            [10] = 1,
            [20] = 1,
            [30] = 1,
            [40] = 1,
            [50] = 1,
            [60] = 1,
            [70] = 1,
            [80] = 1,
            [90] = 1,
            [100] = 1
        }
    }
}
return PPE_Config