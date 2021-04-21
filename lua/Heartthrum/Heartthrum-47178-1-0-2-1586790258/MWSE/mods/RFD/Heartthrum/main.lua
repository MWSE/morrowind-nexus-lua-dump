--Heartthrum
--by RedFurryDemon
--adds sound effect to the Heart of Lorkhan
--needs RFD_Heartthrum.esp active!

local TimerRunning = false
local HRTimer
--default heart rate is 20 bpm
local HR = 3
local sourcePos
local nukeHeartOnce = false
local checkPlayerCell
local CCRegistered = false

--5. stop the mod once the Heart is destroyed
local function silence()
	if (nukeHeartOnce == false) then
		HRTimer:cancel()
		event.unregister("cellChanged", checkPlayerCell)
		CCRegistered = false
		mwse.log("[Heartthrum] The Heart has been destroyed.")
		nukeHeartOnce = true
		TimerRunning = false
	end
end

--4. main part of the mod: calculate the volume based on PC's distance from the Heart and play sound; runs every time the timer calls it
local function calcDistance()
	if (tes3.getGlobal("HeartDestroyed") == 1) then
		silence()
 		return
	end
	if not tes3.getPlayerCell().isInterior then
		sourcePos = tes3.getReference("RFD Sound Heart ext").position:copy()
	else
		sourcePos = tes3.getReference("RFD Sound Heart").position:copy()
	end
	distance = tes3.player.position:distance(sourcePos)
	if distance < 35000 then
			vol = (math.remap (distance, 0, 35000, 1, 0))*3
			if tes3.getPlayerCell().isInterior then
				vol = vol*2
			end
			tes3.playSound{sound="RFD_HL_sound", volume=vol}
	end
end

--timer that runs constantly in-game until cancelled; periodically calls function calcDistance
local function runTimer()
	if TimerRunning then
		HRTimer = timer.start{duration=HR, iterations=0, type=timer.real, callback=calcDistance}
	end
end

--3. if in exterior cell, check distance to know when to get the timer running
local function checkWorldspace()
	sourcePos = tes3.getReference("RFD Sound Heart ext").position:copy()
	distance = tes3.player.position:distance(sourcePos)
	if distance < 40000 then
		if not TimerRunning then
			TimerRunning = true
			runTimer()
		end
	else
		if TimerRunning then
			TimerRunning = false
			HRTimer:cancel()
		end
	end
end

--2. this function is called on every cell change and after loading
checkPlayerCell = function()
	if tes3.getPlayerCell().isInterior then
		if (tes3.getPlayerCell().id:find("Dagoth Ur") or tes3.getPlayerCell().id:find("Akulakhan")) then
			--workaround for teleport/coc
			if not TimerRunning then
				TimerRunning = true
				runTimer()
			end
		else
			if TimerRunning then
				TimerRunning = false
				HRTimer:cancel()
			end
		end
	else
		checkWorldspace()
	end
end

--1.5. initialized and loaded are split in case the player destroys the Heart and then loads a different save
local function loaded()
	if (tes3.getGlobal("HeartDestroyed") == 0) then
		--reset the variables, since lua data doesn't persist between saves
		TimerRunning = false
		nukeHeartOnce = false
		checkPlayerCell()
		--don't register the event if it's already been registered!
		if (CCRegistered == false) then
			event.register("cellChanged", checkPlayerCell)
			CCRegistered = true
		end
		mwse.log("[Heartthrum] Loaded a game in which the Heart is still beating.")
	else
		mwse.log("[Heartthrum] Loaded a game in which the Heart has been destroyed.")
	end
end

--1. look for these stuff happening from the beginning, and run other functions when they happen
local function initialized()
	if not tes3.isModActive("RFD_Heartthrum.esp") then
		--comment out this warning if it annoys you, but I leave it uncommented by default for the casuals
		tes3.messageBox("[Heartthrum] RFD_Heartthrum.esp not loaded")
		return
	end
	event.register("loaded", loaded)
	mwse.log("[Heartthrum] initialized")
end

event.register("initialized", initialized)