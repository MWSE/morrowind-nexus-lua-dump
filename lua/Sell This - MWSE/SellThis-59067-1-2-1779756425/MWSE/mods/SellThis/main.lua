-- A small MWSE mod to mark items that are wished to be sold. Also adds a "Sell Junk" button to merchants.
-- Changelog: 
	-- Fixed a bug where the inventory screen wasn't refreshed on marking/unmarking an item. 
	-- Refactored some code so it uses only one icon file for tooltips and tiles. Also has a fixed location on the tile, this plays nicer with SellThis mod. 
	-- Refactored some code to use a reusable showMessage() function. Also allow for this to be enabled/disabled in MCM.
	-- Removed some dead functions and locals.


local mod = require("SellThis.config")
local config = mod.config

require("SellThis.mcm")

local logPrefix = "[Sell This]"

-- Stored per save.
local dataKey = "SellThis_markedItems"

-- Last item tooltip object.
local hoveredObject = nil
local hoveredItemData = nil
local hoveredTooltip = nil

-- Frame tracking prevents stale hover data.
local hoverFrame = 0
local currentFrame = 0

-- Visible inventory/container/barter item tiles.
local visibleTilesByKey = {}

local sellJunkButtonId = tes3ui.registerID("SellThis_SellJunkButton")

local function log(message)
	if config.debugLog then
		mwse.log("%s %s", logPrefix, message)
	end
end

local function showMessage(message, ...)
	if not config.showMessages then
		return
	end

	tes3.messageBox(message, ...)
end

local function getItemDataDebugText(itemData)
	if not itemData then
		return "itemData=nil"
	end

	local parts = {}

	if itemData.soul then
		table.insert(parts, "soul=" .. tostring(itemData.soul.id or itemData.soul))
	end

	if itemData.charge ~= nil then
		table.insert(parts, "charge=" .. tostring(itemData.charge))
	end

	if itemData.condition ~= nil then
		table.insert(parts, "condition=" .. tostring(itemData.condition))
	end

	if itemData.owner then
		table.insert(parts, "owner=" .. tostring(itemData.owner.id or itemData.owner))
	end

	if #parts == 0 then
		return "itemData=yes/no special fields"
	end

	return table.concat(parts, " | ")
end

local function getMarkKeyCode()
	if type(config.markKeyCombo) ~= "table" then
		config.markKeyCombo = {
			keyCode = tes3.scanCode.F4,
		}
	end

	if config.markKeyCombo.keyCode == nil then
		config.markKeyCombo.keyCode = tes3.scanCode.F4
	end

	return config.markKeyCombo.keyCode
end

local function getMarkedItems()
	if not tes3.player then
		return nil
	end

	tes3.player.data[dataKey] = tes3.player.data[dataKey] or {}

	return tes3.player.data[dataKey]
end

local function getObjectName(object)
	if not object then
		return "Unknown item"
	end

	return object.name or object.id or "Unknown item"
end

local function getItemDataKeyPart(itemData)
	if not itemData then
		return nil
	end

	local parts = {}

	-- Soul gems and any other itemData-backed item with a soul.
	if itemData.soul and itemData.soul.id then
		table.insert(parts, "soul:" .. string.lower(tostring(itemData.soul.id)))
	end

	-- Charge is useful for enchanted/charged/soul data when present.
	if itemData.charge ~= nil then
		table.insert(parts, "charge:" .. string.format("%.6f", tonumber(itemData.charge) or 0))
	end

	-- Condition may help distinguish damaged equipment. Keep 0 too, because
	-- soul gems report condition=0 and it is part of their itemData.
	if itemData.condition ~= nil then
		table.insert(parts, "condition:" .. tostring(itemData.condition))
	end

	-- Owner is included only when present.
	if itemData.owner then
		local ownerId = itemData.owner.id or tostring(itemData.owner)
		table.insert(parts, "owner:" .. string.lower(tostring(ownerId)))
	end

	if #parts == 0 then
		return nil
	end

	return table.concat(parts, "|")
end

local function getObjectKey(object, itemData)
	if not object or not object.id then
		return nil
	end

	local baseId = string.lower(object.id)
	local itemDataPart = getItemDataKeyPart(itemData)

	if itemDataPart then
		return baseId .. "|" .. itemDataPart
	end

	return baseId
end

local function getBaseObjectKey(object)
	return getObjectKey(object, nil)
end

local function isMarkableItem(object)
	if not object then
		return false
	end

	local allowedTypes = {
		[tes3.objectType.alchemy] = true,
		[tes3.objectType.ammunition] = true,
		[tes3.objectType.apparatus] = true,
		[tes3.objectType.armor] = true,
		[tes3.objectType.book] = true,
		[tes3.objectType.clothing] = true,
		[tes3.objectType.ingredient] = true,
		[tes3.objectType.light] = true,
		[tes3.objectType.lockpick] = true,
		[tes3.objectType.miscItem] = true,
		[tes3.objectType.probe] = true,
		[tes3.objectType.repairItem] = true,
		[tes3.objectType.weapon] = true,
	}

	return allowedTypes[object.objectType] == true
end

local function isMarked(object, itemData)
	local markedItems = getMarkedItems()
	local key = getObjectKey(object, itemData)

	if not markedItems or not key then
		return false
	end

	if markedItems[key] == true then
		return true
	end

	-- Legacy fallback: if an older version marked the base item ID, still
	-- treat itemData versions as marked until the player unmarks them.
	local baseKey = getBaseObjectKey(object)
	if baseKey and baseKey ~= key and markedItems[baseKey] == true then
		return true
	end

	return false
end

local function setMarked(object, marked, itemData)
	local markedItems = getMarkedItems()
	local key = getObjectKey(object, itemData)
	local baseKey = getBaseObjectKey(object)

	if not markedItems or not key then
		return
	end

	if marked then
		markedItems[key] = true
	else
		markedItems[key] = nil

		-- Clear old base-ID marks too, otherwise legacy soul gem/base marks
		-- would keep all matching itemData copies marked.
		if baseKey and baseKey ~= key then
			markedItems[baseKey] = nil
		end
	end
end

local function tooltipAlreadyHasSellThisInfo(tooltip)
	if not tooltip then
		return false
	end

	return tooltip:findChild("SellThis_Label") ~= nil
end

local function addSellThisTooltip(e)
	if not e.tooltip then
		return
	end

	if tooltipAlreadyHasSellThisInfo(e.tooltip) then
		return
	end

	if not isMarked(e.object, e.itemData) then
		return
	end

	e.tooltip:createImage({
		id = "SellThis_Icon",
		path = "Textures\\SellThis\\sellthis_coin.tga",
		width = 16,
		height = 16,
	})

	e.tooltip:createLabel({
		id = "SellThis_Label",
		text = "Sell This",
		color = tes3ui.getPalette("header_color"),
	})

	e.tooltip:updateLayout()
end

local function refreshCurrentTooltip()
	if not hoveredTooltip or not hoveredObject then
		return
	end

	local existingIcon = hoveredTooltip:findChild("SellThis_Icon")
	if existingIcon then
		existingIcon:destroy()
	end

	local existingLabel = hoveredTooltip:findChild("SellThis_Label")
	if existingLabel then
		existingLabel:destroy()
	end

	if isMarked(hoveredObject, hoveredItemData) then
		hoveredTooltip:createImage({
			id = "SellThis_Icon",
			path = "Textures\\SellThis\\sellthis_coin.tga",
			width = 16,
			height = 16,
		})

		hoveredTooltip:createLabel({
			id = "SellThis_Label",
			text = "Sell This",
			color = tes3ui.getPalette("header_color"),
		})
	end

	hoveredTooltip:updateLayout()
end

local function findChildByName(element, name)
	if not element or not element.children then
		return nil
	end

	for _, child in pairs(element.children) do
		if child.name == name then
			return child
		end
	end

	return nil
end

local function getTileIconElement(tileElement)
	if not tileElement then
		return nil
	end

	return findChildByName(tileElement, "itemTile_icon")
end

local function removeSellThisTileIcon(tileElement)
	local iconElement = getTileIconElement(tileElement)
	if not iconElement then
		return
	end

	local existing = iconElement:findChild("SellThis_TileIcon")
	if existing then
		existing:destroy()
		iconElement:updateLayout()
	end
end

local function addSellThisTileIcon(tileElement)
	local iconElement = getTileIconElement(tileElement)
	if not iconElement then
		log("No itemTile_icon found for marked tile.")
		return
	end

	local existing = iconElement:findChild("SellThis_TileIcon")
	if existing then
		existing:destroy()
	end

	local marker = iconElement:createImage({
		id = "SellThis_TileIcon",
		path = "Textures\\SellThis\\sellthis_coin.tga",
	})

	marker.width = 16
	marker.height = 16
	marker.scaleMode = true
	marker.absolutePosAlignX = 1.0
	marker.absolutePosAlignY = 1.0
	marker.consumeMouseEvents = false

	iconElement:updateLayout()
end



local function onItemTileUpdated(e)
	if not config.enabled then
		return
	end

	if not e.element or not e.item then
		return
	end

	local key = getObjectKey(e.item, e.itemData)

	if key then
		visibleTilesByKey[key] = visibleTilesByKey[key] or {}
		table.insert(visibleTilesByKey[key], e.element)
	end

	removeSellThisTileIcon(e.element)

	if not isMarked(e.item, e.itemData) then
		return
	end

	addSellThisTileIcon(e.element)

	log(string.format("Added tile icon: %s", getObjectName(e.item)))
end

local function refreshKnownTilesForObject(object, itemData)
	local key = getObjectKey(object, itemData)
	if not key then
		return
	end

	local tiles = visibleTilesByKey[key]
	if not tiles then
		return
	end

	for i = #tiles, 1, -1 do
		local tile = tiles[i]

		local success = pcall(function()
			removeSellThisTileIcon(tile)

			if isMarked(object, itemData) then
				addSellThisTileIcon(tile)
			end
		end)

		if not success then
			table.remove(tiles, i)
		end
	end
end

local function refreshInventoryWindows()
	local menuNames = {
		"MenuInventory",
		"MenuContents",
		"MenuBarter",
	}

	for _, menuName in ipairs(menuNames) do
		local menu = tes3ui.findMenu(menuName)

		if menu then
			menu:updateLayout()
		end
	end
end

local function refreshTilesForObject(object, itemData)
	refreshKnownTilesForObject(object, itemData)
	refreshInventoryWindows()

	timer.delayOneFrame(function()
		if tes3ui.updateInventoryTiles then
			tes3ui.updateInventoryTiles()
		end

		refreshKnownTilesForObject(object, itemData)
		refreshInventoryWindows()
	end)
end

local function onObjectTooltip(e)
	if not config.enabled then
		return
	end

	if not isMarkableItem(e.object) then
		hoveredObject = nil
		hoveredItemData = nil
		hoveredTooltip = nil
		return
	end

	hoveredObject = e.object
	hoveredItemData = e.itemData
	hoveredTooltip = e.tooltip
	hoverFrame = currentFrame

	addSellThisTooltip(e)
end

local function isPlayerInventoryTile(tile)
	local current = tile

	for i = 1, 12 do
		if not current then
			break
		end

		if current.name == "MenuInventory_scrollpane" then
			return true
		end

		if current.name == "MenuBarter_scrollpane" then
			return false
		end

		current = current.parent
	end

	return false
end

local function toggleHoveredItem()
	if not config.enabled then
		return
	end

	if not hoveredObject or hoverFrame < currentFrame - 1 then
		hoveredObject = nil
		hoveredItemData = nil
		hoveredTooltip = nil
		log("No current hovered item to toggle.")
		return
	end

	if not isMarkableItem(hoveredObject) then
		log("Hovered object is not markable.")
		return
	end

	local objectToToggle = hoveredObject
	local itemDataToToggle = hoveredItemData
	local currentlyMarked = isMarked(objectToToggle, itemDataToToggle)
	local newMarked = not currentlyMarked

	setMarked(objectToToggle, newMarked, itemDataToToggle)

	local itemName = getObjectName(objectToToggle)
	local key = getObjectKey(objectToToggle, itemDataToToggle)
	local matchingVisibleTiles = 0
	local matchingPlayerTiles = 0

	if key and visibleTilesByKey[key] then
		matchingVisibleTiles = #visibleTilesByKey[key]

		for _, tile in ipairs(visibleTilesByKey[key]) do
			local success, shouldCount = pcall(function()
				return tile
					and tile.triggerEvent ~= nil
					and isPlayerInventoryTile(tile)
			end)

			if success and shouldCount then
				matchingPlayerTiles = matchingPlayerTiles + 1
			end
		end
	end

	if newMarked then
		showMessage("Sell This\n%s\nMARKED.",itemName)
		log(string.format(
			"MARKED | name=%s | id=%s | key=%s | matchingVisibleTiles=%d | matchingPlayerTiles=%d | %s",
			itemName,
			tostring(objectToToggle.id),
			tostring(key),
			matchingVisibleTiles,
			matchingPlayerTiles,
			getItemDataDebugText(itemDataToToggle)
		))
	else
		showMessage("Sell This\n%s\nUNMARKED.",itemName)
		log(string.format(
			"UNMARKED | name=%s | id=%s | key=%s | matchingVisibleTiles=%d | matchingPlayerTiles=%d | %s",
			itemName,
			tostring(objectToToggle.id),
			tostring(key),
			matchingVisibleTiles,
			matchingPlayerTiles,
			getItemDataDebugText(itemDataToToggle)
		))
	end

	refreshCurrentTooltip()
	refreshTilesForObject(objectToToggle, itemDataToToggle)
end
local function getCurrentWorldTargetObject()
	local target = nil

	if tes3.getPlayerTarget then
		target = tes3.getPlayerTarget()
	end

	if not target then
		return nil
	end

	if target.baseObject then
		return target.baseObject
	end

	if target.object then
		return target.object
	end

	return nil
end

-- Sell Junk button and barter support.

local function getElementText(element)
	if not element then
		return nil
	end

	if element.text then
		return element.text
	end

	if element.widget and element.widget.text then
		return element.widget.text
	end

	return nil
end

local function findTextElementRecursive(element, searchText, depth)
	if not element or depth > 30 then
		return nil
	end

	local text = getElementText(element)

	if text and string.find(string.lower(text), string.lower(searchText), 1, true) then
		return element
	end

	if element.children then
		for _, child in pairs(element.children) do
			local found = findTextElementRecursive(child, searchText, depth + 1)
			if found then
				return found
			end
		end
	end

	return nil
end

local function safeFindChild(element, id)
	if not element then
		return nil
	end

	local success, result = pcall(function()
		return element:findChild(id)
	end)

	if success then
		return result
	end

	return nil
end

local function safeCreateButton(parent, id, text)
	if not parent then
		return nil
	end

	local success, result = pcall(function()
		return parent:createButton({
			id = id,
			text = text,
		})
	end)

	if success then
		return result
	end

	log("Failed to create Sell Junk button.")
	return nil
end

local function clickMarkedPlayerTiles()
	local clicked = 0

	local markedItems = getMarkedItems()
	if not markedItems then
		return 0
	end

	for key, marked in pairs(markedItems) do
		if marked then
			local tiles = visibleTilesByKey[key]

			if tiles then
				for i = #tiles, 1, -1 do
					local tile = tiles[i]

					local success, shouldClick = pcall(function()
						return tile
							and tile.triggerEvent ~= nil
							and isPlayerInventoryTile(tile)
					end)

					if success and shouldClick then
						local clickedSuccess = pcall(function()
							tile:triggerEvent("mouseClick")
						end)

						if clickedSuccess then
							clicked = clicked + 1
							log(string.format("Clicked player inventory marked tile: key=%s", tostring(key)))

							-- Stable behavior: one tile per key.
							break
						else
							table.remove(tiles, i)
						end
					elseif not success then
						table.remove(tiles, i)
					end
				end
			end
		end
	end

	if tes3ui.updateInventoryTiles then
		timer.delayOneFrame(function()
			tes3ui.updateInventoryTiles()
		end)
	end

	return clicked
end

local function addSellJunkButtonToBarter(menu)
	if not config.enabled then
		return
	end

	if not menu then
		return
	end

	if safeFindChild(menu, sellJunkButtonId) then
		return
	end

	local offerElement = findTextElementRecursive(menu, "Offer", 0)

	if not offerElement then
		log("Could not find Offer element in live MenuBarter.")
		return
	end

	log(string.format(
		"Found Offer element: name=%s | id=%s | type=%s | text=%s | parentName=%s | parentId=%s",
		tostring(offerElement.name),
		tostring(offerElement.id),
		tostring(offerElement.type),
		tostring(getElementText(offerElement)),
		tostring(offerElement.parent and offerElement.parent.name or nil),
		tostring(offerElement.parent and offerElement.parent.id or nil)
	))

	local parent = offerElement.parent or menu

	if safeFindChild(parent, sellJunkButtonId) then
		return
	end

	local button = safeCreateButton(parent, sellJunkButtonId, "Sell Junk")
	if not button then
		return
	end

button:register("mouseClick", function()
		local clicked = clickMarkedPlayerTiles()

		if clicked > 0 then
			showMessage("Sell This\nOffering %s items.",clicked)
			log(string.format("Sell Junk clicked. Added %s marked player tile(s).", clicked))
		else
			showMessage("Sell This\nNo items are marked for sell.")
			log("Sell Junk clicked. No visible marked items found.")
		end
	end)

	parent:updateLayout()
	menu:updateLayout()

	log("Added Sell Junk button.")
end

local function onUiActivated(e)
	if not config.enabled then
		return
	end

	local name = e.element and e.element.name

	log(string.format(
		"uiActivated: name=%s id=%s",
		tostring(name),
		tostring(e.element and e.element.id or nil)
	))

	if name ~= "MenuBarter" then
		return
	end

	log("MenuBarter activated. Trying immediate Sell Junk button.")
	addSellJunkButtonToBarter(e.element)
end

local function onKeyDown(e)
	if not config.enabled then
		return
	end

	if e.keyCode ~= getMarkKeyCode() then
		return
	end

	if tes3.menuMode() then
		toggleHoveredItem()
		return
	end

	local object = getCurrentWorldTargetObject()

	if not object or not isMarkableItem(object) then
		log("No current world item to toggle.")
		return
	end

	hoveredObject = object
	hoveredItemData = nil
	hoveredTooltip = nil
	hoverFrame = currentFrame

	toggleHoveredItem()
end

local function onMenuExit(e)
	hoveredObject = nil
	hoveredItemData = nil
	hoveredTooltip = nil
	hoverFrame = 0
	visibleTilesByKey = {}
end

local function onSimulate()
	currentFrame = currentFrame + 1
end

local function initialized()
	log("Initialized.")
end

event.register(tes3.event.initialized, initialized)

event.register(tes3.event.uiObjectTooltip, onObjectTooltip, {
	priority = -100,
})

event.register(tes3.event.keyDown, onKeyDown)
event.register(tes3.event.itemTileUpdated, onItemTileUpdated)
event.register(tes3.event.menuExit, onMenuExit)
event.register(tes3.event.simulate, onSimulate)
event.register(tes3.event.uiActivated, onUiActivated)