local config = require("ndvr.equipment_menu.config.config")
local utils = require("ndvr.equipment_menu.utils")
local menu = require("ndvr.equipment_menu.menu")

local equipWindow = nil
local equipWindowScroll = nil
local equipWindowButton = nil

local equipSlotsWindowID = tes3ui.registerID("NdvrEquipmentMenuWindow")
local equipSlotsButtonID = tes3ui.registerID("NdvrEquipmentMenuButton")

local showEquipSlotsWindow = false

local armorSlots = {}
local clothingSlots = {}
local weaponSlots = {}

local function getReadableSlotList()
	armorSlots = utils.getArmorSlots()

	local excludeRings = true
    clothingSlots = utils.getClothingSlots(excludeRings)

    weaponSlots = utils.getWeaponSlots()
end

local function createMenuContent()
	getReadableSlotList()

	if config.showWeaponTable then
		menu.addWeaponTable(equipWindowScroll, weaponSlots)
	end

	if config.showArmorTable then
		menu.addArmorTable(equipWindowScroll, armorSlots)
	end

	if config.showClothingTable then
		menu.addClothingTable(equipWindowScroll, clothingSlots)
	end
end

local function refreshMenu()
	if not config.modEnabled then
		if equipWindow then
			equipWindow:destroy()
		end

		equipWindow = nil
		return
	end

	equipWindowScroll:getContentElement():destroyChildren()
	createMenuContent()
	equipWindow:updateLayout()
end

local function createEquipWindow()
	if not config.modEnabled then
		return
	end

    if equipWindow then
        return
    end

    equipWindow = tes3ui.createMenu{ id = equipSlotsWindowID, dragFrame = true, loadable = true }
	equipWindow:loadMenuPosition()

	equipWindow.text = "Equipment"

	equipWindowScroll = equipWindow:createVerticalScrollPane()
    equipWindowScroll.widthProportional = 1.0
    equipWindowScroll.heightProportional = 1.0

	createMenuContent()
end

local function saveWindowState()
    tes3.player.data.ndvrEquipmentSlotsMenu = tes3.player.data.ndvrEquipmentSlotsMenu or {}
    tes3.player.data.ndvrEquipmentSlotsMenu.showEquipSlotsWindow = showEquipSlotsWindow
end

local function toggleEquipWindow()
	if not config.modEnabled then
		return
	end
	
    if equipWindow and equipWindow.visible ~= nil then
		showEquipSlotsWindow = not showEquipSlotsWindow
        equipWindow.visible = not equipWindow.visible
		saveWindowState()
        return
    end

	showEquipSlotsWindow = true
	saveWindowState()
    createEquipWindow()
end

local function addToggleEquipmentMenuButton(e)
	local menuInventory = e.element or e.menu
	if not menuInventory then return end

	local characterBox = menuInventory:findChild(tes3ui.registerID("MenuInventory_character_box"))
	if not characterBox then
		return
	end

	equipWindowButton = characterBox:createButton{
		id = equipSlotsButtonID,
		text = "+"
	}
	equipWindowButton.absolutePosAlignX = 0.0
	equipWindowButton.absolutePosAlignY = 0.0

	equipWindowButton:register("mouseClick", function()
		toggleEquipWindow()
	end)
end


local function refreshEquipButton()
	local menuInventory = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
	if not menuInventory then return end

	local existing = menuInventory:findChild(equipSlotsButtonID)
	if config.modEnabled and config.showToggleMenuButton then
		if not existing then
			addToggleEquipmentMenuButton{ menu = menuInventory }
		end
	else
		if existing then
			existing:destroy()
			equipWindowButton = nil
		end
	end

	menuInventory:updateLayout()
end

event.register("uiActivated", function(e)
	-- ensure button always nil on load, then add it if mod enabled
	equipWindowButton = nil

	refreshEquipButton()
end)

local function inventoryMenuEnter(e)
	refreshEquipButton()

	if not config.modEnabled then
		return
	end

	local allowedMenus = {
		MenuInventory = true,
		MenuStat = true,
		MenuMagic = true,
		MenuMap = true,
		MenuMulti = true,
	}

	if not allowedMenus[e.menu.name] then
        return
    end

	if equipWindow and not equipWindow.visible and showEquipSlotsWindow then
		equipWindow.visible = true
	elseif showEquipSlotsWindow then
		createEquipWindow()
	end

	refreshMenu()
end
event.register('menuEnter', inventoryMenuEnter)

local function anyMenuExit()
	if equipWindow and equipWindow.visible then
		equipWindow.visible = false
	end
end
event.register('menuExit', anyMenuExit)

event.register("equipped", function(e)
    refreshMenu()
end)

event.register("unequipped", function(e)
    refreshMenu()
end)

event.register("loaded", function()
	-- to avoid crash after reload
    equipWindow = nil

	local savedState = tes3.player.data.ndvrEquipmentSlotsMenu and tes3.player.data.ndvrEquipmentSlotsMenu.showEquipSlotsWindow
    if savedState then
        showEquipSlotsWindow = tes3.player.data.ndvrEquipmentSlotsMenu.showEquipSlotsWindow
    end
	
	saveWindowState()
end)

event.register("initialized", function()
    mwse.log("[Equipment Menu] Mod loaded.")
end)

local function isInventoryOnlyOpen()
    local inv = tes3ui.findMenu("MenuInventory")
    --local barter = tes3ui.findMenu("MenuBarter")
    return inv and inv.visible --and (not barter or not barter.visible)
end

event.register("keyDown", function(e)
	local keybind = config.toggleMenuKeybind

	if not config.enableKeybindToggle then
		return
	end

	if e.isAltDown then
        return
    end

    if not tes3ui.menuMode() or not isInventoryOnlyOpen() then
        return
    end

    if e.keyCode == keybind.keyCode then
        toggleEquipWindow()
    end
end)

require("ndvr.equipment_menu.MCM.mcm")