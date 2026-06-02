local types = require("openmw.types")
local I = require("openmw.interfaces")

require("scripts.PetTheScribs.logic.scribs")

local CREATURE_SCRIPT = 'scripts/PetTheScribs/scribAnim.lua'
local lastJellyTime = {}
local totalPats = {}

local function onSave()
    return {
        lastJellyTime = lastJellyTime,
        totalPats = totalPats,
    }
end

local function onLoad(saveData)
    if not saveData then return end
    lastJellyTime = saveData.lastJellyTime or {}
    totalPats = saveData.totalPats or {}
end

local function onCreatureActive(creature, actor)
    local scrib = Scribs[creature.recordId]
    if not scrib or types.Actor.isDead(creature) then return end
    creature:addScript(CREATURE_SCRIPT)

    scrib(actor, creature, { lastJellyTimeList = lastJellyTime })

    totalPats[actor.id] = totalPats[actor.id] and totalPats[actor.id] + 1 or 1
    -- because other mods deserve to know it too
    actor:sendEvent("PetTheScribs_ScribPetted", totalPats[actor.id])
end

I.Activation.addHandlerForType(types.Creature, onCreatureActive)

local function onAskedDetach(creature)
    creature:removeScript(CREATURE_SCRIPT)
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        PetTheScribs_detachMe = onAskedDetach,
    },
}
