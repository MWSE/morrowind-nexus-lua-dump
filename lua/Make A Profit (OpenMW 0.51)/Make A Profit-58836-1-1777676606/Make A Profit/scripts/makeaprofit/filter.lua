-- barter filters: contraband greying, pawnbroker restrictions, category hiding
-- contraband and pawnbroker wrap each row's disabledFn via a persistent filter; category hiding uses IE's register/unregister API
 
local types   = require('openmw.types')
local util    = require('openmw.util')
local I       = require('openmw.interfaces')
local omwself = require('openmw.self')
 
local constants = require('scripts.InventoryExtender.util.constants')
local ieHelpers = require('scripts.InventoryExtender.util.helpers')
 
local Filter = {}
 
-- cached between enter/leave
local cachedMerchant     = nil
local cachedIllicit      = false
local cachedPawnbroker   = false
 
-- category button visibility
local hiddenKeysCache    = {} 
local activeKeysToHide   = nil
local categoryWrapped    = false
 
local CONTRABAND_IDS = {
    ['potion_skooma_01']		= true,
    ['ingred_moon_sugar_01']	= true,
    ['ingred_raw_ebony_01']		= true,
    ['ingred_raw_glass_01']		= true,
}
 
local DWEMER_PATTERNS = {
    '^misc_dwrv_',
    '^misc_dwemer_',
}
 
local ILLICIT_FACTIONS = {
    ['thieves guild']			= true,
    ['camonna tong']			= true,
}
 
-- local ILLICIT_RACES = {
-- 	["tsaesci"] = true,
-- 	["chimeri-quey"] = true,
-- 	["keptu-quey"] = true,
-- 	["suthay-raht"] = true,
-- 	["cathay-raht"] = true,
-- 	["dagi-raht"] = true,
-- 	["ohmes-raht"] = true,
-- }
-- add creature npc here too
 
local CATEGORY_TO_SERVICES = {
    Weapon						= { 'Weapon' },
    Armor						= { 'Armor' },
    Clothing					= { 'Clothing' },
    Potion						= { 'Potions' },
    Ingredient					= { 'Ingredients' },
    Scroll						= { 'Books' },
    Book						= { 'Books' },
    Misc						= { 'Misc' },
}
 
local ENCHANTABLE_CATEGORIES = {
    Weapon						= true,
    Armor						= true,
    Clothing					= true,
    Book						= true,
    Scroll						= true,
}
 
function Filter.isContraband(item)
    local id = item.recordId:lower()
    if CONTRABAND_IDS[id] then
        return true
    end
    for _, pattern in ipairs(DWEMER_PATTERNS) do
        if id:find(pattern) then
            return true
        end
    end
    return false
end
 
function Filter.isIllicitTrader(npc)
    if not types.NPC.objectIsInstance(npc) then
        return false
    end
	
    if types.Actor.stats.ai.alarm(npc).modified == 0 then
        return true
    end
	
    local record = types.NPC.record(npc)
    if record.class and record.class:lower() == 'smuggler' then
        return true
    end
	-- add khajiit and creature merchants
	local factions = types.NPC.getFactions(npc)
    for _, factionId in ipairs(factions) do
        if ILLICIT_FACTIONS[factionId:lower()] then
            return true
        end
    end
	
    return false
end
 
function Filter.isPawnbroker(npc)
    if not types.NPC.objectIsInstance(npc) then
        return false
    end
    local record = types.NPC.record(npc)
    return record.class and record.class:lower() == 'pawnbroker'
end
 
local function isDamaged(item, record)
    local condition = types.Item.itemData(item).condition
    local maxCondition = record.health
    if condition and maxCondition and maxCondition > 0 then
        return condition < maxCondition
    end
    return true
end
 
-- restriction check (shared by disabledFn and eject)
local function isRestricted(item, itemRecord)
    if not cachedMerchant then return false end
	
    if S_ENABLE_CONTRABAND and not cachedIllicit then
        if Filter.isContraband(item) then
            return true
        end
    end
	
    if S_ENABLE_PAWNBROKER and cachedPawnbroker then
        if types.Weapon.objectIsInstance(item) or types.Armor.objectIsInstance(item) then
            if not isDamaged(item, itemRecord or item.type.record(item)) then
                return true
            end
        end
    end
	
    return false
end
 
-- IE grey restricted items
local function registerPersistentFilter(windowName)
    local window = I.InventoryExtender.getWindow(windowName)
    if not window or not window.itemTable then return end
	
    window.itemTable.layout.userData.setFilter('mapDisableFilter', function(row)
        if row._map_disableWrapped then return true end
        row._map_disableWrapped = true
		
        local origDisabledFn = row.disabledFn
		
        row.disabledFn = function(r)
            -- preserve IE's own disabled logic (e.g. organic containers)
            if origDisabledFn and origDisabledFn(r) then
                return true
            end
			
            if I.UI.getMode() ~= 'Barter' then return false end
			
            return isRestricted(row.item, row.itemRecord)
        end
		
        return true
    end)
end
 
-- sell-anything barterFilter override
local function isSellAnythingActive()
	if G_inForcedTrade then return true end
	if not S_ENABLE_SELL_ANYTHING then return false end
	local merc = omwself.type.stats.skills.mercantile(omwself).modified
	return merc >= S_SELL_ANYTHING_THRESHOLD
end
 
-- replace IE's barterFilter so the service-type check can be bypassed at high mercantile; all other barterFilter logic preserved
local function registerBarterOverride(windowName)
	local window = I.InventoryExtender.getWindow(windowName)
	if not window or not window.itemTable then return end
	
	window.itemTable.layout.userData.setFilter('barterFilter', function(row)
		if I.UI.getMode() == 'Barter' then
			if ieHelpers.isGold(row.item) then return false end
			if row.item.type.record(row.item).isKey then return false end
			
			local barterNpc = window.ctx.windowArgs.Trade
			if not barterNpc then return false end
			
			-- service gate
			if not isSellAnythingActive() then
				local services = barterNpc.type.record(barterNpc).servicesOffered
				if services.MagicItems and row.itemRecord.enchant then else
					for t, serviceName in pairs(constants.TypeToService) do
						if types[t].objectIsInstance(row.item) then
							if not services[serviceName] then
								return false
							end
							break
						end
					end
				end
			end
			
			-- barter count tracking
			if window.type == 'Inventory' then
				if row.isBartered then
					return window.ctx.barterState.buying[row.item.id]
						and window.ctx.barterState.buying[row.item.id].count > 0
				end
				local sellingCount = window.ctx.barterState.selling[row.item.id]
					and window.ctx.barterState.selling[row.item.id].count or 0
				return row.getCount() > sellingCount
			elseif window.type == 'Trade' then
				if not isSellAnythingActive() and window.target.type.hasEquipped(window.target, row.item) then
					return false
				end
				if row.isBartered then
					return window.ctx.barterState.selling[row.item.id]
						and window.ctx.barterState.selling[row.item.id].count > 0
				end
				local buyingCount = window.ctx.barterState.buying[row.item.id]
					and window.ctx.barterState.buying[row.item.id].count or 0
				return row.getCount() > buyingCount
			end
		else
			return not row.isBartered
		end
	end)
end
 
function Filter.init()
    registerPersistentFilter('Inventory')
    registerPersistentFilter('Trade')
    registerBarterOverride('Inventory')
    registerBarterOverride('Trade')
end
 
-- eject restricted items from barter state
function Filter.ejectRestricted(ctx)
    if I.UI.getMode() ~= 'Barter' then return false end
    if not cachedMerchant then return false end
    if not ctx or not ctx.barterState then return false end
	
    local ejected = false
	
    for id, entry in pairs(ctx.barterState.selling) do
        if isRestricted(entry.item) then
            ctx.barterState.selling[id] = nil
            ejected = true
        end
    end
	
    for id, entry in pairs(ctx.barterState.buying) do
        if isRestricted(entry.item) then
            ctx.barterState.buying[id] = nil
            ejected = true
        end
    end
	
    return ejected
end
 
local RESTRICTED_TINT = util.color.rgb(1, 0.35, 0.35)
local NO_TINT         = util.color.rgb(1, 1, 1)
 
local function findNamedLayout(layoutOrElement, name, lastElem)
	local isElem = type(layoutOrElement) == 'userdata'
	if isElem then lastElem = layoutOrElement end
	local layout = isElem and layoutOrElement.layout or layoutOrElement
	if layout.name == name then return layout, lastElem end
	if layout.content then
		for _, child in pairs(layout.content) do
			local hit, elem = findNamedLayout(child, name, lastElem)
			if hit then return hit, elem end
		end
	end
end
 
function Filter.tintRestrictedRows()
	if I.UI.getMode() ~= 'Barter' then return end
	
	for _, windowName in ipairs({'Inventory', 'Trade'}) do
		local window = I.InventoryExtender.getWindow(windowName)
		if window and window.itemTable then
			local state = window.itemTable.layout.userData.getState()
			if not state then goto nextWindow end
			
			for _, row in ipairs(state.sortedRows) do
				local widget = state.rowCache[row.id]
				if widget then
					local icon, parentElem = findNamedLayout(widget, 'itemIcon')
					if icon then
						local restricted = isRestricted(row.item, row.itemRecord)
						local tint = restricted and RESTRICTED_TINT or NO_TINT
						if icon.props.color ~= tint then
							icon.props.color = tint
							if parentElem then
								--parentElem:update()
							end
						end
					end
				end
			end
			
			::nextWindow::
		end
	end
end
 
local function applyCategoryVisibility(window)
	G_nextFrameJobs['catVis_' .. tostring(window)] = function()
		if not window or not window.categoryFilter then return end
		local bar = window.categoryFilter.layout.content.categoryBar
		if not bar or not bar.content then return end
		
		local categories = I.InventoryExtender.getCategories()
		
		for i, child in ipairs(bar.content) do
			local cat = categories[i]
			if cat then
				local shouldHide = activeKeysToHide and activeKeysToHide[cat.key] or false
				if shouldHide then
					local isElem = type(child) == 'userdata'
					local layout = isElem and child.layout or child
					layout.props = layout.props or {}
					layout.props.alpha = 0.15
					layout.events = nil
					if isElem then child:update() end
				else
					local isElem = type(child) == 'userdata'
					local layout = isElem and child.layout or child
					if layout.events then
						local origEvent = layout.events.mouseRelease
						layout.events.mouseRelease = async:callback(function(...)  origEvent(...) applyCategoryVisibility(window) end)
					end
				end
			end
		end
	end
end
 
local function wrapCategoryUpdate(window)
    if not window or not window.categoryFilter then return end
    local ud = window.categoryFilter.layout.userData
    if ud._map_catWrapped then return end
	
    local orig = ud.updateCategories
    ud.updateCategories = function(...)
        orig(...)
        applyCategoryVisibility(window)
    end
    ud._map_catWrapped = true
end
 
local function getKeysToHide(merchant)
    local recordId = merchant.recordId
    if hiddenKeysCache[recordId] then
        return hiddenKeysCache[recordId]
    end
	
    local keysToHide = {}
    local services = merchant.type.record(merchant).servicesOffered
    local hasMagicItems = services.MagicItems
	
    for _, cat in ipairs(I.InventoryExtender.getCategories()) do
        local serviceKeys = CATEGORY_TO_SERVICES[cat.key]
        if serviceKeys then
            local merchantHandles = false
            for _, svcKey in ipairs(serviceKeys) do
                if services[svcKey] then
                    merchantHandles = true
                    break
                end
            end
            if not merchantHandles and hasMagicItems and ENCHANTABLE_CATEGORIES[cat.key] then
                merchantHandles = true
            end
            if not merchantHandles then
                keysToHide[cat.key] = true
            end
        end
    end
	
    hiddenKeysCache[recordId] = keysToHide
    return keysToHide
end
 
function Filter.onEnterBarter(merchant)
    cachedMerchant   = merchant
    cachedIllicit    = merchant and Filter.isIllicitTrader(merchant) or false
    cachedPawnbroker = merchant and Filter.isPawnbroker(merchant) or false
	
    if not merchant then return end
	
    if not categoryWrapped then
        for _, windowName in ipairs({'Inventory', 'Trade'}) do
            wrapCategoryUpdate(I.InventoryExtender.getWindow(windowName))
        end
        categoryWrapped = true
    end
	
    if S_ENABLE_CATEGORY_HIDING and types.NPC.objectIsInstance(merchant)
        and not isSellAnythingActive() then
        activeKeysToHide = getKeysToHide(merchant)
        if not next(activeKeysToHide) then
            activeKeysToHide = nil
        end
    else
        activeKeysToHide = nil
    end
	
    for _, windowName in ipairs({'Inventory', 'Trade'}) do
        applyCategoryVisibility(I.InventoryExtender.getWindow(windowName))
    end
end
 
function Filter.onLeaveBarter()
    for _, windowName in ipairs({'Inventory', 'Trade'}) do
        local window = I.InventoryExtender.getWindow(windowName)
        if window and window.itemTable then
            local state = window.itemTable.layout.userData.getState()
            if state then
                for _, widget in pairs(state.rowCache) do
                    local icon = findNamedLayout(widget, 'itemIcon')
                    if icon and icon.props.color ~= NO_TINT then
                        icon.props.color = NO_TINT
                        widget:update()
                    end
                end
            end
        end
    end
	
    cachedMerchant   = nil
    cachedIllicit    = false
    cachedPawnbroker = false
    activeKeysToHide = nil
	
    for _, windowName in ipairs({'Inventory', 'Trade'}) do
        applyCategoryVisibility(I.InventoryExtender.getWindow(windowName))
    end
end
 
return Filter
