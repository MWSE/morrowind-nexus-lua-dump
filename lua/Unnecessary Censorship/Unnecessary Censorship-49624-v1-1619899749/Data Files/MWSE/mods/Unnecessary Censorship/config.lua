local config = {}

local settings = {
    dunmerEnabled = true,
    argonianEnabled = true
}
local dunmer = {
    {"Fetcher", "F*****r"},
    {"fetcher", "f*****r"},
    {"ilk-drinker", "ilk-******r"},
    {"N'wah", "N'**h"},
    {"n'wah", "n'**h"},
    {"Nchow", "N***w"},
    {"nchow", "n***w"},
    {"S'wit", "S'**t"},
    {"s'wit", "s'**t"},
    {"B'vek", "B'**k"},
    {"b'vek", "b'**k"},
}
local argonian = {
    {"Xuth", "X**h"},
    {"xuth", "x**h"},
    {"Xhuth", "X***h"},
    {"xhuth", "x***h"},
    {"Kaoc", "K**c"},
    {"kaoc", "k**c"},
    {"Waxhutil", "W******l"},
    {"waxhutil", "w******l"},
    {"Waxhuthi ", "W******i"},
    {"waxhuthi", "w******i"},
    {"Lukiul", "L****l"},
    {"lukiul", "l****l"}
}
local updates = {
    {"v1", "Hello world!"}
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Unnecessary Censorship")
    local settingsPage = template:createPage{label = "Config", noScroll = true}
    local enableSub = settingsPage:createSideBySideBlock()
    enableSub:createInfo{text = "Dunmer Censorship"}
    enableSub:createOnOffButton{
        variable = mwse.mcm.createTableVariable{
            id = "dunmerEnabled",
            table = settings
        }
    }
    enableSub = settingsPage:createSideBySideBlock()
    enableSub:createInfo{text = "Argonian Censorship"}
    enableSub:createOnOffButton{
        variable = mwse.mcm.createTableVariable{
            id = "argonianEnabled",
            table = settings
        }
    }
    local updatesTitle = settingsPage:createCategory("Updates")
    for _, update in pairs(updates) do
        local updateTitle = updatesTitle:createCategory(update[1])
        updateTitle:createInfo{text = update[2]}
    end

    template:saveOnClose("Unnecessary Censorship", settings)
    mwse.mcm.register(template)
end

--------------------------------------------------

function config.init()
    local tryLoadConfig = mwse.loadConfig("Unnecessary Censorship")
    if (tryLoadConfig) then
        config.setSettings(tryLoadConfig)
    else
        mwse.saveConfig("Unnecessary Censorship", config.getSettings())
    end
    event.register("modConfigReady", registerModConfig)
end

function config.getSettings()
    return settings
end

function config.setSettings(s)
    settings = s
end

function config.getDunmer()
    return dunmer
end

function config.getArgonian()
    return argonian
end

return config