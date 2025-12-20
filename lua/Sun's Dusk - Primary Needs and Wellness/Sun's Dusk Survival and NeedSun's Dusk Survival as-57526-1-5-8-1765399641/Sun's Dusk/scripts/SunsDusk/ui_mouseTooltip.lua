local makeBorder = require("scripts.SunsDusk.ui_makeborder")
local makeDescriptionTooltip = require("scripts.SunsDusk.ui_descriptionTooltip")
local BORDER_STYLE = "thin" --"none", "thin", "normal", "thick", "verythick"
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

return function (record, newValue, customName, qualityMult, count, enchantId, enchRemoveColor) --makeTooltip	
	local elem = makeDescriptionTooltip(record, newValue, customName, qualityMult, count, enchantId, enchRemoveColor)
	elem.template = borderTemplate
	elem = ui.create(elem)
	return elem
end