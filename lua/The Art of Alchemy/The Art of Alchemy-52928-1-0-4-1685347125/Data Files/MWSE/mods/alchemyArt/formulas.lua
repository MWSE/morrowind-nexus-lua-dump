local effects = require("alchemyArt.effects")

local formulas = {}

local function handleOverflow(value)

    -- prevents alchemical singularity exploit, without outright not taking into account non base values or values > 100
    -- every next 100 points of attribute contribute less to the power of potion

    local result = 0
    local i = 1
    while value > 100 do
        value = value - 100
        result = result + math.floor(100/i)
        i = i + 1
    end
    result = result + math.floor(value/i)
    return result
end

formulas.getEffectMagnitudeDuration = function(effectId, power, durationMult)
    local magicEffect = tes3.getMagicEffect(effectId)
    local override = effects.override[effectId]
    local magnitude
    if override then
        if override.duration ~= nil then
            if override.duration ~= 0 then
                magnitude = power/(override.powerDiv*override.duration)
            else
                magnitude = power/(override.powerDiv)
            end
            return magnitude, override.duration
        end
        power = power/override.powerDiv
    end
    if magicEffect.hasNoMagnitude and magicEffect.hasNoDuration then
        return 0, 0
    elseif magicEffect.hasNoMagnitude then
        return 0, math.floor(power/48 + 0.5)
    elseif magicEffect.hasNoDuration then
        return math.floor(power/12 + 0.5), 0
    else
        return formulas.getMagnitudeDuration(power, durationMult)
    end
end

formulas.getMagnitudeDuration = function(power, durationMult)

    if durationMult == nil then
        if power < 100 then
            durationMult = 1.5
        elseif power < 250 then
            durationMult = 2
        else
            durationMult = 3
        end
    end
    
    local magnitude = math.sqrt(power/durationMult)
    local duration = magnitude * durationMult

    return math.floor(magnitude + 0.5), math.floor(duration + 0.5)
end

formulas.getEffectPower = function(effect)
    if effect.object.hasNoDuration and effect.object.hasNoMagnitude then
        return 300
    elseif effect.object.hasNoDuration then
        return 12 * (effect.min + effect.max)/2
    elseif effect.object.hasNoMagnitude then
        return 48 * effect.duration
    else
        return effect.duration * (effect.min + effect.max)/2
    end
end

formulas.getPower = function (apparatusQuality)
    local alchemy = tes3.mobilePlayer.alchemy.current
    local intelligence = handleOverflow(tes3.mobilePlayer.intelligence.current)
    local luck = handleOverflow(tes3.mobilePlayer.luck.current)
    local power = alchemy + intelligence/5 + luck/10
    power = power * math.log(power) * apparatusQuality
    return math.floor(power + 0.5)
end

formulas.limitMaxPower = function(power, apparatusQuality)
    local alchemy = tes3.mobilePlayer.alchemy.current
    local intelligence = handleOverflow(tes3.mobilePlayer.intelligence.current)
    local luck = handleOverflow(tes3.mobilePlayer.luck.current)
    local maxPower = alchemy + intelligence/5 + luck/10
    maxPower = maxPower * math.log(maxPower) * 2 * apparatusQuality
    return math.floor(math.min(maxPower, power) + 0.5)
end

formulas.limitMinPower = function(power, apparatusQuality)
    local alchemy = tes3.mobilePlayer.alchemy.current
    local intelligence = handleOverflow(tes3.mobilePlayer.intelligence.current)
    local luck = handleOverflow(tes3.mobilePlayer.luck.current)
    local minPower = alchemy + intelligence/5 + luck/10
    minPower = minPower * math.log(minPower)/(2 * apparatusQuality)
    -- mwse.log("min power %s, power %s", minPower, power)
    return math.floor(math.max(minPower, power) + 0.5)
end

formulas.getSuccessChance = function()
    local alchemy = tes3.mobilePlayer.alchemy.current
    local intelligence = tes3.mobilePlayer.intelligence.current
    local luck = tes3.mobilePlayer.luck.current
    return alchemy + intelligence/5 + luck/10
end

formulas.getSuccess = function ()
    local chance = formulas.getSuccessChance()
    if math.random(1, 100) > chance then
        return false
    end
    return true
end

return formulas