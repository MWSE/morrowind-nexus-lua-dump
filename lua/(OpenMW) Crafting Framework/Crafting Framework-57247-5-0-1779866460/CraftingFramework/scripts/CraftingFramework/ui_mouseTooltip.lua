local makeBorder = require("scripts.CraftingFramework.ui_makeborder") 
local BORDER_STYLE = "thin" -- options: none, thin, normal, thick, verythick
local background = ui.texture { path = 'black' }
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
		relativeSize  = v2(1,1),
		alpha = OPACITY,
	}
}).borders



-- accepts the same opts table as makeDescriptionTooltip, or positional args.
-- wraps the description tooltip with padding; border rides the outer Flex.
return function (record, newValue, customName, qualityMult, count, enchantId, enchRemoveColor)
	local inner
	if type(record) == "table" and record.record then
		inner = makeDescriptionTooltip(record)
	else
		inner = makeDescriptionTooltip(record, newValue, customName, qualityMult, count, enchantId, enchRemoveColor)
	end
	return ui.create{
		type = ui.TYPE.Flex,
		layer = 'Notification',
		template = borderTemplate,
		props = {
			autoSize = true,
		},
		content = ui.content {
			{ props = { size = v2(1, 1) } },
			{
				type = ui.TYPE.Flex,
				props = { horizontal = true },
				content = ui.content {
					{ props = { size = v2(2, 2) } },
					inner,
					{ props = { size = v2(2, 2) } },
				},
			},
			{ props = { size = v2(2, 2) } },
		},
	}
end