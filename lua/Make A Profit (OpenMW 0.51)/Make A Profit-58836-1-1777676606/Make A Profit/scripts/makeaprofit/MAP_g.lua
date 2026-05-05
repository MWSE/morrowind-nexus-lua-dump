local types = require('openmw.types')
local world = require('openmw.world')
local I     = require('openmw.interfaces')
 
local function transferCurrency(props)
    if not props.player or not props.merchant then return end
    if not props.amount or props.amount == 0 then return end
	
    local currencyId = props.currencyId or 'gold_001'
	
    if props.amount < 0 then
        local cost = -props.amount
        local playerInv = types.Actor.inventory(props.player)
        local currency = playerInv:find(currencyId)
        if currency then
            currency:remove(cost)
        end
        props.merchant.type.setBarterGold(props.merchant,
            props.merchant.type.getBarterGold(props.merchant) + cost)
    else
        local payout = props.amount
        local currency = world.createObject(currencyId, payout)
        currency:moveInto(types.Actor.inventory(props.player))
        props.merchant.type.setBarterGold(props.merchant,
            props.merchant.type.getBarterGold(props.merchant) - payout)
    end
end
 
local function serviceRefund(props)
    if not props.player then return end
    if not props.amount or props.amount <= 0 then return end
	
    local currencyId = props.currencyId or 'gold_001'
    local currency = world.createObject(currencyId, props.amount)
    currency:moveInto(types.Actor.inventory(props.player))
end
 
local function doInvest(props)
    if not props.player or not props.merchant then return end
    if not props.amount or props.amount <= 0 then return end

    local currencyId = props.currencyId or 'gold_001'
    local playerInv = types.Actor.inventory(props.player)
    local gold = playerInv:find(currencyId)
    if gold then
        gold:remove(props.amount)
    end

    -- player loses raw amount; merchant gains the effective portion (defaults to amount)
    local merchantGain = props.effective or props.amount
    props.merchant.type.setBarterGold(props.merchant,
        props.merchant.type.getBarterGold(props.merchant) + merchantGain)
	
    if props.disp and props.disp > 0 and types.NPC.objectIsInstance(props.merchant) then
        types.NPC.modifyBaseDisposition(props.merchant, props.player, props.disp)
    end
	
	props.player:sendEvent('MAP_RefreshInfoBars')
end
 
-- mirrored from player-script setting via MAP_SetPawnbrokerDamage
local pawnbrokerDamageEnabled = false
 
local function setPawnbrokerDamage(props)
    pawnbrokerDamageEnabled = props and props.enabled and true or false
end
 
local function damagePawnbrokerWares(merchant)
	local inventories = {types.Actor.inventory(merchant)}
    for _, cont in pairs(merchant.cell:getAll(types.Container)) do
		if cont.owner and cont.owner.recordId == merchant.recordId then
			table.insert(inventories, types.Container.inventory(cont))
		end
	end
   
    local damaged = 0
	for _, inv in pairs(inventories) do
		if not inv:isResolved() then
			inv:resolve()
		end
		for _, item in ipairs(inv:getAll(types.Weapon)) do
			local rec = types.Weapon.record(item)
			local maxHealth = rec.health
			if maxHealth and maxHealth > 1 then
				local data = types.Item.itemData(item)
				local cond = data.condition
				if cond == nil or cond >= maxHealth then
					data.condition = maxHealth - 1
					damaged = damaged + 1
				end
			end
		end
			
		for _, item in ipairs(inv:getAll(types.Armor)) do
			local rec = types.Armor.record(item)
			local maxHealth = rec.health
			if maxHealth and maxHealth > 1 then
				local data = types.Item.itemData(item)
				local cond = data.condition
				if cond == nil or cond >= maxHealth then
					data.condition = maxHealth - 1
					damaged = damaged + 1
				end
			end
		end
	end
	for _, item in ipairs(merchant.cell:getAll(types.Weapon)) do
		local rec = types.Weapon.record(item)
		local maxHealth = rec.health
		if maxHealth and maxHealth > 1 then
			local data = types.Item.itemData(item)
			local cond = data.condition
			if cond == nil or cond >= maxHealth then
				data.condition = maxHealth - 1
				damaged = damaged + 1
			end
		end
	end
		
	for _, item in ipairs(merchant.cell:getAll(types.Armor)) do
		local rec = types.Armor.record(item)
		local maxHealth = rec.health
		if maxHealth and maxHealth > 1 then
			local data = types.Item.itemData(item)
			local cond = data.condition
			if cond == nil or cond >= maxHealth then
				data.condition = maxHealth - 1
				damaged = damaged + 1
			end
		end
	end
end
 
-- fires on any NPC activation; only acts on player activating a pawnbroker
I.Activation.addHandlerForType(types.NPC, function(npc, actor)
    if not pawnbrokerDamageEnabled then return end
    if not actor or actor.type ~= types.Player then return end
    local rec = types.NPC.record(npc)
    if rec.class and rec.class:lower() == 'pawnbroker' then
        damagePawnbrokerWares(npc)
    end
end)
 
 
local function applyInvestment(props)
    if not props.merchant then return end
    if not props.investment or props.investment <= 0 then return end
	
    local current = props.merchant.type.getBarterGold(props.merchant)
    local target  = current + props.investment
	
    props.merchant.type.setBarterGold(props.merchant, target)
end
 
return {
    eventHandlers = {
        MAP_TransferCurrency       = transferCurrency,
        MAP_ServiceRefund          = serviceRefund,
        MAP_DoInvest               = doInvest,
        MAP_ApplyInvestment        = applyInvestment,
        MAP_SetPawnbrokerDamage    = setPawnbrokerDamage,
    },
}
