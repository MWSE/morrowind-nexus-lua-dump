local defaultConfig = {
	
	modEnabled = true,
    canLock = 25,
    canTrap = 50,
    sellTrapPanels = true,
    trapMerchant = {},
    stepTraps = {
	    se_trap_panel_cont = true
    }
}

for npc in tes3.iterateObjects(tes3.objectType.npc) do
	if npc.class.id == "Assassin Service" or npc.class.id == "Thief Service" then
		defaultConfig.trapMerchant[npc.id:lower()] = true
	end
end

local mwseConfig = mwse.loadConfig("Security Expertise", defaultConfig)

return mwseConfig