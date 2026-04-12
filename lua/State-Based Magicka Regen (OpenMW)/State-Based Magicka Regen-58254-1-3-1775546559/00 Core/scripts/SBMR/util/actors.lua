local core = require("openmw.core")
local T = require("openmw.types")
local self = require("openmw.self")

local mStore = require("scripts.SBMR.config.store")

local module = {
    magicka = T.Actor.stats.dynamic.magicka(self),
    fatigue = T.Actor.stats.dynamic.fatigue(self),
    intelligence = T.Actor.stats.attributes.intelligence(self),
    willpower = T.Actor.stats.attributes.willpower(self),
    activeEffects = T.Actor.activeEffects(self),
}

local function getRegenMainStat()
    if mStore.settings.regenMainStat.value == mStore.regenMainStats.Intelligence then
        return module.intelligence.modified
    elseif mStore.settings.regenMainStat.value == mStore.regenMainStats.Willpower then
        return module.willpower.modified
    end
    return module.magicka.base
end

local function hasMagickaRegen()
    return module.activeEffects:getEffect(core.magic.EFFECT_TYPE.RestoreMagicka).magnitude > 0
end

module.getBaseRegen = function(mainStatPercent)
    return getRegenMainStat() * mainStatPercent / 100
end

module.getWillpowerFactor = function()
    local setting = mStore.settings.willpowerRegenImpactPercent.value
    return (setting.from + (setting.to - setting.from) * (module.willpower.modified / 100)) / 100
end

module.getIntelligenceFactor = function()
    local setting = mStore.settings.intelligenceRegenImpactPercent.value
    return (setting.from + (setting.to - setting.from) * (module.intelligence.modified / 100)) / 100
end

module.getFatigueFactor = function()
    local setting = mStore.settings.fatigueRegenImpactPercent.value
    local fatigueRatio = module.fatigue.base == 0 and 0 or math.min(1, module.fatigue.current / module.fatigue.base)
    return (setting.from + (setting.to - setting.from) * fatigueRatio) / 100
end

module.getEncumbranceFactor = function()
    local setting = mStore.settings.encumbranceRegenImpactPercent.value
    if setting.from == 100 and setting.to == 100 then
        return 1
    end
    local encumbrance = T.Actor.getEncumbrance(self)
    local capacity = T.Actor.getCapacity(self)
    local encumbranceRatio = capacity == 0 and 1 or (1 - math.min(1, encumbrance / capacity))
    return (setting.from + (setting.to - setting.from) * encumbranceRatio) / 100
end

module.getMovementFactors = function()
    if mStore.settings.walkRegenPercent.value == 100 and mStore.settings.runRegenPercent.value == 100
            or self.controls.movement == 0 then
        return 1, 1
    end
    if self.controls.run then
        return 1, mStore.settings.runRegenPercent.value / 100
    else
        return mStore.settings.walkRegenPercent.value / 100, 1
    end
end

module.getRegeneratingActorsFactor = function()
    if hasMagickaRegen() then
        return mStore.settings.regeneratingActorsRegenPercent.value / 100
    end
    return 1
end

module.getStuntedMagickaFactor = function()
    if mStore.settings.stuntedMagickaRegenPercent.value == 100
            or module.activeEffects:getEffect(core.magic.EFFECT_TYPE.StuntedMagicka).magnitude <= 0 then
        return 1
    end
    return mStore.settings.stuntedMagickaRegenPercent.value / 100
end

module.getRegenFactor = function()
    -- first check factors that can regularly be zero
    local regeneratingActorsFactor = module.getRegeneratingActorsFactor()
    if regeneratingActorsFactor == 0 then return 0 end
    local stuntedMagickaFactor = module.getStuntedMagickaFactor()
    if stuntedMagickaFactor == 0 then return 0 end
    local walkFactor, runFactor = module.getMovementFactors()
    return module.getWillpowerFactor()
            * module.getIntelligenceFactor()
            * module.getFatigueFactor()
            * module.getEncumbranceFactor()
            * walkFactor
            * runFactor
            * regeneratingActorsFactor
            * stuntedMagickaFactor
end

return module