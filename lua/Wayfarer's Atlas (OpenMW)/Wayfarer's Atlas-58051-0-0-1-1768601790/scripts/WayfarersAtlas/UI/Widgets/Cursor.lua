local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")

local UIObject = require("scripts/WayfarersAtlas/UI/UIObject")

local v2 = OMWUtil.vector2

---@class WAY.Cursor: WAY.UIObject
local Cursor = UIObject:extend("Cursor")

function Cursor.new()
	---@type WAY.Cursor
	return Cursor.bind(UI.create({
		layer = "Notification",
		type = UI.TYPE.Image,
		props = {
			size = v2(24, 24),
			visible = false,
		},
	}))
end

function Cursor:move(position)
	local props = self:getProps()
	props.position = position + v2(12, -4)

	self:queueUpdate()
end

function Cursor:changeIcon(texture)
	self:getProps().resource = texture
end

return Cursor
