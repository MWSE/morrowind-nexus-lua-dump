local modPath = "capsDrop"
local defaultConfig = {
	enabled = true,
	scanCode = { keyCode = tes3.scanCode.caps, isShiftDown = false, isAltDown = false, isControlDown = false },
}
local config = mwse.loadConfig(modPath, defaultConfig)

--- @param e tes3uiEventData
local function onInventoryTileClicked(e)
	if not config.enabled then
		return
	end
	local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
	if contentsMenu and contentsMenu.visible == true then
		return
	end
	local barterMenu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
	if barterMenu and barterMenu.visible == true then
		return
	end
	local cursorIcon = tes3ui.findHelpLayerMenu(tes3ui.registerID("CursorIcon"))
	if (cursorIcon) then
		return
	end

	-- If the player is holding the Caps key, 
	local isCapsDown = tes3.worldController.inputController:isKeyDown(config.scanCode.keyCode)
	if not isCapsDown then
		return
	end

	local tile = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") --- @type tes3inventoryTile
	local item = tile.item
	local itemData = tile.itemData
	local count = tile.count

	-- Drop the item.
	if itemData then
		tes3.dropItem({ reference = tes3.player, item = item, itemData = itemData, count = count })
	else
		tes3.dropItem({ reference = tes3.player, item = item, matchNoItemData = true, count = count })
	end

	return false
end

--- @param e itemTileUpdatedEventData
local function onInventoryTileUpdated(e)
	e.element:registerBefore("mouseClick", onInventoryTileClicked)
end
event.register("itemTileUpdated", onInventoryTileUpdated, { filter = "MenuInventory", priority = 15 }) -- load before UI Expansion

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Caps Drop")
	template:saveOnClose(modPath, config)

	local page = template:createPage()

	local settings = page:createCategory("Settings")
	settings:createYesNoButton({
		label = "Enable Mod",
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})
	settings:createKeyBinder{
		label = "Assign Drop Hotkey (Default: Caps)",
		allowCombinations = false,
		variable = mwse.mcm.createTableVariable { id = "scanCode", table = config },
		defaultSetting = { keyCode = tes3.scanCode.caps, isShiftDown = false, isAltDown = false, isControlDown = false },
	}

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)

