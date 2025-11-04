local types = require('openmw.types')

local this = {}


---@param object any
---@param itemId string
---@param countUnresolved boolean?
---@return integer?
function this.countOf(object, itemId, countUnresolved, defaultVal)
    if object.recordId == itemId then return object.count or defaultVal end
    if not (types.Actor.objectIsInstance(object) or types.Container.objectIsInstance(object)) then return defaultVal end

    local inventory = types.Container.objectIsInstance(object) and types.Container.inventory(object) or types.Actor.inventory(object)
    if countUnresolved and not inventory:isResolved() then return 1 end

    return inventory:countOf(itemId)
end


return this