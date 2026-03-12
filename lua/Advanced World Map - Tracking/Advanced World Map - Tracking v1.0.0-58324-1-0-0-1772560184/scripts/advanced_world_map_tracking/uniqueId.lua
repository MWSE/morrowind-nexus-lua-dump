local storage = require("openmw.storage")
local common = require("scripts.advanced_world_map_tracking.common")

local this = {}

local id = 0

local storageSection = storage.playerSection(common.defaultStorageId)
if storageSection then
    id = storageSection:get(common.uniqueIdKey) or 0
end


---@return string
function this.get()
    local res = string.format("%.0f", id)
    id = id + 1
    return res
end


function this.load(data)
    id = data[common.uniqueIdKey] or 0
end


function this.save(data)
    data[common.uniqueIdKey] = id
end

return this