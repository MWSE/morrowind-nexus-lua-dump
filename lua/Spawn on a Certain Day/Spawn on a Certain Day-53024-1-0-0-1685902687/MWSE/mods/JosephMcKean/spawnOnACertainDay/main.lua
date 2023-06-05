event.register("charGenFinished", function()
	tes3.messageBox({
		message = "Start on a random day?",
		buttons = { "Yes", "No" },
		callback = function(e)
			if e.button == 0 then
				tes3.setGlobal("Month", math.random(0, 11))
				tes3.setGlobal("Day", math.random(1, 28))
				tes3.setGlobal("GameHour", math.random(0, 23))
				local weatherChances = tes3.getRegion().weatherChances
				if not weatherChances then return end
				for i = 1, 10 do
					if math.random(100) < weatherChances[i] then
						tes3.worldController.weatherController:switchImmediate(i - 1)
						tes3.worldController.weatherController:updateVisuals()
						break
					end
				end
			end
		end,
	})
end)

event.register("initialized", function() mwse.overrideScript("jsmk_scd", function() end) end)
