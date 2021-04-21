local config = require("OperatorJack.TheLevitationAct.config")

local function getCells()
    local temp = {}
    local cells = tes3.dataHandler.nonDynamicData.cells

    for i=1, #cells do
        temp[cells[i].id:lower()] =  true
    end
    
    local list = {}
    for name in pairs(temp) do
        list[#list+1] = name
    end
    
    table.sort(list)
    return list
end

local function createGeneralCategory(template)
    local page = template:createSideBarPage{
        label = "General Settings",
        description = "Hover over a setting to learn more about it."
    }

    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createSlider{
        label = "Bounty Value",
        description = "Use this option to configure the amount of bounty received when getting caught using the levitation efect.",
        min = 0,
        max = 1000,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "bountyValue",
            table = config
        }
    }

    return category
end

local function createCellWhitelist(template)
    template:createExclusionsPage{
        label = "Whitelist Cells",
        description = "Whitelisted cells will never trigger a crime when levitation is used in those cells. The whitelisted cell will also apply to any cells beginning with that cell name. For example, 'Tel Vos' whitelists all cells starting with 'Tel Vos'.",
        leftListLabel = "Whitelist Cells",
        rightListLabel = "Cells",
        variable = mwse.mcm.createTableVariable{
            id = "cellWhitelist",
            table = config,
        },
        filters = {
            {callback = getCells},
        },
    }
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("The Levitation Act")
template:saveOnClose("The-Levitation-Act", config)

createGeneralCategory(template)
createCellWhitelist(template)

mwse.mcm.register(template)