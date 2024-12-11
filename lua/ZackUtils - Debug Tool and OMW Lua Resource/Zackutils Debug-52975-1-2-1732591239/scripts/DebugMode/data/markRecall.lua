local cam = require('openmw.interfaces').Camera
local camera = require('openmw.camera')
local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local storage = require("openmw.storage")
local async = require("openmw.async")
local input = require("openmw.input")
local I = require("openmw.interfaces")

--local markRecall = require("scripts.DebugMode.data.markRecall")
local markStorage = storage.playerSection("markStorage")

local function saveLocation(pos)
    local key = tostring(pos):lower()
    markStorage:set(key,{position = self.position,rotation = self.rotation,cell = self.cell.id})

    return "Saved location to " .. key
end
local function getLocation(pos)
    local val = markStorage:get(tostring(pos):lower())
    return val
end
local function runRecall(pos)
    local location = getLocation(pos)
    if location then
        print("Found Location")
    else
        return "No location"
    end
    core.sendGlobalEvent("ZackUtilsTeleportToCell", {
        cellId = location.cell,
        item = self,
        position = location.position,
        rotation = location.rotation
    })
    return "Teleported to cell  " .. location.cell
end
local function isValidLocation(key)
    
    local location = getLocation(key)
    return location ~= nil
end
return {
    saveLocation = saveLocation,
    getLocation = getLocation,
    runRecall = runRecall,
    isValidLocation = isValidLocation,
}