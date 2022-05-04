--[[
		Mod Compare Tooltip
		Author: rfuzzo

		This mod adds compare tooltips to inventory items against equipped items of the same category.

		TODO:
			- blacklist comparisons
		BUGS:
			- fix arrow layout breaking for long comparisons
			- fix name icon field for lookat comparisons
]] --
local config = require("rfuzzo.CompareTooltip.config")
local common = require("rfuzzo.CompareTooltip.common")
local ashfall = require("rfuzzo.CompareTooltip.module_ashfall")
local uiexpansion = require("rfuzzo.CompareTooltip.module_uiexpansion")

local lock = false

-- Make sure we have the latest MWSE version.
if (mwse.buildDate == nil) or (mwse.buildDate < 20220423) then
	event.register("initialized", function()
		tes3.messageBox("[ CTT ]  Compare tooltips requires the latest version of MWSE. Please run MWSE-Updater.exe.")
	end)
	return
end

--- Find an item to compare for a given object
--- @param e uiObjectTooltipEventData
local function find_compare_object(e)
	local obj = e.object
	-- get corresponding Equipped
	local stack = tes3.getEquippedItem({
		actor = tes3.player,
		objectType = obj.objectType,
		slot = obj.slot,
		-- type = obj.type,
	})
	if (stack == nil) then
		-- mwse.log("[ CE ] <<<<< " .. obj.id .. " nothing equipped found for slot")
		return
	end

	-- found an item to compare against
	local equipped = stack.object
	-- mwse.log("[ CE ] Found equipped item: %s (for %s)", equipped.id, obj.id)

	--[[
		if the weapon types don't match, don't compare
		marksmanBow 	9 	Marksman, Bow
		marksmanCrossbow 	10 	Marksman, Crossbow
		marksmanThrown 	11 	Marksman, Thrown
		arrow 	12 	Arrows
		bolt 	13 	Bolts
	]]
	local curWeapType = tonumber(obj.type)
	local equWeapType = tonumber(equipped.type)
	if (curWeapType ~= nil and equWeapType ~= nil) then
		-- mwse.log("[ CE ] weap type: %s (for %s)", curWeapType, equWeapType)
		if (curWeapType < 9 and equWeapType > 8) then
			return
		end
		if (equWeapType < 9 and curWeapType > 8) then
			return
		end
	end

	return stack
end

--- checks a ui block if it should be compared
--- @param name string
local function check_compare_block(name)
	-- checks
	-- do not compare the name field
	if (name == 'HelpMenu_name') then
		return false
	end
	if (name == 'HelpMenu_weaponType') then
		return false
	end

	return true
end

--- Creates the inline compare tooltip
--- @param e uiObjectTooltipEventData
--- @param stack tes3equipmentStack 
local function create_inline(e, stack)

	-- common.mod_log("------- %s ------------------------------", e.object.id)

	-- cache values
	-- create equipped tooltip to cache the fields but don't raise the event
	lock = true
	local equTooltip = tes3ui.createTooltipMenu { item = stack.object, itemData = stack.itemData } -- equiped item
	lock = false

	local equTable = {}

	for _, element in pairs(equTooltip:findChild('PartHelpMenu_main').children) do
		if (element.text ~= nil and element.name ~= nil) then
			equTable[element.name] = element.text
			-- common.mod_log("  vanilla_cache (%s): %s", element.name, equTable[element.name])
		end
	end
	-- UI Expansion support
	uiexpansion.uiexpansion_cache(equTooltip, 'UIEXP_Tooltip_IconGoldBlock', equTable)
	uiexpansion.uiexpansion_cache(equTooltip, 'UIEXP_Tooltip_IconWeightBlock', equTable)
	-- Ashfall support
	ashfall.ashfall_cache(equTooltip, 'Ashfall:ratings_warmthValue', equTable)
	ashfall.ashfall_cache(equTooltip, 'Ashfall:ratings_coverageValue', equTable)

	-- create current item tooltip again but don't raise the event
	lock = true
	local tooltip = tes3ui.createTooltipMenu { item = e.object, itemData = e.itemData } -- current item
	lock = false

	-- modify values
	-- compare all toplevel properties
	for _, element in pairs(tooltip:findChild('PartHelpMenu_main').children) do

		if (not check_compare_block(element.name)) then
			goto continue
		end

		-- do not compare fields without a colon
		local cText = element.text
		local _, j = string.find(cText, ":")
		if (j == nil) then
			goto continue
		end
		-- do not compare fields without a text
		local eText = equTable[element.name]
		if (eText == nil) then
			goto continue
		end

		eText = string.sub(eText, j + 2)
		cText = string.sub(cText, j + 2)

		-- common.mod_log("  vanilla_update: %s vs %s", cText, eText)

		-- Compare
		local status = common.compare_text(cText, eText, element.name)
		common.set_color(element, status)
		common.set_arrows(element, status)

		if (config.useParens) then
			-- add compare text
			element.text = element.text .. " (" .. eText .. ")"
		end

		-- icon hack for arrows
		if (config.useArrows) then
			element.text = "  " .. element.text .. "     "
		end

		element:updateLayout()

		::continue::
	end

	-- UI Expansion support
	uiexpansion.uiexpansion_update(equTooltip, 'UIEXP_Tooltip_IconGoldBlock', equTable)
	uiexpansion.uiexpansion_update(equTooltip, 'UIEXP_Tooltip_IconWeightBlock', equTable)
	-- ashfall support support
	ashfall.ashfall_update(equTooltip, 'Ashfall:ratings_warmthValue', equTable)
	ashfall.ashfall_update(equTooltip, 'Ashfall:ratings_coverageValue', equTable)

	tooltip:updateLayout()
end

--- main mod
--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
	-- checks
	if (not config.enableMod) then
		return
	end
	if (lock) then
		return
	end
	local obj = e.object
	if (obj == nil) then
		return
	end
	-- key check
	if (config.useKey) then
		local inputController = tes3.worldController.inputController
		if (not inputController:isKeyDown(config.comparisonKey.keyCode)) then
			return
		end
	end

	-- don't do anything for non-inventory tile objects
	-- local reference = e.reference
	-- if (reference ~= nil) then
	-- 	return
	-- end
	--[[
			filter to object types:
			armor				1330467393
			weapon			1346454871
			clothing		1414483011
			TODO not supported yet:
			ammunition	1330466113
			lockpick		1262702412
			probe				1112494672
	]]
	local objectType = obj.objectType
	if (objectType ~= 1330467393 and objectType ~= 1346454871 and objectType ~= 1414483011) then
		-- common.mod_log("not supported type: %s", tostring(objectType))
		return
	end
	-- if equipped, return
	local isEquipped = tes3.player.object:hasItemEquipped(obj)
	if (isEquipped) then
		-- common.mod_log(" <<<<< %s is equipped", obj.id)
		return
	end

	-- if item found to compare to
	local stack = find_compare_object(e)
	if (stack ~= nil) then
		-- if (config.useInlineTooltips) then
		create_inline(e, stack)
		-- end
		return
	end

	-- else the current item is always better
	-- set color to green for everything
	local tt = e.tooltip
	for _, element in pairs(tt:findChild('PartHelpMenu_main').children) do

		if (not check_compare_block(element.name)) then
			goto continue
		end

		-- do not compare fields without a colon
		local cText = element.text
		local _, j = string.find(cText, ":")
		if (j == nil) then
			goto continue
		end

		-- Compare
		common.set_color(element, 1)
		common.set_arrows(element, 1)

		-- icon hack for arrows
		if (config.useArrows) then
			element.text = "  " .. element.text .. "     "
		end

		element:updateLayout()
		::continue::
	end

	-- UI Expansion support disabled here becasue annoying
	-- uiexpansion.uiexpansion_color_block(tt, 'UIEXP_Tooltip_IconGoldBlock', 1)
	-- uiexpansion.uiexpansion_color_block(tt, 'UIEXP_Tooltip_IconWeightBlock', 1)

	-- Ashfall support
	ashfall.ashfall_color_block(tt, 'Ashfall:ratings_warmthValue', 1)
	ashfall.ashfall_color_block(tt, 'Ashfall:ratings_coverageValue', 1)

end

--- recreate tooltip
--- @param isVanilla boolean
--- @param e keyDownEventData
local function recreate_tooltip(isVanilla, e)
	-- checks
	if (not config.enableMod) then
		return
	end
	if (not config.useKey) then
		return
	end
	if (not (e.keyCode == config.comparisonKey.keyCode)) then
		return
	end
	local helpMenu = tes3ui.findHelpLayerMenu("HelpMenu")
	if (helpMenu == nil) then
		return
	end
	local objOrRef = helpMenu:getPropertyObject("PartHelpMenu_object")
	if (objOrRef == nil) then
		return
	end

	-- local dbgStr = "keyDown"
	-- if (isVanilla) then
	-- 	dbgStr = "keyUp"
	-- end
	-- common.mod_log("%s %s/%s %s get item data", dbgStr, tostring(e.keyCode), tostring(config.comparisonKey.keyCode),
	--                objOrRef.id)

	-- get item data
	local obj = objOrRef.object
	local itemData = objOrRef.itemData
	-- common.mod_log("  itemdata %s", tostring(itemData ~= nil))
	-- common.mod_log("  obj %s", tostring(obj ~= nil))
	-- common.mod_log("  %s objOrRef type: %s", objOrRef.id, tostring(objOrRef.objectType))

	-- it's not a ref (= a not a vanilla looked at thing)
	if (obj == nil) then
		obj = objOrRef
		local reference = tes3.getReference(objOrRef.id)
		if (reference ~= nil) then
			itemData = reference.itemData
		end
	end

	-- disable comparison for specific types
	local objectType = obj.objectType
	if (objectType ~= 1330467393 and objectType ~= 1346454871 and objectType ~= 1414483011) then
		-- common.mod_log("  %s disable comparison for specific type: %s", obj.id, tostring(objectType))
		return
	end

	-- common.mod_log("  found obj %s with itemdata %s", obj.id, tostring(itemData ~= nil))

	-- recreate tooltip
	if (isVanilla) then
		lock = true
	end
	tes3ui.createTooltipMenu { item = obj, itemData = itemData }
	if (isVanilla) then
		lock = false
	end
end

-- used to display comparisions on key down
--- @param e keyDownEventData
local function keyDownCallback(e)
	recreate_tooltip(false, e)
end

-- used to display comparisions on key down
--- @param e keyUpEventData
local function keyUpCallback(e)
	recreate_tooltip(true, e)
end

--[[
    Init mod
]]
--- @param e initializedEventData
local function initializedCallback(e)
	-- init mod
	common.mod_log("ashfall plugin active: %s", tostring(tes3.isLuaModActive("mer.ashfall")))
	common.mod_log("UI Expansion plugin active: %s", tostring(tes3.isLuaModActive("UI Expansion")))

	event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback, { priority = -110 })
	event.register(tes3.event.keyDown, keyDownCallback)
	event.register(tes3.event.keyUp, keyUpCallback)

	common.mod_log("%s v%.1f Initialized", config.mod, config.version)
end

event.register(tes3.event.initialized, initializedCallback)

--[[
		Handle mod config menu.
]]
require("rfuzzo.CompareTooltip.mcm")
