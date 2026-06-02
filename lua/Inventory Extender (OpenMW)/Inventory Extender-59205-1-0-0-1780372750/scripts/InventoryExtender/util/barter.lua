local types = require('openmw.types')
local util = require('openmw.util')
local self = require('openmw.self')
local core = require('openmw.core')

local helpers = require('scripts.InventoryExtender.util.helpers')

local function getEffectiveValue(item, count)
    local basePrice = item.type.record(item).value

    local itemData = item.type.itemData(item)
    local itemRecord = item.type.record(item)

    local x
    if types.Weapon.objectIsInstance(item) or types.Armor.objectIsInstance(item) then
        local condition = itemData.condition
        if condition then
            x = basePrice * (condition / itemRecord.health)
        else
            x = basePrice
        end
    elseif types.Lockpick.objectIsInstance(item) or types.Probe.objectIsInstance(item) or types.Repair.objectIsInstance(item) then
        local uses = itemData.condition or 0
        local maxUses = itemRecord.maxCondition
        x = basePrice * (uses / maxUses)
    elseif itemData.soul then
        x = helpers.getItemValue(item)
    else
        x = basePrice
    end
    return x * count
end

local function haggle(npc, playerOffer, merchantOffer)
    if playerOffer <= merchantOffer then
        return true
    end

    if types.Creature.objectIsInstance(npc) then
        return false
    end

    local buying = merchantOffer < 0
    local a = math.abs(merchantOffer)
    local b = math.abs(playerOffer)
    local d = buying and math.modf(100 * (a - b) / a) or math.modf(100 * (b - a) / b)

    local clampedDisposition = util.clamp(npc.type.getDisposition(npc, self), 0, 100)

    local a1 = self.type.stats.skills.mercantile(self).modified
    local b1 = 0.1 * self.type.stats.attributes.luck(self).modified
    local c1 = 0.2 * self.type.stats.attributes.personality(self).modified
    local d1 = npc.type.stats.skills.mercantile(npc).modified
    local e1 = 0.1 * npc.type.stats.attributes.luck(npc).modified
    local f1 = 0.2 * npc.type.stats.attributes.personality(npc).modified

    local dispositionTerm = core.getGMST('fDispositionMod') * (clampedDisposition - 50)
    local pcTerm = (dispositionTerm + a1 + b1 + c1) * helpers.getFatigueTerm(self)
    local npcTerm = (d1 + e1 + f1) * helpers.getFatigueTerm(npc)
    local x = core.getGMST('fBargainOfferMulti') * d + core.getGMST('fBargainOfferBase') + math.modf(pcTerm - npcTerm)

    local roll = math.random(1, 100)

    if roll > x or (merchantOffer < 0 and 0 < playerOffer) then
        return false
    end

    local skillGain = 0
    local finalPrice = math.abs(playerOffer)
    local initialMerchantOffer = math.abs(merchantOffer)

    if (not buying and (finalPrice > initialMerchantOffer)) then
        skillGain = math.floor(100 * (finalPrice - initialMerchantOffer) / finalPrice)
    elseif (buying and (finalPrice < initialMerchantOffer)) then
        skillGain = math.floor(100 * (initialMerchantOffer - finalPrice) / initialMerchantOffer)
    end

    return true, skillGain
end

local function getBarterOffer(merchant, basePrice, buying)
    if basePrice == 0 then
        return basePrice
    end
    if types.Creature.objectIsInstance(merchant) then
        return math.max(1, math.modf(basePrice))
    end

    local clampedDisposition = util.clamp(merchant.type.getDisposition(merchant, self), 0, 100)
    local a = math.min(self.type.stats.skills.mercantile(self).modified, 100)
    local b = math.min(0.1 * self.type.stats.attributes.luck(self).modified, 10)
    local c = math.min(0.2 * self.type.stats.attributes.personality(self).modified, 10)
    local d = math.min(merchant.type.stats.skills.mercantile(merchant).modified, 100)
    local e = math.min(0.1 * merchant.type.stats.attributes.luck(merchant).modified, 10)
    local f = math.min(0.2 * merchant.type.stats.attributes.personality(merchant).modified, 10)
    local pcTerm = (clampedDisposition - 50 + a + b + c) * helpers.getFatigueTerm(self)
    local npcTerm = (d + e + f) * helpers.getFatigueTerm(merchant)
    local buyTerm = 0.01 * (100 - 0.5 * (pcTerm - npcTerm))
    local sellTerm = 0.01 * (50 - 0.5 * (npcTerm - pcTerm))
    local offerPrice = math.modf(basePrice * (buying and buyTerm or sellTerm))
    return math.max(1, offerPrice)
end

local function updateOffer(ctx)
    local state = ctx.barterState
    local merchant = ctx.windowArgs.Trade
    if not state or not merchant then
        return
    end

    local merchantOffer = 0
    for _, buyingData in pairs(state.buying) do
        local basePrice = getEffectiveValue(buyingData.item, buyingData.count)
        local cap = math.modf(math.max(1, 0.75 * basePrice))
        local buyingPrice = getBarterOffer(merchant, basePrice, true)
        merchantOffer = merchantOffer - math.max(cap, buyingPrice)
    end

    for _, sellingData in pairs(state.selling) do
        local basePrice = getEffectiveValue(sellingData.item, sellingData.count)
        local cap = math.modf(math.max(1, 0.75 * basePrice))
        local sellingPrice = getBarterOffer(merchant, basePrice, false)
        merchantOffer = merchantOffer + (types.NPC.objectIsInstance(merchant) and math.min(cap, sellingPrice) or sellingPrice)
    end

    local diff = merchantOffer - (state.currentMerchantOffer or 0)
    state.currentMerchantOffer = merchantOffer
    state.currentBalance = (state.currentBalance or 0) + diff
end

return {
    haggle = haggle,
    updateOffer = updateOffer,
}