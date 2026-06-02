local config = require("TamrielRebuilt.config")
local getActivePlugin = require("TamrielRebuilt.firemoth")

if config.firemothWarning == true then
	event.register(tes3.event.initialized, function()
		if tes3.isModActive("TR_Mainland.esm") and not tes3.isModActive("TR_Firemoth_remover.esp") then
			local firemothPlugin = getActivePlugin(tes3.isModActive)

			if firemothPlugin then
				tes3ui.showNotifyMenu("Tamriel Rebuilt содержит собственную улучшенную версию мода \"Осада Форта Огненной Бабочки\" (Siege at Firemoth) и его квестов, которая несовместима с другими модами, добавляющими или изменяющими Форт Огненой Бабочки." .. 
										" Пожалуйста отключите \"" .. firemothPlugin .. "\", или используйте плагин \"Firemoth remover\", представленный на странице Nexus и сайте Tamriel Rebuilt, или используйте патч, созданный специально для используемого вами мода Firemoth, если он существует.")
			end
		end
	end)
end

-- Setup MCM
dofile("TamrielRebuilt.mcm")