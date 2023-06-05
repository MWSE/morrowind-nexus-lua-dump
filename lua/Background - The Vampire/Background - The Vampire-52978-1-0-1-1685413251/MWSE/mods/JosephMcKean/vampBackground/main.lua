local charBackgrounds = include("mer.characterBackgrounds.interop")

local function onInitialized()
	charBackgrounds.addBackground {
		id = "jsmk_vamp",
		name = "Vampire",
		description = "You are a vampire, crawling in the dark, suffering the pangs of the relentless and terrible thirst for blood.\n\nYou start as a vampire\nThe game starts at nighttime.",
		doOnce = function()
			local vampClans = {
				{ name = "Aundae", startScript = "Vampire_Aundae_PC" },
				{ name = "Berne", startScript = "Vampire_Berne_PC" },
				{ name = "Quarra", startScript = "Vampire_Quarra_PC" },
			}
			--[[if tes3.isModActive("TR_Mainland.esm") then
				table.insert(vampClans, { name = "Baluath", startScript = "T_ScVamp_Baluath_PC" })
				table.insert(vampClans, { name = "Orlukh", startScript = "T_ScVamp_Orlukh_PC" })
			end]]
			local buttons = {
				{
					text = "Random",
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
			tes3ui.showMessageMenu({ id = "jsmk_vamp_choose", message = "Choose your vampire clan", buttons = buttons })

			tes3.worldController.hour.value = (tes3.worldController.weatherController.sunsetHour + 2) % 24
			tes3.worldController.weatherController:updateVisuals()
		end,
	}
end
event.register("initialized", onInitialized)
