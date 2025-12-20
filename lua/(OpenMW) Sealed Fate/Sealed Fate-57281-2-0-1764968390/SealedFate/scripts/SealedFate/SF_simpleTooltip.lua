-- ╭──────────────────────────╮
-- │  Borders and tooltips	  │
-- ╰──────────────────────────╯
local MOUSE_TOOLTIP_FONT_SIZE = 16
local MOUSE_TOOLTIP_FONT_COLOR = util.color.hex("dfc99f")
local makeBorder = require("scripts.SealedFate.ui_makeborder")
local BORDER_STYLE = "thin" --"none", "thin", "normal", "thick", "verythick"
local background  = ui.texture { path = 'black' }
local borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
local borderFile = "thin"
if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
	borderFile = "thick"
end
local OPACITY = 0.8

local borderTemplate = makeBorder(borderFile, borderColor or nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = background,
		relativeSize = v2(1, 1),
		alpha = OPACITY,
	}
}).borders

-- mouse tooltip
local function makeMouseTooltip(position, text)
	local layerId = ui.layers.indexOf("Notification")
	local G_hudLayerSize = ui.layers[layerId].size
	
	-- Determine anchor and offset based on mouse position
	local anchorX, offsetX
	local anchorY, offsetY
	
	-- Horizontal positioning
	if position.x < G_hudLayerSize.x / 2 then
		-- Left side: anchor left, offset right
		anchorX = 0
		offsetX = 4
	else
		-- Right side: anchor right, offset left
		anchorX = 1
		offsetX = -4
	end
	
	-- Vertical positioning
	if position.y < G_hudLayerSize.y / 2 then
		-- Top side: anchor top, offset down
		anchorY = 0
		offsetY = 4
	else
		-- Bottom side: anchor bottom, offset up
		anchorY = 1
		offsetY = -4
	end
	
	local elem = ui.create{
		type = ui.TYPE.Text,
		layer = 'Notification',
		name = uiElementName,
		template = borderTemplate,
		props = {
			text = text,
			textSize = MOUSE_TOOLTIP_FONT_SIZE,
			textColor = MOUSE_TOOLTIP_FONT_COLOR,
			anchor = v2(anchorX, anchorY),
			multiline = true,
			position = v2(position.x + offsetX, position.y + offsetY),
		},
		userData = {
			offset = v2(offsetX, offsetY),
		}
	}
	return elem
end

return function (element, textFunction)
	
	element.layout.events = element.layout.events or {}
	local events = element.layout.events
	
	local existingFocusGain = events.focusGain
	local existingFocusLoss = events.focusLoss
	local existingMouseMove = events.mouseMove

	
	events.focusGain = async:callback(function(data, elem)
		if not mouseTooltip and currentDangerLevel~= 0 then
			mouseTooltip = makeMouseTooltip(v2(500,500), textFunction())
		end
		if existingFocusGain then existingFocusGain(data, elem) end
	end)
	
	events.focusLoss = async:callback(function(data, elem)
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
		if existingFocusLoss then existingFocusLoss(data, elem) end
	end)
	
	events.mouseMove = async:callback(function(data, elem)
		if mouseTooltip then
			mouseTooltip.layout.props.position = v2(
				data.position.x + mouseTooltip.layout.userData.offset.x,
				data.position.y + mouseTooltip.layout.userData.offset.y
			)
			mouseTooltip:update()
		end
		if existingMouseMove then existingMouseMove(data, elem) end
	end)
end