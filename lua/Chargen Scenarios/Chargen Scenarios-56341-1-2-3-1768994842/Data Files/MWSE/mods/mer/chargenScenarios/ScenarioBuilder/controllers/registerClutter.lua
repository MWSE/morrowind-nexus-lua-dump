
local common = require("mer.chargenScenarios.common")
local Controls = require("mer.chargenScenarios.util.Controls")


local logger = require("mer.chargenScenarios.ScenarioBuilder.luaLogger").new{
    outputFile = "ChargenScenarioClutter.txt",
}

local luaClutterTemplate = [[
    { --${name}
        ids = {"${id}"},
        position = {${posx}, ${posy}, ${posz}},
        orientation = {${orz}},
        cell = "${cell}",
        scale = ${scale},
    },
]]

local function addClutter(clutterToAdd)
    local clutterString = luaClutterTemplate:
        gsub("${name}", clutterToAdd.name or ""):
        gsub("${id}", clutterToAdd.id):
        gsub("${posx}", clutterToAdd.position[1]):
        gsub("${posy}", clutterToAdd.position[2]):
        gsub("${posz}", clutterToAdd.position[3]):
        gsub("${orz}", table.concat(clutterToAdd.orientation, ", ")):
        gsub("${cell}", clutterToAdd.cell.id):
        gsub("${scale}", clutterToAdd.scale)
    logger:info("\n" .. clutterString)
end

---@param target tes3reference
local function registerClutter(target)
    local clutter = {
        name = target.object.name,
        id = target.object.id,
        position = {
            math.floor(target.position.x),
            math.floor(target.position.y),
            math.floor(target.position.z),
        },
        orientation = {
            target.orientation.x,
            target.orientation.y,
            target.orientation.z,
        },
        cell = target.cell,
        scale = string.format("%.2d", target.scale),
        data = (function()
            local data = {}
            for k, v in pairs(target.data) do
                if not type(v) == "table" then
                    data[k] = v
                end
            end
            return data
        end)()
    }
    addClutter(clutter)
end

---@param e keyDownEventData
local function onKeyDown(e)
    if common.config.mcm.registerClutterEnabled then
        if Controls.isKeyPressed(e, common.config.mcm.registerClutterHotKey) then
            local result = tes3.rayTest{
                position = tes3.getPlayerEyePosition(),
                direction = tes3.getPlayerEyeVector(),
                ignore = { tes3.player },
                maxDistance = tes3.getPlayerActivationDistance()
            }
            if not (result and result.reference) then
                tes3.messageBox("No reference found.")
                return
            end
            local target = result.reference

            tes3ui.showMessageMenu{
                message = string.format("Register %s as clutter?", target.object.name),
                buttons = {
                    {
                        text = "Yes",
                        callback = function()
                            registerClutter(target)
                        end
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

