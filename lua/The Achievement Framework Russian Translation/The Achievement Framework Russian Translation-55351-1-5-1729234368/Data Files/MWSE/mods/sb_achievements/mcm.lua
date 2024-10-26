local confPath = "sb_achievements"

---@class mcm
local mcm = { config = mwse.loadConfig(confPath) or
        {
            showHiddenAchievements = 0
        }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Модуль достижений" }
    template:saveOnClose(confPath, mcm.config)

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Показать или скрыть описания неоткрытых достижений" }
    elementGroup:createDropdown {
        options  = {
            { label = "Использовать предустановки авторов модов", value = 0 },
            { label = "Скрыть описания достижений", value = 1 },
            { label = "Показать описания достижений", value = 2 },
            { label = "Группировать неоткрытые достижения", value = 3 }
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