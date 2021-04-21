
local GUI_ID_MenuBarter = tes3ui.registerID("MenuBarter")
local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuInventory = tes3ui.registerID("MenuInventory")
local GUI_ID_MenuInventory_Weightbar = tes3ui.registerID("MenuInventory_Weightbar")

local common = require("Units and Vagueness.common")

----------------------------------------------------------------------------------------------------
-- Inventory: Searching and filtering.
----------------------------------------------------------------------------------------------------

local function calculateCarryWeight()
	local inventoryMenu = tes3ui.findMenu(GUI_ID_MenuInventory)
	local weightBar = inventoryMenu:findChild(GUI_ID_MenuInventory_Weightbar)
	local textElement = weightBar:findChild(tes3ui.registerID("PartFillbar_text_ptr"))

	local mobilePlayer = tes3.mobilePlayer

	if mobilePlayer.encumbrance.objectType == tes3.objectType.tes3statistic then
		-- get carry weight values
		local enc = mobilePlayer.encumbrance.current
		local max = mobilePlayer.encumbrance.base
		local norm = mobilePlayer.encumbrance.normalized

		local unit = ""

		-- apply conversion
		if (common.config.useUnitConversionType == 1) then
			unit = string.format("kg") -- set to kilograms
			max = max / 10
			enc = enc / 10
			enc = common.formatStripZeros(enc)
			textElement.text = string.format("%s/%u %s", enc, max, unit)


		elseif (common.config.useUnitConversionType == 2) then
			unit = string.format("lb") -- set to pounds
			max = max / 4.5359
			enc = enc / 4.5359
			enc = common.formatStripZeros(enc)
			textElement.text = string.format("%s/%u %s", enc, max, unit)


		elseif (common.config.useUnitConversionType == 3) then
			if norm <= 0.200 then
				textElement.text = string.format("%s", common.dictionary.roleplayCarryWeightZero)
			elseif norm <= 0.400 then
				textElement.text = string.format("%s", common.dictionary.roleplayCarryWeightOne)
			elseif norm <= 0.600 then
				textElement.text = string.format("%s", common.dictionary.roleplayCarryWeightTwo)
			elseif norm < 1.000 then
				textElement.text = string.format("%s", common.dictionary.roleplayCarryWeightThree)
			else
				textElement.text = string.format("%s", common.dictionary.roleplayCarryWeightFour)
			end
		end

		--tes3.messageBox({ message = "weightbar "..textElement.text });
	end
end


local function onMenuInventoryActivated(e)
	if (not e.newlyCreated) then
		return
	end

	local inventoryMenu = tes3ui.findMenu(GUI_ID_MenuInventory)
	inventoryMenu:registerAfter("update", function(ed)
		calculateCarryWeight()
		ed.source:forwardEvent(ed)
	end)
	inventoryMenu:triggerEvent("update")
end
event.register("uiActivated", onMenuInventoryActivated, { filter = "MenuInventory" } )
event.register("menuEnter", onMenuInventoryActivated, { filter = "MenuInventory" } )