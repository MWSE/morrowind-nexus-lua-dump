local Dropdown = require('mcm.components.settings.Dropdown')

function Dropdown:createDropdown()
	if self.dropdownActive then
		-- Destroy dropdown
		self.elements.dropdownParent:destroyChildren()
		self.dropdownActive = false
		self.elements.dropdownParent:getTopLevelMenu():updateLayout()
		return
	end
	-- Create dropdown
	self.dropdownActive = true
	local dropdown = self.elements.dropdownParent:createThinBorder()
	dropdown.flowDirection = "top_to_bottom"
	dropdown.autoHeight = true
	dropdown.widthProportional = 1.0
	dropdown.paddingAllSides = 6
	dropdown.borderTop = 0
	local options = self.options
	for i = 1, #options do
		local option = options[i]
		local listItem = dropdown:createTextSelect({ text = option.label })
		listItem.widthProportional = 1.0
		listItem.autoHeight = true
		listItem.borderBottom = 3
		local widget = listItem.widget
		widget.idle = tes3ui.getPalette("normal_color")
		widget.over = tes3ui.getPalette("normal_over_color")
		widget.pressed = tes3ui.getPalette("normal_pressed_color")
		listItem:register("mouseClick", function()
			self:selectOption(option)
		end)
	end
	self.elements.dropdown = dropdown
	dropdown:getTopLevelMenu():updateLayout()
end