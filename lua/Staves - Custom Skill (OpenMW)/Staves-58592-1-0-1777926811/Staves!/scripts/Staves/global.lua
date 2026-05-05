--[[
    Staves! — Global Script

    - Attaches the Staves actor script to NPCs and creatures so they can
      apply staff perk procs when hit.
    - Receives runtime-state sync events from the player script and
      stores them in a global storage section for actor scripts to read.
]]

local storage = require('openmw.storage')
local types   = require('openmw.types')

local ACTOR_SCRIPT = "scripts/Staves/actor.lua"
local runtimeSection = storage.globalSection('Runtime_Staves')

local function onActorActive(actor)
    if (types.NPC.objectIsInstance(actor) or types.Creature.objectIsInstance(actor))
        and not actor:hasScript(ACTOR_SCRIPT) then
        actor:addScript(ACTOR_SCRIPT)
    end
end

-- ─── Runtime state sync ─────────────────────────────────────────────────────
-- The player script sends this every ~0.5s (or on equipment change) so the
-- actor scripts can read current skill level, staff equipped, perk toggles
-- and pre-computed scaled values without each actor having to query the
-- player directly.

local function updateRuntime(data)
    if not data then return end
    runtimeSection:set('active', data.active)
    runtimeSection:set('staffRecordId', data.staffRecordId)
    runtimeSection:set('skill', data.skill)

    runtimeSection:set('concussiveEnabled', data.concussiveEnabled)
    runtimeSection:set('concussiveChance', data.concussiveChance)
    runtimeSection:set('concussiveFatigue', data.concussiveFatigue)
    runtimeSection:set('concussiveLevel', data.concussiveLevel)
    runtimeSection:set('concussiveSound', data.concussiveSound)

    runtimeSection:set('arcaneSiphonEnabled', data.arcaneSiphonEnabled)
    runtimeSection:set('arcaneSiphonChance', data.arcaneSiphonChance)
    runtimeSection:set('arcaneSiphonAmount', data.arcaneSiphonAmount)
    runtimeSection:set('arcaneSiphonLevel', data.arcaneSiphonLevel)
    runtimeSection:set('arcaneSiphonSound', data.arcaneSiphonSound)

    runtimeSection:set('resonantConduitEnabled', data.resonantConduitEnabled)
    runtimeSection:set('resonantConduitChance', data.resonantConduitChance)
    runtimeSection:set('resonantConduitCharge', data.resonantConduitCharge)
    runtimeSection:set('resonantConduitLevel', data.resonantConduitLevel)

    runtimeSection:set('nullPulseEnabled', data.nullPulseEnabled)
    runtimeSection:set('nullPulseChance', data.nullPulseChance)
    runtimeSection:set('nullPulseDuration', data.nullPulseDuration)
    runtimeSection:set('nullPulseLevel', data.nullPulseLevel)
    runtimeSection:set('nullPulseSound', data.nullPulseSound)
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    },
    eventHandlers = {
        Staves_UpdateRuntime = updateRuntime,
    },
}
