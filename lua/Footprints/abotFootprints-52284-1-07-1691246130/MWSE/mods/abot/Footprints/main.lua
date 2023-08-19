---@diagnostic disable: param-type-mismatch
--[[Actors footprints]]

local defaultConfig = {
playerFootprints = true,
npcFootprints = true,
creatureFootprints = true,
maxDistance = 3072, -- max distance from player for footprints spawning (512 - 16384)
dirtyExterior = true,
dirtyInterior = true,
dirtyWeather = true, -- dirty feet in bad weather
dirtyWaterwalk = false, -- dirty feet after waterwalking
dirtyUnderWater = 2, -- dirty feet when under water level 0 = Off, 1 = Check normal water, 2 = Ceck also fake water meshes
dirtyTexture = true, -- dirty feet after staying on a dirty surface
footprintDuration = 2, -- duration of cell footprints in simulated game hours.
fpDuration = 300, -- duration of footprints in real time seconds.
fpMaxNumber = 10000, -- max total number of footprints present at the same time
dirtyDuration = 90, -- dirty feet lasting duration in real time seconds
msInWaterTimerDelay = 1500, -- milliseconds timer delay to detect in water/dirty feet
puffsOn = true, -- footprints puffs in snow/sand
skipStairs = false, -- try detecting and skipping staircases when placing footprints
alphaPerc = 55, -- footprinth alpha percent, lower = more transparent
beastBoots = false, -- beast races can't wear visible boots and always have bare feet footprints
priority = 10000, -- addSound() event priority. Must be higher than priority for addSound() event used by other loaded mods.
---lookForExtraMeshes = false, -- look for extra _R, _L meshes for special creatures footprints.
logLevel = 0,
}

local author = 'abot'
local modName = 'Footprints'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)

-- set in modConfigReady
local playerFootprints = config.playerFootprints
local npcFootprints = config.npcFootprints
local creatureFootprints = config.creatureFootprints
local maxDistance = config.maxDistance
local dirtyExterior = config.dirtyExterior
local dirtyInterior = config.dirtyInterior
local dirtyWeather = config.dirtyWeather
local dirtyUnderWater = config.dirtyUnderWater
local dirtyWaterwalk = config.dirtyWaterwalk
local dirtyTexture = config.dirtyTexture
local puffsOn = config.puffsOn
local skipStairs = config.skipStairs
local alphaMul = config.alphaPerc * 0.01
local beastBoots = config.beastBoots

if config.footprintDuration > 48 then
	config.footprintDuration = defaultConfig.footprintDuration
end
local footprintDuration = config.footprintDuration
local fpDuration = config.fpDuration
local fpMaxNumber = config.fpMaxNumber
local dirtyDuration = config.dirtyDuration
if config.inWaterTimerDelay then
	config.inWaterTimerDelay = nil -- clean legacy value
end
local inWaterTimerDelay = config.msInWaterTimerDelay * 0.001
local configPriority = config.priority
local logLevel = config.logLevel
local logLevel1 = logLevel >= 1
local logLevel2 = logLevel >= 2
local logLevel3 = logLevel >= 3
local logLevel4 = logLevel >= 4
local logLevel5 = logLevel >= 5

---local lookForExtraMeshes = config.lookForExtraMeshes
local noFootprints = not (
	playerFootprints
	or npcFootprints
	or creatureFootprints
)
local dirtyEnabled = (
	dirtyWaterwalk
	or (dirtyUnderWater > 0)
)
and (
	dirtyExterior
	or dirtyInterior
)

local fpPrefix = 'ab01fp'
local fpStaSides = {'l', 'r'}

local mData = dofile(modPrefix .. '.data')
 -- {'anml','boot','boot2','foot','guar','hoof','mech','mech2','paw','puff','rat','rept','skel','taln'}
local fpStaTypes = mData.fpStaTypes
local creStaTypes = mData.creStaTypes

local resourcePath = 'abot/fp'

local fpBaseMeshes = {}

event.register('initialized',
function ()
	local typ, side, fpMeshId, meshFile, meshPath, meshNode, meshNodeName
	-- fpStaTypes = {'anml','boot','boot2','foot','guar','hoof','mech','mech2','paw','puff','rat','rept','skel','taln'}

	for i = 1, #fpStaTypes do
		typ = fpStaTypes[i]
		for j = 1, 2 do
			side = fpStaSides[j]-- e.g. 'l'
			fpMeshId = string.format("%s_%s", typ, side) -- e.g. 'foot_l'
			meshFile = string.format('%s/%s.nif', resourcePath, fpMeshId) -- e.g. 'abot/fp/foot_r.nif'
			meshPath = string.format('Meshes/%s', meshFile) -- e.g. 'Meshes/abot/fp/foot_r.nif'
			if tes3.getFileExists(meshPath) then
				meshNode = tes3.loadMesh(meshFile)
				if meshNode then
					meshNodeName = meshNode.name
					if (not meshNodeName)
					or (meshNodeName == '') then
						if logLevel4 then
							mwse.log('%s "%s".name set to "%s"', modPrefix, fpMeshId, fpPrefix)
						end
						meshNode.name = fpPrefix -- e.g. 'ab01fp' mark to find and detach them
					end
					fpBaseMeshes[fpMeshId] = meshNode
					if logLevel5 then
						for k, v in pairs(meshNode.children) do
							mwse.log('children[%s] = %s', k, v)
						end
						mwse.log('%s: fpBaseMeshes["%s"] = %s', modPrefix, fpMeshId, fpBaseMeshes[fpMeshId])
					end
				else
					mwse.log('%s error tes3.loadMesh("%s")', modPrefix, meshFile)
				end
			else
				mwse.log('%s error: "%s" not found', modPrefix, meshPath)
			end
		end
	end
end, {doOnce = true})

---local tes3_objectType_static = tes3.objectType.static


-- reset in loaded()
local player, player1stPerson

local dirtyActorRefs = {} --  e.g. dirtyActorRefs[actorRef] = sec

local doPack = false
local packing = false

local function packDirtyActorRefs()
	if packing then
		return
	end
	doPack = true
	packing = true
	local t = {}
	for k, v in pairs(dirtyActorRefs) do
		if v then
			t[k] = v
			dirtyActorRefs[k] = nil
		end
	end
	dirtyActorRefs = t
	doPack = false
	packing = false
	if logLevel5 then
		mwse.log('%s: packDirtyActorRefs()', modPrefix)
	end
end

local function clearDirtyActorRefs()
	for k, v in pairs(dirtyActorRefs) do
		if v then
			dirtyActorRefs[k] = nil
		end
	end
	dirtyActorRefs = {}
end


local function back2slash(s)
	return string.gsub(s, [[\]], [[/]])
end

local function getFileName(filePath)
	local s = back2slash(filePath)
	s = string.match(s, "([^\\/]-)%.%w-$")
	if not s then
		if logLevel1 then
			mwse.log('%s getFileName("%s") = "%s"', modPrefix, filePath, s)
		end
	end
	return s
end

--[[ local function getFilePath(filePath)
	local s = back2slash(filePath)
	s = string.match(s, "(.*[/\\])")
	if not s then
		s = ''
	end
	return s
end ]]

-- deep enough to get sticky dirty feet in e.g. Vivec sewers
local minWaterDepth = 20

local minRayLen = 40 -- must be enough to cover steep angles

local function getWaterLevel(cell)
	if cell.isOrBehavesAsExterior then
		return 0
	end
	if cell.hasWater
	and cell.waterLevel then
		return cell.waterLevel
	end
	return nil
end



local tes3_actorType_creature = tes3.actorType.creature
local tes3_actorType_npc = tes3.actorType.npc

local function checkValidActor(actorRef)
	local validActor = false
	if actorRef == player then
		if playerFootprints then
			validActor = true
		end
	else
		local mob = actorRef.mobile
		if mob then
			local actorType = mob.actorType
			if actorType == tes3_actorType_creature then
				if creatureFootprints then
					validActor = true
				end
			elseif npcFootprints then
				validActor = true
			end
		end
	end
	if not validActor then
		if dirtyActorRefs[actorRef] then
			dirtyActorRefs[actorRef] = nil
			doPack = true
		end
	end
	return validActor
end


local function getInWaterDepth(t)
--[[
input: {actRef, waterMeshRef, timed}: actor reference (required), fake water mesh reference, timed (boolean)
output: actor (positive) in-water depth, 0 if not available, negative means out of water
]]
	local actorRef = t.actRef
	if not actorRef then
		return 0
	end

	local actorRefId = actorRef.id
	local actorPosZ = actorRef.position.z

	if not checkValidActor(actorRef) then
		return 0
	end

	if logLevel5 then
		mwse.log('%s: getInWaterDepth({{actRef = "%s", waterMeshRef = "%s"}) cell = "%s", z = %s',
			modPrefix, actorRefId, t.waterMeshRef, actorRef.cell.editorName, actorPosZ)
	end
	local waterLevel
	if t.waterMeshRef then
		waterLevel = t.waterMeshRef.position.z
	else
		waterLevel = getWaterLevel(actorRef.cell)
	end

	if not waterLevel then
		waterLevel = actorPosZ - 1000 -- make it like out of water if no water detected
	end

	local depth = waterLevel - actorPosZ

	local minDepthZ = waterLevel - minWaterDepth

	if dirtyWaterwalk then
		if actorRef.mobile.waterWalking > 0 then
			minDepthZ = actorPosZ -- trick to simulate being underwater
		end
	end

	if logLevel5 then
		mwse.log('%s: getInWaterDepth() cell = "%s", actor "%s" z = %s, waterLevel = %s, minWaterDepth = %s, depth = %s',
			modPrefix, actorRef.cell.editorName, actorRefId, actorPosZ, waterLevel, minWaterDepth, depth)
	end

	if actorPosZ > minDepthZ then
		-- out of water
		if dirtyEnabled then
			if t.timed then
				local sec = dirtyActorRefs[actorRef]
				if sec then
					sec = sec - inWaterTimerDelay
					if sec <= 0 then
						sec = nil
						doPack = true
					end
				end
				if sec then
					if logLevel5 then
						mwse.log('%s: timed getInWaterDepth() dirtyActorRefs["%s"] decreased to %s', modPrefix, actorRefId, sec)
					end
				elseif logLevel3 then
					mwse.log('%s: timed getInWaterDepth() actor "%s" dirtyActorRefs timer expired', modPrefix, actorRefId)
				end
				dirtyActorRefs[actorRef] = sec
			end
		end
		return depth
	end

	-- in water below
	if dirtyEnabled then
		if logLevel5 then
			mwse.log('%s: getInWaterDepth() actor "%s" deep (%s) in water, dirtyActorRefs timer reset',
				modPrefix, actorRefId, depth)
		end
		dirtyActorRefs[actorRef] = dirtyDuration
	end
	return depth
end

local function cellHasWeather(cell)
	if cell.isOrBehavesAsExterior
	and cell.region then
		return true
	end
	return false
end

local badWeather = false

local function badWeatherOff()
	if logLevel2 then
		mwse.log('%s: badWeatherOff()', modPrefix)
	end
	badWeather = false
end

local function isBadWeatherIndex(weatherIndex)
 -- 4 Rain, 5 Thunder, 6 Ash, 7 Blight, 8 Snow, 9 Blizzard
	local bad = (weatherIndex >= 4)
			and (weatherIndex <= 9)
	---tes3.messageBox(string.format("weather = %s, bad = %s", w, bad))
	return bad
end

local function checkBadWeather(e)
	if not dirtyWeather then
		badWeather = false
		return
	end
	if not dirtyExterior then
		if not dirtyInterior then
			return
		end
	end
	local funcPrefix = string.format('%s checkBadWeather()', modPrefix)
	local i
	if e then
		i = e.to.index
	else
		local currentWeather = tes3.getCurrentWeather()
		if currentWeather then
			i = currentWeather.index
		end
	end
	if not i then
		if logLevel1 then
			mwse.log('%s: weather index not found', funcPrefix)
		end
		return
	end
	local currBadWeather = isBadWeatherIndex(i)
	if currBadWeather == badWeather then
		if logLevel4 then
			mwse.log('%s: badWeather = %s', funcPrefix, badWeather)
		end
		return
	end
	badWeather = currBadWeather
	if logLevel2 then
		mwse.log('%s: set badWeather %s', funcPrefix, badWeather)
	end
	if badWeather then
		if logLevel2 then
			mwse.log('%s: badWeather timer started', funcPrefix)
		end
		timer.start({duration = dirtyDuration, callback = badWeatherOff})
	end
end

local function timedInWaterCheck()
	if dirtyEnabled then
		if not packing then
			for actorRef, sec in pairs(dirtyActorRefs) do
				if sec then
					getInWaterDepth({actRef = actorRef, timed = true})
				end
			end
		elseif logLevel5 then
			mwse.log('%s: timedInWaterCheck() packing, getInWaterDepth skipped', modPrefix)
		end
	end
	if cellHasWeather(player.cell) then
		checkBadWeather()
	end
end

local function weatherChanged(e)
	if logLevel2 then
		mwse.log('%s: weatherChanged()', modPrefix)
	end
	checkBadWeather(e)
end


local cachedTex = {} -- valid textures ids cache

local texWhitelist = {'grass','dirt','snow','ice','sand','ash','scrub','grave','mud','moss','salt','muck'}
local texDirtyWhitelist = {'dirt','snow','ice','sand','ash','mud','salt','muck'}
local texBlacklist = {'glass'}
local meshBlacklist = {'water','tree','ex_v_ban'}
local texPufflist = {'snow','sand','ash'}

---local DOWN = tes3vector3.new(0, 0, -1)
---local UP = tes3vector3.new(0, 0, 1)

local pi = math.pi
local doublepi = 2 * pi

local sneakDeltaAngles = {math.rad(5), math.rad(20)}

local function getNormalizedAngle(angle)
	angle = angle % doublepi
	if angle > pi then
		angle = angle - doublepi
	end
	return angle
end

local function getNormalizedOrientation(ori)
	ori.x = getNormalizedAngle(ori.x)
	ori.y = getNormalizedAngle(ori.y)
	ori.z = getNormalizedAngle(ori.z)
	return ori
end

local function rotationDifference(vec1, vec2) -- thanks Hrnchamd
	vec1 = vec1:normalized()
	vec2 = vec2:normalized()
	local axis = vec1:cross(vec2)
	local norm = axis:length()
	if norm < 1e-5 then
		return tes3vector3.new(0, 0, 0)
	end
	local angle = math.asin(norm)
	if vec1:dot(vec2) < 0 then
		angle = pi - angle
	end
	axis:normalize()
	local m = tes3matrix33.new()
	m:toRotation(-angle, axis.x, axis.y, axis.z)
	return m:toEulerXYZ()
end

--[[local function array2str(a)
	if not a then
		return a
	end
	return string.format('{%s}', table.concat(a, ', '))
end]]

-- set in modConfigReady()
---local worldObjectRoot, worldPickRoot, worldLandscapeRoot

local function getTexture(rayHit, actorRef)
	local funcPrefix = string.format('%s getTexture(actorRef = "%s")', modPrefix, actorRef)
	local texturingProperty = rayHit.object.texturingProperty
	if not texturingProperty then
		if logLevel5 then
			mwse.log('%s: texturingProperty = %s', funcPrefix, texturingProperty)
		end
		return nil
	end
	local baseMap = texturingProperty.maps[1]
	if not baseMap then
		if logLevel5 then
			mwse.log('%s: baseMap = %s', funcPrefix, baseMap)
		end
		return nil
	end
	local texture = baseMap.texture
	if not texture then
		if logLevel5 then
			mwse.log('%s: texture = %s', funcPrefix, texture)
		end
		return nil
	end
	local fnam = texture.fileName -- important!!! it is .fileName, not .filename
	if not fnam then
		if logLevel5 then
			mwse.log('%s: texture.fileName = %s', funcPrefix, fnam)
		end
		return nil
	end

	local tex = string.lower(getFileName(fnam))
	if logLevel4 then
		mwse.log('%s: tex = "%s"', funcPrefix, tex)
	end

	local hit = cachedTex[tex]
	if hit then
		if logLevel3 then
			if hit == 1 then
				mwse.log('%s: hit cached "%s" texture', funcPrefix, tex)
			else
				mwse.log('%s: hit cached "%s" dirtyActorRefs texture', funcPrefix, tex)
			end
		end
		return tex -- return cached valid texture
	end

	local actorFeetDirty = badWeather
	if not actorFeetDirty then
		actorFeetDirty = dirtyActorRefs[actorRef]
	end

	local actorRefId = actorRef.id
	local cell = actorRef.cell
	if actorFeetDirty then
		if cellHasWeather(cell) then
			if dirtyExterior then
				if logLevel3 then
					mwse.log('%s: dirtyActorRefs "%s" hit exterior texture = "%s"',
						funcPrefix, actorRefId, tex)
				end
				return tex -- do not cache it to cachedTex[tex] though
			end
		elseif dirtyInterior then
			if logLevel3 then
				mwse.log('%s: dirtyActorRefs "%s" hit interior texture = "%s"', funcPrefix, actorRefId, tex)
			end
			return tex -- do not cache it to cachedTex[tex] though
		end
	end

	if string.find(tex, 'lava', 1, true) then
		if string.find(tex, 'crust', 1, true) then
			hit = 3 -- dirtyActorRefs
		end
	elseif not string.multifind(tex, texBlacklist, 1, true) then
		if string.multifind(tex, texDirtyWhitelist, 1, true) then
			hit = 2
		elseif string.multifind(tex, texWhitelist, 1, true) then
			hit = 1
		end
	end

	if not hit then
		return nil
	end

	cachedTex[tex] = hit
	if hit == 1 then
		if logLevel3 then
			mwse.log('%s: "%s" hit whitelisted texture', funcPrefix, actorRefId, tex)
		end
	elseif hit == 2 then
		if dirtyTexture then
			dirtyActorRefs[actorRef] = dirtyDuration
			if logLevel3 then
				mwse.log('%s: "%s" hit "%s" dirty whitelisted texture', funcPrefix, actorRefId, tex)
			end
		end
	elseif hit == 3 then
		if dirtyTexture then
			dirtyActorRefs[actorRef] = dirtyDuration
			if logLevel3 then
				mwse.log('%s: dirty "%s" hit "%s" lava texture', funcPrefix, actorRefId, tex)
			end
		end
	end
	return tex
end


local function rayTest(rayParams)
	local rayHit = tes3.rayTest(rayParams)
	if logLevel < 4 then
		return rayHit
	end
	local funcPrefix = string.format('%s rayTest({position = %s, direction = %s, maxDistance = %s, root = %s})',
		modPrefix, rayParams.position, rayParams.direction, rayParams.maxDistance, rayParams.root)
	if rayHit then
		local hitRef = rayHit.reference
		if hitRef then
			local mesh = back2slash(hitRef.object.mesh)
			mwse.log('%s: hitRef = "%s", mesh = "%s"', funcPrefix, hitRef, mesh)
		else
			mwse.log('%s: intersection = "%s"', funcPrefix, rayHit.intersection)
		end
	else
		mwse.log('%s: rayHit = "%s"', funcPrefix, rayHit)
	end
	return rayHit
end

local tes3_objectType_light = tes3.objectType.light
local tes3_objectType_miscItem = tes3.objectType.miscItem
local tes3_objectType_activator = tes3.objectType.activator

local puffs = {} --- puffs[node] = timestamp

local function onLoad() -- clear them before loading
	for k, v in pairs(puffs) do
		if v then
			if k.parent then
				k.parent:detachChild(k)
			end
			puffs[k] = nil
		end
	end
	puffs = {}
end

local function getRealtimeSecondsFromStart()
	return os.clock()
end

local function getRoundedRealtimeSecondsFromStart()
	return math.floor(os.clock() + 0.5)
end

---local maxPuffCount = 0
local function checkPuffs() -- called from a timer on loaded()
	local now = getRealtimeSecondsFromStart()
	local t = {}
	---local count = 0
	for k, v in pairs(puffs) do
		if k.parent then
			if v
			and ((now - v) < 0.9) then
				t[k] = v -- copy to new table
				---count = count + 1
			else
				k.parent:detachChild(k)
				puffs[k] = nil
			end
		end
	end
	--[[if count > maxPuffCount then
		maxPuffCount = count
		mwse.log('puffs maxPuffCount = %s', maxPuffCount)
	end]]
	puffs = t
end

 -- current and max total number of placed footprint, reset in modConfigReady()
local fpNumber = 0
local fpNumMax = 0

local maxFootprintSlope = math.rad(78)

local function placeFootprint(actorRef, meshId, fpStaSide)
	local funcPrefix = string.format('%s placeFootprint("%s", "%s", "%s")',
		modPrefix, actorRef.id, meshId, fpStaSide)

	local actorRefId = actorRef.id
	local mob = actorRef.mobile

	-- note: a valid rayHit.normal needs return Normal = true in the rayTest
	local raySize = minRayLen
	local boundSize = mob.boundSize

	if boundSize then
-- higher startZ as I want to check for actor submerged in fake water
		raySize = boundSize.z * actorRef.scale
	end

	local toIgnore
	if (actorRef == player)
	or (actorRef == player1stPerson) then
		toIgnore = {player, player1stPerson}
	else
		toIgnore = {actorRef, player, player1stPerson}
	end

	local pos
	local function updatePos(dz) -- next rayTest needs a fresh position
		pos = actorRef.position:copy()
		pos = pos + mob.velocity
		pos.z = pos.z + dz
	end

	local cell = actorRef.cell
	local up = actorRef.upDirection
	local rayHit, tex, hitRef, obj, lcMesh

	updatePos(raySize)
	local rayParams = {position = pos, ignore = toIgnore,
		maxDistance = raySize + minRayLen,
		returnNormal = true, useModelCoordinates = true, returnColor = true
	}

	if getWaterLevel(cell) then
		getInWaterDepth({actRef = actorRef})

	elseif dirtyUnderWater > 1 then
		-- necessary to detecty submerged in fake water meshes
		rayParams.useBackTriangles = true
		rayParams.direction = up
	-- interactable (NPCs, items, plants, activators, doors) + EditorMarkers
		rayParams.root = cell.pickObjectsRoot

		rayHit = rayTest(rayParams)
		if rayHit then
			hitRef = rayHit.reference
			if hitRef then
				obj = hitRef.baseObject
				if obj.objectType == tes3_objectType_activator then
					lcMesh = back2slash(string.lower(obj.mesh))
					if string.find(lcMesh, 'water', 1, true) then
						if logLevel1 then
							mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
						end
						getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
					else
						rayHit = nil
					end
					if string.multifind(lcMesh, meshBlacklist, 1, true) then
						if logLevel3 then
							mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
						end
						return -- skip problematic meshes
					end
				end
			end
		end

		if not rayHit then
			-- check statics fake water meshes
			rayParams.root = cell.staticObjectsRoot
			updatePos(raySize)
			rayHit = rayTest(rayParams)
			if rayHit then
				hitRef = rayHit.reference
				if hitRef then
					obj = hitRef.baseObject
					lcMesh = back2slash(string.lower(obj.mesh))
					if string.find(lcMesh, 'water', 1, true) then
						if logLevel1 then
							mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
						end
						getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
					end
					if string.multifind(lcMesh, meshBlacklist, 1, true) then
						if logLevel3 then
							mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
						end
						return -- skip problematic meshes
					end
				end
			end
		end

	end

	local down = up:copy()
	down:negate() -- negate() negates in place!
	---assert(up.z + down.z == 0)

	rayParams.direction = down
	rayParams.useBackTriangles = false -- we don't need it anymore
	rayParams.root = cell.pickObjectsRoot
	updatePos(raySize)
	rayHit = rayTest(rayParams)

	if rayHit then
		hitRef = rayHit.reference
		if hitRef then
			obj = hitRef.baseObject
			lcMesh = back2slash(string.lower(obj.mesh))
			local hitRefId = hitRef.id
			if hitRef.mobile then -- skip any not ignored mobiles
				if logLevel3 then
					mwse.log('%s: hit "%s" mobile, skip', funcPrefix, hitRefId)
				end
			elseif obj.objectType == tes3_objectType_miscItem then -- skip MISC for now
				if logLevel1 then
					mwse.log('%s: hit "%s" MISC item, skip', funcPrefix, hitRefId)
				end
			elseif hitRef.isLocationMarker then -- skip any editor marker
				if logLevel1 then
					mwse.log('%s: hit "%s" editor marker, skip', funcPrefix, hitRefId)
				end
			else
				if string.find(lcMesh, 'water', 1, true) then
					if logLevel1 then
						mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
					end
					getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
				end

				if string.multifind(lcMesh, meshBlacklist, 1, true) then
					if logLevel3 then
						mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
					end
					return -- skip problematic meshes
				end
				tex = getTexture(rayHit, actorRef)
			end
		end
	end

	if not tex then
		rayParams.root = cell.staticObjectsRoot -- statics, non carry lights, player
		updatePos(raySize)
		rayHit = rayTest(rayParams)

		if rayHit then
			local node = rayHit.object
			local found = node.name
			and (node.name == fpPrefix)
			if not found then
				node = node.parent
				found = node.name
				and (node.name == fpPrefix)
			end
			if found then
				if logLevel4 then
					mwse.log('%s: hit "%s" base footprint, skip', funcPrefix, node.name)
				end
				return
			end
		end

		if rayHit then
			hitRef = rayHit.reference
			if hitRef then
				obj = hitRef.baseObject
				lcMesh = back2slash(string.lower(obj.mesh))
				local hitRefId = hitRef.id
				if obj.objectType == tes3_objectType_light then
					if logLevel1 then
						mwse.log('%s: hit "%s" non carryable light, continue', funcPrefix, hitRefId)
					end
					-- skip any not ignored light, but keep searching
				else
					if string.find(lcMesh, 'water', 1, true) then -- fake water mesh exception
						if logLevel1 then
							mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
						end
						getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
					end
					if string.multifind(lcMesh, meshBlacklist, 1, true) then
						if logLevel3 then
							mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
						end
						return -- skip problematic meshes
					end
					if skipStairs then
						if string.find(lcMesh, 'stair', 1, true) then
							if not string.find(lcMesh, 'upstair', 1, true) then
								if logLevel3 then
									mwse.log('%s: hit "%s" staircase, skip', funcPrefix, lcMesh)
								end
								return -- skip staircases
							end
						end
					end
					tex = getTexture(rayHit, actorRef)
				end
			end
		end
	end

	if not tex then
		if not cell.isInterior then
			---rayParams.ignore = nil
			rayParams.root = cell.landscape.sceneNode -- check terrain
			rayParams.maxDistance = 2 * minRayLen
			updatePos(minRayLen)
			rayParams.position = pos -- needs a fresh new position to work
			rayHit = rayTest(rayParams)
			if rayHit then
				if rayHit.distance > (minRayLen * 0.9) then
					tex = getTexture(rayHit, actorRef)
				end
			end
		end
	end

	if (not rayHit)
	or (not tex) then
		if logLevel4 then
			mwse.log('%s: no valid texture found, skip', funcPrefix)
		end
		return -- no valid texture found, skip
	end

	local ori = actorRef.orientation:copy()
	if hitRef then
		ori = ori - hitRef.orientation
	end
	local diff = rotationDifference(actorRef.upDirection, rayHit.normal)
	ori = ori + diff
	ori = getNormalizedOrientation(ori)

	if math.abs(ori.x) > maxFootprintSlope then
		if logLevel1 then
			mwse.log('%s: deg abs(ori.x = %s)) > maxFootprintSlope = %s, skip',
				funcPrefix, math.deg(ori.x), math.deg(maxFootprintSlope))
		end
		return -- something wrong here, skip
	end

	if math.abs(ori.y) >= maxFootprintSlope then
		if logLevel1 then
			mwse.log('%s: deg abs(ori.y = %s) > maxFootprintSlope = %s, skip',
				funcPrefix, math.deg(ori.y), math.deg(maxFootprintSlope))
		end
		return -- something wrong here, skip
	end

	local dx = 0
	local dy

	if fpStaSide == fpStaSides[1] then  -- l
		dy = 1
		if mob.isSneaking then
			dx = dx - 1
			ori.z = ori.z - sneakDeltaAngles[1]
		end
	else  -- r
		dy = -2
		if mob.isSneaking then
			dx = dx + 1
			ori.z = ori.z + sneakDeltaAngles[2]
		end
	end

	ori.z = getNormalizedAngle(ori.z)

	--[[if mob.isMovingForward then
		dy = dy + 5
	elseif mob.isMovingBack then
		dy = dy - 2
	end
	if mob.isMovingLeft then
		dx = dx - 2
	elseif mob.isMovingRight then
		dx = dx + 2
	end]]

	local footprintScale = 1

	if boundSize then
		local k = actorRef.scale
		obj = actorRef.baseObject
		local race
		if not (mob.actorType == tes3_actorType_creature) then
			race = obj.race
			if race then
				local weight = race.weight
				if weight then
					local female = obj.female
					local w
					if female then
						w = weight.female
					else
						w = weight.male
					end
					k = k * w
					if race.isBeast then
						if string.sub(meshId, 1, 3) == 'paw' then
							k = k * 0.8 -- decrease khajiit paw footprint size compared to creatures paw size
						end
					end
				end
			end
		end
		local boundSize_x = boundSize.x * k
		if boundSize_x then
			if boundSize_x > 0 then
				local stdSizeX = 44
				footprintScale = boundSize_x / stdSizeX
				if logLevel4 then
					mwse.log('%s: footprintScale = boundSize_x %s / %s = %s', funcPrefix, boundSize_x, stdSizeX, footprintScale)
				end
				local boundSize_y = boundSize.y * k
				if boundSize_y then
					dy = dy * boundSize_y / boundSize_x
				end
			end
		end
	end

	pos = rayHit.intersection + tes3vector3.new(dx, dy, 1) + mob.velocity
	---local maxZ = actorRef.position.z + 2
	local cellEditorName = actorRef.cell.editorName
	if logLevel4 then
		mwse.log('%s: mesh = "%s", cell = "%s", position = %s, orientation = %s, scale = %s',
			funcPrefix, meshId, cellEditorName, pos, ori, footprintScale)
	end
	local mesh = fpBaseMeshes[meshId]
	if not mesh then
		if logLevel1 then
			mwse.log('%s: fpBaseMeshes["%s"] not found', funcPrefix, meshId)
		end
		return
	end

	local materialProperty = mesh.children[1].materialProperty
	---assert(materialProperty)
	if not math.isclose(materialProperty.alpha, alphaMul, 0.0001) then
		if logLevel4 then
			mwse.log('%s: footprint alpha changed from %s to %s',
				funcPrefix, materialProperty.alpha, alphaMul)
		end
		materialProperty.alpha = alphaMul
	end

	local node = mesh:clone()
	local child = node.children[1]
	child.name = getRoundedRealtimeSecondsFromStart() -- name used to store creation time
	local hitNode = rayHit.object
	local attachNode = hitNode.parent
	local m = hitNode.rotation:copy()
	m:fromEulerXYZ(ori.x, ori.y, ori.z) -- rotate in place

	---node.scale = footprintScale / attachNode.scale
	---node.translation = hitNode.translation + pos
	local scale = 1
	local sceneNode
	if hitRef then
		sceneNode = hitRef.sceneNode
		if sceneNode then
			scale = sceneNode.scale
			if logLevel4 then
				mwse.log('%s: hitRef = "%s", mesh = "%s", sceneNode.scale = %s', funcPrefix, hitRef.id, obj.mesh, scale)
			end
		end
	else
		scale = attachNode.scale
	end
	node.translation = hitNode.translation + pos -- note hitNode coordinates are local for meshes
	node.scale = footprintScale / scale -- e.g. if the mesh is double scale , we need to halve the footprint scale

	---local m = hitNode.worldTransform.rotation:transpose()
	---local m = hitNode.worldTransform.rotation
	node.rotation = m

	attachNode:attachChild(node)
	fpNumber = fpNumber + 1
	if fpNumber > fpNumMax then
		fpNumMax = fpNumber
	end

	if puffsOn then
		if string.multifind(tex, texPufflist, 1, true) then
			local puff = fpBaseMeshes[string.format('puff_%s', fpStaSide)]:clone()
			local particles = puff.children[1].children[1]
			---assert(particles:isInstanceOfType(tes3.niType.NiParticles))
			local controller = particles.controller
			---assert(controller:isInstanceOfType(tes3.niType.NiParticleSystemController))
			local colorData = controller.particleModifiers.colorData
			---assert(colorData:isInstanceOfType(tes3.niType.NiColorData))
			local keys = colorData.keys
			local rayHitColor = rayHit.color
			local color
			for i = 1, #keys do
				color = keys[i].color
				--[[color.r = 255
				color.g = 0
				color.b = 0]]
				color.r = rayHitColor.r
				color.g = rayHitColor.g
				color.b = rayHitColor.b
			end
			--[[local name = string.format('Bip01 %s Toe0', string.upper(fpStaSide))
			local toe = actorRef.sceneNode:getObjectByName(name)
			if toe then
				toe:attachChild(puff)
				toe:update()
			else
				node:attachChild(puff)
			end]]
			node:attachChild(puff)
			puffs[puff] = getRealtimeSecondsFromStart()
			if logLevel4 then
				mwse.log('%s: tex = "%s", color = %s, "%s" footprint puff attached',
					funcPrefix, tex, rayHitColor, actorRef.id)
			end
		end
	end

	local updateNode = attachNode
	if sceneNode then
		updateNode = sceneNode
	end
	updateNode:update()
	updateNode:updateProperties()
	updateNode:updateEffects()

	if logLevel3 then
		mwse.log('%s: actorRef = "%s", meshId = "%s",\nscale = %s, pos = %s, actorRefPos = %s\ndx = %s, dy = %s, fpNumber = %s, fpNumMax = %s',
			funcPrefix, actorRefId, meshId, footprintScale, pos, actorRef.position, dx, dy, fpNumber, fpNumMax)
	end

	return true
end


---local lastPlayerFootprintSide

local function placeBaseFootprint(actorRef, fpStaType, fpStaSide)
	--[[local isPlayer = (actorRef == player)
	if isPlayer then
		-- always alternate left/right player footprints as it is cheap/fast and more noticeable.
		-- it would be better to do it for all actors but I don't want to manage/store the extra complexity
		if lastPlayerFootprintSide then
			if fpStaSide == lastPlayerFootprintSide then
				if fpStaSide == fpStaSides[1] then
					fpStaSide = fpStaSides[2] -- r
				else
					fpStaSide = fpStaSides[1] -- l
				end
			end
		end
		lastPlayerFootprintSide = fpStaSide
	end]]
	local fpMeshId = string.format("%s_%s", fpStaType, fpStaSide)
	placeFootprint(actorRef, fpMeshId, fpStaSide)
end

-- reset in loaded()
local visitedCells = {} -- e.g. visitedCells[cell] = now

local function clearVisitedCells()
	for k, v in pairs(visitedCells) do
		if v then
			visitedCells[k] = nil
		end
	end
	visitedCells = {}
end

local function packVisitedCells()
	local t = {}
	for k, v in pairs(visitedCells) do
		if k then
			t[k] = v
			visitedCells[k] = nil
		end
	end
	visitedCells = t
end


---local ni_type_NiNode = ni.type.NiNode
local function deleteNodeFootprints(parent)
	---local i = 0
	for node in table.traverse({parent}) do
		---if node:isOfType(ni_type_NiNode)
		if node.name -- name can be nil
		and node.name == fpPrefix then
			node.parent:detachChild(node)
			if fpNumber > 0 then
				fpNumber = fpNumber - 1
			end
		end
	end
	---if logLevel4 then
		---mwse.log('%s: deleteNodeFootprints("%s/%s"), %s footprints deleted', modPrefix, parent.parent, parent, i)
	---end
end

local function deleteCellFootprints(cell)
	visitedCells[cell] = nil
	deleteNodeFootprints(cell.staticObjectsRoot)
	deleteNodeFootprints(cell.pickObjectsRoot)
	if cell.isInterior then
		return
	end
	deleteNodeFootprints(cell.landscape.sceneNode)
end

local ni_type_NiTriShape = ni.type.NiTriShape
local ni_propertyType_material = ni.propertyType.material

local function processNodeFootprints(parent, now)
	local child, name, age
	for node in table.traverse({parent}) do
		if node.name -- name can be nil
		and (node.name == fpPrefix) then
			child = node.children[1]
			if child:isOfType(ni_type_NiTriShape) then
				name = child.name
				---mwse.log('child.name = "%s"', name)
				age = now - name -- name used to store creation time
				if age > fpDuration then
					node.parent:detachChild(node)
					if fpNumber > 0 then
						fpNumber = fpNumber - 1
					end
				else
					--[[
					-- slowly sink footprints
					node.translation.z = node.translation.z - (0.46 / fpDuration)
					]]
					-- alpha is normally global for all the footprint meshes but...
					-- YAY! finally managed to change alpha for this node only, cloning/detach/attach of property is needed
					local materialProperty = child:detachProperty(ni_propertyType_material):clone()
					materialProperty.alpha = alphaMul * (fpDuration - age) / fpDuration
					child:attachProperty(materialProperty)
					child:updateProperties()
				end
			end
		end
	end
	parent:update()
end

local function processCellFootprints(cell)
	local now = getRoundedRealtimeSecondsFromStart()
	processNodeFootprints(cell.staticObjectsRoot, now)
	processNodeFootprints(cell.pickObjectsRoot, now)
	if not cell.isInterior then
		processNodeFootprints(cell.landscape.sceneNode, now)
	end
	if logLevel3 then
		mwse.log('%s: processCellFootprints("%s") fpNumber = %s, fpNumMax = %s',
			modPrefix, cell.editorName, fpNumber, fpNumMax)
	end
end

local function processCurrCellFootprints()
	processCellFootprints(player.cell)
end

local fpTimer
local function checkStartfpTimer()
	if fpTimer then
		fpTimer:cancel()
	end
	fpTimer = timer.start({duration = (0.025 * fpDuration) - (0.01 * math.random()),
		callback = processCurrCellFootprints, iterations = -1})
end


local function checkCellFootprints(cell, now)
	local lastVisited = visitedCells[cell]
	if logLevel3 then
		mwse.log('%s: checkCellFootprints("%s", %s) lastVisited = %s',
			modPrefix, cell.editorName, now, lastVisited)
	end
	if lastVisited then
		local diff = now - lastVisited
		if diff >= footprintDuration then
			if logLevel2 then
				mwse.log('%s: checkCellFootprints("%s", %s) cell not visited for %s hours, delete footprints',
					modPrefix, cell.editorName, now, diff)
			end
			deleteCellFootprints(cell)
		end
		return
	end
	visitedCells[cell] = now
end

local function cellDeactivated(e)
	if visitedCells[e.cell] then
		if logLevel4 then
			mwse.log('%s: cellDeactivated(), deleting cell "%s" footprints', modPrefix, e.cell.editorName)
		end
		deleteCellFootprints(e.cell)
	end
end

local function getSimulatedHoursFromStart()
	local hoursPassed = tes3.getSimulationTimestamp() - 3746001
	return math.floor(hoursPassed + 0.5)
end

local function cellChanged(e)
-- in game simulated hours, taking timescale into account
	local now = getSimulatedHoursFromStart()

	local previousCell = e.previousCell
	if previousCell then
		checkCellFootprints(previousCell, now)
	end
	local cell = e.cell
	if not cell then
		return
	end
	if previousCell then
		checkCellFootprints(cell, now)
	else -- just reloaded or new game
		if visitedCells[cell] then
			if logLevel4 then
				mwse.log('%s: cellChanged(), deleting cell "%s" footprints', modPrefix, e.cell.editorName)
			end
			deleteCellFootprints(cell)
		end
	end

	if doPack then
		packDirtyActorRefs()
	end

	if not dirtyWeather then
		badWeather = false
		return
	end
	if not dirtyExterior then
		if not dirtyInterior then
			return
		end
	end
	if cellHasWeather(cell) then
		checkBadWeather()
	end
end


local function loaded()
	player = tes3.player
	player1stPerson = tes3.player1stPerson
	local data = player.data
	if not data then
		player.data = {}
		data = player.data
	end

	-- clear dirtyActorRefs table

	clearDirtyActorRefs()
	clearVisitedCells()

	doPack = false
	packing = false

	local ab01fpDirty = data.ab01fpDirty
	if ab01fpDirty then
		local actorRef
		local playerPos = player.position
		-- rebuild dirtyActorRefs table from player.data.ab01fpDirty
		for actorRefId, sec in pairs(ab01fpDirty) do
			actorRef = tes3.getReference(actorRefId)
			if actorRef then
				if actorRef.position:distance(playerPos) <= 16384 then
					if logLevel4 then
						mwse.log('%s: loaded() ab01fpDirty["%s"] = %s', modPrefix, actorRefId, sec)
					end
					dirtyActorRefs[actorRef] = sec
				end
			end
			ab01fpDirty[actorRefId] = nil
		end
		data.ab01fpDirty = {}
	end

	timer.start({duration = inWaterTimerDelay, callback = timedInWaterCheck, iterations = -1})

	puffs = {}
	timer.start({duration = (math.random() * 0.01) + 0.43, callback = checkPuffs, iterations = -1})

	fpTimer = nil
	checkStartfpTimer()

	---lastPlayerFootprintSide = nil

end


local function save()
	local data = player.data
	data.ab01fpDirty = {}
	local ab01fpDirty = data.ab01fpDirty
	local t = {}
-- pack dirtyActorRefs table and save it to player.data.ab01fpDirty
	local lcId
	for ref, sec in pairs(dirtyActorRefs) do
		if sec then
			lcId = string.lower(ref.id)
			if logLevel4 then
				mwse.log('%s: save() ab01fpDirty["%s"] = %s', modPrefix, lcId, sec)
			end
			ab01fpDirty[lcId] = sec
			t[ref] = sec
			dirtyActorRefs[ref] = nil
		end
	end
	dirtyActorRefs = t

	packVisitedCells()
end


local tes3_objectType_armor = tes3.objectType.armor
local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_armorSlot_boots = tes3.armorSlot.boots
local tes3_clothingSlot_shoes = tes3.clothingSlot.shoes

local fpSndTypes = {
'anml', 'boot', 'foot',
'frgt', -- frostgiant
'scrib',
'sludge', -- durzog
}
local fpLongSndSides = {'left', 'right'}

local tes3_effect_levitate = tes3.effect.levitate
local tes3_effect_slowFall = tes3.effect.slowFall

---local lastFootprintId

local dummies = {'dumm','mann','target','invis'}

local function isDummy(mob)
	local mobRef = mob.reference
	local obj = mobRef.baseObject
	local mesh
	local race = obj.race
	if race then
		 -- check for invisible race NPC
		local chest = race.maleBody.chest
		if not chest then
			chest = race.femaleBody.chest
		end
		if not chest then
			return true
		end
		mesh = chest.mesh
		if not mesh then
			return true
		end
		if mesh == '' then
			return true
		end
	end
	mesh = obj.mesh
	if not mesh then
		return false
	end
	if mesh == '' then
		return false
	end
	if string.multifind(string.lower(back2slash(mesh)), dummies, 1, true) then
		return true
	end
	return false
end


local addSoundPrefix = string.format("%s addSound(e)", modPrefix)
local bodyFallSound = {['body fall large'] = true, ['body fall medium'] = true, ['body fall small'] = true}

local function addSound(e)
	if noFootprints then
		return
	end

	if fpNumber >= fpMaxNumber then
		if logLevel4 then
			mwse.log('%s: fpNumber (%s ) >= fpMaxNumber (%s), skip', addSoundPrefix, fpNumber, fpMaxNumber)
		end
		return
	end

	local sound = e.sound
	if not sound then
		if logLevel1 then
			mwse.log('%s warning: no e.sound, skip', addSoundPrefix)
		end
		return
	end
	local actorRef = e.reference
	if not actorRef then
		return -- it happens!!!
	end

	local mob = actorRef.mobile
	if not mob then
		return
	end

	local actorType = mob.actorType
	if not actorType then
		if logLevel4 then
			mwse.log('%s: "%s" is not some npc/creature, skip', addSoundPrefix, actorRef)
		end
		return -- process only NPCs and creatures
	end

	local actorRefId = actorRef.id

	if mob.isTurningLeft then
		if not (actorRef == player) then
-- skip when turning left as it could be an animation often triggered by bump in Smart Companions
			if logLevel4 then
				mwse.log('%s: "%s" turning left, skip', addSoundPrefix, actorRefId)
			end
			return
		end
	end

	-- safety, player is updated on loaded() but this event may fire before
	if not player then
		return
	end
	if not (player == tes3.player) then
		return
	end

	if actorRef == player1stPerson then
		if logLevel1 then
			mwse.log('%s: replacing "%s" with "%s"', addSoundPrefix, actorRefId, player.id)
		end
		actorRef = player
	end

	local actorObj = actorRef.baseObject

	--[[if logLevel5 then
		mwse.log('%s: actorRef = "%s"', addSoundPrefix, actorRefId)
	end]]

	local actorIsPlayer = (actorRef == player)

	if actorIsPlayer then
		if not playerFootprints then
			if logLevel4 then
				mwse.log('%s: "%s" is player, player footprints disabled, skip', addSoundPrefix, actorRefId)
			end
			return
		end
	elseif actorType == tes3_actorType_creature then
		if not creatureFootprints then
			if logLevel4 then
				mwse.log('%s: "%s" is creature, creature footprints disabled, skip', addSoundPrefix, actorRefId)
			end
			return
		end
	elseif not npcFootprints then
		if logLevel4 then
			mwse.log('%s: "%s" is NPC, NPC footprints disabled, skip', addSoundPrefix, actorRefId)
		end
		return
	end

	local actorMesh = actorObj.mesh
	if (not actorMesh)
	or (actorMesh == '') then
		if logLevel4 then
			mwse.log('%s: "%s" actor with no mesh, skip', addSoundPrefix, actorRefId)
		end
		return
	end
	local lcMeshName = string.lower(getFileName(actorMesh)) -- e.g. 'bear_black_larger'

	-- skip these creatures early
	if actorObj.swims
	or actorObj.flies then
		if not actorObj.walks then
			if not actorObj.biped then
				if logLevel4 then
					mwse.log('%s: "%s" swimming/flying creature, skip', addSoundPrefix, actorRefId)
				end
				return
			end
		end
	end

	if mob.underwater then
		if logLevel4 then
			mwse.log('%s: "%s".underwater, getInWaterDepth, then skip', addSoundPrefix, actorRefId)
		end
		getInWaterDepth({actRef = actorRef}) -- upgrade dirtyActorRefs[actorRef]
		return
	end

	if not mob.canJump then
-- includes dead, knocked down, knocked out, paralyzed, jumping, falling, swimming, flying
		---if not mob.isSwimming then
		if logLevel4 then
			mwse.log('%s: not "%s".canJump, skip', addSoundPrefix, actorRefId)
		end
		return
		---end
	end

	if mob.levitate > 0 then
		if logLevel4 then
			mwse.log('%s: "%s".levitate = %s, skip', addSoundPrefix, actorRefId, mob.levitate)
		end
		return
	end
-- canJump is not reliable enough
	local effects = mob:getActiveMagicEffects({effect = tes3_effect_levitate})
	if effects then
		if effects[1] then
			if logLevel4 then
				mwse.log('%s: "%s" levitate effect, skip', addSoundPrefix, actorRefId)
			end
			return
		end
	end

	effects = mob:getActiveMagicEffects({effect = tes3_effect_slowFall})
	if effects then
		if effects[1] then
			if logLevel4 then
				mwse.log('%s: "%s" slowFall effect, skip', addSoundPrefix, actorRefId)
			end
			return
		end
	end

	if isDummy(mob) then
		if logLevel4 then
			mwse.log('%s: "%s" is a dummy/invisible race NPC, skip', addSoundPrefix, actorRefId)
		end
-- skip practice dummy/mannequins/archery target creatures
		return
	end

	local lcSndId = string.lower(sound.id)

	if mob.waterWalking > 0 then -- waterWalking is a number!
		---if (lcSndId == 'footwaterleft')
		---or (lcSndId == 'footwaterright') then
		if dirtyWaterwalk then
			getInWaterDepth({actRef = actorRef}) -- upgrade dirtyActorRefs[actorRef]
		elseif logLevel5 then
			mwse.log('%s: "%s" waterwalking sound, skip', addSoundPrefix, actorRefId)
		end
		return
		---end
	end

	if e.isVoiceover then
		if logLevel4 then
			mwse.log('%s: "%s" e.isVoiceover, skip', addSoundPrefix, actorRefId)
		end
		return
	end

	--[[if logLevel4 then
		mwse.log('%s: actor = "%s"', addSoundPrefix, actorRefId)
	end]]

	local depth = getInWaterDepth({actRef = actorRef}) -- also upgrades dirtyActorRefs[actorRef]
	if depth >= minWaterDepth then
		if logLevel4 then
			mwse.log('%s: "%s" in water depth (%s) >= minWaterDepth (%s), skip',
				addSoundPrefix, actorRefId, depth, minWaterDepth)
		end
		return
	end

	if not actorIsPlayer then
		local dist = actorRef.position:distance(player.position)
		if dist > maxDistance then
			if logLevel4 then
				mwse.log('%s: "%s".playerDistance (%s) > maxDistance (%s), skip',
					addSoundPrefix, actorRefId, dist, maxDistance)
			end
			return
		end
	end

	local fnam = sound.filename
	if not fnam then
		if logLevel1 then
			mwse.log('%s warning: sound.filename = "%s", skip', addSoundPrefix, fnam)
		end
		return
	end
-- converting backslash to avoid risk of invalid escape sequence on string processing
	local lcFilename = string.lower(back2slash(fnam))

	if not (
		string.startswith(lcFilename, 'fx/')
		or string.startswith(lcFilename, 'cr/')
	) then -- skip non-standard sounds
		if logLevel5 then
			mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s" not starting with "fx/" or "cr/", skip', addSoundPrefix, actorRefId, sound.id, fnam)
		end
		return
	end

	if logLevel4 then
		mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s"', addSoundPrefix, actorRefId, sound.id, fnam)
	end

	local fpStaType, fpStaSide

	-- try and match special case walk[lr] first
	local fpSndType, fpSndSide = string.match(lcFilename, "(walk)([lr])_") -- e.g. 'fx/foot/walkl_md.wav'
	if logLevel4 then
		mwse.log('%s: fpSndType = "%s", fpSndSide = "%s"', addSoundPrefix, fpSndType, fpSndSide)
	end

	if fpSndSide then
		fpStaSide = fpSndSide -- 'l' or 'r'
	else
		fpSndType = nil
	end

	if not fpSndType then
		fpSndType = string.multifind(lcFilename, fpSndTypes, 1, true)
	end
	if not fpSndType then
		if logLevel5 then
			mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s" not a standard foot sound type, skip',
				addSoundPrefix, actorRefId, sound.id, fnam)
		end
		return
	end

	if logLevel3 then
		mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s"', addSoundPrefix, actorRefId, sound.id, fnam)
	end

	if not fpStaSide then
		for i = 1, #fpLongSndSides do
			if string.find(lcSndId, fpLongSndSides[i], 1, true) then
				fpSndSide = fpLongSndSides[i]
				fpStaSide = fpStaSides[i]
				if logLevel4 then
					mwse.log('%s: string.find("%s", "%s", 1, true)', addSoundPrefix, lcSndId, fpSndSide)
				end
				break
			end
		end
	end

	--[[if not fpSndSide then
		if logLevel4 then
			mwse.log('%s: fpSndSide not found, skip', addSoundPrefix)
		end
		return
	end]]

	if not fpStaSide then
		if logLevel4 then
			mwse.log('%s: fpStaSide not found, skip', addSoundPrefix)
		end
		return
	end

	if actorType >= tes3_actorType_npc then -- 1 = NPC, 2 = player
		if string.startswith(lcMeshName, 'mountedguar') then
			-- special Rot's mounted guars are npcs
			fpStaType = 'guar'
			placeBaseFootprint(actorRef, fpStaType, fpStaSide)
			return
		end
		if bodyFallSound[lcSndId] then
			fpStaType = 'boot'
		elseif lcSndId == 'defaultland' then
			fpStaType = 'foot'
		end
		if fpStaType then -- falling NPC or animal
			if logLevel4 then
				mwse.log('%s: falling NPC fpStaType = "%s"', addSoundPrefix, fpStaType)
			end
			placeBaseFootprint(actorRef, fpStaType, fpStaSides[1]) -- l
			timer.start({duration = 0.1, type = timer.real, callback = function ()
				placeBaseFootprint(actorRef, fpStaType, fpStaSides[2]) -- r
			end})
			return
		end

		if mob.werewolf then
			fpStaType = 'paw'
		else -- look for equipped boots
			local isBeastRace = false
			local race = actorObj.race
			if race then
				if race.isBeast then
					isBeastRace = true
				end
			end

			local function setBeastBareFootprints()
				local lcRaceId = string.lower(race.id)
				if lcRaceId == 'argonian' then
					fpStaType = 'rept'
				else
					fpStaType = 'paw'
				end
			end

			if isBeastRace
			and (not beastBoots) then
				setBeastBareFootprints()
			else
				local equippedBootsStack = tes3.getEquippedItem({actor = actorRef,
					objectType = tes3_objectType_armor, slot = tes3_armorSlot_boots})
				if equippedBootsStack then
					local weightClass = equippedBootsStack.object.weightClass
					if weightClass > 0 then
						fpStaType = 'boot2'
					else
						fpStaType = 'boot'
					end
				else -- no boots equipped, look for equipped shoes
					local equippedShoesStack = tes3.getEquippedItem({actor = actorRef,
						objectType = tes3_objectType_clothing, slot = tes3_clothingSlot_shoes})
					if equippedShoesStack then
						fpStaType = 'boot'
					else -- no shoes equipped, check race
						fpStaType = 'foot' -- default
						if isBeastRace then
							setBeastBareFootprints()
						end
					end -- if equippedShoesStack
				end -- if equippedBootsStack
			end -- if raceDefined and (not beastBoots)
		end -- if mob.werewolf

		if logLevel3 then
			mwse.log('%s: fpSndType = "%s" fpStaType = "%s" lcFilename = "%s"', addSoundPrefix, fpSndType, fpStaType, lcFilename)
		end
		placeBaseFootprint(actorRef, fpStaType, fpStaSide)

		return
	end

	-- remaining creature processing below

	local creStaType = creStaTypes[lcMeshName] -- e.g. 'paw'
	if creStaType then -- creature mesh classified in creStaTypes, place related standard footprint
		fpStaType = creStaType
		placeBaseFootprint(actorRef, fpStaType, fpStaSide)
		return -- should cover most standard classified creature meshes using footprints from Meshes/abot/fp/ folder
	end

	--[[
	if not lookForExtraMeshes then
		return
	end

	-- non-recognized creatures below, for possible expansion
	-- e.g. having path/my_creature.nif
	-- you can add dedicated footprints meshes
	-- path/my_creature_r.nif
	-- path/my_creature_l.nif

	local doLog = false
	local fpMeshId = string.format("%s_%s", lcMeshName, fpStaSide) -- e.g. new fpMeshId is now 'earth golem_r'
	if not (fpMeshId == lastFootprintId) then
		lastFootprintId = fpMeshId
		doLog = logLevel2
	end
	if doLog then
		mwse.log('%s: fpMeshId = "%s"', addSoundPrefix, fpMeshId)
	end

	local fpBaseMesh = fpBaseMeshes[fpMeshId]
	if fpBaseMesh then
		placeFootprint(actorRef, fpMeshId, fpStaSide) -- place it
		return
	end

	local rep = string.format('_%s%.nif', fpStaSide) -- e.g. '_r.nif'
	local fpMeshPath = back2slash(string.lower(actorMesh))
	fpMeshPath = string.gsub(fpMeshPath, '%.nif', rep) -- e.g. now "wormgod/earth golem_r.nif"
	if doLog then
		mwse.log('%s: fpMeshPath = "%s"', addSoundPrefix, fpMeshPath)
	end
	if tes3.getFileExists('Meshes/'..fpMeshPath) then
		if doLog then
			mwse.log('%s: tes3.loadMesh("%s")', addSoundPrefix, fpMeshPath)
		end
		local fpMesh = tes3.loadMesh(fpMeshPath)
		if fpMesh then -- e.g. a special "wormgod\earth golem_r.nif" foot mesh is found
			fpBaseMeshes[fpMeshId] = fpMesh
			placeFootprint(actorRef, fpMeshId, fpStaSide) -- place it
			return
		end
	end

	]]
end -- addSound(e)

local function referenceDeactivated(e)
	local ref = e.reference
	if dirtyActorRefs[ref] then
		if logLevel4 then
			mwse.log('%s: referenceDeactivated() dirtyActorRefs["%s"] = nil', modPrefix, ref.id)
		end
		dirtyActorRefs[ref] = nil
		doPack = true
	end
end

local function death(e)
	local ref = e.reference
	if dirtyActorRefs[ref] then
		if logLevel4 then
			mwse.log('%s: death() dirtyActorRefs["%s"] = nil', modPrefix, ref.id)
		end
		dirtyActorRefs[ref] = nil
		doPack = true
	end
end


local function modConfigReady()

	fpNumber = 0 -- reset here as footprints are discarded on game restart

	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId, table = config}
	end

	--[[worldObjectRoot = tes3.game.worldObjectRoot
	worldPickRoot = tes3.game.worldPickRoot
	---assert(worldPickRoot)
	worldLandscapeRoot = tes3.game.worldLandscapeRoot]]

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		playerFootprints = config.playerFootprints
		npcFootprints = config.npcFootprints
		creatureFootprints = config.creatureFootprints
		maxDistance = config.maxDistance
		dirtyExterior = config.dirtyExterior
		dirtyInterior = config.dirtyInterior
		dirtyWeather = config.dirtyWeather
		dirtyUnderWater = config.dirtyUnderWater
		dirtyWaterwalk = config.dirtyWaterwalk
		dirtyTexture = config.dirtyTexture
		footprintDuration = config.footprintDuration

		if not (fpDuration == config.fpDuration) then
			fpDuration = config.fpDuration
			checkStartfpTimer()
		end

		fpMaxNumber = config.fpMaxNumber
		dirtyDuration = config.dirtyDuration
		inWaterTimerDelay = config.msInWaterTimerDelay * 0.001
		puffsOn = config.puffsOn
		skipStairs = config.skipStairs
		alphaMul = config.alphaPerc * 0.01
		beastBoots = config.beastBoots

		logLevel = config.logLevel
		logLevel1 = logLevel >= 1
		logLevel2 = logLevel >= 2
		logLevel3 = logLevel >= 3
		logLevel4 = logLevel >= 4
		logLevel5 = logLevel >= 5

		---lookForExtraMeshes = config.lookForExtraMeshes
		if not (
			dirtyExterior
		 or dirtyInterior
		) then
			badWeather = false
			clearDirtyActorRefs()
		end
		noFootprints = not (
			playerFootprints
			or npcFootprints
			or creatureFootprints
		)
		dirtyEnabled = (
			dirtyWaterwalk
			or (dirtyUnderWater > 0)
		)
		and (
			dirtyExterior
			or dirtyInterior
		)

		if not (config.priority == configPriority) then
			if event.isRegistered('addSound', addSound, {priority = configPriority}) then
				event.unregister('addSound', addSound, {priority = configPriority})
			end
			configPriority = config.priority
			event.register('addSound', addSound, {priority = configPriority})
		end

		mwse.saveConfig(configName, config, {indent = true})
	end

	local info = [[Actors footprints

Note: visible footprints are deleted from a cell when it is unloaded.
No footprint reference data is added to game saves,
and any visible footprint is discarded on game executable restart anyway.]]

	local preferences = template:createSideBarPage{
		label = info,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	---local controls = preferences:createCategory({label = mcmName})
	local controls = preferences:createCategory({})
	---controls:createInfo({text = info})

	local function getDescription(frmt, variableId)
		return string.format(frmt, defaultConfig[variableId])
	end

	local yesOrNo = {[false] = 'No', [true] = 'Yes'}

	local function getYesNoDescription(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton({
		label = 'Player footprints',
		description = getYesNoDescription([[Default: %s.
Enable player footprints]], 'playerFootprints'),
		variable = createConfigVariable('playerFootprints')
	})
	controls:createYesNoButton({
		label = 'NPCs footprints',
		description = getYesNoDescription([[Default: %s.
Enable NPCs footprints]], 'npcFootprints'),
		variable = createConfigVariable('npcFootprints')
	})
	controls:createYesNoButton({
		label = 'Creatures footprints',
		description = getYesNoDescription([[Default: %s.
Enable creatures footprints.]], 'creatureFootprints'),
		variable = createConfigVariable('creatureFootprints')
	})

local tweakHint = [[

You could try lowering this setting if too many spawned footprints are badly hitting your frame rate,
or increasing it if you have good frame rate and want the footprints to last longer e.g. to track enemies in the wilderness.]]

	controls:createSlider({
		label = 'Footprint max duration: %s sec',
		description = getDescription([[Default: %s.
Max duration of each footprint in real time seconds.]]..tweakHint, 'fpDuration'),
		variable = createConfigVariable('fpDuration'),
		min = 60, max = 7200, step = 1, jump = 5,
	})

	controls:createSlider({
		label = 'Footprints max distance',
		description = getDescription([[Default: %s.
Max distance from player for footprints spawning.]]..tweakHint, 'maxDistance'),
		variable = createConfigVariable('maxDistance')
		,min = 512, max = 15384, step = 1, jump = 10
	})

	controls:createSlider({
		label = 'Max number of footprints: %s',
		description = getDescription([[Default: %s.
Max total number of footprints that could be present at the same time.]]..tweakHint, 'fpMaxNumber'),
		variable = createConfigVariable('fpMaxNumber'),
		min = 100, max = 50000, step = 1, jump = 10,
	})

	controls:createYesNoButton({
		label = 'Dirty feet in exteriors/interiors with bad weather',
		description = getYesNoDescription([[Default: %s.
Enables dirty feet in exteriors/interiors with bad weather.]], 'dirtyExterior'),
		variable = createConfigVariable('dirtyExterior')
	})

	controls:createYesNoButton({
		label = 'Dirty feet in interiors',
		description = getYesNoDescription([[Default: %s.
Enables having still dirty feet for a while after entering interiors.]], 'dirtyInterior'),
		variable = createConfigVariable('dirtyInterior')
	})

	controls:createYesNoButton({
		label = 'Dirty feet in bad weather',
		description = getYesNoDescription([[Default: %s.
Enables dirty feet in bad weather (e.g. raining, snowing).]], 'dirtyWeather'),
		variable = createConfigVariable('dirtyWeather')
	})

	local optionList = {'No', 'Yes, check only standard water', 'Yes, check also fake water meshes'}
	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s", i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local function getDropDownDescription(frmt, variableId)
		local i = defaultConfig[variableId]
		return string.format(frmt, string.format('%s. %s', i, optionList[i+1]))
	end

	controls:createDropdown({
		label = 'Wet feet from being submerged:',
		options = getOptions(),
		description = getDropDownDescription([[Default: %s.
Note:
option "2. Yes, check also fake water meshes" requires some more raytesting so you can try
lowering it to "1. Yes, check only standard water" if you have low FPS.]], 'dirtyUnderWater'),
		variable = createConfigVariable('dirtyUnderWater')
	})

	controls:createYesNoButton({
		label = 'Dirty feet after waterwalking',
		description = getYesNoDescription([[Default: %s.
Enables dirty feet from waterwalking.]], 'dirtyWaterwalk'),
		variable = createConfigVariable('dirtyWaterwalk')
	})

	controls:createYesNoButton({
		label = 'Dirty feet from dirty/sticky surfaces',
		description = getYesNoDescription([[Default: %s.
Enables dirty feet from walking over a dirty/sticky surface
e.g. mud, snow, lava, sand...]], 'dirtyTexture'),
		variable = createConfigVariable('dirtyTexture')
	})

	controls:createYesNoButton({
		label = 'Footprints puffs',
		description = getYesNoDescription([[Default: %s.
Enables Footprints puffs effect on proper surfaces e.g. snow, sand, ash...]], 'puffsOn'),
		variable = createConfigVariable('puffsOn')
	})

	controls:createYesNoButton({
		label = 'Skip stairs',
		description = getYesNoDescription([[Default: %s.
Try detecting and skipping staircases when placing footprints.]], 'skipStairs'),
		variable = createConfigVariable('skipStairs')
	})

	controls:createSlider({
		label = 'Footprints alpha %s%%',
		description = getDescription([[Default: %s%%.
Footprint initial alpha percent (lower = more transparent).
Use it to tweak initial footprints transparency/darkness for better blending according to your texture replacers.
Note: footprints automatically alpha fade out from this value as time goes by until they are fully deleted.
]], 'alphaPerc'),
		variable = createConfigVariable('alphaPerc'),
		min = 15, max = 100, step = 1, jump = 5,
	})

	controls:createSlider({
		label = 'Cell footprints duration: %s simulated game hours',
		description = getDescription([[Default: %s.
Duration of footprints in simulated game hours.
When you change cell, if current cell/previous cell was visited earlier than this number of hours,
current/previous cell footprints will be deleted.]],
'footprintDuration'),
		variable = createConfigVariable('footprintDuration'),
		min = 1, max = 48, step = 1, jump = 5,
	})

	controls:createSlider({
		label = 'Dirty feet duration: %s sec',
		description = getDescription([[Default: %s.
Duration in real time seconds of dirty feet effect
(e.g. from wading in water, walking on snow...)
Effective only when some "Dirty feet" option is enabled.]], 'dirtyDuration'),
		variable = createConfigVariable('dirtyDuration'),
		min = 10, max = 300, step = 1, jump = 10,
	})

	controls:createSlider({
		label = 'Wet state detection timer delay: %s ms',
		description = getDescription([[Default: %s ms.
Timer delay (in real time milliseconds) to detect actor in water/dripping wet feet.
Effective only when some "Dirty feet" option is enabled.
Updates on reload.]], 'msInWaterTimerDelay'),
		variable = createConfigVariable('msInWaterTimerDelay'),
		min = 250, max = 5000, step = 1, jump = 10,
	})

	optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}

	controls:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		description = getDropDownDescription('Default: %s','logLevel'),
		variable = createConfigVariable('logLevel'),
	})

	controls:createYesNoButton({
		label = 'Beast races boots/shoes footprints allowed',
		description = getYesNoDescription([[Default: %s.
Beast races by default cannot wear visible boots and always have bare feet footprints.
Only enable if you are using a mod allowing beast races to equip boots/shoes visually covering/replacing beast feet.]], 'beastBoots'),
		variable = createConfigVariable('beastBoots')
	})

	controls:createSlider({
		label = 'Priority',
		description = getDescription([[Default: %s.
addSound() event priority.
As this mods works detecting standard movement sounds, it must be higher than priority for addSound() event
used by other loaded mods that could stop/replace the same sounds.
If this mod does not seem to work, you could try increasing this value.]], 'priority'),
		variable = createConfigVariable('priority'),
		min = 1000, max = 100000, step = 1, jump = 10,
	})

	-- controls:createYesNoButton){
		-- label = 'Look for extra meshes',
		-- description = getDescription([[Look for extra feet meshes for special creatures footprints.
-- Default: %s.
-- Only enable in case extra/future expansion
-- "<creature_mesh_name>_l.nif",
-- "<creature_mesh_name>_r.nif"
-- special footprint meshes are present.]], 'lookForExtraMeshes'),
		-- variable = createConfigVariable('lookForExtraMeshes')
	-- })

	event.register('save', save)
	event.register('load', onLoad)
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)
	event.register('cellDeactivated', cellDeactivated)

	event.register('weatherChangedImmediate', weatherChanged)
	event.register('weatherTransitionFinished', weatherChanged)
	event.register('referenceDeactivated', referenceDeactivated)
	event.register('death', death)

-- must be higher priority than other mods blocking vanilla sounds
	event.register('addSound', addSound, {priority = configPriority})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)
