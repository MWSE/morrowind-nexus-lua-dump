local self = require('openmw.self')
local core = require('openmw.core')

local owner = {}
return {
    engineHandlers = {
        onActive = function()
            owner = {
                recordId = self.owner.recordId,
                factionId = self.factionId,
                factionRank = self.factionRank,
            }
        end,
        onInactive = function()
            if next(owner) then
                core.sendGlobalEvent('IE_OwnedItemInactive', {
                    recordId = self.recordId,
                    owner = owner,
                })
            end
        end
    }
}