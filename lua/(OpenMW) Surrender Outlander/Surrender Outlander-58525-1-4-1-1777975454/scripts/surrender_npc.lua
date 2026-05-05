local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local anim  = require("openmw.animation")
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
        onInactive = function()
            if not ceasefire then
                core.sendGlobalEvent("Surrender_RequestRemoval", self.object)
            end
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

        Surrender_PickupGold = function(data)
            if not data or not data.goldItem or not data.player then return end
            if types.Actor.isDead(self.object) then return end
            if not data.goldItem:isValid() then return end

            local goldItem = data.goldItem
            local player   = data.player
            local message  = data.message

            local ARRIVAL_RADIUS    = 70
            local ARRIVAL_RADIUS_SQ = ARRIVAL_RADIUS * ARRIVAL_RADIUS
            local MAX_WAIT          = 5.0

            local started     = core.getSimulationTime()
            local animPlayed  = false
            local cleanedUp   = false

            local function cleanup()
                if cleanedUp then return end
                cleanedUp = true
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                self:enableAI(true)
                AI.removePackages("Travel")
            end

            local function playPickupAnim()
                if animPlayed then return end
                animPlayed = true

                self:enableAI(false)
                local fired = false

                I.AnimationController.addTextKeyHandler("loot02", function(groupname, key)
                    if key == "attach" and not fired then
                        fired = true
                        core.sendGlobalEvent("Surrender_FinalizeGoldPickup", {
                            npc      = self.object,
                            goldItem = goldItem,
                            player   = player,
                            message  = message,
                        })
                    end
                end)

                I.AnimationController.playBlendedAnimation("loot02", {
                    startKey = "start",
                    stopKey  = "stop",
                    priority = anim.PRIORITY.Scripted,
                    speed    = 1,
                })

                -- end the loot sequence ~2s after animation starts
                async:newUnsavableSimulationTimer(2.0, cleanup)
            end

            local function pollArrival()
                if not self:isActive() or types.Actor.isDead(self.object) then
                    cleanup()
                    return
                end
                if not goldItem:isValid() then
                    cleanup()
                    return
                end

                local dx = self.position.x - goldItem.position.x
                local dy = self.position.y - goldItem.position.y
                local dz = self.position.z - goldItem.position.z
                local distSq = dx*dx + dy*dy + dz*dz

                if distSq <= ARRIVAL_RADIUS_SQ then
                    playPickupAnim()
                    return
                end

                -- timeout
                if core.getSimulationTime() - started > MAX_WAIT then
                    cleanup()
                    return
                end

                async:newUnsavableSimulationTimer(0.2, pollArrival)
            end

            async:newUnsavableSimulationTimer(0.1, function()
                if not self:isActive() then return end
                if types.Actor.isDead(self.object) then return end
                if not goldItem:isValid() then return end

                AI.startPackage({
                    type         = "Travel",
                    destPosition = goldItem.position,
                    cancelOther  = false,
                })

                async:newUnsavableSimulationTimer(0.3, pollArrival)
            end)
        end,
    },
}