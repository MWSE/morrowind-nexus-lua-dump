local world = require("openmw.world")
local types = require("openmw.types")
local shared = require("scripts.ldttu_shared")
local LOCAL_SCRIPT = "scripts/ldttu_creature.lua"

local cachedSettings = shared.DEFAULTS

local function tryAttach(actor)
    if not types.Creature.objectIsInstance(actor) then return false end
    if types.Actor.isDead(actor) then return false end
    if not shared.determineGroup(actor.recordId) then return false end

    if not actor:hasScript(LOCAL_SCRIPT) then
        actor:addScript(LOCAL_SCRIPT)
    end
    actor:sendEvent("LDTTU_UpdateSettings", cachedSettings)
    return true
end

local function LDTTU_GlobalSettings(s)
    cachedSettings = s
    for _, actor in ipairs(world.activeActors) do
        if types.Creature.objectIsInstance(actor)
           and not types.Actor.isDead(actor)
           and actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent("LDTTU_UpdateSettings", s)
        end
    end
end

local function LDTTU_DebugMessage(msg)
    print(msg)
end

local function LDTTU_RequestRemoval(actor)
    if not actor or not actor:isValid() then return end
    if actor:hasScript(LOCAL_SCRIPT) then
        actor:removeScript(LOCAL_SCRIPT)
    end
end

local function onActorActive(actor)
    tryAttach(actor)
end

return {
    eventHandlers = {
        LDTTU_GlobalSettings = LDTTU_GlobalSettings,
        LDTTU_DebugMessage = LDTTU_DebugMessage,
        LDTTU_RequestRemoval = LDTTU_RequestRemoval
    },
    engineHandlers = {
        onActorActive = onActorActive
    }
}