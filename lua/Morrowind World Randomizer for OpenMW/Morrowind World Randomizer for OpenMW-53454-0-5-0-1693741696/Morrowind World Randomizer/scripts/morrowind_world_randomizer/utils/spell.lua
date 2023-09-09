local this = {}

function this.calculateEffectCost(effect)
    local mul = effect.range == 2 and 1.5 or 1
    return mul * ((effect.magnitudeMin + effect.magnitudeMax) * (effect.duration + 1) + effect.area) * (effect.effect.baseCost or 1) / 40
end

return this