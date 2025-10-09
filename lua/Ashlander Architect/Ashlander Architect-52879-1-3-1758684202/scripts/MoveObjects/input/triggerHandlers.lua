local input = require('openmw.input')
local ui = require('openmw.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')


local knownActions = require("scripts.MoveObjects.input.knownActions")

local keyBindings = storage.playerSection("AA_KeyBindings")


local function getKeyCodeKB(bindingName)
    return keyBindings:get(bindingName .. "_key")
end
local function getKeyCodeCTRL(bindingName)
    return keyBindings:get(bindingName .. "_ctrl")
end
local function onKeyPress()

end
local function onControllerButtonPress()

end

return {
    engineHandlers = {
        onKeyPress = function(key)
            if not types.Player.isCharGenFinished(self) then return end
            
            for index, value in pairs(knownActions) do
                if key.code == getKeyCodeKB(value) then
                    I.MoveObjects.handleInput(key, nil, value)
                end
            end
        end,
        onControllerButtonPress = function(ctrl)
            if not types.Player.isCharGenFinished(self) then return end
            for index, value in pairs(knownActions) do
                if ctrl == getKeyCodeCTRL(value) then
                    I.MoveObjects.handleInput(nil, ctrl, value)
                end
            end
        end,
        onMouseButtonPress = function(btn)
            for index, value in pairs(knownActions) do
                if btn == 1 and "leftMb" == getKeyCodeKB(value) then
                    I.MoveObjects.handleInput("leftMb", nil, value)
                elseif btn == 3 and "rightMb" == getKeyCodeKB(value) then
                    I.MoveObjects.handleInput("leftMb", nil, value)
                end
            end
        end
    }
}
