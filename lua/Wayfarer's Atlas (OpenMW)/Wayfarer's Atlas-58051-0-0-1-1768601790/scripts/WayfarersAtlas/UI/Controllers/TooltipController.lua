local Tooltip = require("scripts/WayfarersAtlas/UI/Widgets/Tooltip")
local Utils = require("scripts/WayfarersAtlas/Utils")

---@class WAY.TooltipController
local TooltipController = {}
TooltipController.__index = TooltipController

function TooltipController.new()
	return setmetatable({
		_instance = nil,
	}, TooltipController)
end

function TooltipController:get()
	if self._instance == nil then
		self._instance = Tooltip.new()
		self._instance:setVisible(false)
	end

	return self._instance
end

---@param uiObject WAY.UIObject
function TooltipController:register(uiObject, callback)
	uiObject:registerEvent("mouseMove", function(e)
		self._currentUIObject = uiObject

		local tooltip = TooltipController:get()
		local tooltipContent = tooltip:getTooltipContent()

		if not tooltip:isVisible() then
			Utils.removeAll(tooltipContent)
			callback(tooltipContent, uiObject)
		end

		-- If there is no tooltip content, disable the tooltip.
		if tooltipContent[1] == nil then
			tooltip:setVisible(false)
		-- Otherwise, move to the new cursor position.
		else
			tooltip:setVisible(true)
			tooltip:move(e.position)
		end

		return true
	end)

	uiObject:registerEvent("focusLoss", function()
		if self._instance then
			self._currentUIObject = nil
			self._instance:setVisible(false)
		end

		return true
	end)

	uiObject:registerEvent("custom_destroyed", function()
		if self._instance and self._currentUIObject == uiObject then
			self._currentUIObject = nil
			self._instance:setVisible(false)
		end
	end)
end

return TooltipController.new()
