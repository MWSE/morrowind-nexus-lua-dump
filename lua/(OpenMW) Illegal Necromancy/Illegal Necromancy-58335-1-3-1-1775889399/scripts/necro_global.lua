local types = require("openmw.types")
local core  = require("openmw.core")
local world = require("openmw.world")
local I     = require("openmw.interfaces")

local shared                = require("scripts.necro_shared")
local SUMMON_MAP   = shared.SUMMON_MAP
local EXEMPT_CELLS          = shared.EXEMPT_CELLS


return {
    engineHandlers = {
        onActorActive = function(actor)
            local recordId = actor.recordId:lower()
            if not SUMMON_MAP[recordId] then return end
            local player = world.players[1]
            if not player then return end

            local expectedEffect = SUMMON_MAP[recordId]
            local effectId       = core.magic.EFFECT_TYPE[expectedEffect]
            if not effectId then return end

            local effects = types.Actor.activeEffects(player)
            local effect  = effects:getEffect(effectId)
            if not effect or effect.magnitude == 0 then return end

            local cell = actor.cell
            if cell and EXEMPT_CELLS[cell.id] then return end
            player:sendEvent("NecroCheckWitness", { summonId = actor.recordId:lower() })
        end,
    },
    eventHandlers = {
        NecroCommitCrime = function(data)
            if not data or not data.player then return end
            I.Crimes.commitCrime(data.player, {
                type        = types.Player.OFFENSE_TYPE.Assault,
                victimAware = true,
            })
        end,
    },
}