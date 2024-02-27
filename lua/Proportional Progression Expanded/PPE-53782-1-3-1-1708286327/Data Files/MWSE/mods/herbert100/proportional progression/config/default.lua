
---@class PPE.config
local default = {
    profile_name = "default", ---@type string
    version = {major = 1, minor = 3, patch = 0, number = 1 + 3/100},
    scale = 1,                              ---@type number
    specialization_modifier = 1,            ---@type number
    major_skill_modifier = 1,               ---@type number
    minor_skill_modifier = 1,               ---@type number
    misc_skill_modifier = 1,                ---@type number
    slider_min = .05,                        ---@type number
    slider_max = 5,                         ---@type number
    interpolate_level_modifiers = true,    ---@type boolean

    -- levels per level
    lvl_delta = 10,                         ---@type integer
    max_lvl = 100,                          ---@type integer


    log_level = "INFO",                          ---@type string
    priority = -2,                          ---@type integer
    --[[ keeps track of whether this is the first time the mod has ever been launched by the user.
    this is used for determining whether we should try to import the old config into the new version of the mod.
    it is only checked when the game is launched.
    ]]
    first_time = true,
    skill = {
        enable = false,

        ---@type table<tes3.skill, number>
        modifiers = { }
    },
    custom_skill = {
        enable = false,
        ---@type table<string, number>
        modifiers = {

        },
    },
    
    level = {
        enable = false,
        ---@type table<number, number>
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
    skill_level = {
        enable = false,
        ---@type table<number, number>
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



for _, id in pairs(tes3.skill) do   
    default.skill.modifiers[id] = 1
end

local skills_module = include("SkillsModule") ---@type SkillsModule?
if skills_module then
    for id in pairs(skills_module.skills) do
        default.custom_skill.modifiers[id] = 1
    end
end
skills_module = nil

return default ---@type PPE.config