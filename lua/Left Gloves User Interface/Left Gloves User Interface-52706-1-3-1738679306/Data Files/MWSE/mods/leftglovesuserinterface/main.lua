-- Made by Petethegoat. Special thanks to Hrnchamd.
local versionString = "1.3"

local UIID_ICON
local UIID_SHADOW
local ITEMS_TO_MIRROR = {}

--- @param item tes3item|tes3armor|tes3clothing
local function shouldMirror(item)
	return item.isLeftPart and ITEMS_TO_MIRROR[item.id]
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
	if not shouldMirror(e.object) then return end
	local icon = e.tooltip:findChild("HelpMenu_icon")
	if icon then
		icon.imageScaleX = -1
	end
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

--- @param e itemTileUpdatedEventData
local function onInventoryTileUpdated(e)
	if shouldMirror(e.item) then
		e.element:findChild(UIID_ICON).imageScaleX = -1
		e.element:findChild(UIID_SHADOW).imageScaleX = -1
	end
end
event.register(tes3.event.itemTileUpdated, onInventoryTileUpdated)

---@param e uiActivatedEventData
local function onRepairUI(e)
	local node = e.element:findChild("MenuRepair_ServiceList"):getContentElement()
	--mwse.log(tes3ui.lookupID(node.id))
	for i = 1, #node.children do
		local icon = node.children[i].children[2].children[1]
		local stack = icon:getPropertyObject("MenuRepair_Object", "tes3itemStack")
		---@cast stack tes3itemStack
		if shouldMirror(stack.object) then
			icon.imageScaleX = -1
			icon.scaleMode = true
		end
	end
	e.element:updateLayout()
end
event.register(tes3.event.uiActivated, onRepairUI, { filter = "MenuRepair" })

local function enchantCallback(e)
	local node = e.source:findChild("MenuEnchantment_Item")
	--Not a typo. Thanks, null.
	local item = node:getPropertyObject("MenuEnchantment_SoulGem")
	if item and shouldMirror(item) then
		node.children[1].imageScaleX = -1
		e.source:unregisterAfter(tes3.uiEvent.update, enchantCallback)
		e.source:updateLayout()
		e.source:registerAfter(tes3.uiEvent.update, enchantCallback)
	end

end

---@param e uiActivatedEventData
local function onEnchantUI(e)
	if not e.newlyCreated then
		return
	end

	e.element:registerAfter(tes3.uiEvent.update, enchantCallback)
end
event.register(tes3.event.uiActivated, onEnchantUI, { filter = "MenuEnchantment" })

local function selectCallback(e)
	local node = e.source:findChild("MenuInventorySelect_scrollpane"):getContentElement()
	for i = 1, #node.children do
		local item = node.children[i]:getPropertyObject("MenuInventorySelect_object")
		if item and shouldMirror(item) then
			node.children[i]:findChild("MenuInventorySelect_icon_brick").imageScaleX = -1
			node.children[i]:findChild("MenuInventorySelect_shadow_brick").imageScaleX = -1
		end
	end
	e.source:unregisterAfter(tes3.uiEvent.update, selectCallback)
	e.source:updateLayout()
	e.source:registerAfter(tes3.uiEvent.update, selectCallback)
end

---@param e uiActivatedEventData
local function onSelectUI(e)
	if not e.newlyCreated then
		return
	end

	e.element:registerAfter(tes3.uiEvent.update, selectCallback)
end
event.register(tes3.event.uiActivated, onSelectUI, { filter = "MenuInventorySelect" })

local function quickUpdate(e)
	for i = 1, 9 do
		local item = tes3.getQuickKey({slot = i}):getItem()
		if item and shouldMirror(item) then
			local target = e:getContentElement().children[2].children[i]
			if i > 5 then
				target = e:getContentElement().children[3].children[i - 5]
			end
			if #target.children[1].children > 0 then
				target.children[1].children[1].imageScaleX = -1
				target.children[1].children[2].imageScaleX = -1
			end
		end
	end

	e:updateLayout()
end

local function quickCallback(e)
	e.source:unregisterAfter(tes3.uiEvent.update, quickCallback)
	quickUpdate(e.source)
	e.source:registerAfter(tes3.uiEvent.update, quickCallback)
end

---@param e uiActivatedEventData
local function onQuickUI(e)
	quickUpdate(e.element)

	if not e.newlyCreated then
		return
	end

	e.element:registerAfter(tes3.uiEvent.update, quickCallback)
end
event.register(tes3.event.uiActivated, onQuickUI, { filter = "MenuQuick" })

--- @param e enchantedItemCreatedEventData
local function enchantedItemCreatedCallback(e)
	-- manually add it as soon as the enchantment is created.
	-- subsequent loads will include it from the save file.
	if shouldMirror(e.baseObject) then
		ITEMS_TO_MIRROR[e.object.id] = true
	end
end
event.register(tes3.event.enchantedItemCreated, enchantedItemCreatedCallback)

local function onLoaded()
	UIID_ICON = tes3ui.registerID("itemTile_icon")
	UIID_SHADOW = tes3ui.registerID("itemTile_shadow")

	ITEMS_TO_MIRROR = {}
	local foundIcons = {}
	for i in tes3.iterateObjects(tes3.objectType.clothing) do
		---@cast i tes3clothing
		if not i.isLeftPart then
			if foundIcons[i.icon] and foundIcons[i.icon] ~= true then
				ITEMS_TO_MIRROR[foundIcons[i.icon]] = true
			end
			foundIcons[i.icon] = true
		elseif i.isLeftPart then
			if foundIcons[i.icon] == true then
				ITEMS_TO_MIRROR[i.id] = true
			else
				foundIcons[i.icon] = i.id
			end
		end
	end

	for i in tes3.iterateObjects(tes3.objectType.armor) do
		---@cast i tes3armor
		if not i.isLeftPart then
			if foundIcons[i.icon] and foundIcons[i.icon] ~= true then
				ITEMS_TO_MIRROR[foundIcons[i.icon]] = true
			end
			foundIcons[i.icon] = true
		elseif i.isLeftPart then
			if foundIcons[i.icon] == true then
				ITEMS_TO_MIRROR[i.id] = true
			else
				foundIcons[i.icon] = i.id
			end
		end
	end

	--for k, _ in pairs(ITEMS_TO_MIRROR) do mwse.log(k) end
end
event.register(tes3.event.loaded, onLoaded)

event.register(tes3.event.modConfigReady, function()
	mwse.log("[Left Gloves User Interface] " .. versionString .. " loaded successfully.")
end)