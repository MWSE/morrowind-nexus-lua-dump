--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Time Control - Messagebox Module                                    │
│  Custom messageboxes with smooth fade-out using onFrame              │
╰──────────────────────────────────────────────────────────────────────╯
]]

local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2

local M = {}

local messages = {}

local FADE_START = 1
local FADE_DURATION = 0.5
local PADDING_H = 12
local PADDING_V = 6
local MESSAGE_SPACING = 4
local BOTTOM_OFFSET = 100
local MAX_MESSAGES = 3

local function repositionMessages()
	local layerId = ui.layers.indexOf("HUD")
	local hudSize = ui.layers[layerId].size
	local yOffset = 0
	
	for i = #messages, 1, -1 do
		local msg = messages[i]
		yOffset = yOffset + msg.height
		msg.widget.layout.props.position = v2(hudSize.x / 2, hudSize.y - BOTTOM_OFFSET - yOffset)
		msg.widget:update()
		yOffset = yOffset + MESSAGE_SPACING
	end
end

local function show(element, options)
	options = options or {}
	
	if type(element) == "string" then
		element = {
			type = ui.TYPE.Text,
			props = {
				text = element,
				textSize = options.textSize or 16,
				textColor = options.textColor or TEXT_COLOR or util.color.hex("d4b77f"),
				textShadow = true,
				textShadowColor = util.color.rgb(0, 0, 0),
				autoSize = true,
			}
		}
	end
	
	local paddingH = options.paddingH or PADDING_H
	local paddingV = options.paddingV or PADDING_V
	local borderColor = options.borderColor or THEME_COLOR or util.color.rgb(1,1,1)
	
	local widget = ui.create({
		type = ui.TYPE.Container,
		layer = 'HUD',
		template = makeBorder("thin", borderColor, 1, {
			type = ui.TYPE.Image,
			props = {
				resource = getTexture('black'),
				relativeSize = v2(1, 1),
				alpha = 0.85,
			}
		}).borders,
		props = {
			autoSize = true,
			anchor = v2(0.5, 1),
			position = v2(0, 0),
		},
		content = ui.content{
			{
				type = ui.TYPE.Flex,
				props = { horizontal = true, autoSize = true },
				content = ui.content{
					{ type = ui.TYPE.Widget, props = { size = v2(paddingH, 0) } },
					{
						type = ui.TYPE.Flex,
						props = { horizontal = false, autoSize = true },
						content = ui.content{
							{ type = ui.TYPE.Widget, props = { size = v2(0, paddingV) } },
							element,
							{ type = ui.TYPE.Widget, props = { size = v2(0, paddingV) } },
						}
					},
					{ type = ui.TYPE.Widget, props = { size = v2(paddingH, 0) } },
				}
			}
		}
	})
	
	table.insert(messages, {
		widget = widget,
		age = 0,
		height = (options.textSize or 16) + (paddingV * 2) + 4,
	})
	
	while #messages > MAX_MESSAGES do
		messages[1].widget:destroy()
		table.remove(messages, 1)
	end
	
	repositionMessages()
end

local function onFrame(dt)
	if #messages == 0 then return end
	local timePassed = 0.05
	if core.getSimulationTimeScale() > 0 then 
		timePassed = core.getRealFrameDuration()/core.getSimulationTimeScale()
	end
	local removed = false
	for i = #messages, 1, -1 do
		local msg = messages[i]
		msg.age = msg.age + timePassed
		
		if msg.age > FADE_START then
			local alpha = math.max(0, 1 - (msg.age - FADE_START) / FADE_DURATION)
			msg.widget.layout.props.alpha = alpha
			msg.widget:update()
			
			if alpha <= 0 then
				msg.widget:destroy()
				table.remove(messages, i)
				removed = true
			end
		end
	end
	
	if removed then
		repositionMessages()
	end
end

local function clear()
	for _, msg in ipairs(messages) do
		msg.widget:destroy()
	end
	messages = {}
end

M.show = show
M.clear = clear
M.onFrame = onFrame

return M