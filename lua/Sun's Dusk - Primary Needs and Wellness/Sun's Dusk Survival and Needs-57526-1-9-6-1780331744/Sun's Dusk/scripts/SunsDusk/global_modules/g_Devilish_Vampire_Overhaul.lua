if not core.contentFiles.has("Devilish_Vampire_Overhaul.esp") and not core.contentFiles.has("Devilish_Vampire_Overhaul.omwscripts") then return end

local SCRIPT_ID = "bloodthirst_dd_w"

local prevStatus = 0
local lastStage = 0

G_onUpdateJobs.vampire_drinkBlood = function(dt, now)
	local script = world.mwscript.getGlobalScript(SCRIPT_ID)
	if not script or not script.isRunning then return end

	local status = script.variables.status
	if status == 1 then
		lastStage = script.variables.doonce
	elseif prevStatus == 1 and status == 0 and script.variables.button == 0 then
		print("drank blood", lastStage )
		for _, player in pairs(world.players) do
			player:sendEvent("SunsDusk_Vampire_drankBlood", { stage = lastStage })
		end
	end
	prevStatus = status
end
