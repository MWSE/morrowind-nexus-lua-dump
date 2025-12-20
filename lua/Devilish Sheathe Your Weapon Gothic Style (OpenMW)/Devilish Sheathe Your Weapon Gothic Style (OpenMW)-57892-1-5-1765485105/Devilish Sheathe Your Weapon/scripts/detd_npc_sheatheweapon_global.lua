local types = require('openmw.types')
local util = require('openmw.util')

local SCRIPT_NAME = 'scripts/detd_npc_sheatheweapon.lua'
local hookedObjects = {}

local function onObjectActive(obj)
    if not obj or not obj:isValid() then return end
    if obj.type ~= types.NPC then return end
    if types.Actor.isDead(obj) then return end
    
    local id = obj.id
    if hookedObjects[id] then return end
    
    hookedObjects[id] = obj
    obj:addScript(SCRIPT_NAME)
end

local function unhookObject(data)
    local obj = data.object
    if not obj or not obj:isValid() then return end
    
    if obj.id then
        hookedObjects[obj.id] = nil
    end
    
    obj:removeScript(SCRIPT_NAME)
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
    },
    eventHandlers = {
        detd_npc_sheatheweapon_Unhook = unhookObject,
    },
}
