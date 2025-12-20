local world = require("openmw.world")
local types = require("openmw.types")

local data = { object = nil }

local function getJournalIndex(id)
    local quests = types.Player.quests(world.players[1])
    return quests and quests[id] and quests[id].stage
end

return {
    engineHandlers = {
        onActivate = function(object, actor)
            if types.NPC.objectIsInstance(object)
                and actor == world.players[1]
            then
                local index = getJournalIndex("md24_j_disease") or 0
                if (index < 15) then
                    return
                end

                local crimeLevel = types.Player.getCrimeLevel(actor)
                if crimeLevel > 100 then
                    return
                end

                local activeSpells = types.Actor.activeSpells(object)
                local isDiseased = activeSpells:isSpellActive("md24_greatnewdisease")
                local globalVariables = world.mwscript.getGlobalVariables(actor)
                globalVariables.md24_globSpeakerState = isDiseased and 1 or 2
            end
        end,
        onSave = function()
            return data
        end,
        onLoad = function(savedData)
            data = savedData or {}
        end,
    },
    eventHandlers = {
        md24_furn_paradoxscale = function(e)
            data.object = e.object
        end,
        md24_teleport_return = function()
            if data.object and data.object.cell then
                world.players[1]:teleport(data.object.cell, data.object.position)
            end
        end,
    },
}
