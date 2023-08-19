local mod = { name = "Playable Heads Whitelister" }

local defaults = {
	whitelist = {
		["morrowind.esm"] = true,
		["tribunal.esm"] = true,
		["bloodmoon.esm"] = true,
		["tamriel_data.esm"] = true,
		["oaab_data.esm"] = true,
		["vanilla friendly wearables expansion.esm"] = true,
		["rp_louis beauchamp.esp"] = true,
	},
}

---@class playableHeadsWhitelister.config
---@field whitelist table<string, boolean>
local config = mwse.loadConfig(mod.name, defaults)

local isVanillaRace = {
	["Argonian"] = true,
	["Breton"] = true,
	["Dark Elf"] = true,
	["High Elf"] = true,
	["Imperial"] = true,
	["Khajiit"] = true,
	["Nord"] = true,
	["Orc"] = true,
	["Redguard"] = true,
	["Wood Elf"] = true,
}

event.register("initialized", function()
	---@param bodyPart tes3bodyPart
	for bodyPart in tes3.iterateObjects(tes3.objectType.bodyPart) do
		if bodyPart.partType == tes3.activeBodyPartLayer.base then
			if (bodyPart.part == tes3.partIndex.head) or (bodyPart.part == tes3.partIndex.hair) then
				if bodyPart.playable then if isVanillaRace[bodyPart.raceName] then if not config.whitelist[bodyPart.sourceMod:lower()] then bodyPart.playable = false end end end
			end
		end
	end
end)
