local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local metadata = config.metadata --[[@as MWSE.Metadata]]
local logger = common.createLogger("MCM")

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/joy-of-painting/releases"
    },
    {
        text = "Wiki",
        url = "https://github.com/jhaakma/joy-of-painting/wiki"
    },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/53036"
    },
    {
        text = "Buy me a coffee",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://next.nexusmods.com/profile/Merlord/mods",
    },
    {
        text = "ImageLib by Greatness7",
        url = "https://next.nexusmods.com/profile/Greatness7/mods",
    }
}

local function addSideBar(component)
    component.sidebar:createCategory(metadata.package.name)
    component.sidebar:createInfo{ text = metadata.package.description}

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
    local template = mwse.mcm.createTemplate{ name = metadata.package.name }
    template.onClose = function()
        config.save()
        event.trigger("JoyOfPainting:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config.mcm },
        callback = function(self)
            if self.variable.value == true then
                logger:info("Enabling mod")
                event.trigger("JoyOfPainting:ModEnabled")
                event.trigger("JoyOfPainting:McmUpdated")
            else
                logger:info("Disabling mod")
                event.trigger("JoyOfPainting:ModDisabled")
            end
        end
    }

    page:createSlider{
        label = "Max Saved Paintings",
        description = "Set the maximum number of full-resolution paintings of each art style saved to `Data Files/Textures/jop/saved/`. Once the maximum is reached, the oldest painting will be deleted to make room for the new one.",
        min = 1,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "maxSavedPaintings", table = config.mcm },
    }

    page:createTextField{
        label = "Saved Painting Size",
        description = "Set the size of the saved paintings. This will be the length of the smallest dimension of the painting.",
        variable = mwse.mcm.createTableVariable{ id = "savedPaintingSize", table = config.mcm },
        numbersOnly = true,
    }

    page:createYesNoButton{
        label = "Enable Tapestry Removal",
        description = "When enabled, you can activate a tapestry to remove it to make room for a painting.",
        variable = mwse.mcm.createTableVariable{ id = "enableTapestryRemoval", table = config.mcm },
    }

    page:createYesNoButton{
        label = "Show Tapestry Tooltip",
        description = "When enabled, a tooltip will be shown when you hover over a tapestry. Requires a restart for change to take effect.",
        variable = mwse.mcm.createTableVariable{ id = "showTapestryTooltip", table = config.mcm },
        restartRequired = true,
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for all JoyOfPainting Loggers.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }

    template:createExclusionsPage{
        label = "Paint Supplies Merchants",
        description = "Select which merchants sell paint supplies.",
        leftListLabel = "Paint Supplies Merchants",
        rightListLabel = "Excluded Merchants",
        filters = {
            {
                label = "",
                callback = function()
                    local npcs = {}
                    for obj in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast obj tes3npc
                        if obj.class and obj.class.bartersMiscItems then
                            local id = obj.id:lower()
                            npcs[id] = true
                        end
                        if obj.aiConfig.bartersMiscItems then
                            local id = obj.id:lower()
                            npcs[id] = true
                        end
                    end
                    local npcsList = {}
                    for npc, _ in pairs(npcs) do
                        table.insert(npcsList, npc)
                    end
                    table.sort(npcsList)
                    return npcsList
                end
            }
        },
        variable = mwse.mcm.createTableVariable{
            id = "paintSuppliesMerchants",
            table = config.mcm,
        },
    }
end
event.register("modConfigReady", registerMCM)