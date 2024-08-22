local configPath = "Experience Bar"
local cfg = {}
---@class bsExperienceBar<K, V>: { [K]: V }
local defaults = {
    displayTime = 5,
    blacklist = {
        Acrobatics = true,
        Athletics = true,
    },
}


---@class bsExperienceBar
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath, defaultConfig = defaults, config = config })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createSlider({
        label = "How Long to Display Before Fade Out",
        configKey = "displayTime",
        min = 0, max = 30, step = 1, jump = 1,
    })

    template:createExclusionsPage({
        label = "Excluded Skills",
        configKey = "blacklist",
        filters = {
            {label = "Skills", callback = cfg.getSkills}
        },
        showReset = true
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)


function cfg.getSkills()
    local skills = {}
    for _, skill in pairs(tes3.skill) do
        table.insert(skills, tes3.skillName[skill])
    end
    table.sort(skills)
    return skills
end


return config