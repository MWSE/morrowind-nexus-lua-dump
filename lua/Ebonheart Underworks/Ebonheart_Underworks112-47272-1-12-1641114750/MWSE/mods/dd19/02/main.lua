event.register('initialized', function ()
	local dd19rebirthConfig = tes3.findGlobal('dd19rebirthConfig')

	if not dd19rebirthConfig then
		return
	end

	event.register('loaded', function ()
		local scriptId = 'dd19_rebirthConfigScript'
		if mwscript.scriptRunning(scriptId) then
			mwscript.stopScript({script = scriptId})
		end

		if dd19rebirthConfig.value > 0.9 then
			return
		end

		-- uninitialized Ebonheart Underworks detected
		timer.start({duration = 15, callback = function ()
			local charGenState = tes3.worldController.charGenState

			local function simulate()
				if not ( math.floor(charGenState.value + 0.5) == -1) then
					---mwse.log("charGenState = %s", charGenState)
					return
				end
				local dd19rebirth = tes3.findGlobal('dd19rebirth')
				if dd19rebirth then
					if tes3.findGlobal('MR_RM_House') then -- Rebirth detected
						dd19rebirth.value = 1 -- set Ebonheart Underworks rebirth flag on
						---mwse.log('tes3.setGlobal("dd19rebirth", 1)')
					else
						dd19rebirth.value = 0 -- set Ebonheart Underworks rebirth flag off
						---mwse.log('tes3.setGlobal("dd19rebirth", 0)')
					end
				end
				local dd19rebirthConfig = tes3.findGlobal('dd19rebirthConfig')
				if dd19rebirthConfig then
					if dd19rebirthConfig.value == 0 then
						dd19rebirthConfig.value = 1 -- set Ebonheart Underworks configuration done
						local dd19noThief = tes3.findGlobal('dd19noThief')
						if dd19noThief then
							tes3.messageBox({
								message = "Ebonheart Underworks: do you want thief branch of multi branch quest even if you are not a Thieves Guild member?",
								buttons = { "No (default)", "Yes, gimme" },
								callback = function(e)
									dd19noThief.value = e.button -- 0 = disabled(default), 1 = enabled
								end
							})
						end
					end
				end
				event.unregister('simulate', simulate)
			end -- simulate()

			event.register('simulate', simulate)

	end -- callback
	})

	end) -- loaded function ()

end) -- initialized function ()
