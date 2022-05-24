local confPath = "sb_luce_remi_comp"

local mcm = { config              = mwse.loadConfig(confPath) or
        {
            mode    = 1,
            keyBind = { keyCode = tes3.scanCode.p }
        },
              uiMultiRefreshState = true,
              uiMapRefreshState   = true
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Immersive Compass" }
    template.onClose = function()
        mcm.uiMultiRefreshState = true
        mcm.uiMapRefreshState = true
        mwse.saveConfig(confPath, mcm.config)
    end
    --template:saveOnClose(confPath, mcm.config)

    local page = template:createPage { label = "", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Mode" }
    elementGroup:createDropdown {
        options  = {
            { label = "No Compass", value = 0 },
            { label = "Half Compass", value = 1 },
            { label = "Full Compass", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = mcm.config
        }
    }

    elementGroup = page:createSideBySideBlock()
    elementGroup:createInfo { text = "Hotkey" }
    elementGroup:createKeyBinder {
        variable = mwse.mcm:createTableVariable {
            id    = "keyBind",
            table = mcm.config
        }
    }

    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm