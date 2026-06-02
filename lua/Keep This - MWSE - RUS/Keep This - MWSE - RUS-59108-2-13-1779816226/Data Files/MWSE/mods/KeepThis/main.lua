-- A small MWSE mod to mark items that are wish to be kept. Will prevent the player from dropping them or selling them. 
-- Changelog: 
	-- Fixed a bug where the inventory screen wasn't refreshed on marking/unmarking an item. 
	-- Refactored some code so it uses only one icon file for tooltips and tiles. Also has a fixed location on the tile, this plays nicer with KeepThis mod. 
	-- Refactored some code to use a reusable showMessage() function. Also allow for this to be enabled/disabled in MCM.

local mod = require("KeepThis.config")
local config = mod.config

require("KeepThis.mcm")

local logPrefix = "[Keep This]"

-- Stored per save.
local dataKey = "KeepThis_markedItems"

-- Last item hovered in an item tooltip.
local hoveredObject = nil
local hoveredItemData = nil

local visibleItemTiles = setmetatable({}, { __mode = "k" })

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

local function getMarkKeyCode()
	if type(config.markKeyCombo) ~= "table" then
		config.markKeyCombo = {
			keyCode = tes3.scanCode.F3,
		}
	end

	if config.markKeyCombo.keyCode == nil then
		config.markKeyCombo.keyCode = tes3.scanCode.F3
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

	if itemData.soul and itemData.soul.id then
		table.insert(parts, "soul:" .. string.lower(tostring(itemData.soul.id)))
	end

	if itemData.charge ~= nil then
		table.insert(parts, "charge:" .. string.format("%.6f", tonumber(itemData.charge) or 0))
	end

	if itemData.condition ~= nil then
		table.insert(parts, "condition:" .. tostring(itemData.condition))
	end

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

	-- Legacy fallback for older Keep This saves that marked by base ID only.
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

		if baseKey and baseKey ~= key then
			markedItems[baseKey] = nil
		end
	end
end

local function tooltipAlreadyHasKeepThisInfo(tooltip)
	if not tooltip then
		return false
	end

	return tooltip:findChild("KeepThis_Label") ~= nil
end

local function addKeepThisTooltip(e)
	if not e.tooltip then
		return
	end

	if tooltipAlreadyHasKeepThisInfo(e.tooltip) then
		return
	end

	if not isMarked(e.object, e.itemData) then
		return
	end

	e.tooltip:createImage({
		id = "KeepThis_Icon",
		path = "Textures\\KeepThis\\keepthis_star.tga",
		width = 16,
		height = 16,
	})

	e.tooltip:createLabel({
		id = "KeepThis_Label",
		text = "Предмет помечен",
		color = tes3ui.getPalette("header_color"),
	})

	e.tooltip:updateLayout()
end

local function findChildByName(element, name)
	if not element then
		return nil
	end

	local children = nil

	pcall(function()
		children = element.children
	end)

	if not children then
		return nil
	end

	for _, child in pairs(children) do
		if child then
			local childName = nil

			pcall(function()
				childName = child.name
			end)

			if childName == name then
				return child
			end
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

local function removeKeepThisTileIcon(tileElement)
	local iconElement = getTileIconElement(tileElement)
	if not iconElement then
		return
	end

	local existing = iconElement:findChild("KeepThis_TileIcon")
	if existing then
		existing:destroy()
		iconElement:updateLayout()
	end
end

local function addKeepThisTileIcon(tileElement)
	local iconElement = getTileIconElement(tileElement)
	if not iconElement then
		log("No itemTile_icon found for marked tile.")
		return
	end

	local existing = iconElement:findChild("KeepThis_TileIcon")
	if existing then
		existing:destroy()
	end

	local marker = iconElement:createImage({
		id = "KeepThis_TileIcon",
		path = "Textures\\KeepThis\\keepthis_star.tga",
	})

	marker.width = 16
	marker.height = 16
	marker.scaleMode = true
	marker.absolutePosAlignX = 0.0
	marker.absolutePosAlignY = 0.0
	marker.consumeMouseEvents = false

	iconElement:updateLayout()
end

local function refreshVisibleTilesForItem(object, itemData)
	local targetKey = getObjectKey(object, itemData)

	if not targetKey then
		return
	end

	for tileElement, tileInfo in pairs(visibleItemTiles) do
		if tileInfo and tileInfo.object then
			local tileKey = getObjectKey(tileInfo.object, tileInfo.itemData)

			if tileKey == targetKey then
				removeKeepThisTileIcon(tileElement)

				if isMarked(tileInfo.object, tileInfo.itemData) then
					addKeepThisTileIcon(tileElement)
				end
			end
		end
	end
end

local function onItemTileUpdated(e)
	if not config.enabled then
		return
	end

	if not e.element or not e.item then
		return
	end

	visibleItemTiles[e.element] = {
		object = e.item,
		itemData = e.itemData,
	}

	removeKeepThisTileIcon(e.element)

	if not isMarked(e.item, e.itemData) then
		return
	end

	addKeepThisTileIcon(e.element)

	log(string.format("Added tile icon: %s", getObjectName(e.item)))
end

local function onObjectTooltip(e)
	if not config.enabled then
		return
	end

	if not isMarkableItem(e.object) then
		hoveredObject = nil
		hoveredItemData = nil
		return
	end

	hoveredObject = e.object
	hoveredItemData = e.itemData

	addKeepThisTooltip(e)
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

local function toggleHoveredItem()
	if not config.enabled then
		return
	end

	if not hoveredObject then
		log("No hovered item to toggle.")
		return
	end

	if not isMarkableItem(hoveredObject) then
		log("Hovered object is not markable.")
		return
	end

	local currentlyMarked = isMarked(hoveredObject, hoveredItemData)
	local newMarked = not currentlyMarked

	setMarked(hoveredObject, newMarked, hoveredItemData)
	refreshVisibleTilesForItem(hoveredObject, hoveredItemData)
	refreshInventoryWindows()
	local itemName = getObjectName(hoveredObject)
	local key = getObjectKey(hoveredObject, hoveredItemData)

	if newMarked then
		showMessage("%s - предмет помечен.", itemName)
		log(string.format("Marked: %s | key=%s", itemName, tostring(key)))
	else
		showMessage("%s - метка снята.", itemName)
		log(string.format("Unmarked: %s | key=%s", itemName, tostring(key)))
	end
end

local function returnDroppedReferenceToPlayer(reference)
	if not reference then
		return false
	end

	local object = reference.baseObject
	if not object then
		return false
	end

	local count = reference.stackSize or 1

	local itemData = nil
	if count == 1 then
		itemData = reference.itemData
	end

	tes3.addItem({
		reference = tes3.player,
		item = object,
		count = count,
		itemData = itemData,
	})

	reference.itemData = nil

	if reference.disable then
		reference:disable()
	end

	if reference.delete then
		reference:delete()
	end

	return true
end

local function onItemDropped(e)
	if not config.enabled or not config.preventDropping then
		return
	end

	if not e.reference then
		return
	end

	local object = e.reference.baseObject
	local itemData = e.reference.itemData

	if not object or not isMarked(object, itemData) then
		return
	end

	local itemName = getObjectName(object)

	if returnDroppedReferenceToPlayer(e.reference) then
		showMessage("%s - предмет помечен. Его нельзя выбросить.", itemName)
		log(string.format("Returned dropped marked item: %s", itemName))
	else
		log(string.format("Failed to return dropped marked item: %s", itemName))
	end
end

local function getMarkedItemInBarterOffer(e)
	if not e.selling then
		return nil
	end

	for _, tile in pairs(e.selling) do
		local object = tile.item
		local itemData = tile.itemData

		if object and isMarked(object, itemData) then
			return object, itemData
		end
	end

	return nil, nil
end

local function onBarterOffer(e)
	if not config.enabled or not config.preventSelling then
		return
	end

	local markedObject = getMarkedItemInBarterOffer(e)

	if not markedObject then
		return
	end

	local itemName = getObjectName(markedObject)

	showMessage("%s - предмет помечен.", itemName)
	log(string.format("Blocked barter offer with marked item: %s", itemName))

	e.block = true
	return false
end



local function onKeyDown(e)
	if not config.enabled then
		return
	end

	if e.keyCode ~= getMarkKeyCode() then
		return
	end

	toggleHoveredItem()
end

local function initialized()
	log("Initialized.")
end

event.register(tes3.event.initialized, initialized)

event.register(tes3.event.uiObjectTooltip, onObjectTooltip, {
	priority = -100,
})


-- Registers
event.register(tes3.event.keyDown, onKeyDown)
event.register(tes3.event.itemDropped, onItemDropped)
event.register(tes3.event.barterOffer, onBarterOffer)
event.register(tes3.event.itemTileUpdated, onItemTileUpdated)