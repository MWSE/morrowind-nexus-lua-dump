local types = require("openmw.types")

local storage = require("scripts.advanced_world_map.storage.localStorage")
local commonData = require("scripts.advanced_world_map.common")

local this = {}


this.doorHashTable = {}


function this.register(ref)
    local id = commonData.doorHash(ref, types.Door.destCell(ref).id)
    this.doorHashTable[id] = true
end


function this.unregister(ref)
    local id = commonData.doorHash(ref, types.Door.destCell(ref).id)
    this.doorHashTable[id] = nil
end


function this.contains(refOrHashId)
    if type(refOrHashId) ~= "string" then
        refOrHashId = commonData.doorHash(refOrHashId, types.Door.destCell(refOrHashId).id)
    end
    return this.doorHashTable[refOrHashId] ~= nil
end


function this.init()
    this.doorHashTable = storage.data[commonData.disabledDoorsFieldId] or {}
end


return this