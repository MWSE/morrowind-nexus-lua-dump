local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local AI    = require("openmw.interfaces").AI
local I     = require("openmw.interfaces")

local ceasefire    = false
local savedFight   = nil

local endCeasefire  -- forward declaration

local function startCeasefire(seconds)
    local fightStat = types.Actor.stats.ai.fight(self)
    if not savedFight then
        savedFight = fightStat.base
    end
    fightStat.base = 10

    AI.filterPackages(function(p)
        return p.type ~= "Combat"
    end)
    self.type.setStance(self, 0)

    ceasefire = true

    async:newUnsavableSimulationTimer(seconds, function()
        if ceasefire then
            endCeasefire()
        end
    end)
end

endCeasefire = function()
    ceasefire = false
    local fightStat = types.Actor.stats.ai.fight(self)
    fightStat.base = savedFight or 10
    savedFight = nil
end

local function isTargetingPlayer(player)
    local ok, targets = pcall(function() return AI.getTargets("Combat") end)
    if not ok then return false end
    for _, t in ipairs(targets) do
        if t == player then return true end
    end
    return false
end

return {
    engineHandlers = {
        onActive = function()
            I.Combat.addOnHitHandler(function(attack)
                if not ceasefire then return end
                if not attack.attacker then return end
                if types.Player.objectIsInstance(attack.attacker) then
                    core.sendGlobalEvent("Surrender_PlayerAttacked", {})
                end
            end)
        end,
    },

    eventHandlers = {
        Surrender_Ceasefire = function(data)
            if not data or not data.player then return end
            if types.Actor.isDead(self.object) then return end
            if not isTargetingPlayer(data.player) then return end
            startCeasefire(data.ceasefire or 15)
        end,

        Surrender_BreakCeasefire = function()
            if not ceasefire then return end
            endCeasefire()
        end,
    },
}