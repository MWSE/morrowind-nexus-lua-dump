local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local async = require('openmw.async')
local world = require('openmw.world')

-- fires when items appears active to game world
local function onItemActive(item)
    -- find partial string, recordId appears to be lower case      
    if string.find(item.recordId,string.lower("MwG_Apo_EoS")) then
        -- potion drop named event to first player (no multiplayer support)
        world.players[1]:sendEvent("potion_drop", { potion = item.recordId })
    end
end

-- fires when potion type is activated
I.Activation.addHandlerForType(types.Potion, async:callback(function(potion, actor)
    if string.find(potion.recordId,string.lower("MwG_Apo_EoS")) then
    --print("up") -- print    
    --potion pick event to player (same as above)
        world.players[1]:sendEvent("potion_pick", { potion = potion.recordId })
    end
end))

return { engineHandlers = { onItemActive = onItemActive }}