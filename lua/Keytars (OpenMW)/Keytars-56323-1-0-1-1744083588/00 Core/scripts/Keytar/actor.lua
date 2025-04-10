local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')

local ignoreTimer = 0
local ignoreTimerMax = 3

local function isKeytarist(actor)
    if actor.type ~= types.NPC or actor.recordId == self.recordId then
        return false
    end
    local equippedR = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    return equippedR and equippedR.recordId == "_rlts_wep_keytar"
end

local function update(dt)
    if ignoreTimer < ignoreTimerMax then
        ignoreTimer = ignoreTimer + dt
        I.AI.filterPackages(function(package)
            return not (package.type == 'Combat' and package.target and isKeytarist(package.target))
        end)
    end
end

local function onDiedOrInactive()
    core.sendGlobalEvent('ActorDiedOrInactive', { actor = self })
end

return {
    engineHandlers = {
        onUpdate = update,
        onInactive = onDiedOrInactive
    },
    eventHandlers = {
        Died = onDiedOrInactive,
        IgnoreKeytarists = function()
            ignoreTimer = 0
        end
    }
}