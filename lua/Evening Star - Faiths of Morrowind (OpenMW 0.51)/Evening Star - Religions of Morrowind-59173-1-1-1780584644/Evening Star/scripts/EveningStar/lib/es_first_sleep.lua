-- ------------------------------ Evening Star : first sleep prompt --------
-- once-per-playthrough nudge: after the player's first real sleep, if ct isn't installed and no deity is chosen,
-- show an intro and open deity selection.
-- the interactive message is a modal overlay (no ui mode) that pauses sim,
-- so we detect dismissal by watching sim time freeze then resume.

local INTRO_MSG =
	"Religion\n\n" ..
	"Most denizens of Tamriel are religious. You may choose to follow a deity, " ..
	"receiving a minor blessing and learning about their sacred tenets.\n\n" ..
	"(If you wish to follow a different deity later, find and activate their shrine in the world.)"

-- ------------------------------ dismissal poll ----------------------------

local prevSim  = nil
local sawPause = false

local function tickWaitForDismissal()
	local cur = core.getSimulationTime()
	if prevSim and cur <= prevSim then
		-- sim time frozen this frame -> message is up
		sawPause = true
	elseif sawPause then
		-- was frozen, now advancing -> player clicked ok
		G_onFrameJobs["es_first_sleep_tick"] = nil
		prevSim  = nil
		sawPause = false
		if ES.openDeityChoice then ES.openDeityChoice() end
		return
	end
	prevSim = cur
end

-- ------------------------------ trigger -----------------------------------
-- G_postSleepJobs fires after the rest cycle ends, which is after the LevelUp window closes (if any)

table.insert(G_postSleepJobs, function(slept)
	if not ES.S or not ES.S.TOGGLE_ENABLED then return end
	if slept < 1 then return end                    -- cancelled rest, not real sleep
	if not G_currentBed then return end             -- t-key waiting, not bed
	if ES.saveData.seenReligionPrompt then return end
	
	-- mark seen up front so we never re-trigger even if anything below fails
	ES.saveData.seenReligionPrompt = true
	
	if #ES.saveData.activeDeities > 0 then return end -- already worship someone
	
	prevSim  = core.getSimulationTime()
	sawPause = false
	I.UI.showInteractiveMessage(INTRO_MSG)
	G_onFrameJobs["es_first_sleep_tick"] = tickWaitForDismissal
end)

----local sawChargenReview = false
--G_onPlayerInfoChangedJobs.ES_showReligionPrompt = function(source)
--	if source == "chargen" and chargenFinished() then
--		local noUiSeconds = 0
--		G_onFrameJobs.ES_waitForChargenFinished = function(dt)
--			if dt == 0 or I.UI.getMode() or not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.ViewMode) then -- or not sawChargenReview then
--				noUiSeconds = 0
--			else
--				noUiSeconds = noUiSeconds + dt
--			end
--			if noUiSeconds > 0.5 then
--				G_onFrameJobs.ES_waitForChargenFinished = nil
--
--				if not ES.S.TOGGLE_ENABLED then return end
--				if ES.saveData.seenReligionPrompt then return end
--				if #ES.saveData.activeDeities > 0 then return end
--
--				ES.saveData.seenReligionPrompt = true
--				prevSim  = core.getSimulationTime()
--				sawPause = false
--				I.UI.showInteractiveMessage(INTRO_MSG)
--				G_onFrameJobs["es_first_sleep_tick"] = tickWaitForDismissal
--			end
--		end
--	end
--end

--table.insert(G_UiModeChangedJobs, function(data)
--	if not ES.S.TOGGLE_ENABLED then return end
--	if data.newMode == "ChargenClassReview" then
--		sawChargenReview = true
--	end
--end)