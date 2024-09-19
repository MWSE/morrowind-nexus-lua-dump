--[[
Inventory Sorter
Surprisingly complex until we get some hook to the game item tiles sorting function
or at least some hack to pass to the sorting function a desired string instead of the item name
]]

local common = require('abot.Inventory Sorter.common')

local modPrefix = common.modPrefix
local config = common.config or {}

local itemRecs = common.itemRecs -- e.g. itemRecs['bk_affairsofwizards'] = {a = timestamp, e = timestamp}}

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
end
common.updateFromConfig = updateFromConfig
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

local function notify(str, ...)
	tes3.messageBox({message = tostring(str):format(...), showInDialog = false})
end

-- set in loaded()
local player, mobilePlayer

-- used to allow sort options menu only when mouse clicks are
-- inside proper windows if sort options key combo uses mouse
local mouseOverTileMenu = false

local function beforeMouseOverTileMenu(e)
	if logLevel6 then
		mwse.log('%s: beforeMouseOverTileMenu("%s")', modPrefix, e.source.name)
	end
	mouseOverTileMenu = true
end

local function beforeMouseLeaveTileMenu(e)
	if logLevel6 then
		mwse.log('%s: beforeMouseLeaveTileMenu("%s")', modPrefix, e.source.name)
	end
	mouseOverTileMenu = false
end

local idMenuBarter = tes3ui.registerID('MenuBarter')
local idMenuContents = tes3ui.registerID('MenuContents')
local idMenuInventory = tes3ui.registerID('MenuInventory')
local idMenuInventorySelect = tes3ui.registerID('MenuInventorySelect')
local idMenuMagicSelect = tes3ui.registerID('MenuMagicSelect')
local idMenuMessage = tes3ui.registerID('MenuMessage')

local digits = 14
local maxValue = 10^digits
local numFormat = string.format('%%0%s.03f', digits + 5) -- e.g. "0000000000001500.000"
local numPattern = "^%d+%.%d%d%d$"

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
		mwse.log('%s: setItemName("%s", "%s")',	modPrefix, item.id, name)
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

local function getDamageReachSpeed(w)
	if w.isProjectile
	or w.isAmmo then
		return (w.chopMin + w.chopMax) * 0.5 * w.speed
	end
	return (w.chopMin + w.chopMax + w.slashMin + w.slashMax + w.thrustMin + w.thrustMax) * 0.5 * w.speed * w.reach
end

local minDivider = 0.0001

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
local ab01goldWeight

-- updated when changing sortBy
local goldWeight = 0

local function getObjWeight(obj)
	if ab01goldWeight then
		if string.lower(obj.id) == 'gold_001' then
			return goldWeight
		end
	end
	return obj.weight
end

local function getValueWeightRatio(obj)
	return getFrac(obj.value, getObjWeight(obj))
end

local function getWeightValueRatio(obj)
	return getFrac(getObjWeight(obj), obj.value)
end

local MCPSoulgemValueRebalance -- set in modConfigReady()

local function getSoulGemValue(item, itemData)
	if not item.isSoulGem then
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
	return item.value * soulValue
end

local inTools = {
[T3OT_lockpick] = true,
[T3OT_probe]= true,
[T3OT_repairItem] = true
}

local function getItemStat(item, itemData)
	local objType = item.objectType
	local v = math.remap(getValueWeightRatio(item), 0, 10000, 1, 1000)

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
			v = math.remap(v, 0, 10000, 1, 1000)
		end
	end
	return v
end

local function fnum(v)
	return string.format(numFormat, v)
end

local itemNames = {}
local skipTileSort = true

local idCursorIcon = tes3ui.registerID('CursorIcon')

local function getCursorIcon()
	return tes3ui.findHelpLayerMenu(idCursorIcon)
end

local function resetItemNames()
	skipTileSort = true
	for item, name in pairs(itemNames) do
		if name then
			if string.find(name, numPattern) then
				if item.modified then
					item.modified = false
				end
			else
				setItemName(item, name)
			end
		end
	end
end

local function getFileName(s)
	return string.match(s, '([^\\/]+)%.%w+$')
end

local function getNameFromPath(path)
	local s = getFileName(path)
	s = string.gsub(s, '^%w+_', '') -- strip starting prefix
	s = string.gsub(s, '_', ' ') -- replace remaining underscores with spaces
	return string.gsub(s, '^%l', string.upper) -- upcase first character
end

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
				if not string.find(name, numPattern) then
					t[item] = name
				elseif not string.find(item_name, numPattern) then
					t[item] = item_name
				else -- safety enforcer
					local s = getNameFromFile(item)
					if s then
						mwse.log('%s: WARNING id = "%s", name = "%s", itemNames["%s"] = "%s" --> "%s"',
							modPrefix, item.id, item_name, item.id, name, s)
						t[item] = s
					end
				end
				item.modified = false
				if not t[item] then
					mwse.log('%s: checkPackResetItemNames() id = "%s", name = "%s", itemNames["%s"] = "%s")',
						modPrefix, item.id, item_name, item.id, name)
					assert(false)
				end
			end
			itemNames[item] = nil
		end
	end
	itemNames = t
end

-- with low priority so it can still be skipped
local function save()
	checkPackResetItemNames()
end

local idPartDragMenu_thick_border = tes3ui.registerID('PartDragMenu_thick_border')
local idPartDragMenu_center_frame = tes3ui.registerID('PartDragMenu_center_frame')
local idPartDragMenu_drag_frame = tes3ui.registerID('PartDragMenu_drag_frame')
local idPartDragMenu_title_tint = tes3ui.registerID('PartDragMenu_title_tint')
local idPartDragMenu_title = tes3ui.registerID('PartDragMenu_title')

local function getElementPath(elem, ancestor)
	local el = elem
	local t = { el }
	if not ancestor then
		ancestor = el:getTopLevelMenu()
	end
	if not ancestor then
		return t
	end
	local k = 0
	while not (el == ancestor) do
		el = el.parent
		if el.name
		and ( string.len(el.name) > 0 ) then
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

local function getElementPathStr(elem, ancestor)
	local el = elem
	local t = getElementPath(el, ancestor)
	local s = ''
	local last = #t
	for i = 1, last do
		el = t[i]
		s = s .. el.id .. ' ("' .. el.name .. '")'
		if not (i == last) then
			s = s .. ', '
		end
	end
	return s
end

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
local menuTitleElements = {}

local function getMenuTitle(menu)
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
			mwse.log('%s: getMenuTitle("%s") path: %s',
				modPrefix, menu.name, getElementPathStr(el, menu))
		end
	end
	return el
end

local function updateMenuTitle(menuId, item)
	local menu = tes3ui.findMenu(menuId)
	if not menu then
		return
	end
	local el = getMenuTitle(menu)
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
	and (string.len(s) > 0) then
		local byPrefix = ' (by '
		local by = byPrefix .. sortByOptions[sortBy].n .. ')'
		if mulQuantity then
			by = string.gsub(by, ',', '%*,')
		end
		if showSortBy then
			if string.find(s, byPrefix, 1, true) then
				s = string.gsub(s, ' (%(by [^%)]+%))', by)
			else
				s = s .. by
			end
		end
	end
	if el.text == s then
		return
	end
	if logLevel1 then
		mwse.log('%s: %s title reset from "%s" to "%s"',
			modPrefix, menu.name, el.text, s)
	end
	el.text = s -- update Menu title
end

local function updateInventoryMenuTitle()
	updateMenuTitle(idMenuInventory)
end

local function updateAllMenuTiles()
	--[[local etime
	if logLevel3 then
		etime = os.clock()
	end]]
	if getCursorIcon() then
		return
	end
	skipTileSort = false
	local menu = tes3ui.findMenu(idMenuBarter)
	if menu
	and menu.visible then
		tes3ui.updateBarterMenuTiles()
	end
	menu = tes3ui.findMenu(idMenuContents)
	if menu
	and menu.visible then
		tes3ui.updateContentsMenuTiles()
	end
	menu = tes3ui.findMenu(idMenuInventory)
	if menu
	and menu.visible then
		tes3ui.updateInventoryTiles()
	end
	resetItemNames()
	updateInventoryMenuTitle()

	--[[if logLevel3 then
		mwse.log('%s: updateAllMenuTiles() elapsed time: %.5f', modPrefix, os.clock() - etime)
	end]]

end

local function updateItemTimestamps(item, params)
	local lcItemId = string.lower(item.id)
	local itemRec = itemRecs[lcItemId]
	local timestamp = common.incTimestamp()
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

local function sortItem(item, count, itemData)
	local funcPrefix
	if logLevel1 then
		funcPrefix = modPrefix .. ' sortItem()'
	end
	local itemId = item.id
	local lcItemId = string.lower(itemId)
	local itemRec = itemRecs[lcItemId]
	local objType = item.objectType

	local v -- value that will replace the item name as itemNewName = string.format(numFormat, v) for sorting
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
			v = getObjWeight(item)
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
			v = math.remap(getValueWeightRatio(item), 0, 1000000, 1, 100000)
		elseif sortBy == 3 then
			v = math.remap(getWeightValueRatio(item), 0, 1000, 1, 1000000)
		end
	end

	local itemRealName = item.name
	local itemNewName = itemRealName
	if sortBy > 1 then
		if v then
			if sortBy > 3 then
				if qt
				and mulQuantity then
					v = v * math.abs(count)
				end
				if sortBy % 2 > 0 then -- odd means descending order
					v = maxValue - v
				end
			end
			itemNewName = fnum(v)
		end
	end
	if itemNewName == itemRealName then
		return
	end

	if logLevel5 then
		mwse.log('%s: sortItem("%s") itemNewName = "%s", itemRealName = "%s"',
			modPrefix, itemId, itemNewName, itemRealName)
	end

	if not string.find(itemRealName, numPattern) then
		itemNames[item] = itemRealName
	end
	setItemName(item, itemNewName)
end

local ab01insoTCid = tes3ui.registerProperty('ab01insoTC')
local idMenuInventory_Thing = tes3ui.registerProperty('MenuInventory_Thing')
---local idMenuBarter_Thing = tes3ui.registerProperty('MenuBarter_Thing')
---local idMenuInventory_Object = tes3ui.registerProperty('MenuInventory_Object')

local inputController -- set in modConfigReady

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
		if tile.isEquipped then
			mobilePlayer:unequip({item = itm})
		else
			mobilePlayer:equip({item = itm})
		end
		return true
	end
end

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
			---mwse.log("%s:registerBefore('mouseClick', beforeMouseClickInventoryTileElement)", item.id)
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
		---el:registerAfter('mouseClick', delayedUpdateAllMenuTiles)
	---elseif (menuId == idMenuBarter)
			---and ( not el:getPropertyBool(ab01insoTCid) ) then
		---el:setPropertyBool(ab01insoTCid, true)
		---el:registerAfter('mouseClick', delayedUpdateAllMenuTiles)
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
	local stack = mobilePlayer.currentEnchantedItem
	if stack
	and (stack.object == item) then
		if logLevel2 then
			mwse.log('%s: itemTileUpdated() currentEnchantedItem = "%s" ("%s")',
				modPrefix, item.id, item.name)
		end
		return
	end
	if getCursorIcon() then
		return
	end
	sortItem(item, tile.count, e.itemData)
end

local function activate(e)
	if not (e.activator == player) then
		return
	end
	local item = e.target.object
	if not item.value then
		return
	end
	updateItemTimestamps(item, {activate = true})
end

local function equip(e)
	if not (e.reference == player) then
		return
	end
	local item = e.item
	updateItemTimestamps(item, {equip = true})
end

local function equipped(e)
	if not (e.reference == player) then
		return
	end
	local item = e.item
	updateItemTimestamps(item, {equip = true})
	updateAllMenuTiles()
end

local function unequipped(e)
	if not (e.reference == player) then
		return
	end
	if not e.item then
		return
	end
	updateAllMenuTiles()
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
local idSortOptionsMenuName = tes3ui.registerID(sortOptionsMenuName)

local sortOrderMenuButtons = {}

local function setSortOrderMenuButtons()
	local prefix = {[false] = '  ', [true] = '> '}
	local suffix = {[false] = '  ', [true] = ' <'}
	if logLevel2 then
		local s2 = 'sortBy = ' .. sortBy .. ' (' .. sortByOptions[sortBy].n .. ')'
		if logLevel3 then
			mwse.log('%s: setSortOrderMenuButtons() %s', modPrefix, s2)
		end
	end
	for i = 1, #sortByOptions do
		local o = sortByOptions[i]
		local value = o.v
		local isCurrent = (sortBy == value)
		local s = prefix[isCurrent] .. o.n .. suffix[isCurrent]
		if logLevel5 then
			mwse.log('"%s" = %s', s, value)
		end
		sortOrderMenuButtons[i] = {
			text = s,
			callback = function ()
				sortBy = value
				if ab01goldWeight then
					goldWeight = ab01goldWeight.value
				end
				if logLevel3 then
					local s = 'sortBy = ' .. sortBy .. ' (by ' .. sortByOptions[sortBy].n .. ')'
					notify(s)
				end
				updateAllMenuTiles()
			end
		}
	end
end

local function getAlreadyVisibleMenu(menus)
	for i = 1, #menus do
		local menu = tes3ui.findMenu(menus[i])
		if menu
		and menu.visible then
			return menu
		end
	end
end

local idCancelButton = tes3ui.registerID('MenuMessage_CancelButton')

local function onKeyCombo(e)
	if not tes3ui.menuMode() then
		return
	end
	if tes3.isKeyEqual({expected = sortOrderCombo, actual = e}) then
		mulQuantity = true
	elseif tes3.isKeyEqual({expected = sortOrderCombo2, actual = e}) then
		mulQuantity = false
	else
		return
	end
	local menu = tes3ui.findMenu(idSortOptionsMenuName)
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
	---mwse.log('onKeyCombo() 5')
	setSortOrderMenuButtons()
	tes3ui.showMessageMenu({id = sortOptionsMenuName,
		message = 'Sort by item type and...',
		buttons = sortOrderMenuButtons, cancels = true,
		leaveMenuMode = false, -- thanks Hrnchamd
		--[[customBlock = function(parent)
			parent.childAlignX = 0.5
			parent.paddingAllSides = 8
			local btn = parent:createCycleButton({
				id = 'ab01insoCycleBtn',
				options = {
					{text = 'Hide: Off', value = 1},
					{text = 'Hide: WAKB', value = 2},
					{text = 'Hide: ACES', value = 3},
				},
				index = hideFilter,
			})
			---btn.value = hideFilter
			btn:registerAfter('click', function() hideFilter = btn.value end)
		end,]]
	})
end

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

--[[
local scrollPaneElements = {}

local function getScrollPaneElement(menu)
	local menuId = menu.id
	local el = scrollPaneElements[menuId]
	if el then
		return el
	end
	local menuName = menu.name
	el = getChildFromPath(menu, {menuName..'_scrollpane', idPartScrollPane_pane})
	if el then
		scrollPaneElements[menuId] = el
		if logLevel5 then
			mwse.log('%s: getScrollPaneElement("%s") path: %s',
				modPrefix, menuName, getElementPathStr(el, menu))
		end
	end
	return el
end

local function beforeMouseClickScrollPaneElement(e)
	local el = e.source
	tes3.messageBox('%s click relativeX = %s, relativeY = %s', el.name, e.relativeX, e.relativeY)
end
]]

local function uiActivatedTileMenu(e)
	if not e.newlyCreated then
		return
	end
	local menu = e.element
	menu:registerBefore('mouseOver', beforeMouseOverTileMenu)
	menu:registerBefore('mouseLeave', beforeMouseLeaveTileMenu)
	menu:registerBefore('destroy', beforeDestroyTileMenu)
	--[[local scrollPane = getScrollPaneElement(menu)
	scrollPane:registerBefore('mouseClick', beforeMouseClickScrollPaneElement)]]
end

local function mcmOnClose()
	if not (config.modEnabled == modEnabled) then
		toggleEvents(config.modEnabled)
	end
	updateFromConfig()
	common.saveConfig()
end
common.mcmOnClose = mcmOnClose


local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	toggleEvents(config.modEnabled)
end

local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	sortBy = 1
	menuTitleElements = {}
	updateAllMenuTiles()
	initOnce()
	checkPackResetItemNames()
end

local function modConfigReady()
	-- better to register uiActivated ASAP for e.newlyCreated to work
	for _, menuName in ipairs(menuTileNames) do
		event.register('uiActivated', uiActivatedTileMenu, {filter = menuName})
	end
	common.modConfigReady()
end
event.register('modConfigReady', modConfigReady)


event.register('initialized',
function ()
	inputController = tes3.worldController.inputController
	MCPSoulgemValueRebalance = tes3.hasCodePatchFeature(tes3.codePatchFeature.soulgemValueRebalance)
	ab01goldWeight = tes3.findGlobal('ab01goldWeight')
	if ab01goldWeight then
		goldWeight = ab01goldWeight.value
	end
	event.register('save', save, {priority = -300000})
	event.register('loaded', loaded)

end, {doOnce = true}
)
