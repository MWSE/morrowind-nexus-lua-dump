local config  = require("Krimson.Auto Harvest.config")

local template = mwse.mcm.createTemplate("Auto Harvest")
    template:saveOnClose("Auto Harvest", config)
    template:register()

local page = template:createSideBarPage({
    label = "Auto Harvest",
    description = "Automatically harvests ingredients from any organic containers within range.\n\nWill not harvest any container that is blacklisted or has a script attached to it",
})

local settings = page:createCategory("Auto Harvest Settings\n\n\n")

settings:createOnOffButton({
    label = "Auto Mode\n\n\n",
    description = "Turns on/off Auto Mode. Same as using the hotkey listed below.\n\nDefault: On\n\n",
    variable = mwse.mcm.createTableVariable {id = "waitHarvest", table = config}
})

settings:createKeyBinder{
    label = "Auto Mode Hotkey. Restart the game to apply.\n\n\n",
    description = "Changes the keys to turn on/off Auto Mode.\n\nDefault: P\n\n",
    allowCombinations = true,
    restartRequired = false,
    variable = mwse.mcm.createTableVariable{id = "toggleMod", table = config, defaultSetting = {keyCode = tes3.scanCode.p, isShiftDown = false, isAltDown = false, isControlDown = false}}
}

settings:createKeyBinder{
    label = "Harvest Hotkey. Restart the game to apply.\n\n\n",
    description = "Changes the keys to harvest on key press.\n\nOnly active if Auto Mode is off.\n\nDefault: H\n\n",
    allowCombinations = true,
    restartRequired = false,
    variable = mwse.mcm.createTableVariable{id = "harvestKey", table = config, defaultSetting = {keyCode = tes3.scanCode.h, isShiftDown = false, isAltDown = false, isControlDown = false}}
}

settings:createKeyBinder{
    label = "Cell Blacklist Hotkey. Restart the game to apply.\n\n\n",
    description = "Changes the keys to add/remove current cell from blacklist.\n\nDefault: B\n\n",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{id = "blacklistKey", table = config, defaultSetting = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}}
}

settings:createOnOffButton({
    label = "Enable Auto Harvest on Waiting\n\n",
    description = "Turns on/off Auto Harvesting while \"waiting\" in the rest menu.\n\nOnly active if Auto Mode is off.\n\nDefault: Off\n\n",
    variable = mwse.mcm.createTableVariable {id = "waitHarvest", table = config}
})

settings:createSlider{
    label = "\n\nDistance from player to harvest",
    description = "Changes the distance which Auto Harvest will gather ingredients.\n\nDistance is game units(256) multiplied by slider value.\n\nWill only harvest from containers in the current cell.\n\nDefault: 2\n\n",
    min = 1,
    max = 20,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{id = "harvestDistance", table = config}
}

settings:createSlider{
    label = "\n\n\nScan interval between harvests",
    description = "Changes the time between each Auto Harvest scan.\n\nTime is measured in seconds.\n\nOnly active if Auto Mode is on.\n\nDefault: 10\n\n",
    min = 1,
    max = 30,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{id = "harvestTime", table = config}
}

settings:createOnOffButton({
    label = "Ingredients",
    description = "Turns on/off harvesting loose ingredients.\n\nDefault: On\n\n",
    variable = mwse.mcm.createTableVariable {id = "ingredient", table = config}
})

template:createExclusionsPage{
    label = "Container Blacklist",
    description = "All organic non-plant containers and minerals(adamantium, diamonds, ebony, and glass) are blacklisted by default.\n\n Any container blacklisted here will NOT be harvested.",
    leftListLabel = "Blacklisted Containers",
    rightListLabel = "Harvestable Containers",
    variable = mwse.mcm.createTableVariable{
        id = "AHContainerBL",
        table = config,
    },
    filters = {
        {
            label = "Cells",
            callback = function()

                local cellList = {}

                for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do

                    table.insert(cellList, cell.id:lower())
                end
                table.sort(cellList)
                return cellList
            end

        },

        {
            label = "Containers",
            callback = function ()

                local itemList = {}

                for item in tes3.iterateObjects(tes3.objectType.container) do

                    if item.script == nil then

                        table.insert(itemList, item.id:lower())
                    end
                end
                table.sort(itemList)
                return itemList
            end
        },

        {
            label = "Ingredients",
            callback = function ()

                local itemList = {}

                for item in tes3.iterateObjects(tes3.objectType.ingredient) do

                    if item.script == nil then

                        table.insert(itemList, item.id:lower())
                    end
                end
                table.sort(itemList)
                return itemList
            end
        },
    },
}