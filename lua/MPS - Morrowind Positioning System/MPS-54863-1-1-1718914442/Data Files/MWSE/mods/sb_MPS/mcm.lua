local config = mwse.loadConfig("sb_MPS")
if not config then
    config = { units = 0, style = 0 }
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Morrowind Positioning System" }
    template:saveOnClose("sb_MPS", config)

    local page = template:createPage { label = "Config", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup:createInfo { text = "Unit System" }
    elementGroup:createDropdown {
        options  = {
            { label = "Morrowind Units", value = 0 },
            { label = "Metric Units", value = 1 },
            { label = "Imperial Units", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "units",
            table = config
        }
    }
    
    elementGroup = page:createSideBySideBlock()

    elementGroup:createInfo { text = "Style" }
    elementGroup:createDropdown {
        options  = {
            { label = "Global Cooridinates", value = 0 },
            { label = "Local Coordinates (w/o Cells in Interiors)", value = 1 },
            { label = "Local Coordinates (w/ Cells in Interiors)", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "style",
            table = config
        }
    }

    mwse.mcm.register(template)
end

local mcm = { config = config }

function mcm.init()
    event.register(tes3.event.modConfigReady, registerModConfig)
end

return mcm