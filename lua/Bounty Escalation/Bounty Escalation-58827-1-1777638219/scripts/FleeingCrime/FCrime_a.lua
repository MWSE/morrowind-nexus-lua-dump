local types = require("openmw.types")
local util = require("openmw.util")
local self = require("openmw.self")
local core = require("openmw.core")
local AI = require("openmw.interfaces").AI
local nearby = require("openmw.nearby")
local isPursingPlayer = false
local isFightingPlayer = false
local cooldownTimer = 0
if types.NPC.records[self.recordId].class ~= "guard" then
    return
end
local lastPackageType = nil
local function onUpdate(dt)
    if cooldownTimer > 0 then
        --print("Cooldown timer: " .. tostring(cooldownTimer))
        cooldownTimer = cooldownTimer - dt
        if cooldownTimer > 0 then
            return
        else
            cooldownTimer = 0
        end
    end
            local player = nearby.players[1]
    local crime = types.Player.getCrimeLevel(player)
    local check = AI.getActivePackage(self)
    if isFightingPlayer or isPursingPlayer then --if dead no reportCrime.
        local health = types.Actor.stats.dynamic.health(self).current
        if health < 0.5 then
            isFightingPlayer = false
            isPursingPlayer = false
            return
        end
    end
    if check and check.type ~= lastPackageType and check.type == "Pursue" then
        local target = check.target
        if target then
            if target == player then
                isPursingPlayer = true
                --print("Started pursuing player")
            end
        end
    elseif check and check.type == "Combat" and check.type ~= lastPackageType then
        local target = check.target
        if target then
            if target == player then
                isFightingPlayer = true
                --print("Started fighting player")
            end
        end
    elseif isPursingPlayer and check and check.type == "Pursue" then
        return
    elseif isFightingPlayer and check and check.type == "Combat" then
        return
    elseif check.type == "Wander" and (isPursingPlayer  or  isFightingPlayer) then
        if types.Player.getCrimeLevel(player) > 0 then
            ----print("Stopped pursuing player, fleeing crime report should be sent.")
            core.sendGlobalEvent("reportCrimeEvent_FC", { crime = "fleeingCrime", guard = self })
        else
            ----print("Stopped pursuing player, not reported fleeing crime because player has no crime level.")
        end
        isPursingPlayer = false
        --print("Stopped pursuing player, paid probably")
    elseif lastPackageType and check.type ~= lastPackageType then
        --print(check.type, lastPackageType)
    end
    lastPackageType = check.type
end
local function onInactive()
    if cooldownTimer > 0 then
        return
    end
    if (isPursingPlayer or isFightingPlayer) and types.Player.getCrimeLevel(nearby.players[1]) > 0 then
      --  cooldownTimer = 120
        isPursingPlayer = false
        isFightingPlayer = false
        lastPackageType = nil
        ----print("NPC is inactive, fleeing crime report should be sent if they were pursuing or fighting the player.")

        core.sendGlobalEvent("reportCrimeEvent_FC", { crime = "fleeingCrime", guard = self })
    end
end
return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = onInactive,
        onSave = function() return { cooldownTimer = cooldownTimer } end,
        onLoad = function(data) if data and data.cooldownTimer then cooldownTimer = data.cooldownTimer end end,
    },
    interfaceName = "FCrime_a",
    interface = {
        isPursingPlayer = function() return isPursingPlayer end,
        isFightingPlayer = function() return isFightingPlayer end,
        getCooldownTimer = function() return cooldownTimer end,
    }
}
