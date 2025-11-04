--[[
Inventory Sorter
Surprisingly complex until we get some hook to the game item tiles sorting function
or at least some hack to pass to the sorting function a desired string instead of the item name
]]

local defaultConfig = {
sortOrderCombo = { -- right mouse button
	mouseButton = 1,
},
sortOrderCombo2 = { -- alt + right mouse button
	mouseButton = 1,
	isAltDown = true,
},
showSortBy = true,
ctrlClickEquip = true,
modEnabled = true,
logLevel = 0,
}

local author = 'abot'
local modName = 'Inventory Sorter'
local modPrefix = author..'\\'..modName
local configName = author..modName
configName = configName:gsub(' ', '_')
local mcmName = author.."'s "..modName

local config = mwse.loadConfig(configName, defaultConfig)

-- to be saved/loaded
local timestamp = 0 -- integer timestamp, to be saved/loaded in
local itemRecs = {} -- e.g. itemRecs['bk_affairsofwizards'] = {a = timestamp, e = timestamp}}

local function incTimestamp()
	timestamp = timestamp + 1
	return timestamp
end

local modEnabled, sortOrderCombo, sortOrderCombo2, showSortBy, ctrlClickEquip, logLevel
local logLevel1, logLevel2, logLevel3, logLevel4, logLevel5, logLevel6

local function updateFromConfig()
	modEnabled = config.modEnabled
	sortOrderCombo = config.sortOrderCombo
	sortOrderCombo2 = config.sortOrderCombo2
	showSortBy = config.showSortBy
	ctrlClickEquip = config.ctrlClickEquip
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
	logLevel6 = logLevel >= 6
	---mwse.log('>>> logLevel = %s', config.logLevel)
end
updateFromConfig()

local sortBy = 1

-- note: you can rearrange the options order (move rows up/down),
-- but not the values inside {} unless you change the itemTileUpdated(e) code accordingly
local sortByOptions = {
{n = 'Name, Asc', v = 1},
{n = 'Value/Weight, Asc', v = 2},
{n = 'Value/Weight, Desc', v = 3},
{n = 'Value, Asc', v = 4},
{n = 'Value, Desc', v = 5},
{n = 'Weight, Asc', v = 6},
{n = 'Weight, Desc', v = 7},
{n = 'Score, Asc', v = 8},
{n = 'Score, Desc', v = 9},
{n = 'Time Activated, Asc', v = 10},
{n = 'Time Activated, Desc', v = 11},
{n = 'Time Equipped, Asc', v = 12},
{n = 'Time Equipped, Desc', v = 13},
}

local menuTileNames = {'MenuInventory', 'MenuContents', 'MenuBarter'}
local menuTileNamesDict = table.invert(menuTileNames)

local tes3_menuMode, tes3_messageBox = tes3.menuMode, tes3.messageBox

local function notify(str, ...)
	if not tes3_menuMode() then
		tes3_messageBox(tostring(str):format(...))
	end
end

-- set in loaded()
local player ---@type tes3reference|nil
local mobilePlayer ---@type tes3mobileNPC|nil

-- used to allow sort options menu only when mouse clicks are
-- inside proper windows if sort options key combo uses mouse
local mouseOverTileMenu = false

local mwse_log = mwse.log

---@param e tes3uiEventData
local function beforeMouseOverTileMenu(e)
	if logLevel6 then
		mwse_log('%s: beforeMouseOverTileMenu("%s")', modPrefix, e.source.name)
	end
	mouseOverTileMenu = true
end

---@param e tes3uiEventData
local function beforeMouseLeaveTileMenu(e)
	if logLevel6 then
		mwse_log('%s: beforeMouseLeaveTileMenu("%s")', modPrefix, e.source.name)
	end
	mouseOverTileMenu = false
end

local tes3ui_findMenu = tes3ui.findMenu
local tes3ui_registerID = tes3ui.registerID

local idMenuBarter = tes3ui_registerID('MenuBarter')
local idMenuContents = tes3ui_registerID('MenuContents')
local idMenuInventory = tes3ui_registerID('MenuInventory')
local idMenuInventorySelect = tes3ui_registerID('MenuInventorySelect')
local idMenuMagicSelect = tes3ui_registerID('MenuMagicSelect')
local idMenuMessage = tes3ui_registerID('MenuMessage')

local math_abs, math_modf, math_remap = math.abs, math.modf, math.remap

local maxValue = 10^14
local numPattern = '^#%x+%.%d%d%d$'

---@param item tes3item
---@param name string
local function setItemName(item, name)
	if not item then
		return
	end
	if not item.name then
		return
	end
	if item.name == name then
		return
	end
	if logLevel3 then
		mwse_log('%s: setItemName("%s", "%s")',	modPrefix, item.id, name)
	end
	item.name = name -- the one and only place where we effectively change item.name
	item.modified = false -- important!!! this ensures no name change is stored in game saves
end

-- set to false by keyCombo2 to skip taking item quantity into account
local mulQuantity = true

local T3OT = tes3.objectType
---local T3OT_alchemy = T3OT.alchemy
local T3OT_ammo = T3OT.ammo
local T3OT_apparatus = T3OT.apparatus
local T3OT_armor = T3OT.armor
local T3OT_book = T3OT.book
local T3OT_clothing = T3OT.clothing
---local T3OT_ingredient = T3OT.ingredient
local T3OT_light = T3OT.light
local T3OT_lockpick = T3OT.lockpick
local T3OT_miscItem = T3OT.miscItem
local T3OT_probe = T3OT.probe
local T3OT_weapon = T3OT.weapon

local T3OT_repairItem = T3OT.repairItem

local tes3_bookType_book = tes3.bookType.book

---@param w tes3weapon
local function getDamageReachSpeed(w)
	if w.isProjectile
	or w.isAmmo then
		return (w.chopMin + w.chopMax) * 0.5 * w.speed
	end
	return (w.chopMin + w.chopMax + w.slashMin + w.slashMax + w.thrustMin + w.thrustMax) * 0.5 * w.speed * w.reach
end

local minDivider = 0.0001

---@param x number
---@param y number
---@return number
local function getFrac(x, y)
	if (not x)
	or (x < minDivider) then
		x = minDivider
	end
	if (not y)
	or (y < minDivider) then
		y = minDivider
	end
	return x / y
end

-- set in initialized()
local ab01goldWeight ---@type tes3globalVariable|nil

-- updated when changing sortBy
local goldWeight = 0

---@param item tes3item
---@return number|nil
local function getItemWeight(item)
	if ab01goldWeight then
		if item.id:lower() == 'gold_001' then
			return goldWeight
		end
	end
	return item['weight']
end

---@param item tes3item
---@return number
local function getValueWeightRatio(item)
	return getFrac(item['value'], getItemWeight(item))
end

---@param item tes3item
---@return number
local function getWeightValueRatio(item)
	return getFrac(getItemWeight(item), item['value'])
end

-- set in modConfigReady()
local MCPSoulgemValueRebalance = false

---@param miscItem tes3misc
---@param itemData tes3itemData
---@return number|nil
local function getSoulGemValue(miscItem, itemData)
	if not miscItem.isSoulGem then
		return
	end
	if not itemData then
		return
	end
	local soul = itemData.soul
	if not soul then
		return
	end
	local soulValue = soul.soul
	if not soulValue then
		return
	end
	if MCPSoulgemValueRebalance then
		return (soulValue * soulValue / 10000 + 2) * soulValue
	end
	return miscItem.value * soulValue
end

local inTools = {
[T3OT_lockpick] = true,
[T3OT_probe]= true,
[T3OT_repairItem] = true
}

---@param item tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3item|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
---@param itemData tes3itemData
---@return number
local function getItemStat(item, itemData)
	local objType = item.objectType
	local v = math_remap(getValueWeightRatio(item), 0, 10000, 1, 1000)

	local function mulCondition()
		if itemData
		and itemData.condition then
			v = v * itemData.condition
		else
			v = v * item.maxCondition
		end
	end

	local function addEnchantCapacity()
		if item.enchantCapacity > 0 then
			v = v + item.enchantCapacity
		end
	end

	local function mulDamageReachSpeed()
		v = v * getDamageReachSpeed(item)
	end

	local function mulQuality()
		v = v * item.quality
	end

	if objType == T3OT_clothing then
		addEnchantCapacity()
	elseif objType == T3OT_book then
		if item.type == tes3_bookType_book then
			if item.skill
			and (item.skill >= 0) then
				v = v + 300
			end
		else
			addEnchantCapacity()
		end
	elseif inTools[objType] then
		mulCondition()
		mulQuality()
	elseif objType == T3OT_ammo then
		mulDamageReachSpeed()
		addEnchantCapacity()
	elseif objType == T3OT_weapon then
		mulCondition()
		mulDamageReachSpeed()
		addEnchantCapacity()
	elseif objType == T3OT_armor then
		mulCondition()
		v = v * item.armorRating * item.armorScalar
		addEnchantCapacity()
	elseif objType == T3OT_light
	and item.canCarry then
		local t = 0
		if itemData
		and itemData.timeLeft then
			t = itemData.timeLeft
			if t < 0 then
				t = 0
			end
		else
			t = item.time
			if t < 0 then
				t = 999999999
			end
		end
		v = v + t + (10 * item.radius)
	elseif objType == T3OT_apparatus then
		mulQuality()
	elseif objType == T3OT_miscItem then
		local sgv = getSoulGemValue(item, itemData)
		if sgv then
			v = v * sgv / item.value
			v = math_remap(v, 0, 10000, 1, 1000)
		end
	end
	return v
end

local itemNames = {} -- e.g. itemNames[tes3.getObject("6th bell hammer")] = "Sixth House Bell Hammer"
local itemWasModified = {} -- e.g. itemWasModified[tes3.getObject("6th bell hammer")] = true

local skipTileSort = true

local idCursorIcon = tes3ui_registerID('CursorIcon')
local tes3ui_findHelpLayerMenu = tes3ui.findHelpLayerMenu
local function getCursorIcon()
	return tes3ui_findHelpLayerMenu(idCursorIcon)
end

local function resetItemNames()
	skipTileSort = true
	for item, oldName in pairs(itemNames) do
		if oldName
		and ( not oldName:find(numPattern) ) then
			setItemName(item, oldName)
		end
		if itemWasModified[item] then
			itemWasModified[item] = nil
			item.modified = true
		end
	end
end

---@param s string
local function getFileName(s)
	return s:match('([^\\/]+)%.%w+$')
end

local string_upper = string.upper

---@param path string
local function getNameFromPath(path)
	-- strip starting prefix, replace remaining underscores with spaces, upcase first character
	return getFileName(path):gsub('^%w+_', ''):gsub('_', ' '):gsub('^%l', string_upper)


end

---@param obj tes3item
---@return string|nil
local function getNameFromFile(obj)
	local path = obj.mesh
	if path then
		return getNameFromPath(path)
	end
	path = obj.icon
	if path then
		return getNameFromPath(path)
	end
end

local function checkPackResetItemNames()
	skipTileSort = true
	local t = {}
	for item, name in pairs(itemNames) do
		if name then
			local item_name = item.name
			if item_name then
				if not name:find(numPattern) then
					t[item] = name
				elseif not item_name:find(numPattern) then
					t[item] = item_name
				else -- safety enforcer
					local s = getNameFromFile(item)
					if s then
						mwse_log('%s: WARNING id = "%s", name = "%s", itemNames["%s"] = "%s" --> "%s"',
							modPrefix, item.id, item_name, item.id, name, s)
						t[item] = s
					end
				end
				if itemWasModified[item] then
					itemWasModified[item] = nil
				else
					item.modified = false
				end
				if not t[item] then
					mwse_log('%s: checkPackResetItemNames() id = "%s", name = "%s", itemNames["%s"] = "%s")',
						modPrefix, item.id, item_name, item.id, name)
					---assert(false)
				end
			end
			itemNames[item] = nil
		end
	end
	itemNames = t
end

local function getSavedDataTable()
	local player = tes3.player
	assert(player)
	local data = player.data
	assert(data)
	local ab01inso = data.ab01inso
	if not ab01inso then
		data.ab01inso = {}
		ab01inso = data.ab01inso
	end
	return ab01inso
end

-- with low priority so it can still be skipped
local function save()
	local ab01inso = getSavedDataTable()
	ab01inso.timestamp = timestamp
	ab01inso.itemRecs = itemRecs
	checkPackResetItemNames()
end

local idPartDragMenu_thick_border = tes3ui_registerID('PartDragMenu_thick_border')
local idPartDragMenu_center_frame = tes3ui_registerID('PartDragMenu_center_frame')
local idPartDragMenu_drag_frame = tes3ui_registerID('PartDragMenu_drag_frame')
local idPartDragMenu_title_tint = tes3ui_registerID('PartDragMenu_title_tint')
local idPartDragMenu_title = tes3ui_registerID('PartDragMenu_title')

---@param elem tes3uiElement
---@param ancestor tes3uiElement
---@return tes3uiElement[]
local function getElementPath(elem, ancestor)
	local el = elem
	local t = { el }
	if not ancestor then
		ancestor = el:getTopLevelMenu()
	end
	if not ancestor then
		return t
	end
	local k = 1
	t[k] = el
	while not (el == ancestor) do
		el = el.parent
		if el.name
		and ( el.name:len() > 0 ) then
			k = k + 1
			t[k] = el
		end
	end
	local t2 = {}
	local j = 0
	for i = #t, 1, -1 do
		j = j + 1
		t2[j] = t[i]
	end
	return t2
end

local table_concat = table.concat

---@param elem tes3uiElement
---@param ancestor tes3uiElement
---@return string
local function getElementPathStr(elem, ancestor)
	local el = elem
	local t = getElementPath(el, ancestor)
	local last = #t
	local t2 = {}
	for i = 1, last - 1 do
		el = t[i]
		t2[i] = el.id..' ("'..el.name..'"), '
	end
	el = t[last]
	t2[last] = el.id..' ("'..el.name..'")'
	return table_concat(t2)
end

---@param ancestor tes3uiElement
---@param pathTable number[]|nil
---@return tes3uiElement|nil
local function getChildFromPath(ancestor, pathTable)
	local el = ancestor
	if not el then
		return
	end
	if not pathTable then
		return
	end
	for i = 1, #pathTable do
		if el then
			el = el:findChild(pathTable[i])
		else
			return
		end
	end
	return el
end

 -- cached, reset in loaded, beforeDestroyTileMenu
-- e.g. menuTitleElements[menuId] = el
local menuTitleElements = {}

---@param menu tes3uiElement
---@return tes3uiElement|nil
local function getMenuTitleElem(menu)
	local menuId = menu.id
	local el = menuTitleElements[menuId]
	if el then
		return el
	end
	el = getChildFromPath(menu, {idPartDragMenu_thick_border, idPartDragMenu_center_frame,
		idPartDragMenu_drag_frame, idPartDragMenu_title_tint, idPartDragMenu_title})
	if el then
		menuTitleElements[menuId] = el
		if logLevel5 then
			mwse_log('%s: getMenuTitle("%s") = "%s" path: %s',
				modPrefix, menu.name, el.name, getElementPathStr(el, menu))
		end
	end
	return el
end

---@param menuId number
---@param item tes3item|nil
local function updateMenuTitle(menuId, item)
	local menu = tes3ui_findMenu(menuId)
	if not menu then
		return
	end
	local el = getMenuTitleElem(menu)
	if not el then
		return
	end
	local s = el.text
	if item then
		if itemNames[item] then
			s = itemNames[item]
		else
			s = item.name
		end
	end
	if (menuId == idMenuInventory)
	and (s:len() > 0) then
		local byPrefix = ' (by '
		local by = byPrefix..sortByOptions[sortBy].n..')'
		if mulQuantity then
			by = by:gsub(',', '%*,')
		end
		if showSortBy then
			if s:find(byPrefix, 1, true) then
				s = s:gsub(' (%(by [^%)]+%))', by)
			else
				s = s..by
			end
		end
	end
	if el.text == s then
		return
	end
	if logLevel1 then
		mwse_log('%s: %s title reset from "%s" to "%s"',
			modPrefix, menu.name, el.text, s)
	end
	el.text = s -- update Menu title
end

local function updateInventoryMenuTitle()
	updateMenuTitle(idMenuInventory)
end

local function updateAllMenuTiles()
	local etime
	if logLevel1 then
		etime = os.clock()
	end

	if getCursorIcon() then
		return
	end
	skipTileSort = false
	local menu = tes3ui_findMenu(idMenuBarter)
	if menu
	and menu.visible then
		tes3ui.updateBarterMenuTiles()
	end
	menu = tes3ui_findMenu(idMenuContents)
	if menu
	and menu.visible then
		tes3ui.updateContentsMenuTiles()
	end
	menu = tes3ui_findMenu(idMenuInventory)
	if menu
	and menu.visible then
		tes3ui.updateInventoryTiles()
	end
	resetItemNames()
	updateInventoryMenuTitle()

	if logLevel1 then
		mwse_log('%s: updateAllMenuTiles() elapsed time: %.5f', modPrefix, os.clock() - etime)
	end

end

---@param item tes3item
---@param params table
local function updateItemTimestamps(item, params)
	local lcItemId = item.id:lower()
	local itemRec = itemRecs[lcItemId]
	local timestamp = incTimestamp()
	if itemRec then
		if params.equip then
			itemRec.e = timestamp
		elseif params.activate then
			itemRec.a = timestamp
		end
		return
	end
	itemRecs[lcItemId] = {a = timestamp, e = timestamp}
end

---@param item tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3item|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
---@param count integer
---@param itemData tes3itemData
local function sortItem(item, count, itemData)
	local funcPrefix
	if logLevel1 then
		funcPrefix = modPrefix..' sortItem()'
	end
	local itemId = item.id
	local lcItemId = itemId:lower()
	local itemRec = itemRecs[lcItemId]
	local objType = item.objectType

-- value that will replace the item name for sorting
	local v

	local qt = true -- flag to allow multiply value by tile.count

	-- sort by 1 = Name, 2,3 = Value/Weight, 4,5 = Value, 6,7 = Weight, 8,9 = Score, 10,11 = Last Activated , 12,13 = Last Equipped

	if sortBy >= 8 then -- 13 options, probably worth splitting
		if sortBy >= 12 then -- by time equipped
			if itemRec then
				v = itemRec.e
			else
				v = 0
			end
			qt = false
		elseif sortBy >= 10 then -- by time activated
			if itemRec then
				v = itemRec.a
			else
				v = 0
			end
			qt = false
		else -- sortBy >= 8 by Score condition/timeLeft/charge...
			v = getItemStat(item, itemData)
		end
	else -- sortBy < 8
		if sortBy >= 6 then
			v = getItemWeight(item)
			if not v then
				v = 0
			end
		elseif sortBy >= 4 then
			v = item.value
			if objType == T3OT_miscItem then
				local sgv = getSoulGemValue(item, itemData)
				if sgv then
					v = sgv
				end
			end
			if not v then
				v = 0
			end
		elseif sortBy == 2 then
			v = math_remap(getValueWeightRatio(item), 0, 1000000, 1, 100000)
		elseif sortBy == 3 then
			v = math_remap(getWeightValueRatio(item), 0, 1000, 1, 1000000)
		end
	end

	local itemRealName = item.name
	local itemNewName = itemRealName
	if sortBy > 1 then
		if v then
			if sortBy > 3 then
				if qt
				and mulQuantity then
					v = v * math_abs(count)
				end
				if ( (sortBy % 2) > 0) -- odd means descending order
				and (v < maxValue) then
					v = maxValue - v
				end
			end
			local int, frac = math_modf(v)
-- e.g. int = 999999999999999, frac = 0.1236123 becomes #0a4c67fff.124
			itemNewName = ('#%08x'):format(int)..( ('%.03f'):format(frac) ):sub(2)
			if logLevel6 then
				mwse_log('%s: sortItem("%s") itemNewName = "%s", itemRealName = "%s"',
					modPrefix, itemId, itemNewName, itemRealName)
			end
		end
	end
	if itemNewName == itemRealName then
		return
	end

	if logLevel5 then
		mwse_log('%s: sortItem("%s") itemNewName = "%s", itemRealName = "%s"',
			modPrefix, itemId, itemNewName, itemRealName)
	end

	if not itemRealName:find(numPattern) then
		itemNames[item] = itemRealName
	end
	if item.modified then
		itemWasModified[item] = true -- store it in case something else modified the item
	end
	setItemName(item, itemNewName)
end

local ab01insoTCid = tes3ui.registerProperty('ab01insoTC')
local idMenuInventory_Thing = tes3ui.registerProperty('MenuInventory_Thing')
---local idMenuBarter_Thing = tes3ui.registerProperty('MenuBarter_Thing')
---local idMenuInventory_Object = tes3ui.registerProperty('MenuInventory_Object')

-- set in modConfigReady
local inputController ---@type tes3inputController

---@param tile tes3inventoryTile
local function equipUnequip(tile)
	if not ctrlClickEquip then
		return
	end
	if not inputController:isControlDown() then
		return
	end
	if getCursorIcon() then
		return
	end
	if not tile then
		return
	end
	local itm = tile.item
	if not itm then
		return
	end
	if (tile.count == 1)
	or (
		(itm.objectType == T3OT_ammo)
		and inputController:isAltDown()
	) then
		local itmData = tile.itemData
		if tile.isEquipped then
-- note player, mobilePlayer are safe to use here
-- as we call equipUnequip from beforeMouseClickInventoryTileElement()
-- and we register beforeMouseClickInventoryTileElement() in itemTileUpdated
-- which only fires after loaded event has initialized player to tes3.player
---@diagnostic disable-next-line: need-check-nil
			mobilePlayer:unequip({item = itm, itemData = itmData})
		else
			if itmData then
---@diagnostic disable-next-line: need-check-nil
				mobilePlayer:equip({item = itm, itemData = itmData})
			else
				-- slower, but triggers the equip event so may update things better /abot
---@diagnostic disable-next-line: deprecated
				mwscript.equip({reference = player, item = itm})
			end
		end
		return true
	end
end

---@param e tes3uiEventData
local function beforeMouseClickInventoryTileElement(e)
	---tes3.messageBox('beforeMouseClickInventoryTileElement')
	local el = e.source
	local tile = el:getPropertyObject(
		idMenuInventory_Thing, 'tes3inventoryTile')
	if equipUnequip(tile) then
		return false
	end
end

--[[
local function UIEX_InventoryTileClicked(e)
	local el = e.element
	local menu = el:getTopLevelMenu()
	if not (menu.id == idMenuInventory) then
		return
	end
	if equipUnequip(e.tile) then
		return false
	end
end

local function mouseClickTileElement(e)
	---tes3.messageBox({message = 'mouseClickTileElement'})
	local el = e.source
	local tile = el:getPropertyObject(
		idMenuInventory_Thing, 'tes3inventoryTile')
	if equipUnequip(tile) == false then
		return
	end
	el:forwardEvent(e)
end

local function afterMouseClickTileElement()
	---tes3.messageBox({message = 'afterMouseClickTileElement'})
	updateAllMenuTiles()
end
]]

local function delayedUpdateAllMenuTiles()
	timer.frame.delayOneFrame(
		function ()
			timer.frame.delayOneFrame(updateAllMenuTiles)
		end
	)
end

local function calcBarterPrice()
	delayedUpdateAllMenuTiles()
end

---@param e itemTileUpdatedEventData
local function itemTileUpdated(e)
	local menu = e.menu
	if not menuTileNamesDict[menu.name] then
		return
	end
	local el = e.element
	local item = e.item
	local menuId = menu.id
	--[[if not el:getPropertyBool(ab01insoTCid) then
		el:setPropertyBool(ab01insoTCid, true)
		if menu.id == idMenuInventory then
			---mwse_log("%s:registerBefore('mouseClick', beforeMouseClickInventoryTileElement)", item.id)
			el:registerBefore('mouseClick', beforeMouseClickInventoryTileElement)
			---el:register('mouseClick', mouseClickTileElement)
		end
		---el:registerAfter('mouseClick', afterMouseClickTileElement)
	end]]
	if (menuId == idMenuInventory)
			and ( not el:getPropertyBool(ab01insoTCid) ) then
		el:setPropertyBool(ab01insoTCid, true)
		if ctrlClickEquip then
			el:registerBefore('mouseClick', beforeMouseClickInventoryTileElement)
		end
	end
	if skipTileSort then
		return
	end
	local tile = e.tile
	if tile.isEquipped then
	--- or tile.isBoundItem
	---or tile.isBartered then
		return
	end
-- note player, mobilePlayer are safe to use here
-- as itemTileUpdated only fires after loaded event
-- has initialized player and mobilePlayer
---@diagnostic disable-next-line: need-check-nil
	local stack = mobilePlayer.currentEnchantedItem
	if stack
	and (stack.object == item) then
		if logLevel2 then
			mwse_log('%s: itemTileUpdated() currentEnchantedItem = "%s" ("%s")',
				modPrefix, item.id, item.name)
		end
		return
	end
	if getCursorIcon() then
		return
	end
	sortItem(item, tile.count, e.itemData)
end

---@param e activateEventData
local function activate(e)
	if not (e.activator == player) then
-- safe to use player here as we set player in loaded()
-- and register this event only after that
		return
	end
	local item = e.target.object
	if not item.value then
		return
	end
	updateItemTimestamps(item, {activate = true})
end

---@param e equipEventData
local function equip(e)
	if not (e.reference == player) then
-- safe to use player here as we set player in loaded()
-- and register this event only after that
		return
	end
	local item = e.item
	updateItemTimestamps(item, {equip = true})
end

---@param e equippedEventData
local function equipped(e)
	if not (e.reference == player) then
-- safe to use player here as we set player in loaded()
-- and register this event only after that
		return
	end
	local item = e.item
	updateItemTimestamps(item, {equip = true})
	updateAllMenuTiles()
end

---@param e unequippedEventData
local function unequipped(e)
	if not (e.reference == player) then
-- safe to use player here as we set player in loaded()
-- and register this event only after that
		return
	end
	if not e.item then
		return
	end
	updateAllMenuTiles()
end

---@param e convertReferenceToItemEventData
local function convertReferenceToItem(e)
	local item = e.reference.object
	if not item.value then
		return
	end
	updateItemTimestamps(item, {equip = true})
end

local function magicSelectionChanged()
	updateAllMenuTiles()
end

--[[
local function barterOffer(e)
	if not e.success then
		return
	end
	local tile = e.buying
	if not tile then
		return
	end
	local item = tile.item
	if not item then
		return -- it happens
	end
	checkUpdates = true
	timer.frame.delayOneFrame(updateInventoryMenuTitleAndMenuMagic)
end
]]

local sortOptionsMenuName = 'ab01isSortOptionsMenu'
local idSortOptionsMenuName = tes3ui_registerID(sortOptionsMenuName)

local sortOrderMenuButtons = {}

local function setSortOrderMenuButtons()
	local prefix = {[false] = '  ', [true] = '> '}
	local suffix = {[false] = '  ', [true] = ' <'}
	if logLevel2 then
		local s2 = 'sortBy = '..sortBy..' ('..sortByOptions[sortBy].n..')'
		if logLevel3 then
			mwse_log('%s: setSortOrderMenuButtons() %s', modPrefix, s2)
		end
	end
	for i = 1, #sortByOptions do
		local o = sortByOptions[i]
		local value = o.v
		local isCurrent = (sortBy == value)
		local s = prefix[isCurrent]..o.n..suffix[isCurrent]
		if logLevel5 then
			mwse_log('"%s" = %s', s, value)
		end
		sortOrderMenuButtons[i] = {
			text = s,
			callback = function ()
				sortBy = value
				if ab01goldWeight then
					goldWeight = ab01goldWeight.value
				end
				if logLevel3 then
					local s = 'sortBy = '..sortBy..' (by '..sortByOptions[sortBy].n..')'
					notify(s)
				end
				updateAllMenuTiles()
			end
		}
	end
end

---comment
---@param menus number[]
---@return tes3uiElement|nil
local function getAlreadyVisibleMenu(menus)
	for i = 1, #menus do
		local menu = tes3ui_findMenu(menus[i])
		if menu
		and menu.visible then
			return menu
		end
	end
end

local idCancelButton = tes3ui_registerID('MenuMessage_CancelButton')

local tes3_isKeyEqual = tes3.isKeyEqual

---@param e mouseButtonUpEventData|keyDownEventData|mouseWheelEventData
local function onKeyCombo(e)
	if not tes3_menuMode() then
		return
	end
	if tes3_isKeyEqual({expected = sortOrderCombo, actual = e}) then
		mulQuantity = true
	elseif tes3_isKeyEqual({expected = sortOrderCombo2, actual = e}) then
		mulQuantity = false
	else
		return
	end
	local menu = tes3ui_findMenu(idSortOptionsMenuName)
	if menu
	and menu.visible then
		local cancelButton = menu:findChild(idCancelButton)
		if cancelButton then
			-- exit menu if already there
			cancelButton:triggerEvent('mouseClick')
			return
		end
	end
	if (
		sortOrderCombo.mouseButton
	 or sortOrderCombo2.mouseButton
	)
	and (not mouseOverTileMenu) then
		return
	end
	if not getAlreadyVisibleMenu({idMenuInventory, idMenuContents, idMenuBarter}) then
		return
	end
	if getAlreadyVisibleMenu({idSortOptionsMenuName, idMenuMessage,
			idMenuMagicSelect, idMenuInventorySelect}) then
		return
	end
	---mwse_log('onKeyCombo() 5')
	setSortOrderMenuButtons()
	tes3ui.showMessageMenu({id = sortOptionsMenuName,
		message = 'Sort by item type and...',
		buttons = sortOrderMenuButtons, cancels = true,
		leaveMenuMode = false, -- thanks Hrnchamd
	})
end

---@param e mouseButtonUpEventData
local function mouseButtonUp(e)
	if e.button == 0 then
		return -- skip left mouse
	end
	onKeyCombo(e)
end

local currentlyOn = false
local function toggleEvents(on)
	if on == currentlyOn then
		return
	end
	currentlyOn = on
	local regOrUnreg
	if on then
		regOrUnreg = event.register
	else
		sortBy = 1
		regOrUnreg = event.unregister
	end
	regOrUnreg('itemTileUpdated', itemTileUpdated, {priority = 300000})
	regOrUnreg('mouseButtonUp', mouseButtonUp)
	regOrUnreg('keyDown', onKeyCombo)
	regOrUnreg('mouseWheel', onKeyCombo)

	regOrUnreg('activate', activate)
	regOrUnreg('equipped', equipped)
	regOrUnreg('unequipped', unequipped)
	regOrUnreg('convertReferenceToItem', convertReferenceToItem)

	---regOrUnreg('UIEX:InventoryTileClicked', UIEX_InventoryTileClicked, {priority = 10})

	-- can't use only equipped as consumables do not trigger it,
	-- low priority so it can still be blocked
	regOrUnreg('equip', equip, {priority = -300000})

	regOrUnreg('magicSelectionChanged', magicSelectionChanged)
	---regOrUnreg('barterOffer	', barterOffer)
	regOrUnreg('calcBarterPrice', calcBarterPrice)

end


local function beforeDestroyTileMenu(e)
	local menu = e.source
	if menuTitleElements[menu.id] then
		menuTitleElements[menu.id] = nil
	end
end

local function uiActivatedTileMenu(e)
	if not e.newlyCreated then
		return
	end
	local menu = e.element
	menu:registerBefore('mouseOver', beforeMouseOverTileMenu)
	menu:registerBefore('mouseLeave', beforeMouseLeaveTileMenu)
	menu:registerBefore('destroy', beforeDestroyTileMenu)
end

local loadedOnceDone = false

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	local ab01inso = getSavedDataTable()
	timestamp = ab01inso.timestamp or 0
	itemRecs = ab01inso.itemRecs
	if itemRecs then
		-- clean/pack the table in case some mod is no more loaded
		local t = {}
		local tes3_getObject = tes3.getObject
		for k, v in pairs(itemRecs) do
			---if v then
				if tes3_getObject(k) then
					t[k] = v
					itemRecs[k] = nil
				end
			---end
		end
		itemRecs = t
	else
		itemRecs = {}
	end
	sortBy = 1
	menuTitleElements = {}
	updateAllMenuTiles()
	checkPackResetItemNames()
	if loadedOnceDone then
		return
	end
	loadedOnceDone = true
	toggleEvents(config.modEnabled)
end

local function clearItemrecs()
	for k, _ in pairs(itemRecs) do
		---if v then
			itemRecs[k] = nil
		---end
	end
	itemRecs = {}
end

local function modConfigReady()

	-- better to register uiActivated ASAP for e.newlyCreated to work
	for _, menuName in ipairs(menuTileNames) do
		event.register('uiActivated', uiActivatedTileMenu, {filter = menuName})
	end

	local function onClose()
		if not (config.modEnabled == modEnabled) then
			toggleEvents(config.modEnabled)
		end
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = true})
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config,
		defaultConfig = defaultConfig,
		showDefaultSetting = true,
		onClose = onClose
	})

	local sideBarPage = template:createSideBarPage({
		---label = mcmName,
		---showHeader = true,
		description = [[Use the defined Sorting Order Key/Right Mouse Click Combos to select Inventory/Contents/Barter items secondary sorting order.
Default is set to use right click to access sorting menu (works well assigning e.g. the TAB key to open menus).
Notes:
As far as I know there is no MWSE-Lua way yet to hook into/change original Morrowind inventory tiles sorting function
(e.g. vanilla sorts item tiles by equipped/traded, then item category and finally by name).
As a workaround this mod provides some secondary sorting by quickly changing/restoring the item names under the hood.
Last activated/equipped item timestamps (used to sort by Time Activated/Time Equipped) are stored in game saves.
Temporary item name changes are not stored.
Sorting by Score is currently calculated as some mix/average of available item properties
(e.g. value, weight, damage, reach, speed, armor rating, enchant capacity...).
The mod should be compatible/working better/empowered by UI Expansion Search Bar/Filters.
Compatibility with other complex UI tweaking mods or mods renaming items from MWSE-Lua is not tested/officially supported, although in theory many should work as item name changes by this mod are done on the fly and usually reset right after the sorting happens.]],
		showReset = true,
		postCreate = function(self)
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	})

	local category = sideBarPage:createCategory({})

	local optionList = {'Off','Low','Medium','High','Higher','Huge','Max'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ("%s. %s"):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	category:createKeyBinder({
		label = 'Sorting Order Combo',
		description = [[Mouse/Hotkey combination to select sorting order.
Left mouse button not allowed.]],
		allowMouse = true,
		configKey = 'sortOrderCombo'
	})

	category:createKeyBinder({
		label = "Sorting Order Combo (no quantity)",
		description = [[Mouse/Hotkey combination to select sorting order without taking item quantity into account.
Left mouse button not allowed.]],
		allowMouse = true,
		configKey = 'sortOrderCombo2'
	})

	category:createDropdown({
		label = 'Logging level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	category:createYesNoButton({
		label = 'Show sorting order',
		description = [[Show selected sorting order on window header.]],
		configKey = 'showSortBy'
	})

	category:createYesNoButton({
		label = 'Ctrl Click toggle equip',
		description = [[Press Ctrl + Click to toggle equipping/unequipping a single inventory item (e.g. cuirass),
Press Ctrl + Shift + Click to toggle equipping multiple items (e.g. ammunitions).
Ctrl + Click should still take a single item from a multiple items stack as usual.]],
		configKey = 'ctrlClickEquip'
	})

	local function onButton(e)
		if e.button == 0 then -- Yes pressed
			clearItemrecs()
			updateFromConfig()
		end
	end

	category:createButton({
		---label = 'Reset',
		description = [[Reset last activated/equipped item timestamps data.]],
		buttonText = 'Reset timestamps',
		label = [[
Pros: it will probably reduce save file size a little.
Cons: stored data about last activated/equipped items will be lost, resetting related sorting by Time Activated/Time Equipped.]],
		callback = function ()
			tes3.messageBox({
				message = 'Do you really want to reset last activated/equipped item timestamps data?',
				buttons = {'Yes', 'No'},
				callback = onButton
			})
		end
	})
	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	inputController = tes3.worldController.inputController
	MCPSoulgemValueRebalance = tes3.hasCodePatchFeature(
		tes3.codePatchFeature.soulgemValueRebalance)
	ab01goldWeight = tes3.findGlobal('ab01goldWeight')
	if ab01goldWeight then
		goldWeight = ab01goldWeight.value
	end
	event.register('save', save, {priority = -300000})
	event.register('loaded', loaded)
	local s = 'MWSE\\mods\\'..modPrefix..'\\common.lua'
	if tes3.getFileExists(s) then
		os.remove('Data Files\\'..s) -- try and delete legacy file
	end
end, {doOnce = true})
