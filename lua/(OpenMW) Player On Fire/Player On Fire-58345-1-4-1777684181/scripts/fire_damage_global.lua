local world = require('openmw.world')
local types = require('openmw.types')

local PLAYER_SCRIPT = 'scripts/fire_damage.lua'
local activeFires = {}

local shared = require('scripts.fire_shared')
local fireKeywords = shared.FIRE_KEYWORDS
local fireExemptions = shared.FIRE_EXEMPTIONS

local function isFireObject(obj)
    local id = obj.recordId
    if not id then return false end
    id = id:lower()

    local matched = false
    for i = 1, #fireKeywords do
        if id:find(fireKeywords[i], 1, true) then
            matched = true
            break
        end
    end
    if not matched then return false end

    for i = 1, #fireExemptions do
        if id == fireExemptions[i] then return false end
    end

    return true
end

local function syncWithPlayer()
    local player = world.players[1]
    if not player then return end

    local cleanList = {}
    for id, obj in pairs(activeFires) do
        if obj:isValid() and obj.count > 0 then
            cleanList[#cleanList + 1] = obj
        else
            activeFires[id] = nil
        end
    end

    if not player:hasScript(PLAYER_SCRIPT) then
        player:addScript(PLAYER_SCRIPT)
    end
    player:sendEvent('UpdateFireList', cleanList)
end

return {
    engineHandlers = {
        onObjectActive = function(obj)
            if (types.Static.objectIsInstance(obj) or 
                types.Activator.objectIsInstance(obj) or 
                types.Light.objectIsInstance(obj)) and isFireObject(obj) then
                
                activeFires[obj.id] = obj
                syncWithPlayer()
            end
        end,
    },
    eventHandlers = {
        RequestFireScan = syncWithPlayer
    }
}