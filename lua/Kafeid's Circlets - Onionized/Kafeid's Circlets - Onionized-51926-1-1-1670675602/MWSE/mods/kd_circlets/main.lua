require('kd_circlets.onion')
require('kd_circlets.balance')
require('kd_circlets.wares')
require('kd_circlets.drip')

---@param e uiObjectTooltipEventData
local function removeArmorRating(e)
	if e.object and e.object.objectType == tes3.objectType.armor then
		local items = require('kd_circlets.items')
		for _, item in pairs(items.all) do
			if item == e.object.id then
				local element = e.tooltip:findChild("HelpMenu_armorRating")
				if element then element:destroy() end
				element = e.tooltip:findChild("UIEXP_Tooltip_WeightClass") -- UI Expansion interop
				if element then element:destroy() end
				return
			end
		end
	end
end

event.register("uiObjectTooltip", removeArmorRating)