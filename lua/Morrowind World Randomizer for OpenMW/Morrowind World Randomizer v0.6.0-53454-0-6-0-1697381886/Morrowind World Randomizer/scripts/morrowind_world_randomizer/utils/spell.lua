local this = {}

local core = require("openmw.core")

this.effectIds = {}
for name, id in pairs(core.magic.EFFECT_TYPE) do
    table.insert(this.effectIds, id)
end

function this.calculateEffectCost(effect)
    local mul = effect.range == 2 and 1.5 or 1
    return mul * ((effect.magnitudeMin + effect.magnitudeMax) * (effect.duration + 1) + effect.area) * (effect.effect.baseCost or 1) / 40
end

return this