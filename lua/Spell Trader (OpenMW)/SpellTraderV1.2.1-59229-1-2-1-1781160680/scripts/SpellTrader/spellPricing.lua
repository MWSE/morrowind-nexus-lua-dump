local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')

local Pricing = {}

local function fatigueTerm(actor)
    local stats = actor.type.stats
    local fatigue = stats.dynamic.fatigue(actor)
    local maxFatigue = fatigue and (fatigue.base + fatigue.modifier) or 0
    local normalized = 1
    if math.floor(maxFatigue) ~= 0 then
        normalized = math.max(0, fatigue.current / maxFatigue)
    end
    return core.getGMST('fFatigueBase') - core.getGMST('fFatigueMult') * (1 - normalized)
end

local function effectCost(params)
    local effect = params.effect
    local hasMagnitude = effect.hasMagnitude
    local hasDuration = effect.hasDuration
    local appliedOnce = effect.isAppliedOnce

    local minMagnitude = hasMagnitude and params.magnitudeMin or 1
    local maxMagnitude = hasMagnitude and params.magnitudeMax or 1
    minMagnitude = math.max(1, minMagnitude)
    maxMagnitude = math.max(1, maxMagnitude)

    local duration = hasDuration and params.duration or 1
    if not appliedOnce then
        duration = math.max(1, duration)
    end

    local cost = 0.5 * (minMagnitude + maxMagnitude)
    cost = cost * 0.1 * effect.baseCost
    cost = cost * duration
    cost = cost + 0.05 * math.max(0, params.area) * effect.baseCost
    cost = cost * core.getGMST('fEffectCostMult')

    if params.range == core.magic.RANGE.Target then
        cost = cost * 1.5
    end

    return math.max(0, cost)
end

function Pricing.calcSpellCost(spell)
    if not spell.isAutocalc then
        return spell.cost
    end

    local total = 0
    for _, params in pairs(spell.effects) do
        total = total + effectCost(params)
    end
    return math.floor(total + 0.5)
end

function Pricing.getBarterOffer(player, merchant, basePrice, buying)
    if basePrice == 0 then
        return basePrice
    end
    if types.Creature.objectIsInstance(merchant) then
        return math.max(1, math.modf(basePrice))
    end

    local clampedDisposition = util.clamp(types.NPC.getDisposition(merchant, player), 0, 100)

    local a = math.min(player.type.stats.skills.mercantile(player).modified, 100)
    local b = math.min(0.1 * player.type.stats.attributes.luck(player).modified, 10)
    local c = math.min(0.2 * player.type.stats.attributes.personality(player).modified, 10)
    local d = math.min(merchant.type.stats.skills.mercantile(merchant).modified, 100)
    local e = math.min(0.1 * merchant.type.stats.attributes.luck(merchant).modified, 10)
    local f = math.min(0.2 * merchant.type.stats.attributes.personality(merchant).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * fatigueTerm(player)
    local npcTerm = (d + e + f) * fatigueTerm(merchant)
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.modf(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end

function Pricing.getSpellBuyingPrice(player, merchant, spell)
    local basePrice = math.max(1, math.modf(Pricing.calcSpellCost(spell) * core.getGMST('fSpellValueMult')))
    return Pricing.getBarterOffer(player, merchant, basePrice, true)
end

return Pricing
