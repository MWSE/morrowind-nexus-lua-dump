local confPath = "sb_smith"

local mcm = { config = mwse.loadConfig(confPath) or
    {
        faithfulEnabled = 0
    }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Smith - The Weapon Crafting Framework" }
    template.onClose = function()
        mwse.saveConfig(confPath, mcm.config)
    end

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Faithful Mode" }
    elementGroup:createDropdown {
        options  = {
            { label = "Disabled", value = 0 },
            { label = "Enabled", value = 1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = mcm.config
        }
    }
    page:createInfo{
        text = "Treats weapon crafting similar to repair tools, with a chance for failure and the destruction of the separate parts."
    }

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm