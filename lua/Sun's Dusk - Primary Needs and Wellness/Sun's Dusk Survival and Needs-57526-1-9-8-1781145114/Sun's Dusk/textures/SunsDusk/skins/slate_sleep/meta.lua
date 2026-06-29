-- Slate sleep skin: crescent glyph plaque with a gauge ring and the sleeping-profile badge.
local lib = require("textures.sunsdusk.skins._slatelib")
return lib.makeSlateSkin{
	need = "sleep",
	name = "Slate",
	prefix = "sleep",
	colorKey = "S_COLOR",
	hideKey = "S_HIDE_NO_BUFF",
	profileField = "sleepingProfile",
	-- insomniac replaces the tiredness icon entirely, matching the legacy staged path
	primaryProfiles = { insomniac = true },
}
