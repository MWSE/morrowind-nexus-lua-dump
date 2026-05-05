local i18n = mwse.loadTranslations("Pirate.HotkeysForConsoleCommands")
local config = require("Pirate.HotkeysForConsoleCommands.config")

local LINKS_LIST = {
    --{
        --text = i18n("mcm.TESAll"),
        --url = " "
    --},
    --{
        --text = i18n("mcm.FullRest"),
        --url = " "
    --},
    {
        text = i18n("mcm.Nexus"),
        url = "https://www.nexusmods.com/morrowind/mods/58880"
    },
}
local CREDITS_LIST = {
    {
        text = i18n("mcm.Pirate"),
        url = "https://next.nexusmods.com/profile/Pirate443?gameId=100",
    },
}
local function addSideBar(component)
    component.sidebar:createCategory(i18n("mcm.modname")..i18n("mcm.version")..config.modVersion)
    component.sidebar:createInfo{ text = i18n("mcm.modinfo") }

    local linksCategory = component.sidebar:createCategory(i18n("mcm.Links"))
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
        end
    local creditsCategory = component.sidebar:createCategory(i18n("mcm.Credits"))
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = i18n("mcm.modname"),
    --headerImagePath = "textures/headerImageName.dds"
    }
    template:saveOnClose(config.configPath, config.mcm)
    template:register()
        
    local page = template:createSideBarPage { label = i18n("mcm.Settings"), showReset = true }
    addSideBar(page)
    

    local category1 = page:createCategory{
    label = i18n("mcm.category1.label"),
    description = i18n("mcm.category1.desc"),
    }

    category1:createKeyBinder{
        label = i18n("mcm.Hotkey.RA.label"),
        description = i18n("mcm.Hotkey.RA.desc"),
        defaultSetting = config.mcmDefault.RAKey,
        showDefaultSetting = true,
        variable = mwse.mcm.createTableVariable{ table = config.mcm, id = "RAKey" },
        allowCombinations = true
    }

    category1:createKeyBinder{
        label = i18n("mcm.Hotkey.FixMe.label"),
        description = i18n("mcm.Hotkey.FixMe.desc"),
        defaultSetting = config.mcmDefault.FixMeKey,
        showDefaultSetting = true,
        variable = mwse.mcm.createTableVariable{ table = config.mcm, id = "FixMeKey" },
        allowCombinations = true
    }

end

event.register("modConfigReady", registerMCM)