--[[
	Kogoruhn Expanded
	By Team Drama Kwama
--]]


if (mwse.buildDate == nil) or (mwse.buildDate < 20181013) then
	local function warning()
		tes3.messageBox(
			"[Kogoruhn Expanded] Your MWSE is out of date!"
			.. " You will need to update to a more recent version to use this mod."
		)
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end


-----------------
-- KOGORUHN AI --
-----------------
local kogoruhnCells
local kogoruhnResidents

local function initializeKogoruhn()
	kogoruhnCells = {
		-- exterior cells
		[tes3.getCell{x = -1, y = 15}] = true,
		[tes3.getCell{x = -1, y = 14}] = true,
		[tes3.getCell{x = -1, y = 13}] = true,
		[tes3.getCell{x =  0, y = 15}] = true,
		[tes3.getCell{x =  0, y = 14}] = true,
		[tes3.getCell{x =  0, y = 13}] = true,
		[tes3.getCell{x =  1, y = 15}] = true,
		[tes3.getCell{x =  1, y = 14}] = true,
		[tes3.getCell{x =  1, y = 13}] = true,
		-- interior cells
		[tes3.getCell{id = "kogoruhn, bleeding heart"}] = true,
		[tes3.getCell{id = "kogoruhn, charma's breath"}] = true,
		[tes3.getCell{id = "kogoruhn, dome of pollock's eve"}] = true,
		[tes3.getCell{id = "kogoruhn, dome of urso"}] = true,
		[tes3.getCell{id = "kogoruhn, eye of malis"}] = true,
		[tes3.getCell{id = "kogoruhn, hall of maki"}] = true,
		[tes3.getCell{id = "kogoruhn, hall of phisto"}] = true,
		[tes3.getCell{id = "kogoruhn, hall of the watchful touch"}] = true,
		[tes3.getCell{id = "kogoruhn, hall of toro"}] = true,
		[tes3.getCell{id = "kogoruhn, mangers of slumbering flesh"}] = true,
		[tes3.getCell{id = "kogoruhn, nabith waterway"}] = true,
		[tes3.getCell{id = "kogoruhn, sonorous knell"}] = true,
		[tes3.getCell{id = "kogoruhn, temple of fey"}] = true,
		[tes3.getCell{id = "kogoruhn, vault of aerode"}] = true,
	}
	kogoruhnResidents = {
		[tes3.getObject("ascended_sleeper")] = true,
		[tes3.getObject("ash_ghoul")] = true,
		[tes3.getObject("ash_slave")] = true,
		[tes3.getObject("ash_zombie")] = true,
		[tes3.getObject("corprus_lame")] = true,
		[tes3.getObject("corprus_stalker")] = true,
		[tes3.getObject("dagoth baler")] = true,
		[tes3.getObject("dagoth daynil")] = true,
		[tes3.getObject("dagoth delnus")] = true,
		[tes3.getObject("dagoth elam")] = true,
		[tes3.getObject("dagoth fervas")] = true,
		[tes3.getObject("dagoth girer")] = true,
		[tes3.getObject("dagoth ralas")] = true,
		[tes3.getObject("dagoth reler")] = true,
		[tes3.getObject("dagoth ulen")] = true,
		[tes3.getObject("dagoth uthol")] = true,
		[tes3.getObject("dagoth uvil")] = true,
		[tes3.getObject("dreamer")] = true,
	}
end

local function updateFightLevels()
	local index = tes3.getJournalIndex{id="DK_TheStranger"}

	local fight = 0
	if (index >= 75) or (index < 30) then
		fight = 100
	end

	for ref in tes3.getPlayerCell():iterateReferences() do
		local obj = ref.object.baseObject or ref.object
		if kogoruhnResidents[obj] then
			ref.mobile.fight = fight
			ref.mobile.hello = 0
		end
	end
end

local function combatStarted(e)
	local index = tes3.getJournalIndex{id="DK_TheStranger"}
	if index < 35 then
		-- quest not active
		return
	end

	if index >= 75 then
		event.unregister("combatStarted", combatStarted)
		return
	end

	local ref = e.target.reference
	local obj = ref.object.baseObject or ref.object
	if kogoruhnResidents[obj] then
		tes3.updateJournal{id="DK_TheStranger", index=75}
		updateFightLevels()
	end
end
-----------------


--------------------
-- SHADER CONTROL --
--------------------
local shakeRange = {shader="Disorient", max=18.0, variable="srange"}
local shakeSpeed = {shader="Disorient", max=0.16, variable="sspeed"}
local visionOffset = {shader="Disorient", max=0.12, variable="offset"}
local visionIntensity = {shader="Disorient", max=16.0, variable="intensity"}

local function resetShader(scale)
	shakeRange.value = shakeRange.max * scale
	shakeSpeed.value = shakeSpeed.max * scale
	visionOffset.value = visionOffset.max * scale
	visionIntensity.value = visionIntensity.max * scale
end

local function updateShader()
	mge.setShaderFloat(shakeRange)
	mge.setShaderFloat(shakeSpeed)
	mge.setShaderFloat(visionOffset)
	mge.setShaderFloat(visionIntensity)
	shakeRange.value = math.max(0, shakeRange.value - shakeRange.max/300)
	shakeSpeed.value = math.max(0, shakeSpeed.value - shakeSpeed.max/300)
	visionOffset.value = math.max(0, visionOffset.value - visionOffset.max/300)
	visionIntensity.value = math.max(0, visionIntensity.value - visionIntensity.max/300)
end
--------------------


------------------
-- BELL EFFECTS --
------------------
local bellTimer
local bellPosition
local bellShaderTimer

local function triggerBell()
	local distance = 0
	if not tes3.getPlayerCell().isInterior then
		distance = tes3.player.position:distance(bellPosition)
	end

	-- play scaled bell sounds
	local normalized = math.remap(distance, 0, 16384, 1, 0)
	tes3.playSound{reference=tes3.player, sound="dk_bell_sound", volume=normalized, mixChannel=0, pitch=0.8}

	-- allow statue reductions
	if mwscript.getItemCount{reference=tes3.player, item="misc_6th_ash_statue_01"} > 0 then
		normalized = normalized * 0.85
	end

	-- tes3.messageBox("triggerBell[distance = %.2f, normalized = %.2f]", distance, normalized)

	-- start the shader effect
	resetShader(normalized)
	bellShaderTimer:reset()
	bellShaderTimer:resume()

	-- apply damage when close
	if normalized >= 0.75 then
		tes3.modStatistic{reference=tes3.player, name="health", current=(-18 * normalized)}
		tes3.fadeIn{fader=tes3.worldController.hitFader, duration=3.0}
	end
end

local function enterKogoruhn(cell)
	event.unregister("combatStarted", combatStarted)
	event.register("combatStarted", combatStarted)

	-- don't do any thing else if the bell ringer is already dead
	if tes3.getGlobal("dk_bell_ringer_dead") == 1 then return end

	-- get the positions to be used for all distance-based effects
	if cell.isInterior then
		bellPosition = tes3.player.position
	else
		bellPosition = tes3.getReference("dk_6th_bell_tower_m").position
	end

	-- create shader timer that will be triggered on each bell tick
	bellShaderTimer = timer.start{duration=0.01, iterations=300, type=timer.simulate, callback=updateShader}
	bellShaderTimer:pause()

	-- create the bell timer which triggers the sounds/shaders/etc
	bellTimer = timer.start{duration=5.5, iterations=0, type=timer.simulate, callback=triggerBell}
	triggerBell()

	mge.enableShader{shader="Disorient"}
end

local function leaveKogoruhn(cell)
	event.unregister("combatStarted", combatStarted)

	bellPosition = nil

	if bellTimer then
		bellTimer:cancel()
		bellTimer = nil
	end

	if bellShaderTimer then
		bellShaderTimer:cancel()
		bellShaderTimer = nil
	end

	mge.disableShader{shader="Disorient"}
end
------------------


-------------
-- SCRIPTS --
-------------
local function createOverrides()
	mwse.overrideScript("dk_bell_ringer_death_s", function(e)
		mwscript.stopScript{script="dk_bell_ringer_death_s"}
		mge.disableShader{shader="Disorient"}
		bellShaderTimer:cancel()
		bellTimer:cancel()
	end)
	mwse.overrideScript("dk_bell_ringer_start_s", function(e)
		mwscript.stopScript{script="dk_bell_ringer_start_s"}
		event.unregister("attack", triggerBell, {filter = e.reference})
		event.register("attack", triggerBell, {filter = e.reference})
		bellTimer:pause()
	end)
	mwse.overrideScript("dk_remove_legs_lua", function(e)
		mwscript.stopScript{script="dk_remove_legs_lua"}
		tes3.player.sceneNode:getObjectByName("Bip01 L Calf").appCulled = true
		tes3.player.sceneNode:getObjectByName("Bip01 R Calf").appCulled = true
	end)
	mwse.overrideScript("dk_remove_arms_lua", function(e)
		mwscript.stopScript{script="dk_remove_arms_lua"}
		tes3.player.sceneNode:getObjectByName("Bip01 L Forearm").appCulled = true
		tes3.player.sceneNode:getObjectByName("Bip01 R Forearm").appCulled = true
		tes3.player.sceneNode:getObjectByName("Right Hand").appCulled = true
		tes3.player.sceneNode:getObjectByName("Left Hand").appCulled = true
	end)
	mwse.overrideScript("dk_halve_current_hp", function(e)
		mwscript.stopScript{script="dk_halve_current_hp"}
		local health = tes3.mobilePlayer.health.current
		tes3.setStatistic{reference=tes3.player, name="health", current=health/2}
		tes3.playSound{reference=e.reference, sound="Critical Damage", volume=1.0}
		tes3.fadeIn{fader=tes3.worldController.hitFader, duration=8.0}
	end)
	mwse.overrideScript("dk_kogoruhn_aggro", function(e)
		mwscript.stopScript{script="dk_kogoruhn_aggro"}
		if tes3.getJournalIndex{id="DK_TheStranger"} < 75 then
			tes3.updateJournal{id="DK_TheStranger", index=75}
		end
		updateFightLevels()
	end)
end
---------------


------------
-- EVENTS --
------------
local function loaded(e)
	-- make extra sure the shader is properly updated
	timer.start{
		duration = 0.1,
		iterations = 10,
		type = timer.simulate,
		callback = function()
			if kogoruhnCells[tes3.getPlayerCell()] then
				mge.enableShader{shader="Disorient"}
			else
				mge.disableShader{shader="Disorient"}
			end
			resetShader(0)
			updateShader()
		end,
	}
end

local function cellChanged(e)
	local isKogoruhn = kogoruhnCells[e.cell]
	local wasKogoruhn = e.previousCell and kogoruhnCells[e.previousCell]

	if isKogoruhn and not wasKogoruhn then
		enterKogoruhn(e.cell)
	elseif wasKogoruhn and not isKogoruhn then
		leaveKogoruhn(e.cell)
	end

	if isKogoruhn then
		updateFightLevels()
	end
end

local function initialized(e)
	if not tes3.isModActive("KogoruhnExpanded.esp") then return end

	-- events
	event.register("loaded", loaded)
	event.register("cellChanged", cellChanged)

	-- others
	initializeKogoruhn()
	createOverrides()

	mwse.log("[Kogoruhn Expanded] Initialized Version 1.0")
end
event.register("initialized", initialized)
------------

