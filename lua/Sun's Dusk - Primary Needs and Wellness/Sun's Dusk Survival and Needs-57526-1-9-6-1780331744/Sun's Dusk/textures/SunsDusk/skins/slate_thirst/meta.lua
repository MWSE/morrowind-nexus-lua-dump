-- Slate thirst skin: droplet glyph plaque with a gauge ring.
local lib = require("textures.sunsdusk.skins._slatelib")
return lib.makeSlateSkin{
	need = "thirst",
	name = "Slate",
	prefix = "thirst",
	colorKey = "T_COLOR",
	hideKey = "T_HIDE_NO_BUFF",
}
