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

	--- @param element tes3uiElement
	local function recursiveContentsChanged(element)
		if not element then
			return
		end
		if element.widget and element.widget.contentsChanged then
			element.widget:contentsChanged()
		end
		recursiveContentsChanged(element.parent)
	end
	-- Recursively go back to parent and call contentsChanged because scrolling is affected.
	-- note it still does not fully work as you need to click the scrollbar
	-- to see everything when the dropdown is at the bottom of MCM panel /abot
	recursiveContentsChanged(self.elements.outerContainer.parent)

end