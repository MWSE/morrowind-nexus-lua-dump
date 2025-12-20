-- CF_p.lua (cleaned)
-- Main crafting framework file

-- Core imports
core = require('openmw.core')
vfs = require('openmw.vfs')
I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
Player = require('openmw.types').Player
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
ambient = require('openmw.ambient')
animation = require('openmw.animation')
input = require('openmw.input')
camera = require('openmw.camera')
nearby = require('openmw.nearby')
time = require('openmw_aux.time')

-- settings
MODNAME = "CraftingFramework"
local storage = require('openmw.storage')
playerSection = storage.playerSection('Settings'..MODNAME)
require("CF_scripts.CF_settings")

-- Load core functions
require("CF_scripts.CF_core")
cheatMode = false

-- Colors
textColor = getColorFromGameSettings("fontColor_color_normal_over")
lightText = util.color.rgb(textColor.r^0.5,textColor.g^0.5,textColor.b^0.5)
morrowindGold = getColorFromGameSettings("fontColor_color_normal")
goldenMix =  mixColors(textColor, morrowindGold)
darkerFont = getColorFromGameSettings("fontColor_color_normal")
selectedColor = util.color.rgb(0.6, 0.5, 0.2)
hoverColor = util.color.rgb(0.3, 0.25, 0.15)
morrowindBlue = getColorFromGameSettings("fontColor_color_journal_link")
morrowindBlue2 = getColorFromGameSettings("fontColor_color_journal_link_over")
morrowindBlue3 = getColorFromGameSettings("fontColor_color_journal_link_pressed")
background = ui.texture { path = 'black' }

-- Global state variables
textSize = playerSection:get("FONT_SIZE") or 21
descriptionWidth = math.floor(textSize*22.71)
listWidth =  math.floor(textSize*15.86)

currentSubcategory = nil
currentIndex = nil
cachedTempInventory = nil
lastScroll = 0
artisansTouch = false
filterRecipes = false
tempInventory = nil
lastSelectionMove = 0
moveSelectionDirection = nil
maxRecipes = playerSection:get("MAX_RECIPES") or 21
selectedRecipe = nil
selectedCount = 0
lastFxTime = 0
craftingQueue = {}
pendingInventoryChanges = {}
wildcardFunctions = {}
onFrameFunctions = {}
textureCache = {}
windowPos = v2(0,0)
local inventoryChanged = false
local lastEncumbrance = 0
skillCache = {}
baseSkillCache = {}
skillChanged = true

-- Module imports

require("CF_scripts.ui_craftingWindowHelpers")
makeBorder = require("CF_scripts.ui_makeborder")
craftItem = require("CF_scripts.craftItem")
expText = require("CF_scripts.expText")
makeDescriptionTooltip = require("CF_scripts.ui_descriptionTooltip")
makeMouseTooltip = require("CF_scripts.ui_mouseTooltip")

-- Load profession data
profession = {categories = require("CF_scripts.spreadsheetParser")}

protectedRecordIds = {
["t_de_ebony_pickaxe_01"] = true,
["bm nordic pick"] = true,
["miner's pick"] = true
}



-- Handle key press events
function onKeyPress(key)
	if not craftingWindow then return end
	
	if key.code == input.KEY.DownArrow or key.code == input.KEY.UpArrow then
		local direction = (key.code == input.KEY.DownArrow) and 1 or -1
		moveSelection(direction, true)
		moveSelectionDirection = direction
		lastSelectionMove = core.getRealTime()+0.23
	end
	if key.code == input.KEY.PageDown then
		scrollCraftingWindow(-math.floor(maxRecipes/2))
	elseif key.code == input.KEY.PageUp then
		scrollCraftingWindow(math.floor(maxRecipes/2))
	end
end

-- Handle key release events
function onKeyRelease(key)
	if not craftingWindow then return end
	
	if key.code == input.KEY.DownArrow or key.code == input.KEY.UpArrow then
		moveSelectionDirection = nil
	end
end

-- Handle UI mode changes
function handleUiModeChanged(data)
	if data.newMode == "Repair" then
		if input.isShiftPressed() then
			tempInventory = nil
			skillChanged = true --?
			updateRecipeAvailability(filterRecipes)
			require("CF_scripts.ui_craftingWindow")
			I.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
		else
			require("CF_scripts.ui_repairButton")
		end
	elseif data.oldMode == "Repair" and repairButton then
		repairButton:destroy()
		repairButton = nil
	end	
	if data.newMode == nil and craftingWindow then
		destroyCraftingWindow()
	end
end

-- Handle item notification after crafting
function handleNotifyItem(data)
	local item = data[1]
	local count = data[2]
	local recipeId = data[3]
	local shiftPressed = data[4]
	ui.showMessage("Crafted "..count.." "..item.type.record(item).name..(count and count > 1 and "s" or ""))
	ambient.playSound("item bodypart up", {volume =0.9})
	
	if shiftPressed and getEquipmentSlot(item) then
		if item.count == 0 then
			for _, i in pairs(types.Actor.inventory(self):getAll(item.type)) do
				if i.recordId == item.recordId and types.Item.itemData(i).condition == item.type.record(item).health then
					item = i
				end
			end
		end
		if item.count > 0 then
			local eq = types.Actor.getEquipment(self)
			eq[getEquipmentSlot(item)] = item
			types.Actor.setEquipment(self, eq)
			if I.UI.getMode() == 'Interface' then
				I.UI.setMode()
				I.UI.setMode('Interface')
			end
		end
	end
	inventoryChanged = true
end

-- Handle item notification after crafting
function handleRemovedItem(data)
	local itemId = data[1]
	local count = data[2]	
	inventoryChanged = true
end

-- Handle frame updates
function onFrame(dt)
	for _, f in pairs(onFrameFunctions) do
		f(dt)
	end
	
	if moveSelectionDirection and core.getRealTime() > lastSelectionMove then
		lastSelectionMove = core.getRealTime()+0.015
		moveSelection(moveSelectionDirection)
	end
	
	if craftingWindow and (inventoryChanged or types.Actor.getEncumbrance(self) ~= lastEncumbrance) then
		lastEncumbrance = types.Actor.getEncumbrance(self)
		tempInventory = nil
		updateRecipeAvailability(filterRecipes)
		refreshRecipesAndWindow()
	end
	inventoryChanged = false
end

-- Handle save data
function onSave()
	return saveData
end

-- Handle load data
function onLoad(data)
	saveData = data or {}
	if not saveData.enabledRecipes then
		saveData.enabledRecipes = {}
	end
end

-- Enable a recipe (interface function)
function enableRecipe(recipeId)
	saveData.enabledRecipes[recipeId] = 1
	skillChanged = true
end

function resetRecipe(recipeId)
	saveData.enabledRecipes[recipeId] = nil
	skillChanged = true
end

function onMouseWheel(vertical)
	vertical = vertical * 2
	if craftingWindow and vertical ~= 0 then
		scrollCraftingWindow(vertical)
	end
end	

-- DPAD Scrolling
function onControllerButtonPress(key)
	if not craftingWindow then return end
	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		local direction = (key == input.CONTROLLER_BUTTON.DPadDown) and 1 or -1
		moveSelection(direction, true)
		moveSelectionDirection = direction
		lastSelectionMove = core.getRealTime()+0.23
	end
end

-- DPAD Scrolling
function onControllerButtonRelease(key)
	if not craftingWindow then return end
	
	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		moveSelectionDirection = nil
	end
end

I.SkillProgression.addSkillLevelUpHandler(function(skillId)
	skillChanged = true
end)


function onConsoleCommand(mode, command, selectedObject)
	if command == "lua craft" then
		cheatMode = not cheatMode
		if cheatMode then
			ui.printToConsole("[CraftingFramework] Cheatmode ON", ui.CONSOLE_COLOR.Success)
			print("[CraftingFramework] Cheatmode ON")
			core.sendGlobalEvent('CraftingFramework_getItem', {self, "Repair", "hammer_repair", "Cheat Hammer", 1 })
			tempInventory = nil
			skillChanged = true --?
			updateRecipeAvailability(filterRecipes)
			require("CF_scripts.ui_craftingWindow")
			I.UI.setMode('Interface', {windows = {'Map', 'Stats', 'Magic', 'Inventory'}})
		else
			ui.printToConsole("[CraftingFramework] Cheatmode OFF", ui.CONSOLE_COLOR.Success)
			print("[CraftingFramework] Cheatmode OFF")
		end
	end
end


return {
	engineHandlers = {
		onFrame = onFrame,
		onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
		onControllerButtonRelease = onControllerButtonRelease,
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onSave = onSave,
		onLoad = onLoad,
		onInit = onLoad,
		onConsoleCommand = onConsoleCommand,
	},
	eventHandlers = { 
		UiModeChanged = handleUiModeChanged,
		CraftingFramework_notifyItem = handleNotifyItem,
		CraftingFramework_removedItem = handleRemovedItem,
	},
	interfaceName = "CraftingFramework",
	interface = {
		version = 1,
		enableRecipe = enableRecipe,
		resetRecipe = resetRecipe,
	}
}