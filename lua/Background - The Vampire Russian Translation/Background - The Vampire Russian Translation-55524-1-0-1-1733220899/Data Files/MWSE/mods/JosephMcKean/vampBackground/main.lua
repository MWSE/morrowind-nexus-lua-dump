local charBackgrounds = include("mer.characterBackgrounds.interop")

local function onInitialized()
	charBackgrounds.addBackground {
		id = "jsmk_vamp",
		name = "Вампир",
		description = "Вы - вампир, крадущийся во тьме, страдающий от мук неутолимой и ужасной жажды крови.\n\nВы начинаете игру вампиром.\nИгра начинается в вечернее время.",
		doOnce = function()
			local vampClans = {
				{ name = "Аунда", startScript = "Vampire_Aundae_PC" },
				{ name = "Берне", startScript = "Vampire_Berne_PC" },
				{ name = "Куарра", startScript = "Vampire_Quarra_PC" },
			}
			--[[if tes3.isModActive("TR_Mainland.esm") then
				table.insert(vampClans, { name = "Baluath", startScript = "T_ScVamp_Baluath_PC" })
				table.insert(vampClans, { name = "Orlukh", startScript = "T_ScVamp_Orlukh_PC" })
			end]]
			local buttons = {
				{
					text = "Случайный",
					callback = function(e)
						local clanData = table.choice(vampClans)
						---@diagnostic disable-next-line: deprecated
						mwscript.startScript({ script = clanData.startScript })
					end,
				},
			}
			for _, clanData in ipairs(vampClans) do
				table.insert(buttons, {
					text = clanData.name,
					callback = function(e)
						---@diagnostic disable-next-line: deprecated
						mwscript.startScript({ script = clanData.startScript })
					end,
				})
			end
			tes3ui.showMessageMenu({ id = "jsmk_vamp_choose", message = "Выберите клан вампиров", buttons = buttons })

			tes3.worldController.hour.value = (tes3.worldController.weatherController.sunsetHour + 2) % 24
			tes3.worldController.weatherController:updateVisuals()
		end,
	}
end
event.register("initialized", onInitialized)
