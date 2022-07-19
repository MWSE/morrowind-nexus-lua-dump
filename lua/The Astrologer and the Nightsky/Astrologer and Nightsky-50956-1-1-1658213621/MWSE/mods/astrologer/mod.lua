local seph = require("seph")

local mod = seph.Mod()

mod.id = "astrologer"
mod.name = "The Astrologer and the Nightsky"
mod.description = [[
The Astrologer looks up to the sky to find out his fate daily (Divination Power). The Night Sky is influenced by the dominant constellation every month and enjoys superior luck.
]]
mod.author = "Danae & Sephumbra"
mod.hyperlink = ""
mod.version = {major = 1, minor = 0, patch = 0}
mod.requiredPlugins = {
	"astrologer and nightsky.esp"
}
mod.requiredModules = {
	"class",
	"birthsign",
	"power"
}

return mod