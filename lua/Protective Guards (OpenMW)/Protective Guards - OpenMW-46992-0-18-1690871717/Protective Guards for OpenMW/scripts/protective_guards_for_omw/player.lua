local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local aux_util = require("openmw_aux.util")
local core = require("openmw.core")
local storage = require("openmw.storage")
local self = require("openmw.self")
local blAreas = require("scripts/protective_guards_for_omw/blacklistedAreas")
local section = storage.playerSection("Settings_PGFOMW_Options_Key_KINDI")
local modInfo = require("scripts.protective_guards_for_omw.modInfo")
local pursuit_for_omw = false

local function searchGuardsAdjacentCells(attacker)
    for _, door in pairs(nearby.doors) do
        if door.type.isTeleport(door) and (door.position - self.position):length() < 2000 then
            core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {
                door,
                attacker,
                section:get("Search Guard of Class"):lower()
            })
        end
    end
end

local function nearbyGuards()
    local classes = section:get("Search Guard of Class"):lower()
    return aux_util.mapFilter(nearby.actors, function(actor)
        local actorClass = actor.type.record(actor).class
        return actorClass and classes:find(actorClass:lower())
    end)
end

local function debug(actor, e)
    local guard = actor.type.record(actor)
    local agg = e.actor.type.record(e.actor)
    if storage.playerSection("Settings_PGFOMW_ZDebug_Key_KINDI"):get("Debug") then
        ui.showMessage(string.format("%s of %s class from %s attacks %s", guard.name, guard.class, actor.cell.name, agg.name))
    end
end

return {
    engineHandlers = {
        onActive = function()
            assert(core.API_REVISION >= modInfo.MIN_API, "[Protective Guards] mod requires OpenMW version 0.48 or newer!")
        end
    },
    eventHandlers = {
        ProtectiveGuards_thisActorIsAttackedBy_eqnx = function(e)
            if not section:get("Mod Status") then
                return
            end
            if blAreas[self.cell.name] then
                return
            end

            if types.Player.getCrimeLevel then
                core.sendGlobalEvent("ProtectiveGuards_oldVersionCleanup_eqnx", {
                    actor = self
                })
                if types.Player.getCrimeLevel(self) > 0 then
                    return
                end
            elseif types.Actor.inventory(self):countOf("PG_TrigCrime") > 0 then
                -- not used in v0.49. Kept for backwards compatiblity
                return
            end

            -- guards dislike werewolf in morrowind (only for v0.49 and newer)
            if types.NPC.isWerewolf and types.NPC.isWerewolf(self) then
                return
            end

            local intDist = section:get("Search Guard Distance Interiors")
            local extDist = section:get("Search Guard Distance Exteriors")

            for _, actor in pairs(nearbyGuards()) do
                if (actor.position - self.position):length() < (self.cell.isExterior and extDist or intDist) then
                    actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {
                        attacker = e.actor,
                        isImmune = e.isImmune
                    })
                    debug(actor, e)
                end
            end

            -- future
            -- check if current cell has peaceful npc, playsound for help, goes to a nearby adjacent cell, and alert guards
            if not e.isImmune and section:get("Search Guard In Nearby Adjacent Cells") and pursuit_for_omw then
                searchGuardsAdjacentCells(e.actor)
            end
        end,
        Pursuit_IsInstalled_eqnx = function(e)
            pursuit_for_omw = e.isInstalled
            if pursuit_for_omw then
                print("Pursuit and Protective Guards interaction established")
                -- ui.showMessage("Pursuit and Protective Guards interaction established")
            end
        end
    }
}
