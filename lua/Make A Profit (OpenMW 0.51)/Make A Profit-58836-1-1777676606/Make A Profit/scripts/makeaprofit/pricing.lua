local types = require('openmw.types')
local util  = require('openmw.util')
local self  = require('openmw.self')
local core  = require('openmw.core')

-- regions require SD
local regions = G_hasSunsDusk and require('scripts.MakeAProfit.regions') or nil
local spec    = require('scripts.MakeAProfit.specialization')
local mapUtil = require('scripts.MakeAProfit.util')

local Pricing = {}

local helpers

function Pricing.init(ieHelpers)
    helpers = ieHelpers
end

function Pricing.getEffectiveValue(item, count)
    local basePrice = item.type.record(item).value
    local itemData = item.type.itemData(item)
    local itemRecord = item.type.record(item)
	
    local x
    if types.Weapon.objectIsInstance(item) or types.Armor.objectIsInstance(item) then
        local condition = itemData.condition or 0
        local maxCondition = itemRecord.health
        x = basePrice * (condition / maxCondition)
    elseif types.Lockpick.objectIsInstance(item) or types.Probe.objectIsInstance(item)
        or types.Repair.objectIsInstance(item) then
        local uses = itemData.condition or 0
        local maxUses = itemRecord.maxCondition
        x = basePrice * (uses / maxUses)
    elseif itemData.soul then
        x = helpers and helpers.getItemValue(item) or basePrice
    else
        x = basePrice
    end
    return x * count
end

-- Compute the merchant's price for an item in a given direction.
function Pricing.getDeltaPrice(merchant, basePrice, buying, item)
	if basePrice == 0 or types.Creature.objectIsInstance(merchant) then
		return basePrice
	end
	
	local disposition = util.clamp(
		merchant.type.getDisposition(merchant, self), 0, 100)
	
	local pcMerc = self.type.stats.skills.mercantile(self).modified
	local pcPers = self.type.stats.attributes.personality(self).modified
	local pcLuck = self.type.stats.attributes.luck(self).modified
	
	local npcMerc = math.min(100, merchant.type.stats.skills.mercantile(merchant).modified)
	local npcPers = math.min(100, merchant.type.stats.attributes.personality(merchant).modified)
	local npcLuck = math.min(100, merchant.type.stats.attributes.luck(merchant).modified)
	
	local factionBonus = 0
	if types.NPC.objectIsInstance(merchant) then
		local npcFaction = types.NPC.record(merchant).faction
		if npcFaction and npcFaction ~= '' then
			local rank = types.NPC.getFactionRank(self, npcFaction)
			if rank > 0 then
				factionBonus = rank * 2
			end
		end
	end
	local pcTerm  = (pcMerc  + pcPers * 0.3 + pcLuck * 0.1 + factionBonus) * mapUtil.getFatigueTerm(self)
	local npcTerm = (npcMerc + npcPers * 0.3 + npcLuck * 0.1) * mapUtil.getFatigueTerm(merchant)
	local dispMod = (disposition - 50) * 0.5
	local delta   = (pcTerm - npcTerm + dispMod) / 100
	-- merchant spec bonus
	local specBonus = 0
	if item then
		specBonus = spec.getModifier(merchant, item)
	end
	
	-- forced trade, worse deals
	local forcedPenalty = G_inForcedTrade and 0.2 or 0
	if buying then
		local markup = math.max(0.25, 1.0 - delta * 0.5 - specBonus + forcedPenalty)
		return math.max(1, math.floor(basePrice * markup))
	else
		local payout = math.min(0.75, 0.5 + delta * 0.5 + specBonus - forcedPenalty)
		return math.max(1, math.floor(basePrice * payout))
	end
end

-- compute the full merchant offer from a barter state.
function Pricing.computeCustomOffer(barterState, merchant)
    local merchantOffer = 0
    local trueValue     = 0
	
    local knowsExport = S_KNOWS_EXPORT and self.type.stats.skills.mercantile(self).modified >= S_KNOWS_EXPORT
    for _, data in pairs(barterState.buying) do
        local base  = Pricing.getEffectiveValue(data.item, data.count)
        -- regional supply/demand
        if regions then
            local mult = regions.getRegionalMultiplier(data.item.recordId, true, S_SD_MODIFIER, knowsExport)
            base = math.floor(base * mult)
        end
        local price = Pricing.getDeltaPrice(merchant, base, true, data.item)
        merchantOffer = merchantOffer - price
        trueValue     = trueValue - base
    end
	
    for _, data in pairs(barterState.selling) do
        local base  = Pricing.getEffectiveValue(data.item, data.count)
        if regions then
            local mult = regions.getRegionalMultiplier(data.item.recordId, false, S_SD_MODIFIER, knowsExport)
            base = math.floor(base * mult)
        end
        local price = Pricing.getDeltaPrice(merchant, base, false, data.item)
        merchantOffer = merchantOffer + price
        trueValue     = trueValue + base
    end
	
    return merchantOffer, trueValue
end

-- haggle
function Pricing.haggle(merchant, playerOffer, merchantOffer)
    if playerOffer <= merchantOffer then return true, 0 end
	
    if types.Creature.objectIsInstance(merchant) then return false, 0 end
	
    local buying = merchantOffer < 0
    local absM = math.abs(merchantOffer)
    local absP = math.abs(playerOffer)
	
    local overreach
    if buying then overreach = absM > 0 and math.floor(100 * (absM - absP) / absM) or 0
    else overreach = absP > 0 and math.floor(100 * (absP - absM) / absP) or 0
    end
	
    local disposition = util.clamp( merchant.type.getDisposition(merchant, self), 0, 100)
	
    local pcMerc = self.type.stats.skills.mercantile(self).modified
    local pcPers = self.type.stats.attributes.personality(self).modified
    local pcLuck = self.type.stats.attributes.luck(self).modified
    local npcMerc = merchant.type.stats.skills.mercantile(merchant).modified
    local npcPers = merchant.type.stats.attributes.personality(merchant).modified
    local npcLuck = merchant.type.stats.attributes.luck(merchant).modified
	
    local pcTerm  = (pcMerc + pcPers * 0.2 + pcLuck * 0.1 + (disposition - 50) * 0.5) * mapUtil.getFatigueTerm(self)
    local npcTerm = (npcMerc + npcPers * 0.2 + npcLuck * 0.1) * mapUtil.getFatigueTerm(merchant)
    local threshold = 50 + (pcTerm - npcTerm) * 0.5 - overreach
    local roll = math.random(1, 100)
	
    if roll > threshold then
        return false, 0
    end
	
    local skillGain = 0
    if not buying and absP > absM then skillGain = math.floor(100 * (absP - absM) / absP)
    elseif buying and absP < absM then skillGain = math.floor(100 * (absM - absP) / absM)
    end
	
    return true, skillGain
end

return Pricing