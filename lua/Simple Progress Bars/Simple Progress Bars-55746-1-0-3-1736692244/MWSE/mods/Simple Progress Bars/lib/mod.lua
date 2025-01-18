local mod = {}

mod.init = function (MDIR)
	local i18n = require(MDIR .. ".lib.i18n")
	local info = require(MDIR .. ".modInfo")

	local data = json.loadfile("mods\\" .. MDIR .. "\\json\\data.json")
	local defaults = json.loadfile("mods\\" .. MDIR .. "\\json\\config.json")

	for id,i in pairs(data) do
		mod[id] = i
	end

	mod.id = info.mod
	mod.author = info.author
	mod.version = info.version

	mod.name = i18n("mod.name")
	mod.config = mwse.loadConfig(mod.id, defaults)

	return mod
end

return mod
