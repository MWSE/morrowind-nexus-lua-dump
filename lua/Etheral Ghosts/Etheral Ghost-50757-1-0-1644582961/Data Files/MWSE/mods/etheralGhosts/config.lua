local defaultConfig = {
	modEnabled = true,
	ghosts = {}
}

for obj in tes3.iterateObjects(tes3.objectType.creature) do
	local id = obj.id:lower()
	if string.multifind(id, {"ghost", "ancestor_guardian", "spectre", "welkspr", "und_ghst", "und_wrth"}) then
		defaultConfig.ghosts[id] = true
	end
end

local mwseConfig = mwse.loadConfig("etheralGhosts", defaultConfig)

return mwseConfig;
