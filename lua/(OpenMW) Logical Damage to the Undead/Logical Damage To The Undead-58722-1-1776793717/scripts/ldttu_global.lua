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

return {
    eventHandlers = {
        LDTTU_GlobalSettings = function(s)
            cachedSettings = s
            for _, actor in ipairs(world.activeActors) do
                if types.Creature.objectIsInstance(actor)
                   and not types.Actor.isDead(actor)
                   and actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent("LDTTU_UpdateSettings", s)
                end
            end
        end,
        LDTTU_DebugMessage = function(msg)
            print(msg)
        end,
        LDTTU_RequestRemoval = function(actor)
            if not actor or not actor:isValid() then return end
            if actor:hasScript(LOCAL_SCRIPT) then
                actor:removeScript(LOCAL_SCRIPT)
            end
        end
    },
    engineHandlers = {
        onActorActive = function(actor)
            tryAttach(actor)
        end
    }
}