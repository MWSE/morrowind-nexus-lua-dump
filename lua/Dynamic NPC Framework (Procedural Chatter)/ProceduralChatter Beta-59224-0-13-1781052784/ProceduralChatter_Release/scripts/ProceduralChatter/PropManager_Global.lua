
local ScheduleConfig = require("scripts.ProceduralChatter.data.ScheduleConfig")
local originalPrint = print
_G.print = function(...)
    if ScheduleConfig.DEBUG_MODE then
        originalPrint(...)
    end
end

local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

-- Event Handlers

local function onEquipRequest(e)
    local actor = e.actor
    local propId = e.propId
    local slot = e.slot
    
    if not actor:isValid() then return end

    local inv = types.Actor.inventory(actor)
    local itemRef = inv:find(propId)
    
    -- If not found, create it
    if not itemRef then
         itemRef = world.createObject(propId, 1)
         itemRef:moveInto(inv)
         print(string.format("[PropManager_Global] Added prop '%s' to %s", propId, actor.recordId))
         
         -- IMPORTANT: moveInto might invalidate the specific lua object reference wrapper?
         -- But typically, the object remains valid for script usage.
         -- If OpenMW API shifts the pointer, we might need to re-find it?
         -- However, standard logic suggests 'itemRef' is the object handler. 
         -- If this fail, we know 'find' failed, so we rely on this new object.
    end
    
    -- Send Confirmation back to Local Actor to Equip
    -- (setEquipment must be called locally on SelfObject)
    actor:sendEvent("PropManager_EquipConfirm", { 
        propId = propId, 
        slot = slot 
    })
    print(string.format("[PropManager_Global] Sent EquipConfirm for %s to %s", propId, actor.recordId))
end

local function onUnequipRequest(e)
    local actor = e.actor
    local propId = e.propId
    local slot = e.slot

    if not actor:isValid() then return end

    -- 1. Unequip
    local equipment = types.Actor.getEquipment(actor)
    -- Check if current slot has our prop
    -- Comparing ItemRef is tricky, check recordId
    local currentItem = equipment[slot]
    if currentItem and currentItem.recordId == propId then
        equipment[slot] = nil
        types.Actor.setEquipment(actor, equipment)
    end

    -- 2. Remove from Inventory
    local inv = types.Actor.inventory(actor)
    -- Removing specific count
    if inv:countOf(propId) > 0 then
        inv:remove(propId, 1)
    end
     print(string.format("[PropManager_Global] Removed %s from %s", propId, actor.recordId))
end


return {
    interfaceName = "PropManager_Global",
    interface = {},
    eventHandlers = {
        PropManager_EquipRequest = onEquipRequest,
        PropManager_UnequipRequest = onUnequipRequest,
        PropManager_GiveItem = function(e) 
             local item = world.createObject(e.itemId, e.count or 1)
             item:moveInto(types.Actor.inventory(e.actor))
        end,
        PropManager_RemoveRequest = function(e)
            local actor = e.actor
            local propId = e.propId
            if not actor:isValid() then return end
            
            local inv = types.Actor.inventory(actor)
            if inv:countOf(propId) > 0 then
                -- Remove all instances or just 1? User implies full cleanup.
                -- Let's remove countOf.
                local count = inv:countOf(propId)
                local item = inv:find(propId)
                if item then
                    item:remove(count)
                end
            end
        end
    }
}
