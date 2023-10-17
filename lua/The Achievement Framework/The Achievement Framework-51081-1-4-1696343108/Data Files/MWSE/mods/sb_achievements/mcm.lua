local confPath = "sb_achievements"

---@class mcm
local mcm = { config = mwse.loadConfig(confPath) or
        {
            showHiddenAchievements = 0
        }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "The Achievement Framework" }
    template:saveOnClose(confPath, mcm.config)

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Show or Hide Secret Achievement Descriptions" }
    elementGroup:createDropdown {
        options  = {
            { label = "Mod Author's Choice", value = 0 },
            { label = "Hide Achievement Descriptions", value = 1 },
            { label = "Show Achievement Descriptions", value = 2 },
            { label = "Group Hidden Achievements", value = 3 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "showHiddenAchievements",
            table = mcm.config
        }
    }

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm