local modInfo = require("EquipmentRequirements.modInfo")
local config = require("EquipmentRequirements.config")

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod implements skill requirements to equip weapons and armor. If your relevant skill is not high enough, you will either be unable to equip the item or be subject to penalties. Hover over the \"alternate mode\" option to learn more.",
    }

    page:createOnOffButton{
        label = "Alternate mode",
        description =
            "Normally (with alternate mode off), if you do not meet the skill requirement for an item, you will not be able to equip that item.\n" ..
            "\n" ..
            "With alternate mode enabled, you will be able to equip items you normally don't have the skill for, but you will be subject to penalties for doing so.\n" ..
            "\n" ..
            "These penalties can include: more fatigue loss for attacking, more fatigue loss for running, slower movement speed, and lower chance to successfully cast spells.\n" ..
            "\n" ..
            "Changing this setting will require restarting Morrowind.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "alternateMode",
            table = config,
        },
        restartRequired = true,
        defaultSetting = false,
    }

    return page
end

local template = mwse.mcm.createTemplate("Equipment Requirements")
template:saveOnClose("EquipmentRequirements", config)

createPage(template)
mwse.mcm.register(template)