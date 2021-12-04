local conf = require("bigJayB.PlaceSwap.mer_save").config
local function createMCM()
    local template = mwse.mcm.createTemplate("Jay's Place Swap & Move Away")
    template.onClose = function ()
        conf.save()
    end

    local page = template:createPage()
    page:createKeyBinder{
        label = "Assign key to use with the mod. Restart the game to apply the changes.",
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable{
            id = "key",
            table = conf,
            defaultSetting = {
                keyCode = tes3.scanCode.q,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }
    mwse.mcm.register(template)
end

event.register("modConfigReady", createMCM)