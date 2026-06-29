local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local Pricing = require('scripts.SpellTrader.spellPricing')

local function player()
    return world.players and world.players[1] or nil
end

local function notifyPlayer(eventName, data)
    local p = player()
    if p and p:isValid() then
        p:sendEvent(eventName, data)
    end
end

local function removeGold(actor, amount)
    local inventory = types.Actor.inventory(actor)
    local remaining = amount
    for _, stack in ipairs(inventory:findAll('gold_001')) do
        if remaining <= 0 then
            break
        end
        local count = math.min(stack.count, remaining)
        stack:remove(count)
        remaining = remaining - count
    end
    return remaining == 0
end

local function addMerchantBarterGold(merchant, amount)
    if types.Actor.getBarterGold and types.Actor.setBarterGold then
        types.Actor.setBarterGold(merchant, types.Actor.getBarterGold(merchant) + amount)
    end
end

local function buySpell(data)
    local p = player()
    local merchant = data and data.merchant or nil
    local spellId = data and data.spellId or nil

    if not p or not p:isValid() or not merchant or not merchant:isValid() or not spellId then
        return
    end
    if not types.Actor.objectIsInstance(merchant) then
        return
    end

    local spell = core.magic.spells.records[spellId]
    if not spell or types.Actor.spells(p)[spellId] ~= nil then
        notifyPlayer('SpellTrader_PurchaseFinished', { success = false })
        return
    end

    local merchantSpells = types.Actor.spells(merchant)
    if merchantSpells[spellId] == nil then
        notifyPlayer('SpellTrader_PurchaseFinished', { success = false })
        return
    end

    local price = Pricing.getSpellBuyingPrice(p, merchant, spell)
    local playerGold = types.Actor.inventory(p):countOf('gold_001')
    if price > playerGold then
        notifyPlayer('SpellTrader_PurchaseFinished', { success = false })
        return
    end

    local success = false
    if removeGold(p, price) then
        types.Actor.spells(p):add(spell)
        addMerchantBarterGold(merchant, price)
        p:sendEvent('SpellTrader_PlayBoughtSound')
        success = true
    end
    notifyPlayer('SpellTrader_PurchaseFinished', {
        success = success,
        spellId = spellId,
        price = success and price or nil,
    })
end

return {
    eventHandlers = {
        SpellTrader_BuySpell = buySpell,
    },
}
