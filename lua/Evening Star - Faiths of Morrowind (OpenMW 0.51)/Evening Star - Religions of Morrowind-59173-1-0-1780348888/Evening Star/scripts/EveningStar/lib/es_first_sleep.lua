-- ------------------------------ Evening Star : first sleep prompt --------
-- once-per-playthrough nudge: after the player's first real sleep in a bed
-- or bedroll, if character traits framework isn't installed and no deity
-- has been chosen, show an intro message and then open the full interactive
-- deity selection.
--
-- the interactive message doesn't push a ui mode -- it's a modal overlay
-- handled by the engine that pauses simulation. we detect dismissal by
-- watching simulation time: it freezes while the message is up and resumes
-- when the player clicks OK.

local esCtInterop = require('scripts.EveningStar.lib.es_ct_interop')

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
-- G_postSleepJobs fires after the rest cycle ends, which is after the
-- LevelUp window closes (if any) -- newMode hits nil only then.

table.insert(G_postSleepJobs, function(slept)
	if not ES.S or not ES.S.TOGGLE_ENABLED then return end
	if slept < 1 then return end                    -- cancelled rest, not real sleep
	if not G_currentBed then return end             -- t-key waiting, not bed
	if ES.saveData.seenReligionPrompt then return end
	
	-- mark seen up front so we never re-trigger even if anything below fails
	ES.saveData.seenReligionPrompt = true
	
	if esCtInterop.isInstalled() then return end    -- ct framework drives chargen
	if ES.saveData.currentDeity then return end     -- already chose at a shrine
	
	prevSim  = core.getSimulationTime()
	sawPause = false
	I.UI.showInteractiveMessage(INTRO_MSG)
	G_onFrameJobs["es_first_sleep_tick"] = tickWaitForDismissal
end)