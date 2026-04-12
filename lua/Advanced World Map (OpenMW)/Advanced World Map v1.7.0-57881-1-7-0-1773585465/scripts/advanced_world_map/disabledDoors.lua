local types = require("openmw.types")

local pDoor = require("scripts.advanced_world_map.helpers.protectedDoor")

local storage = require("scripts.advanced_world_map.storage.localStorage")
local commonData = require("scripts.advanced_world_map.common")

local this = {}


this.doorHashTable = {}


function this.register(ref)
    local destCell = pDoor.destCell(ref)
    if not destCell then return end
    local id = commonData.doorHash(ref, destCell.id)
    this.doorHashTable[id] = true
end


function this.unregister(ref)
    local destCell = pDoor.destCell(ref)
    if not destCell then return end
    local id = commonData.doorHash(ref, destCell.id)
    this.doorHashTable[id] = nil
end


function this.contains(refOrHashId)
    if type(refOrHashId) ~= "string" then
        local destCell = pDoor.destCell(refOrHashId)
        if not destCell then return false end
        refOrHashId = commonData.doorHash(refOrHashId, destCell.id)
    end
    return this.doorHashTable[refOrHashId] ~= nil
end


function this.init()
    this.doorHashTable = storage.data[commonData.disabledDoorsFieldId] or {}
end


return this