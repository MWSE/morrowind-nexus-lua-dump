local function simulate()
	local charGenState = tes3.getGlobal("CharGenState")
	if not (charGenState == -1) then
		---mwse.log("charGenState = %s", charGenState)
		return
	end
	if tes3.getGlobal("dd19rebirth") then
		if tes3.getGlobal("MR_RM_House") then -- Rebirth detected
			tes3.setGlobal("dd19rebirth", 1) -- set Ebonheart Underworks rebirth flag on
			---mwse.log('tes3.setGlobal("dd19rebirth", 1)')
		else
			tes3.setGlobal("dd19rebirth", 0) -- set Ebonheart Underworks rebirth flag off
			---mwse.log('tes3.setGlobal("dd19rebirth", 0)')
		end
	end
	if tes3.getGlobal("dd19rebirthConfig") == 0 then
		tes3.setGlobal("dd19rebirthConfig", 1) -- set Ebonheart Underworks configuration done
		if tes3.getGlobal("dd19noThief") then
			tes3.messageBox({
				message = "Ebonheart Underworks: do you want thief branch of multi branch quest even if you are not a Thieves Guild member?",
				buttons = { "No (default)", "Yes, gimme" },
				callback = function(e)
					tes3.setGlobal("dd19noThief", e.button) -- 0 = disabled(default), 1 = enabled
				end
			})
		end
	end
	event.unregister("simulate", simulate)
end

local function delayedRegister()
	event.register("simulate", simulate)
end

local function loaded()
	if tes3.getGlobal("dd19rebirthConfig") == 0 then  -- uninitialized Ebonheart Underworks detected
		timer.start({duration = 15, iterations = 1, callback = delayedRegister})
	end
	if mwscript.scriptRunning("dd19_rebirthConfigScript") then
		mwscript.stopScript({script = "dd19_rebirthConfigScript"})
	end
end
event.register("loaded", loaded)
