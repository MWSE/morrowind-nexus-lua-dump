local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "UNINSTALL",
			name = "Uninstall",
			description = "Deletes all spawned ores and prevents spawning new ones\nYou have to be outside for this to work when toggling this option on!",
			renderer = "checkbox",
			default = false,
		},
		--{
		--	key = "NICE_EXTERIOR_SPAWNS",
		--	name = "Nice Exterior Spawns",
		--	description = "An extra raycast per ore to prevent weird rotations",
		--	renderer = "checkbox",
		--	default = true,
		--},
		{
			key = "VOLUME",
			name = "Volume",
			description = "of the pickaxe",
			renderer = "number",
			default = 0.9,
			argument = {
				min = 0,
				max = 1,
			},
		},
		{
			key = "INTERIOR_MULT",
			name = "Interior Ore Mult",
			description = "Amount scales with area size",
			renderer = "number",
			default = 1,
			argument = {
				min = 0,
				max = 10,
			},
		},
		{
			key = "EXTERIOR_NODES",
			name = "Exterior Ores per cell",
			description = "how many nodes on average?",
			renderer = "number",
			default = 2.8,
			argument = {
				min = 0,
				max = 100,
			},
		},
		
		
	}
}

local updateSettings = function (_,setting)
	--NICE_EXTERIOR_SPAWNS = playerSection:get("NICE_EXTERIOR_SPAWNS")
	UNINSTALL = playerSection:get("UNINSTALL")
	if playerSection:get("UNINSTALL") then
		core.sendGlobalEvent("SimplyMining_removeAllOres", self)
	end
	
end
playerSection:subscribe(async:callback(updateSettings))


I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = ""
}