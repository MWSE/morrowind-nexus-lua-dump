local config = require("OperatorJack.Wands.config")

local function getWeaponMeshes()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.weapon) do
        temp[obj.mesh:lower()] = true
    end
    
    local list = {}
    for mesh in pairs(temp) do
        list[#list+1] = mesh
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
    category:createOnOffButton{
        label = "Enable Debug Messages",
        description = "If enabled, Morrowind will show all debug messages related to this mod in-game and in the MWSE.log.",
        variable = mwse.mcm.createTableVariable{
            id = "showDebug",
            table = config
        }
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Apply Wand Mechanic to Staves",
        description = "If enabled, the wand mechanic will be applied to all weapons of type 'Blunt 2H Wide'.",
        variable = mwse.mcm.createTableVariable{
            id = "applyToStaves",
            table = config
        }
    }

    return category
end

local function createWandsList(template)
    template:createExclusionsPage{
        label = "Wands",
        description = "Meshes registered as wands below will use wand functionality on any weapon that uses that mesh.",
        leftListLabel = "Wand Meshes",
        rightListLabel = "All Weapon Meshes",
        variable = mwse.mcm.createTableVariable{
            id = "wands",
            table = config,
        },
        filters = {
            {callback = getWeaponMeshes},
        },
    }
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Wands")
template:saveOnClose("Wands", config)

createGeneralCategory(template)
createWandsList(template)

mwse.mcm.register(template)