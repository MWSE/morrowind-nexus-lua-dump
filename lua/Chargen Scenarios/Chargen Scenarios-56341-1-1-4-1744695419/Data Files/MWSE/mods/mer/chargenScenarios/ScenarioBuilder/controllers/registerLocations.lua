--[[
    To use this
]]
local common = require('mer.chargenScenarios.common')
local Controls = require("mer.chargenScenarios.util.Controls")

local logger = require("mer.chargenScenarios.ScenarioBuilder.luaLogger").new{
    outputFile = "chargenScenariosLocations.txt",
}

local luaLocationTemplate = [[
    { --${name}
        position = {${posx}, ${posy}, ${posz}},
        orientation =${orz},
        cellId = "${cell}"
    },
]]


local function addLocation(locationToAdd, name)
    local locationString = luaLocationTemplate:
        gsub("${name}", name):
        gsub("${posx}", locationToAdd.position[1]):
        gsub("${posy}", locationToAdd.position[2]):
        gsub("${posz}", locationToAdd.position[3]):
        gsub("${orz}", locationToAdd.orientation)
    if tes3.player.cell.isInterior then
        locationString = locationString:gsub("${cell}", locationToAdd.cell.id)
    else
        locationString = locationString:gsub("${cell}", "nil")
    end
    logger:info("\n" .. locationString)
end

local function registerLocation()
    local location = {
        position = {
            math.floor(tes3.player.position.x),
            math.floor(tes3.player.position.y),
            math.floor(tes3.player.position.z),
        },
        orientation = math.round(tes3.player.orientation.z, 2),
        cell = tes3.player.cell
    }
    timer.delayOneFrame(function()
        local menuId = tes3ui.registerID("Location_Register_Menu")
        local menu = tes3ui.createMenu{ id = menuId, fixedFrame = true }
        menu.minWidth = 400
        menu.alignX = 0.5 ---@diagnostic disable-line
        menu.alignY = 0 ---@diagnostic disable-line
        menu.autoHeight = true
        local t = { name = tes3.player.cell.name }
        local textField = mwse.mcm.createTextField(
            menu,
            {
                label = "Enter name of location:",
                variable = mwse.mcm.createTableVariable{
                    id = "name",
                    table = t
                },
                callback = function()
                    addLocation(location, t.name)
                    tes3ui.leaveMenuMode()
                    tes3ui.findMenu(menuId):destroy()
                end
            }
        )
        tes3ui.acquireTextInput(textField.elements.inputField)
        tes3ui.enterMenuMode(menuId)
    end)
end

---@param e keyDownEventData
local function onKeyDown(e)
    if common.config.mcm.registerLocationsEnabled then
        if Controls.isKeyPressed(e, common.config.mcm.registerLocationsHotKey) then
            tes3ui.showMessageMenu{
                message = "Register current position/orientation/cell as a starting location?",
                buttons = {
                    {
                        text = "Yes",
                        callback = registerLocation
                    },
                    {
                        text = "Cancel"
                    }
                }
            }
        end
    end
end
event.register("keyDown", onKeyDown)

