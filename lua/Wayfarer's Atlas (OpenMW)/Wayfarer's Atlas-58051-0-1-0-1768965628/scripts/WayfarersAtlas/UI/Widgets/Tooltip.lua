local UI = require("openmw.ui")
local I = require("openmw.interfaces")
local OMWUtil = require("openmw.util")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")
local SharedUI = require("scripts/WayfarersAtlas/UI/SharedUI")

local v2 = OMWUtil.vector2

---@class WAY.Tooltip: WAY.UIObject
local Tooltip = UIObject:extend("Tooltip")

function Tooltip.new()
	local tooltipContent = UI.content({})

	---@class WAY.Tooltip
	local self = Tooltip.bind(UI.create({
		layer = "Notification",
		name = "tooltip",
		template = I.MWUI.templates.boxSolid,
		content = UI.content({
			{
				name = "padding",
				template = SharedUI.paddingTemplate(4),
				content = tooltipContent,
			},
		}),
	}))

	self._tooltipContent = tooltipContent

	return self
end

function Tooltip:move(position)
	local layout = self:getLayout()
	layout.props.position = position + v2(0, 20)
	self:queueUpdate()
end

function Tooltip:getTooltipContent()
	return self._tooltipContent
end

return Tooltip
