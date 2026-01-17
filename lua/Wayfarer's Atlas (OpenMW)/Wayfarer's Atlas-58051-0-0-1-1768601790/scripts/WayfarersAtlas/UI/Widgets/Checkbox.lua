local OMWUtil = require("openmw.util")
local Core = require("openmw.core")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local Button = require("scripts/WayfarersAtlas/UI/Widgets/Button")

local l10n = Core.l10n("Interface")
local v2 = OMWUtil.vector2

---@class WAY.Checkbox: WAY.UIObject
local Checkbox = UIObject:extend("Checkbox")

function Checkbox.new()
	---@class WAY.Checkbox
	local self = Checkbox.bind({
		props = { relativeSize = v2(1, 1) },
	})

	self._enabled = nil
	self._button = self:addChild(Button.new())
	self:setEnabled(false)

	self._button:registerEvent("custom_clicked", function()
		self:setEnabled(not self._enabled)
	end)

	return self
end

function Checkbox:isEnabled()
	return self._enabled
end

function Checkbox:setEnabled(enabled)
	if enabled ~= self._enabled then
		self._enabled = enabled
		self._button:setText(l10n(enabled and "Yes" or "No"))
		self:triggerEvent("custom_setEnabled", enabled)
	end

	return self
end

return Checkbox
