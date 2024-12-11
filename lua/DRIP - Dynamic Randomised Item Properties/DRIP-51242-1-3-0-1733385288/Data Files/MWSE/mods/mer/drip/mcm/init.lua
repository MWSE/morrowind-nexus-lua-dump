local common = require("mer.drip.common")
local mcmConfig = mwse.loadConfig(common.config.configPath, common.config.mcmDefault)

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/drip/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/crafting-framework/wiki"
    -- },
    {
        text = "Nexus Page",
        url = "https://www.nexusmods.com/morrowind/mods/51242"
    },
    {
        text = "Buy me a coffee",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format(common.config.modName)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = common.config.modDescription}

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = common.config.modName, headerImagePath = "textures/drip/MCMHeader.dds" }
    template.onClose = function()
        common.config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig }
    }

    page:createSlider{
        label = "First Modifier Chance: %s%%",
        description = "Determines the % chance to give a valid object a Modifier. WARNING: Setting this too high can cause stuttering when first entering a cell. Any higher than 10% is not recommended."
            .. string.format(" Default: %s", common.config.mcmDefault.modifierChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "modifierChance", table = mcmConfig }
    }

    page:createSlider{
        label = "Second Modifier Chance: %s%%",
        description = "Determines the % chance to give a valid object a second Modifier. The actual chance may be slightly lower as some modifiers fail due to the name being too long."
        .. string.format(" Default: %s", common.config.mcmDefault.secondaryModifierChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "secondaryModifierChance", table = mcmConfig }
    }

    page:createSlider{
        label = "Wild Chance: %s%%",
        description = "Determines the % chance to give a valid object an additional Wild Modifier (if applicable). This will change the magnitude of all effects to be from 1 to (min + max)."
        .. string.format(" Default: %s", common.config.mcmDefault.wildChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "wildChance", table = mcmConfig }
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            common.updateLoggers(self.variable.value)
        end
    }
end
event.register("modConfigReady", registerMCM)