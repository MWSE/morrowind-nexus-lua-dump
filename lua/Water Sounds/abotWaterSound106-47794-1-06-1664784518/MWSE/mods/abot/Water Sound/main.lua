-- begin tweakables
local slowPlayerInFakeWater = 2 -- 0 = disable slowing player in fake water, 1 = slow while walking/running, 2 = slow also while flying
local includeActivators = true -- set it to false to disable detection of activators
local minDepth = 48 -- Minimum depth to trigger sounds
local waterLayerVolume = 0.8 -- fake water layer sound volume. Default 0.8 0 = disabled
local underwaterVolume = 0.8 -- fake water dive sound volume. Default 0.8 0 = disabled
-- end tweakables

local author = 'abot'
local modName = 'Water Sound'
local modPrefix = author .. '/' .. modName

-- begin set in loaded()
local player
local mobilePlayer
local t1
local t2
local AO_PCBeastRace -- MAO global short https://www.nexusmods.com/morrowind/mods/46310
local depth
-- end set in loaded()

local AO_PCrunning = 0 -- updated in stopMAOscript()

local function swapSound(oldSound, newSound)
	if tes3.getSoundPlaying({sound = oldSound, reference = player}) then
		mwscript.stopSound({sound = oldSound})
		mwscript.stopSound({reference = player, sound = oldSound})
		mwscript.stopSound({reference = player, sound = newSound})
		tes3.playSound({sound = newSound, reference = player})
		return true
	end
	return false
end

local function stoppedSound(oldSound)
	if tes3.getSoundPlaying({sound = oldSound, reference = player}) then
		mwscript.stopSound({sound = oldSound})
		mwscript.stopSound({reference = player, sound = oldSound})
		return true
	end
	return false
end

local tes3_objectType_armor = tes3.objectType.armor
local armorSlot -- set in loaded()

local function simulateWaterSound()
	local newSound = 'DefaultLandWater'

	if swapSound('DefaultLand', newSound) then
		return
	end

	if swapSound('Body Fall Medium', newSound) then
		return
	end

	local snd = 0

	local equippedArmor = tes3.getEquippedItem({actor = player, objectType = tes3_objectType_armor, slot = armorSlot })
	if equippedArmor then
		local armorWeightClass = equippedArmor.object.weightClass
		if armorWeightClass == 0 then
			if stoppedSound('FootLightLeft') then
				snd = 1
			elseif stoppedSound('FootLightRight') then
				snd = 2
			end
		elseif armorWeightClass == 1 then
			if stoppedSound('FootMedLeft') then
				snd = 1
			elseif stoppedSound('FootMedRight') then
				snd = 2
			end
		elseif armorWeightClass == 2 then
			if stoppedSound('FootHeavyLeft') then
				snd = 1
			elseif stoppedSound('FootHeavyRight') then
				snd = 2
			end
		end
	end

	if snd == 0 then
		if stoppedSound('FootBareLeft') then
			snd = 1
		elseif stoppedSound('FootBareRight') then
			snd = 2
		end
	end

	---mwse.log("simulateWaterSound() armorWeightClass = %s, snd = %s", armorWeightClass, snd)

	if snd == 1 then
		newSound = 'Swim Left'
	elseif snd == 2 then
		newSound = 'Swim Right'
	end
	if snd > 0 then
		mwscript.stopSound({sound = newSound})
		mwscript.stopSound({reference = player, sound = newSound})
		tes3.playSound({reference = player, sound = newSound})
	end

	if underwaterVolume > 0 then
		newSound = 'Underwater'
		if depth > 140 then
			if not tes3.getSoundPlaying({sound = newSound, reference = player}) then
				tes3.playSound({sound = newSound, reference = player, loop = true, volume = underwaterVolume})
			end
			return
		elseif tes3.getSoundPlaying({sound = newSound, reference = player}) then
			mwscript.stopSound({reference = player, sound = newSound})
		end
	end

	if waterLayerVolume > 0 then
		newSound = 'Water Layer'
		if not tes3.getSoundPlaying({sound = newSound, reference = player}) then
			tes3.playSound({sound = newSound, reference = player, loop = true, volume = waterLayerVolume})
		end
	end

end

local fSwimRunBase = 0.5 -- updated in loaded()

local submergedInFakeWater = false
local submergedFactor = 1

local VEC3UP = tes3vector3.new(0, 0, 1)
local timer_active = timer.active

local function cancelt2restartMAOscript()
	if t2 then
		t2:cancel()
	end
	if not AO_PCBeastRace then
		return
	end
	if AO_PCrunning == 0 then
		return
	elseif AO_PCrunning == 3 then
		mwscript.startScript({script ='AO_PCSound_Foot'})
	elseif AO_PCrunning == 1 then
		mwscript.startScript({script ='AO_PCSound_FootArg'})
	elseif AO_PCrunning == 2 then
		mwscript.startScript({script ='AO_PCSound_FootKha'})
	elseif AO_PCrunning == 4 then
		mwscript.startScript({script ='AO_PCSound_FootWw'})
	end
end

local function stopMAOscript()
	if AO_PCBeastRace == 0 then
		if mwscript.scriptRunning({script = 'AO_PCSound_Foot'}) then
			AO_PCrunning = 3
			mwscript.stopScript({script ='AO_PCSound_Foot'})
		elseif mwscript.scriptRunning({script = 'AO_PCSound_FootWw'}) then
			AO_PCrunning = 4
			mwscript.stopScript({script ='AO_PCSound_FootWw'})
		end
	elseif AO_PCBeastRace == 1 then -- argonian
		if mwscript.scriptRunning({script = 'AO_PCSound_FootArg'}) then
			AO_PCrunning = 1
			mwscript.stopScript({script ='AO_PCSound_FootArg'})
		end
	elseif AO_PCBeastRace == 2 then -- khajiit
		if mwscript.scriptRunning({script = 'AO_PCSound_FootKha'}) then
			AO_PCrunning = 2
			mwscript.stopScript({script ='AO_PCSound_FootKha'})
		end
	else
		AO_PCrunning = 0
	end
end

local tes3_objectType_static = tes3.objectType.static
local tes3_objectType_activator = tes3.objectType.activator

-- set in initialized()
local tes3_game_worldObjectRoot, tes3_game_worldPickRoot

local validWater = {
'_water','water_','dg-wt_','dg_circle','terrain_ashmire_','tad_fountain_balmora','nom_ma_pool00',
'nom_bc_pool00','nom_ashlands_pool00','nom_ac_pool00','furn_pycave_pool00','terrain_bc_scum_'
}
local invalidWater = {'spray', 'barrel'}

local function checkCollidingFakeWater()
	submergedInFakeWater = false
	--[[
	mwse.log(
	"%s local result = tes3.rayTest({ position = %s, direction = %s, maxDistance = 2048, findAll = false, ignore = {%s}, useBackTriangles = true})",
	os.clock(), player.position, VEC3UP, player
	)
	--]]
	if not player then
		---assert(player)
		return
	end
	---mobilePlayer = tes3.mobilePlayer
	if not mobilePlayer then
		---assert(mobilePlayer)
		return
	end

	local playerPos = player.position
	if not playerPos then -- better safe than sorry (SOL3 delay)
		cancelt2restartMAOscript()
		return
	end

	local function rayTest(worldRoot)
		return tes3.rayTest({position = playerPos, direction = VEC3UP, maxDistance = 2048, findAll = true,
			ignore = {player}, useBackTriangles = true, root = worldRoot})
	end

	local results = rayTest(tes3_game_worldObjectRoot)

	if not results then
		if includeActivators then
			results = rayTest(tes3_game_worldPickRoot)
		end
	end

	if not results then
		cancelt2restartMAOscript()
		return
	end

	local result, ref, obj, mesh, lcMesh, objType, sourceMod, ok

	for _, v in pairs(results) do
		if v then
			ref = v.reference
			if ref then -- safety as it happens /abot
				obj = ref.object
				mesh = obj.mesh
				if mesh then -- better safe than sorry...
					lcMesh = mesh:lower()
					objType = obj.objectType
					ok = (objType == tes3_objectType_static)
					if not ok then
						if includeActivators then
							if objType == tes3_objectType_activator then
								sourceMod = obj.sourceMod
								if sourceMod then
									ok = not string.find(sourceMod:lower(), 'abottrwatersound', 1, true)
								else
									ok = true
								end
							end
						end
					end
					if ok then
						if not string.multifind(lcMesh, invalidWater, 1, true) then
							if string.multifind(lcMesh, validWater, 1, true) then
								result = v
								break
							end
						end
					end
				end
			end
		end
	end

	if not result then
		cancelt2restartMAOscript()
		return
	end

	local slow = false
	if slowPlayerInFakeWater == 2 then
		slow = true
	elseif slowPlayerInFakeWater == 1 then
		if not mobilePlayer.isFlying then
			slow = true
		end
	end
	depth = result.intersection.z - playerPos.z
	if slow then
		if depth >= minDepth then
			submergedFactor = fSwimRunBase * math.max( 96 / depth, 0.8 )
			submergedInFakeWater = true
		end
	end

	if t2 then
		if t2.state == timer_active then
			return
		end
	end

	if AO_PCBeastRace then -- working as nil evaluates false but 0 evaluates true
		stopMAOscript()
	end
	t2 = timer.start({duration = 0.1, iterations = 15, callback = simulateWaterSound})

	---mwse.log("checkCollidingFakeWater() collidingFakeWater = %s, submergedInFakeWater = %s", collidingFakeWater, submergedInFakeWater)
end

local function calcMoveSpeed(e)
	if not (e.reference == player) then
		return
	end

	if e.speed <= 0 then
		local velocity = e.mobile.velocity
		if velocity then
			if #velocity <= 0 then
				return -- this will skip lots of rayTest, big improvement
			end
		end
	end

	if submergedInFakeWater then
		if slowPlayerInFakeWater then
			-- lower speed in water
			e.speed = e.speed * submergedFactor
		end
	end

	if t1 then
		if t1.state == timer_active then
			return
		end
	end

	---tes3.messageBox("calcMoveSpeed(e)")
	---mwse.log("%s calcMoveSpeed(e) e.speed = %s", os.clock(), e.speed)

	t1 = timer.start({duration = 0.4, iterations = 8, callback = checkCollidingFakeWater})
end

local onLoadOnce -- reset on initialized()
local function loaded()
	t1 = nil
	t2 = nil
	player = tes3.player
	---assert(player)
	mobilePlayer = tes3.mobilePlayer
	---assert(mobilePlayer)
	fSwimRunBase = tes3.findGMST('fSwimRunBase').value -- 0.5 by default
	armorSlot = tes3.armorSlot.boots
	AO_PCBeastRace = tes3.getGlobal('AO_PCBeastRace') -- nil if not found, else value (could be 0)
	if AO_PCBeastRace then
		if ( AO_PCBeastRace == 1 ) -- Argonian
		or ( AO_PCBeastRace == 2 ) then -- Khajiit
			armorSlot = tes3.armorSlot.cuirass -- beast race
		end
	end
	depth = 0
	if onLoadOnce then
		return
	end
	onLoadOnce = true
	event.register('calcMoveSpeed', calcMoveSpeed)
end

local function initialized()
	tes3_game_worldObjectRoot = tes3.game.worldObjectRoot
	assert(tes3_game_worldObjectRoot)
	tes3_game_worldPickRoot = tes3.game.worldPickRoot
	assert(tes3_game_worldPickRoot)
	event.register('loaded', loaded)
	onLoadOnce = false
	local msg = string.format('%s initialized', modPrefix)
	mwse.log(msg)
	if tes3.getScript('TR_Po_WaterSound512') then
		tes3.messageBox('WARNING: Water Sound MWSE-Lua mod makes abotTRWaterSound mod obsolete, you should uninstall it')
	end
end
event.register('initialized', initialized)
