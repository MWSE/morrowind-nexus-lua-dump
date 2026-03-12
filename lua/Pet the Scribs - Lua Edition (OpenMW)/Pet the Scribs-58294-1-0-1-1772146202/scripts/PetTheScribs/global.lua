local types = require("openmw.types")
local I = require("openmw.interfaces")

require("scripts.PetTheScribs.logic.scribs")

local lastJellyTime = {}

local function onSave()
    return { lastJellyTime = lastJellyTime }
end

local function onLoad(saveData)
    if not saveData then return end
    lastJellyTime = saveData.lastJellyTime or {}
end

local function onCreatureActive(creature, actor)
    local scrib = Scribs[creature.recordId]
    if not scrib or types.Actor.isDead(creature) then return end
    scrib(actor, creature, { lastJellyTimeList = lastJellyTime })
end

I.Activation.addHandlerForType(types.Creature, onCreatureActive)

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
}
