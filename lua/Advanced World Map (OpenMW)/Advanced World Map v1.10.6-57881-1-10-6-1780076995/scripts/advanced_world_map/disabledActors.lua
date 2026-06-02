local core = require("openmw.core")

local storage = require("scripts.advanced_world_map.storage.localStorage")
local commonData = require("scripts.advanced_world_map.common")

local this = {}


this.disabledActors = {}


function this.register(id)
    this.disabledActors[id] = true
end


function this.unregister(id)
    this.disabledActors[id] = nil
end


function this.contains(id)
    return this.disabledActors[id] ~= nil
end


function this.init()
    local storageData = storage.data[commonData.disabledActorsFieldId]
    if not storageData then
        storageData = {}
        if core.contentFiles.has("TR_Mainland.esm") then
            storageData["pc_m1_kaltandoralis"] = true
        end
    end

    this.disabledActors = storageData or {}
    storage.data[commonData.disabledActorsFieldId] = this.disabledActors
end


return this