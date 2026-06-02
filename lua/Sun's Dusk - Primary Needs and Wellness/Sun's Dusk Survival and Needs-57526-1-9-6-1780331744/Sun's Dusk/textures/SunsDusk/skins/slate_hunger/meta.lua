-- Slate hunger skin: fork/knife glyph plaque with a gauge ring and the food-profile badge.
local lib = require("textures.sunsdusk.skins._slatelib")
return lib.makeSlateSkin{
	need = "hunger",
	name = "Slate",
	prefix = "hunger",
	colorKey = "H_COLOR",
	hideKey = "H_HIDE_NO_BUFF",
	profileField = "foodProfile",
}
