local modInfo = require("WeightOfTheWorld.modInfo")
local config = require("WeightOfTheWorld.config")
local common = require("WeightOfTheWorld.common")

local multText = " will be multiplied by this value, and the result will contribute to your max encumbrance. Non-integer values are allowed. A value of 0 means this attribute will not contribute to max encumbrance. Negative values will be converted to 0 in-game.\n"

local function changeEnc()
    if not tes3.mobilePlayer then
        return
    end

    local newStr, newEnd, newAgi = common.getAttributes()
    common.changeEnc(newStr, newEnd, newAgi)
end

local function createPage(template)
    local page = template:createSideBarPage{
        description =
            modInfo.mod .. "\n" ..
            "Version " .. modInfo.version .. "\n" ..
            "\n" ..
            "This mod allows you to customize how maximum encumbrance is calculated. In vanilla Morrowind, max encumbrance is determined by applying a multiplier to strength. With this mod, you can also have multipliers for other attributes, add a constant term to the formula independent of attributes, implement a limit to how high max encumbrance can get regardless of attributes, and more.\n" ..
            "\n" ..
            "Hover over each setting to learn more about it.",
    }

    page:createTextField{
        label = "Strength multiplier",
        description =
            "Your strength" .. multText ..
            "\n" ..
            "Default: 5",
        variable = mwse.mcm.createTableVariable{
            id = "strMult",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 5,
        callback = function()
            -- Adding a callback for some reason disables this messagebox on changing the value, so let's just do it manually.
            tes3.messageBox("New value: \'%s\'", config.strMult)
            changeEnc()
        end,
    }

    page:createTextField{
        label = "Endurance multiplier",
        description =
            "Your endurance" .. multText ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "endMult",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 0,
        callback = function()
            tes3.messageBox("New value: \'%s\'", config.endMult)
            changeEnc()
        end,
    }

    page:createTextField{
        label = "Agility multiplier",
        description =
            "Your agility" .. multText ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "agiMult",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 0,
        callback = function()
            tes3.messageBox("New value: \'%s\'", config.agiMult)
            changeEnc()
        end,
    }

    page:createTextField{
        label = "Constant term",
        description =
            "This value will be tacked onto your max encumbrance as a constant amount, after the multipliers above have been applied. Negative values will be converted to 0 in-game.\n" ..
            "\n" ..
            "This acts as a minimum max encumbrance, which you'll have even when the relevant attributes have been drained or damaged to 0.\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "constantTerm",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = 0,
        callback = function()
            tes3.messageBox("New value: \'%s\'", config.constantTerm)
            changeEnc()
        end,
    }

    page:createTextField{
        label = "Maximum max encumbrance",
        description =
            "This value acts as a cap to max encumbrance. Your max encumbrance will never exceed this value, no matter how high the relevant attributes get.\n" ..
            "\n" ..
            "A negative value for this setting has a special function: it means there will be no cap to max encumbrance at all (as in vanilla).\n" ..
            "\n" ..
            "Default: -1 (i.e. no cap)",
        variable = mwse.mcm.createTableVariable{
            id = "maxMax",
            table = config,
            numbersOnly = true,
        },
        defaultSetting = -1,
        callback = function()
            tes3.messageBox("New value: \'%s\'", config.maxMax)
            changeEnc()
        end,
    }

    page:createOnOffButton{
        label = "More accurate encumbrance display",
        description =
            "In vanilla, the inventory menu will only display your encumbrance (current and max) as an integer, even though both can be non-integer values. If this setting is enabled, the encumbrance display will show two digits past the decimal point (accurate to a hundredth of a weight unit) for both current and max encumbrance.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "accurateDisplay",
            table = config,
        },
        defaultSetting = false,
        callback = common.updateEncDisplay,
    }

    return page
end

local template = mwse.mcm.createTemplate("Weight of the World")
template:saveOnClose("WeightOfTheWorld", config)

createPage(template)

mwse.mcm.register(template)