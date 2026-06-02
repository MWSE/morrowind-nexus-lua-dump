local core = require("openmw.core")

local fEffectCostMult = core.getGMST('fEffectCostMult')

local spells = {}

spells.getBaseSpellCost = function(spellId, isEnchant)
    local cost = 0

    local spellRecord
    if isEnchant then
        spellRecord = core.magic.enchantments.records[spellId]
    else
        spellRecord = core.magic.spells.records[spellId]
    end
    if not spellRecord then return cost end

    if not spellRecord.autocalcFlag then
        return spellRecord.cost
    end

    for _, effect in ipairs(spellRecord.effects) do
        local minMagnitude, maxMagnitude = 1, 1
        local baseEffect = effect.effect

        if baseEffect.hasMagnitude then
            minMagnitude = effect.magnitudeMin
            maxMagnitude = effect.magnitudeMax
        end
        if not isEnchant then
            minMagnitude = math.max(1, minMagnitude)
            maxMagnitude = math.max(1, maxMagnitude)
        end

        local x = baseEffect.hasDuration and effect.duration or 1
        if not baseEffect.isAppliedOnce then
            x = math.max(x, 1)
        end
        x = x * 0.1 * baseEffect.baseCost
        x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
        x = x + 0.05 * baseEffect.baseCost * effect.area
        if effect.range == core.magic.RANGE.Target then
            x = x * 1.5
        end
        x = x * fEffectCostMult
        x = math.max(0, x)

        cost = cost + x
    end

    return cost
end

return spells
