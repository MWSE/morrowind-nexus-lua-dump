local storage = require('openmw.storage')
local common = require("scripts.proximityTool.common")

local this = {}

local id = 0

local storageSection = storage.playerSection(common.playerStorageId)
if storageSection then
    id = storageSection:get(common.uniqueIdKey) or 0
end


---@return string
function this.get()
    local res = string.format("%.0f", id)
    id = id + 1
    return res
end


function this.save()
    storageSection:set(common.uniqueIdKey, id)
end

return this