local util = require("mer.realisticArchery.util")
local config = util.config
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/auto-attack/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/auto-attack/wiki"
    -- },
    {
        text = "Nexus Page",
        url = "https://www.nexusmods.com/morrowind/mods/51348"
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
    local versionText = string.format(config.static.modName)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = config.static.modDescription}

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
    local template = mwse.mcm.createTemplate{ name = config.static.modName,}
    template.onClose = function()
        config.save(mcmConfig)
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
        label = "Max Noise: %s Degrees",
        description = "Determines many degrees a projectile can be off by, scaled to the firing NPC/player's Marksman skill."
          .. string.format(" Default: %s%%", config.mcmDefault.maxNoise),
        variable = mwse.mcm.createTableVariable{ id = "maxNoise", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
    }

    page:createSlider{
        label = "Min Distance to Full Damage (at lowest Marksman Skill): %s",
        description = "Determines the minimum distance a projectile must be before it does full damage. This distance is reduced by half at 100 Marksman skill"
            .. string.format(" Default: %s", config.mcmDefault.minDistanceFullDamage),
        variable = mwse.mcm.createTableVariable{ id = "minDistanceFullDamage", table = mcmConfig },
        min = 0,
        max = 5000,
        jump = 100,
        step = 1
    }

    page:createSlider{
        label = "Max Close Range Damage Reduction: %s%%",
        description = "Determines the maximum damage reduction a projectile can have when it is close to the target."
            .. string.format(" Default: %s%%", config.mcmDefault.maxCloseRangeDamageReduction),
        variable = mwse.mcm.createTableVariable{ id = "maxCloseRangeDamageReduction", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
    }

    page:createSlider{
        label = "Sneaking Multiplier: %s%%",
        description = "Dertermines the percentage noise will be reduced when the attacker is sneaking."
            .. string.format(" Default: %s%%", config.mcmDefault.sneakReduction),
        variable = mwse.mcm.createTableVariable{ id = "sneakReduction", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
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
            for _, logger in pairs(util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerMCM)