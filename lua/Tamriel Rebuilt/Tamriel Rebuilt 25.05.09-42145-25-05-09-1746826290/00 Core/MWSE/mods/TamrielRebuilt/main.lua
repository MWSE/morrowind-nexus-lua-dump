local config = require("TamrielRebuilt.config")
local getActivePlugin = require("TamrielRebuilt.firemoth")

if config.firemothWarning == true then
	event.register(tes3.event.initialized, function()
		if tes3.isModActive("TR_Mainland.esm") and not tes3.isModActive("TR_Firemoth_remover.esp") then
			local firemothPlugin = getActivePlugin(tes3.isModActive)

			if firemothPlugin then
				tes3ui.showNotifyMenu("Tamriel Rebuilt contains its own improved version of Fort Firemoth and its quests, which is incompatible with other plugins that add or modify the Siege of Firemoth." .. 
										" Please either deactivate \"" .. firemothPlugin .. "\", use the Firemoth remover plugin provided on Tamriel Rebuilt's Nexus page and website, or use a patch made specifically for your preferred Firemoth mod if it exists.")
			end
		end
	end)
end

-- Setup MCM
dofile("TamrielRebuilt.mcm")