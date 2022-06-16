-- begin tweakables
local slowPlayerInFakeWater = 2 -- 0 = disable slowing player in fake water, 1 = slow while walking/running, 2 = slow also while flying
local includeActivators = true -- set it to false to disable detection of activators
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

local ARMO = tes3.objectType.armor
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

	local equippedArmor = tes3.getEquippedItem({actor = player, objectType = ARMO, slot = armorSlot })
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
end

local fSwimRunBase = 0.5 -- updated in loaded()

local submergedInFakeWater = false
local submergedFactor = 1

local VEC3UP = tes3vector3.new(0, 0, 1)
local TIMER_ACTIVE = timer.active

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
		if mwscript.scriptRunning('AO_PCSound_Foot') then
			AO_PCrunning = 3
			mwscript.stopScript({script ='AO_PCSound_Foot'})
		elseif mwscript.scriptRunning('AO_PCSound_FootWw') then
			AO_PCrunning = 4
			mwscript.stopScript({script ='AO_PCSound_FootWw'})
		end
	elseif AO_PCBeastRace == 1 then -- argonian
		if mwscript.scriptRunning('AO_PCSound_FootArg') then
			AO_PCrunning = 1
			mwscript.stopScript({script ='AO_PCSound_FootArg'})
		end
	elseif AO_PCBeastRace == 2 then -- khajiit
		if mwscript.scriptRunning('AO_PCSound_FootKha') then
			AO_PCrunning = 2
			mwscript.stopScript({script ='AO_PCSound_FootKha'})
		end
	else
		AO_PCrunning = 0
	end
end

local STAT = tes3.objectType.static
local ACTI = tes3.objectType.activator

-- set in initialized()
local tes3_game_worldObjectRoot, tes3_game_worldPickRoot

local function checkCollidingFakeWater()
	submergedInFakeWater = false

	--[[
	mwse.log(
	"%s local result = tes3.rayTest({ position = %s, direction = %s, maxDistance = 2048, findAll = false, ignore = {%s}, useBackTriangles = true})",
	os.clock(), player.position, VEC3UP, player
	)
	--]]

	 -- better safe than sorry
	---player = tes3.player
	if not player then
		---assert(player)
		return
	end
	---mobilePlayer = tes3.mobilePlayer
	if not mobilePlayer then
		---assert(mobilePlayer)
		return
	end

	local ppos = player.position
	if not ppos then -- better safe than sorry (SOL3 delay)
		cancelt2restartMAOscript()
		return
	end

--[[
tes3.game.worldSceneGraphRoot -- everything
tes3.game.worldLandscapeRoot -- landscape
tes3.game.worldObjectRoot -- objects?
tes3.game.worldPickRoot -- activators??
]]
	local result = tes3.rayTest({ position = ppos, direction = VEC3UP, maxDistance = 2048, findAll = false, ignore = {player},
		useBackTriangles = true, root = tes3_game_worldObjectRoot})
	if not result then
		if includeActivators then
			result = tes3.rayTest({ position = ppos, direction = VEC3UP, maxDistance = 2048, findAll = false, ignore = {player},
				useBackTriangles = true, root = tes3_game_worldPickRoot})
		end
	end

	if not result then
		cancelt2restartMAOscript()
		return
	end

	local ref = result.reference
	if not ref then -- it happens /abot
		cancelt2restartMAOscript()
		return
	end

	local obj = ref.object
	local objType = obj.objectType
	local found = objType == STAT
	if not found then
		if includeActivators then
			found = objType == ACTI
		end
	end
	if not found then
		cancelt2restartMAOscript()
		return
	end

	local mesh = obj.mesh
	if not mesh then -- should not be needed but better safe than sorry...
		cancelt2restartMAOscript()
		return
	end

	local lcMesh = string.lower(mesh)
	if not string.multifind(lcMesh, {'_water', 'water_', 'dg-wt_', 'dg_circle', 'terrain_ashmire_', 'tad_fountain_balmora',
		'nom_ma_pool00','nom_bc_pool00','nom_ashlands_pool00','nom_ac_pool00','furn_pycave_pool00','terrain_bc_scum_'}, 1, true) then
		cancelt2restartMAOscript()
		return
	end

	--[[
	local skip = string.find(lcMesh, 'fall', 1, true)
	if not skip then
		skip = string.find(lcMesh, 'spray', 1, true)
	end
	--]]
	local skip = string.multifind(lcMesh, {'spray', 'barrel'}, 1, true)

	if not skip then
		if includeActivators then
			if objType == ACTI then
				local s = obj.sourceMod
				if s then
					skip = string.find(string.lower(s), 'abottrwatersound', 1, true)
				end
			end
		end
	end

	if skip then
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
	if slow then
		local depth = result.intersection.z - player.position.z
		if depth > 56 then
			submergedFactor = fSwimRunBase * math.max( 96 / depth, 0.8 )
			submergedInFakeWater = true
		end
	end

	if t2 then
		if t2.state == TIMER_ACTIVE then
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
		if t1.state == TIMER_ACTIVE then
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
	assert(player)
	mobilePlayer = tes3.mobilePlayer
	assert(mobilePlayer)
	fSwimRunBase = tes3.findGMST('fSwimRunBase').value -- 0.5 by default
	armorSlot = tes3.armorSlot.boots
	AO_PCBeastRace = tes3.getGlobal('AO_PCBeastRace') -- nil if not found, else value (could be 0)
	if AO_PCBeastRace then
		if ( AO_PCBeastRace == 1 ) -- Argonian
		or ( AO_PCBeastRace == 2 ) then -- Khajiit
			armorSlot = tes3.armorSlot.cuirass -- beast race
		end
	end
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

--[[
local result = tes3.rayTest({
	position = tes3.getCameraPosition(), -- Can be any TES3Vector3 or a lua table with 3 elements. Required.
	direction = tes3.getCameraVector(), -- Same as position. Required
	findAll = false, -- Find just one result, or all the results. If true, the result is a table, instead of a single result. Default: false
	sort = true, -- Sort results by distance? Default: true
	useModelCoordinates = false, -- If true, model coordinates are used instead of world coordinates.
	useModelBounds = false, -- If true, the bounding spheres are used instead of model triangles.
	useBackTriangles = false, -- If true back face triangles are not culled for ray test.
	observeAppCullFlag = true, -- Pick will stop if it encounters an object with the flag set.
	returnTexture = false, -- If true, texture coordinates are returned in result.texture
	returnSmoothNormal = false, -- If true, result.normal is a unit-length, interpolated vector from vertex normals. Otherwise it's a unitized facet normal for the intersected triangle.
	returnColor = false, -- If true, the source vertex triangle color is returned.
})

result.reference -- The game reference actually hit.
result.sceneNode -- The node hit.
result.sceneNodeParent -- Parent.
result.intersection.<x/y/z> -- Intersection point.
result.triangleIndex -- The index of the triangle hit if params.useModelBounds is false.
result.vertexIndex[1-3] -- The index of the vertexes hit if params.useModelBounds is false?
result.texture.<x/y> -- See params.returnTexture
result.normal.<x/y/z> -- See params.returnSmoothNormal
result.color -- See params.returnColor

--]]
