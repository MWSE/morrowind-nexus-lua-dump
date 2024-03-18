local core = require "openmw.core"
local input = require("openmw.input")
local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local ui = require('openmw.ui')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local startTime = core.getRealTime()        -- Start time since the game started
local storage = require('openmw.storage')

local selectedObjects = {}

local function removeSelectedObject(obj)
    for index, value in ipairs(selectedObjects) do
        if value == obj then
            table.remove(selectedObjects, index)
            obj:sendEvent("setStance", { stance = types.Actor.STANCE.Nothing })
            obj:sendEvent("setSelected", false)
        end
    end
end
local function updateSelectedObject(obj)
    if not input.isShiftPressed() then
        for index, value in ipairs(selectedObjects) do
            value:sendEvent("setStance", { stance = types.Actor.STANCE.Nothing })
            value:sendEvent("setSelected", false)
            table.remove(selectedObjects, index)
        end
        selectedObjects = {}
    end
    
    table.insert(selectedObjects, obj)

    obj:sendEvent("setStance", { stance = types.Actor.STANCE.Weapon })
    obj:sendEvent("setSelected", true)
end
local function objectSelected(obj)

    for index, value in ipairs(selectedObjects) do
        if value == obj then
            return true
        end
    end
    return false
end
--
local function processMouseClick(clickPos, clickObject, rightClick, leftClick)
    print("Click")

    if clickObject and clickObject.type == types.NPC and leftClick then
        if not objectSelected(clickObject) then
            updateSelectedObject(clickObject)
        end
    elseif clickPos and rightClick and (not clickObject or clickObject.type ~= types.NPC) then
        for index, actor in ipairs(selectedObjects) do
            
        actor:sendEvent('StartAIPackage', { type = 'Travel', destPosition = clickPos })
        end
    elseif clickPos and rightClick and (clickObject and clickObject.type == types.NPC) then
        for index, actor in ipairs(selectedObjects) do
            actor:sendEvent('StartAIPackage', { type = 'Combat', target = clickObject })
        end
    elseif not clickObject and leftClick then
        selectedObjects = {}
    end
end

local function getSelectedObjects()
    if not selectedObjects then
        selectedObjects = {}
    end
    return selectedObjects
end

return {
    interfaceName = "BFMT_Selection",
    interface = {
        processMouseClick = processMouseClick,
        getSelectedObjects = getSelectedObjects,
    }
}
