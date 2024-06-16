local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local core = require('openmw.core')

local stopFn = time.runRepeatedly(function()
    local EquippedItems = types.Actor.getEquipment(self.object)
    local totalWeight = 0 -- Initialize totalWeight inside the loop

    for i, obj in pairs(EquippedItems) do
        if obj and obj.type.records[obj.recordId].weight then
            -- Add the weight of the current object to the total weight
            totalWeight = totalWeight + math.floor(obj.type.records[obj.recordId].weight)
        end
    end
if totalWeight ~= nil then
core.sendGlobalEvent("detdGlobalWeight", totalWeight)
end
    
end,
1 * time.second)