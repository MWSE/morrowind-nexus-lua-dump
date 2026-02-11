local I = require("openmw.interfaces")
local UI = require("openmw.ui")
local Ambient = require("openmw.ambient")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")
local Utils = require("scripts/WayfarersAtlas/Utils")

local COLOR_NORMAL = Utils.colorFromGMST("fontcolor_color_normal")
local COLOR_OVER = Utils.colorFromGMST("fontcolor_color_normal_over")
local COLOR_PRESSED = Utils.colorFromGMST("fontcolor_color_normal_pressed")

---@class WAY.Button: WAY.UIObject
local Button = UIObject:extend("Button")

function Button.new()
	local textLabel = {
		template = I.MWUI.templates.textNormal,
		props = { text = "" },
	}

	---@class WAY.Button
	local self = Button.bind(UI.create(SharedUI.paddedBox({
		template = I.MWUI.templates.padding,
		content = UI.content({ textLabel }),
	})))

	self._textLabel = textLabel

	self:registerEvent("mouseClick", function()
		self:triggerEvent("custom_clicked")
	end)

	self:registerEvent("focusGain", function()
		textLabel.props.textColor = COLOR_OVER
		self:queueUpdate()
	end)

	self:registerEvent("focusLoss", function()
		textLabel.props.textColor = COLOR_NORMAL
		self:queueUpdate()
	end)

	self:registerEvent("mousePress", function(e)
		if e.button == SharedUI.MouseButton.Left then
			Ambient.playSound("menu click")
			textLabel.props.textColor = COLOR_PRESSED
			self:queueUpdate()
		end
	end)

	self:registerEvent("mouseRelease", function(e)
		if e.button == SharedUI.MouseButton.Left then
			textLabel.props.textColor = COLOR_NORMAL
			self:queueUpdate()
		end
	end)

	return self
end

function Button:setText(text)
	self._textLabel.props.text = text
	self:queueUpdate()

	return self
end

return Button
