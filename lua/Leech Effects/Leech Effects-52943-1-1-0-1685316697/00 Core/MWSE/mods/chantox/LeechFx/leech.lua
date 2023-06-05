local interop = require("chantox.LeechFx.interop")
local log = require("chantox.LeechFx.log")

---@class leechHelper.leech.params
---@field effect integer Effect id of leech effect to check for.
---@field source string The origin of damage.
---@field attacker tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer The mobile actor dealing the damage.
---@field damage number Gross damage inflicted by attacker.
---@field mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer The mobile actor that is taking damage.
---@field statistic string The property name of the statistic to set.

---Calculates net leach and heals the attacker
---@param params leechHelper.leech.params
local function leech(params)
    local source = params.source or "attack"

    if (source ~= "attack" or
        params.damage <= 0 or
        not params.attacker) then
        return
    end

    -- Get sum magnitude of leech on attacker
    local effectiveMagnitude = tes3.getEffectMagnitude{
        reference = params.attacker,
        effect = params.effect
    }

    if effectiveMagnitude == 0 then
        return
    end

    -- Mod attacker's statistic
    local mult = 1 - interop.getRes(params.mobile)
    log:debug("Leach resistance mult: " .. mult)
    local heal = math.ceil(mult * effectiveMagnitude/100 * params.damage)
    tes3.modStatistic({
        reference = params.attacker,
        name = params.statistic,
        current = heal,
        limitToBase = true
    })
    log:debug("\"" .. params.statistic .. "\" healed for " .. heal)
end

return leech
