local config = require("TamrielRebuilt.config")

if config.firemothWarning == true then
	event.register(tes3.event.initialized, function()
		if tes3.isModActive("TR_Mainland.esm") and not tes3.isModActive("TR_Firemoth_remover.esp") then
			local firemothPlugin
			
			if tes3.isModActive("Siege at Firemoth.esp") then
				firemothPlugin = "Siege at Firemoth.esp"
			elseif tes3.isModActive("LegionAtFiremoth.esp") then
				firemothPlugin = "LegionAtFiremoth.esp"
			elseif tes3.isModActive("FiremothReclaimed.esp") then
				firemothPlugin = "FiremothReclaimed.esp"
			elseif tes3.isModActive("OfficialMods_v5.esp") then
				firemothPlugin = "OfficialMods_v5.esp"
			elseif tes3.isModActive("Unofficial Morrowind Official Plugins Patched.esp") then
				firemothPlugin = "Unofficial Morrowind Official Plugins Patched.esp"
			elseif tes3.isModActive("Ogg Fort Firemoth Manor.esp") then
				firemothPlugin = "Ogg Fort Firemoth Manor.esp"
			end

			if firemothPlugin then
				tes3ui.showNotifyMenu("Tamriel Rebuilt contains its own improved version of Fort Firemoth and its quests, which is incompatible with other plugins that add or modify the Siege of Firemoth." .. 
										" Please either deactivate \"" .. firemothPlugin .. "\", use the Firemoth remover plugin provided on Tamriel Rebuilt's Nexus page and website, or use a patch made specifically for your preferred Firemoth mod if it exists.")
			end
		end
	end)
end

-- Setup MCM
dofile("TamrielRebuilt.mcm")