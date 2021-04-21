
local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuInventory = tes3ui.registerID("MenuInventory")
local GUI_ID_MenuContents_capacity = tes3ui.registerID("UIEXP_MenuContents_capacity")

local common = require("Units and Vagueness.common")

----------------------------------------------------------------------------------------------------
-- Contents: UI Expansion compatibility with capacity bar
----------------------------------------------------------------------------------------------------

local function calculateCapacity()
	local menu = tes3ui.findMenu(GUI_ID_MenuContents)
	local capacityBar = menu:findChild(GUI_ID_MenuContents_capacity)

	local maxCapacity = menu:getPropertyFloat("MenuContents_containerweight")
	local max = maxCapacity

	local container = menu:getPropertyObject("MenuContents_ObjectContainer")
	local cur = container.inventory:calculateWeight()

	local textElement = capacityBar:findChild(tes3ui.registerID("PartFillbar_text_ptr"))

	-- get carry weight values
	local mobilePlayer = tes3.mobilePlayer

	local unit = ""

	if (common.config.useUnitConversionType == 1) then
		unit = string.format("kg") -- set to kilograms
		max = max / 10
		cur = common.formatStripZeros( cur / 10 )
		textElement.text = string.format("%s/%u %s", cur, max, unit)


	elseif (common.config.useUnitConversionType == 2) then
		unit = string.format("lb") -- set to pounds
		max = max / 4.5359
		cur = common.formatStripZeros( cur / 4.5359 )
		textElement.text = string.format("%s/%u %s", cur, max, unit)


	elseif (common.config.useUnitConversionType == 3) then
		local norm = cur / max

		if cur < 0.01 then
			textElement.text = string.format("%s", common.dictionary.roleplayCapacityZero)
		elseif cur <= 2.000 and norm <= 0.300 then
			textElement.text = string.format("%s", common.dictionary.roleplayCapacityOne)
		elseif norm <= 0.500 then
			textElement.text = string.format("%s", common.dictionary.roleplayCapacityTwo)
		elseif norm <= 0.800 then
			textElement.text = string.format("%s", common.dictionary.roleplayCapacityThree)
		else
			textElement.text = string.format("%s", common.dictionary.roleplayCapacityFour)
		end

		--textElement.text = string.format("%.3f", norm)
	end

	--mwse.log(string.format("[Units and Vagueness] capacity bar %s", textElement.text));
	
	if (maxCapacity <= 0) then
		bar.visible = false
	end
end



local function onMenuContentsActivated(e)
	if (not e.newlyCreated) then
		return
	end

	-- UI Expansion compatibility
	local contentsMenu = e.element
	local capacityBar = contentsMenu:findChild(GUI_ID_MenuContents_capacity)

	-- change the fillbar if it exists
	if capacityBar ~= nil then

		contentsMenu:registerAfter("update", function(ed)
			calculateCapacity()
			ed.source:forwardEvent(ed)

			-- somehow the weightbar is not updating after dropping items into containers, so let's trigger it
			local inventoryMenu = tes3ui.findMenu(GUI_ID_MenuInventory)
			inventoryMenu:triggerEvent("update")
		end)

		contentsMenu:triggerEvent("update")
	end
end
event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" } )




