local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')

local PropManager = {}

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function PropManager.equipProp(propId)
    -- Send Global Request (Ensures item exists/added)
    core.sendGlobalEvent('PropManager_EquipRequest', { 
        actor = self, 
        propId = propId
    })
end

function PropManager.unequipProp(propId)
    core.sendGlobalEvent('PropManager_UnequipRequest', {
        actor = self,
        propId = propId
    })
end

function PropManager.cleanupProp(propId)
    if not propId then return end
    core.sendGlobalEvent('PropManager_RemoveRequest', {
        actor = self,
        propId = propId
    })
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

function PropManager.onEquipConfirm(data)
    local itemId = data.propId
    
    local inv = types.Actor.inventory(self)
    local itemRef = inv:find(itemId)
    
    if itemRef then
        core.sendGlobalEvent('UseItem', {
            object = itemRef,
            actor = self,
            force = true
        })
    else
        print(string.format("[PropManager] ERROR: Item %s missing from inventory after Global Confirm.", itemId))
    end
end

return PropManager
