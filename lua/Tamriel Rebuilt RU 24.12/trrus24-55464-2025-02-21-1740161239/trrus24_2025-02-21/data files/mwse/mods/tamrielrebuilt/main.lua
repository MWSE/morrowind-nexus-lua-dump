local config = require("TamrielRebuilt.config")

event.register(tes3.event.initialized, function()
	if config.firemothWarning == true and tes3.isModActive("TR_Mainland.esm") and not tes3.isModActive("TR_Firemoth_remover.esp") then
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
			tes3ui.showNotifyMenu("Tamriel Rebuilt содержит собственную улучшенную версию мода \"Осада Форта Огненной Бабочки\" (Siege at Firemoth) и его квестов, которая несовместима с другими модами, добавляющими или изменяющими Форт Огненой Бабочки." .. 
									" Пожалуйста отключите \"" .. firemothPlugin .. "\", или используйте плагин \"Firemoth remover\", представленный на странице Nexus и сайте Tamriel Rebuilt, или используйте патч, созданный специально для используемого вами мода Firemoth, если он существует.")
		end
	end
end)

-- Setup MCM
dofile("TamrielRebuilt.mcm")