local types         = require("openmw.types")
local shared        = require("scripts.felms_blessing_shared")

local POTENTIAL_TARGET = "scripts/felms_blessing_npc.lua"

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not types.NPC.objectIsInstance(actor) then return end
            if types.Actor.isDead(actor) then return end
            if actor:hasScript(POTENTIAL_TARGET) then return end

            local validFaction = false
            for _, factionId in pairs(types.NPC.getFactions(actor)) do
                local id = factionId:lower()
                if shared.EXCLUDED_FACTIONS[id] then return end
                if shared.VALID_FACTIONS[id] then validFaction = true end
            end

            if not validFaction then
                local race = types.NPC.record(actor).race
                if race and shared.VALID_RACES[race:lower()] then
                    validFaction = true
                end
            end

            if not validFaction then
                local classId = types.NPC.record(actor).class
                if not classId or not shared.VALID_CLASSES[classId:lower()] then return end
            end

            actor:addScript(POTENTIAL_TARGET)
        end,
    },
    eventHandlers = {
        AxeBlessing_Granted = function(data)
            if not data or not data.player or not data.player:isValid() then return end
            types.Actor.spells(data.player):add(shared.SPELL_ID)
        end,
    },
}