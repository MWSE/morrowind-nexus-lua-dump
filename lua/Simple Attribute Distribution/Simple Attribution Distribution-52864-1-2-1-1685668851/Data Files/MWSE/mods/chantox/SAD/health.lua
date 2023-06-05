local config = require("chantox.SAD.config")
local log = require("chantox.SAD.log")

local this = {}

---Calculate scaling health
local function g(endurance, level)
    return (level - 1) * config.alpha * endurance^config.beta /10
end

---Calculate player health based on their attributes and effects
this.calc = function ()
    local mp = tes3.mobilePlayer
    local base = (mp.strength.current + mp.endurance.current)/2
    local health = base + g(mp.endurance.base, mp.object.level)
    if tes3.hasCodePatchFeature(tes3.codePatchFeature.fortifyMaximumHealth) then
        local bonus = tes3.getEffectMagnitude{
            reference = tes3.player,
            effect = tes3.effect.fortifyHealth,
        }
        log:debug("Bonus health: " .. bonus)
        health = health + bonus
    end
    return math.round(health)
end

---Calculate player health from args, disregarding fortify health effects
---@param strength number
---@param endurance number
---@param level number
---@return number
this.calcBase = function (strength, endurance, level)
    local base = (strength + endurance)/2
    local health = base + g(endurance, level)
    return math.round(health)
end

---Calculate, then set player health.
---If params.heal, heal the player for the difference in max health
---@param params table 
this.update = function (params)
    if not params then
        params = {}
    end
    local mp = tes3.mobilePlayer
    local max = math.max(this.calc(), config.minHealth)
    if config.minHealth then
        max = math.max(1, max)
    end
    log:trace("New max health: " .. max)
    local current = math.min(max, mp.health.current)
    if params.heal then
        local dif = math.max(0, max - mp.health.base)
        log:trace("Healing player for " .. dif)
        current = current + dif
    end

    tes3.setStatistic{
        reference = tes3.player,
        name = 'health',
        base = max
    }

    tes3.setStatistic{
        reference = tes3.player,
        name = 'health',
        current = current
    }
end

return this
