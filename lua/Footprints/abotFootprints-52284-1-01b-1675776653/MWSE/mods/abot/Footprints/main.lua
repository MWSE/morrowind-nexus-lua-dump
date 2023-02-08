--[[Actors footprints]]

local defaultConfig = {
playerFootprints = true,
npcFootprints = true,
creatureFootprints = true,
maxDistance = 3072, -- max distance from player for footprints spawning (512 - 16384)
dirtyExterior = true,
dirtyInterior = true,
dirtyWeather = true, -- dirty feet in bad weather
dirtyWater = true, -- dirty feet when wet
dirtyTexture = true, -- dirty feet after staying on a dirty surface
footprintDuration = 8, -- Duration of footprints in simulated game hours.
dirtyDuration = 60, -- dirty feet lasting duration in real time seconds
inWaterTimerDelay = 2, -- timer delay to detect in water/dirty feet
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
local dirtyWater = config.dirtyWater
local dirtyTexture = config.dirtyTexture

if config.footprintDuration > 48 then
	config.footprintDuration = defaultConfig.footprintDuration
end

local footprintDuration = config.footprintDuration
local dirtyDuration = config.dirtyDuration
local inWaterTimerDelay = config.inWaterTimerDelay
local configPriority = config.priority
local logLevel = config.logLevel
---local lookForExtraMeshes = config.lookForExtraMeshes
local noFootprints = not (
	playerFootprints
	or npcFootprints
	or creatureFootprints
)
local dirtyEnabled = dirtyWater
and (
	dirtyExterior
	or dirtyInterior
)

local fpStaPrefix = 'ab01fp'
local fpStaSides = {[1] = 'L', [2] = 'R'}

local mData = dofile(modPrefix .. '.data')
local fpStaTypes = mData.fpStaTypes -- {'Anml','Boot','Boot2','Foot','Hoof','Paw','Rept','Skel','Taln'}
local creStaTypes = mData.creStaTypes

local resourcePath = 'abot/fp'

local fpBaseStatics = {}

event.register('initialized',
function ()
	local typ, side, id, name, meshPath
	-- fpStaTypes = {'Anml','Boot','Boot2','Foot','Hoof','Paw','Rept','Skel','Taln'}
	for i = 1, #fpStaTypes do
		typ = fpStaTypes[i]
		for j = 1, 2 do
			side = fpStaSides[j]-- e.g. 'L'
			name = string.format("%s_%s", string.lower(typ), string.lower(side))-- e.g. 'foot_l'
			id = string.format("%s%s%s", fpStaPrefix, typ, side) -- e.g. 'ab01fpFootR', 'ab01fpBoot2L'
			meshPath = string.format('Meshes/%s/%s.nif', resourcePath, name) -- e.g. 'Meshes/abot/fp/foot_r.nif'
			if tes3.getFileExists(meshPath) then
				fpBaseStatics[id] = 2 -- 2 = processed, valid, 1 = processed, not available
				if logLevel >= 4 then
					mwse.log('%s: fpBaseStatics["%s"] = %s', modPrefix, id, fpBaseStatics[id])
				end
			else
				mwse.log('%s error: "%s" not found', modPrefix, meshPath)
			end
		end
	end
end, {doOnce = true})

local tes3_objectType_static = tes3.objectType.static


-- reset in loaded()
local player, player1stPerson

local dirtyActorRefs = {}
local doPack = false

local function packDirtyActorRefs()
	doPack = true
	local t = {}
	for k, v in pairs(dirtyActorRefs) do
		if v then
			t[k] = v
			dirtyActorRefs[k] = nil
		end
	end
	dirtyActorRefs = t
	doPack = false
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
		if logLevel > 0 then
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

local function isBadWeatherIndex(weatherIndex)
 -- 4 Rain, 5 Thunder, 6 Ash, 7 Blight, 8 Snow, 9 Blizzard
	local bad = (weatherIndex >= 4)
			and (weatherIndex <= 9)
	---tes3.messageBox(string.format("weather = %s, bad = %s", w, bad))
	return bad
end

-- deep enough to get sticky dirty feet in e.g. Vivec sewers
local minWaterDepth = 20

local rayDepth = 40 -- must be enough to cover steep angles

local function getWaterLevel(cell)
	if cell.isOrBehavesAsExterior then
		return 0
	end
	if cell.hasWater then
		if cell.waterLevel then
			return cell.waterLevel
		end
	end
	return nil
end

local tes3_objectType_npc = tes3.objectType.npc
local tes3_objectType_creature = tes3.objectType.creature

local function checkValidActor(actorRef)
	local validActor = false
	if actorRef == player then
		if playerFootprints then
			validActor = true
		end
	else
		local objType = actorRef.object.objectType
		if objType == tes3_objectType_npc then
			if npcFootprints then
				validActor = true
			end
		elseif objType == tes3_objectType_npc then
			if creatureFootprints then
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

	local waterLevel
	if t.waterMeshRef then
		waterLevel = t.waterMeshRef.position.z
	else
		waterLevel = getWaterLevel(actorRef.cell)
	end

	if not waterLevel then
		waterLevel = actorPosZ - 1000 -- make it like out of water if no water present
	end

	local logLevel5 = logLevel >= 5

	local depth = waterLevel - actorPosZ
	local minDepthZ = waterLevel - minWaterDepth
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
				elseif logLevel >= 4 then
					mwse.log('%s: timed getInWaterDepth() actor "%s" dirtyActorRefs timer expired', modPrefix, actorRefId)
				end
				dirtyActorRefs[actorRef] = sec
			end
		end
		return depth
	end

	-- in water below
	if dirtyEnabled then
		if logLevel >= 4 then
			mwse.log('%s: getInWaterDepth() actor "%s" deep (%s) in water, dirtyActorRefs timer reset',
				modPrefix, actorRefId, depth)
		end
		dirtyActorRefs[actorRef] = dirtyDuration
	end
	return depth
end

local function timedInWaterCheck()
	if dirtyEnabled then
		for actorRef, sec in pairs(dirtyActorRefs) do
			if sec then
				getInWaterDepth({actRef = actorRef, timed = true})
			end
		end
	end
end

local badWeather = false

local function badWeatherOff()
	if logLevel >= 2 then
		mwse.log('%s: badWeatherOff()', modPrefix)
	end
	badWeather = false
end

local function checkBadWeather(e)
	if not dirtyWeather then
		return
	end
	if not dirtyExterior then
		if not dirtyInterior then
			return
		end
	end
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
		return
	end
	local currBadWeather = isBadWeatherIndex(i)
	if currBadWeather == badWeather then
		return
	end
	badWeather = currBadWeather
	if logLevel >= 2 then
		mwse.log('%s: checkBadWeather(), set badWeather %s', modPrefix, badWeather)
	end
	if badWeather then
		if logLevel >= 2 then
			mwse.log('%s: checkBadWeather(), badWeather timer started', modPrefix)
		end
		timer.start({duration = dirtyDuration, callback = badWeatherOff})
	end
end

local function weatherChanged(e)
	if logLevel >= 2 then
		mwse.log('%s: weatherChanged()', modPrefix)
	end
	checkBadWeather(e)
end

local function cellHasWeather(cell)
	if cell.isOrBehavesAsExterior
	and cell.region then
		return true
	end
	return false
end

local cachedTex = {} -- valid textures ids cache

local texWhitelist = {'grass','dirt','snow','ice','sand','ash','scrub','grave','mud','moss','salt','muck'}
local texDirtyWhitelist = {'dirt','snow','ice','sand','ash','mud','salt','muck'}
local texBlacklist = {'glass',}


local UP = tes3vector3.new(0, 0, 1)
local DOWN = tes3vector3.new(0, 0, -1)

local pi = math.pi
local doublepi = 2 * pi
local deg2rad = pi / 180
local sneakDeltaAngle = 15 * deg2rad

local function getNormalizedAngle(angle)
	if angle > pi then
		return angle - doublepi
	end
	if angle < -pi then
		return angle + doublepi
	end
	return angle
end

local function rotationDifference(vec1, vec2) -- thanks hrnchamd
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

--[[
local function getCulledCells(ref, maxDistanceFromRef)
-- active cells matrix example:
-- ^369
-- |258
-- |147
-- +----->
-- example
-- [1] = -3, -10 [2] = -3, -9 [3] = -3, -8
-- [4] = -2, -10 [5] = -2, -9 [6] = -2, -8
-- [7] = -1, -10 [8] = -1, -9 [9] = -1, -8
-- try marking cells that can be skipped

	local cells = {}

	local cell = ref.cell
	if cell.isInterior then
		cells[1] = cell
		return cells
	end

	if not maxDistanceFromRef then
		maxDistanceFromRef = 11585 -- math.floor(math.sqrt(8192*8192*2) + 0.5)
	elseif maxDistanceFromRef > 34756 then -- math.floor(math.sqrt((3*8192)*(3*8192)*2) + 0.5)
		maxDistanceFromRef = 34756
	end
	---assert(ref)
	local skip = {}
	local x = ref.position.x
	local y = ref.position.y
	local cellGridX = cell.gridX
	local cellGridY = cell.gridY

	local x0 = cellGridX * 8192
	local y0 = cellGridY * 8192
	local x1 = x0 + 8191
	local y1 = y0 + 8191

	-- skip cells depending on distance of target marker from cell borders
	local dx = x1 - x
	if dx > maxDistanceFromRef then
		skip[7] = true
		skip[8] = true
		skip[9] = true
	end

	dx = x - x0
	if dx > maxDistanceFromRef then
		skip[1] = true
		skip[2] = true
		skip[3] = true
	end

	local dy = y1 - y
	if dy > maxDistanceFromRef then
		skip[3] = true
		skip[6] = true
		skip[9] = true
	end
	dy = y - y0
	if dy > maxDistanceFromRef then
		skip[1] = true
		skip[4] = true
		skip[7] = true
	end

	local ac = tes3.getActiveCells()
	local c
	local j = 0
	for i = 1, 9 do
		c = ac[i]
		if not skip[i] then
			j = j + 1
			cells[j] = c
			---mwse.log("culledCell = %s", c.editorName)
		end
	end

	if (j == 0)
	or (logLevel >= 2) then
		local msg = "%s: getCulledCells(ref = %s, maxDistanceFromRef = %s)"
		if j == 0 then
			msg = msg .. " no cells found!"
		end
		mwse.log(msg, modPrefix, ref, maxDistanceFromRef)
	end

	return cells
end

local function getActorsInProximity(targetRef, range)
	local targetRefPos = targetRef.position
	local funcPrefix = string.format('%s getActorsInProximity("%s", %s)', modPrefix, targetRef.id, range)
	local doLog = logLevel >= 4
	local cell = targetRef.cell
	local aDist
	local t = {}

	local function processCell()
		for aRef in cell:iterateReferences({tes3_objectType_npc, tes3_objectType_creature}) do
			aDist = targetRefPos:distance(aRef.position)
			if (aDist <= range)
			 and (not aRef.disabled)
			 and (not aRef.deleted) then
				if doLog then
					mwse.log('%s: aRef = "%s" aDist = %s, range = %s', funcPrefix, aRef.id, aDist, range)
				end
				table.insert(t, aRef)
			end
		end
	end

	if cell.isInterior then
		processCell()
		return t
	end

	local culledCells = getCulledCells(targetRef, range)
	for j = 1, #culledCells do
		cell = culledCells[j]
		if doLog then
			mwse.log('%s: testing culledCells[%s] = %s', funcPrefix, j, cell.editorName)
		end
		processCell()
	end
	return t
end
]]

local function array2str(a)
	if not a then
		return a
	end
	local s = '{'
	local sep = ''
	for i = 1, #a do
		s = s .. string.format('%s"%s"', sep, a[i])
		if i == 1 then
			sep = ', '
		end
	end
	s = s .. '}'
	return s
end

--[[local function table2str(t)
	if not t then
		return t
	end
	local s = '{'
	local sep = ''
	for k, v in pairs(t) do
		s = s .. string.format('%s["%s"] = "%s"', sep, k, v)
		if sep == '' then
			sep = ', '
		end
	end
	s = s .. '}'
	return s
end]]

-- set in modConfigReady()
local worldObjectRoot, worldPickRoot, worldLandscapeRoot

local meshBlacklist = {'water','ex_v_ban','lift'}

local function getTexture(rayHit, actorRef)
	local funcPrefix = string.format('%s getTexture(rayHit = {%s}, actorRef = "%s")',
		modPrefix, rayHit, actorRef)
	local logLevel5 = logLevel >= 5
	local texturingProperty = rayHit.object:getProperty(0x4)
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

	local tex = getFileName(string.lower(fnam))
	if logLevel >= 4 then
		mwse.log('%s: tex = "%s"', funcPrefix, tex)
	end

	local hit = cachedTex[tex]
	if hit then
		if logLevel >= 3 then
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
				if logLevel >= 3 then
					mwse.log('%s: dirtyActorRefs "%s" hit exterior texture = "%s"', funcPrefix, actorRefId, tex)
				end
				return tex -- do not cache it to cachedTex[tex] though
			end
		elseif dirtyInterior then
			if logLevel >= 3 then
				mwse.log('%s: dirtyActorRefs "%s" hit interior texture = "%s"', funcPrefix, actorRefId, tex)
			end
			return tex -- do not cache it to cachedTex[tex] though
		end
	end

	if string.find(tex, 'lava', 1, true) then
		if string.find(tex, 'crust', 1, true) then
			hit = 2 -- dirtyActorRefs
		end
	elseif not string.multifind(tex, texBlacklist, 1, true) then
		if string.multifind(tex, texDirtyWhitelist, 1, true) then
			hit = 2
		elseif string.multifind(tex, texWhitelist, 1, true) then
			hit = 1
		end
	end

	if hit then
		cachedTex[tex] = hit
		if hit == 2 then
			if dirtyTexture then
				dirtyActorRefs[actorRef] = dirtyDuration
				if logLevel >= 3 then
					mwse.log('%s: hit dirtyActorRefs "%s" texture', funcPrefix, tex)
				end
			end
		elseif logLevel >= 3 then
			mwse.log('%s: hit "%s" texture', funcPrefix, tex)
		end

		return tex
	end
	return nil
end

local function rayTest(rayParams)
	local rayHit = tes3.rayTest(rayParams)
	if logLevel < 5 then
		return rayHit
	end
	local funcPrefix = string.format('%s rayTest({position = %s, ignore = %s}, maxDistance = %s, root = %s})',
		modPrefix, array2str(rayParams.position), array2str(rayParams.ignore), rayParams.maxDistance, rayParams.root)
	if rayHit then
		local hitRef = rayHit.reference
		if hitRef then
			local mesh = back2slash(hitRef.object.mesh)
			mwse.log('%s: hitRef = "%s", mesh = "%s"', funcPrefix, hitRef, mesh)
		else
			mwse.log('%s: hitRef = "%s"', funcPrefix, hitRef)
		end
	else
		mwse.log('%s: rayHit = "%s"', funcPrefix, rayHit)
	end
	return rayHit
end


local function placeFootprint(actorRef, objId, fpStaSide)

	local funcPrefix = string.format('%s placeFootprint("%s", "%s", "%s")', modPrefix, actorRef.id, objId, fpStaSide)
	---local actorObj = actorRef.object

	local pos = actorRef.position:copy()

	local actorRefId = actorRef.id
	local mobile = actorRef.mobile

	local logLevel5 = logLevel >= 5

	-- note: a valid rayHit.normal needs return Normal = true in the rayTest

	local rayStartZ = rayDepth
	local boundSize = mobile.boundSize

	if boundSize then
		rayStartZ = boundSize.z * actorRef.scale -- higher startZ as I want to check for actor submerged in fake water
	end

	local toIgnore
	if (actorRef == player)
	or (actorRef == player1stPerson) then
		toIgnore = {player, player1stPerson}
	else
		toIgnore = {actorRef, player, player1stPerson}
	end

	local rayParams = {position = {pos.x, pos.y, pos.z + rayStartZ}, direction = DOWN,
		ignore = toIgnore, maxDistance = rayStartZ + rayDepth,
		returnNormal = true, root = worldObjectRoot -- statics, non carry lights, player
	}

	local tex
	local rayHit = rayTest(rayParams)

	if rayHit then
		local hitRef = rayHit.reference
		if hitRef then
			local hitRefId = hitRef.id
			if hitRefId:startswith(fpStaPrefix) then
				if logLevel >= 4 then
					mwse.log('%s: hit "%s" base footprint, skip', funcPrefix, hitRefId)
				end
				return
			end
			local lcMesh = back2slash(string.lower(hitRef.object.mesh))

			if string.find(lcMesh, 'water', 1, true) then -- fake water mesh exception
				if logLevel > 0 then
					mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
				end
				getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
			end

			if string.multifind(lcMesh, meshBlacklist, 1, true) then
				if logLevel >= 4 then
					mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
				end
				return -- skip problematic meshes
			end

			if hitRef.mobile then -- should never happen as worldObjectRoot should only have player
				if logLevel > 0 then
					mwse.log('%s: hit "%s" mobile, skip', funcPrefix, hitRef.id)
				end
			else
				tex = getTexture(rayHit, actorRef)
			end
		end
	end

	if not tex then
		---local range = 512 -- hopefully no actors bigger than this
		---rayParams.ignore = getActorsInProximity(actorRef, range)
		rayParams.root = worldPickRoot -- interactable (NPCs, items, plants, activators, doors) + EditorMarkers
		rayParams.position = {pos.x, pos.y, pos.z + rayStartZ} -- needs a fresh new position to work!!!
		rayHit = rayTest(rayParams)
		if rayHit then
			local hitRef = rayHit.reference
			if hitRef then
				if hitRef.mobile then -- skip not ignored mobiles
					if logLevel > 0 then
						mwse.log('%s: hit "%s" mobile, skip', funcPrefix, hitRef.id)
					end
				else
					local lcMesh = string.lower(hitRef.object.mesh)
					if string.find(lcMesh, 'water', 1, true) then
						if logLevel > 0 then
							mwse.log('%s: hit "%s" fake water mesh', funcPrefix, lcMesh)
						end
						getInWaterDepth({actRef = actorRef, waterMeshRef = hitRef}) -- update dirtyActorRefs[actorRef]
					end

					if string.multifind(lcMesh, meshBlacklist, 1, true) then
						if logLevel >= 4 then
							mwse.log('%s: hit "%s" blacklisted mesh, skip', funcPrefix, lcMesh)
						end
						return -- skip problematic meshes
					end
					tex = getTexture(rayHit, actorRef)
				end
			end
		end
	end

	if not tex then
		if not actorRef.cell.isInterior then
			rayParams.ignore = nil
			rayParams.root = worldLandscapeRoot -- check terrain
			rayParams.position = {pos.x, pos.y, pos.z + rayDepth} -- needs a fresh new position to work!!!
			rayParams.maxDistance = 2 * rayDepth
			rayHit = rayTest(rayParams)
			if rayHit then
				if rayHit.distance > (rayDepth * 0.9) then
					tex = getTexture(rayHit, actorRef)
				end
			end
		end
	end

	if (not rayHit)
	or (not tex) then
		if logLevel >= 4 then
			mwse.log('%s: no valid texture found, skip', funcPrefix)
		end
		return -- no valid texture found, skip
	end

	local dx = 0
	local dy

	local oriZ = mobile.facing

	if fpStaSide == fpStaSides[1] then  -- left
		dy = 1
		if mobile.isSneaking then
			dx = dx + 1
			oriZ = oriZ - sneakDeltaAngle
		end
	else  -- right
		dy = -2
		if mobile.isSneaking then
			dx = dx - 1
			oriZ = oriZ + sneakDeltaAngle
		end
	end

	oriZ = getNormalizedAngle(oriZ)

	local ori = rotationDifference(UP, rayHit.normal)
	ori.z = oriZ

	if mobile.isMovingForward then
		dy = dy + 10
	elseif mobile.isMovingBack then
		dy = dy - 4
	end
	if mobile.isMovingLeft then
		dx = dx - 3
	elseif mobile.isMovingRight then
		dx = dx + 3
	end

	local footprintScale = 1

	if boundSize then
		local k = actorRef.scale
---		local obj = actorRef.object
---		local objType = obj.objectType
---		if objType == tes3_objectType_npc then
---			local race = obj.race
---			if race then
---				local weight = obj.weight
---				if weight then
---					k = k * weight
---				end
---			end
---		end
		local boundSize_x = boundSize.x * k
		if boundSize_x then
			if boundSize_x > 0 then
				local stdSizeX = 44
				footprintScale = boundSize_x / stdSizeX
				if logLevel >= 3 then
					mwse.log('%s: footprintScale = boundSize_x %s / %s = %s', funcPrefix, boundSize_x, stdSizeX, footprintScale)
				end
				local boundSize_y = boundSize.y * k
				if boundSize_y then
					dy = dy * boundSize_y / boundSize_x
				end
			end
		end
	end

	local kSpeed
	---mwse.log("runSpeed = %s, walkSpeed = %s, velocity = %s", mobile.runSpeed, mobile.walkSpeed, mobile.velocity)
	if mobile.isRunning then
		kSpeed = mobile.runSpeed / 100
	else
		kSpeed = mobile.walkSpeed / 100
	end
	dx = dx * kSpeed
	dy = dy * kSpeed

	local sinZ = math.sin(oriZ)
	local cosZ = math.cos(oriZ)
	local dx2 = (dx * cosZ) + (dy * sinZ)
	local dy2 = (dx * sinZ) + (dy * cosZ)

	local delta = tes3vector3.new(dx2, dy2, 1)

	pos = rayHit.intersection + delta
	local maxZ = actorRef.position.z + 2
	local cellEditorName = actorRef.cell.editorName
	if logLevel5 then
		mwse.log('%s: tes3.createReference({object = "%s", cell = "%s", position = %s, orientation = %s, scale = %s}',
			funcPrefix, objId, cellEditorName, pos, ori, footprintScale)
	end
	local fpRef = tes3.createReference({object = objId, cell = actorRef.cell,
		position = pos:copy(), orientation = ori, scale = footprintScale
	})
	if not fpRef then
		if logLevel5 then
			mwse.log('%s: tes3.createReference({object = "%s", cell = "%s"}) failed', funcPrefix, objId, cellEditorName)
		end
		return
	end

	local fpObj = fpRef.object
	local sceneNode = fpObj.sceneNode
	if sceneNode then
		if (not sceneNode.name)
		or ( not (sceneNode.name == fpStaPrefix) ) then
			sceneNode.name = fpStaPrefix
			if logLevel >= 3 then
				mwse.log('%s "%s".sceneNode.name set to "%s"', funcPrefix, objId, sceneNode.name)
			end
		end
	elseif logLevel >= 3 then
		mwse.log('%s "%s".sceneNode = %s', funcPrefix, objId, sceneNode)
	end

	local p = fpRef.position
	if p.z > maxZ then
		p.z = maxZ -- fix footprint height in case of something clipping on raytrace
	end
	fpRef.modified = false -- important!!! better to not bloat the save
	if logLevel >= 3 then
		mwse.log('%s: actorRef = "%s", objId = "%s", fpRef = "%s"\nscale = %s, pos = %s, actorRefPos = %s',
			funcPrefix, actorRefId, objId, fpRef.id, footprintScale, pos, actorRef.position)
		mwse.log('dx = %s, dy = %s, dx2 = %s, dy2 = %s', dx, dy, dx2, dy2)
	end
end

local lastPlayerFootprintSide

local function placeBaseFootprint(actorRef, fpStaType, fpStaSide)
	if actorRef == player then
		-- always alternate left/right player footprints as it is cheap/fast and more noticeable.
		-- it would be better to do it for all actors but I don't want to manage/store the extra complexity
		if lastPlayerFootprintSide then
			if fpStaSide == lastPlayerFootprintSide then
				if fpStaSide == fpStaSides[1] then
					fpStaSide = fpStaSides[2]
				else
					fpStaSide = fpStaSides[1]
				end
			end
		end
		lastPlayerFootprintSide = fpStaSide
	end

	local objId = string.format("%s%s%s", fpStaPrefix, fpStaType, fpStaSide)

	placeFootprint(actorRef, objId, fpStaSide)
end


local function save()
	local data = player.data or {}
	local doLog = logLevel >= 4
	data.ab01fpDirty = {}
	local ab01fpDirty = data.ab01fpDirty
	local t = {}
-- pack dirtyActorRefs table and save it to player.data.ab01fpDirty
	local lcId
	for ref, sec in pairs(dirtyActorRefs) do
		if sec then
			lcId = string.lower(ref.id)
			if doLog then
				mwse.log('%s: save() ab01fpDirty["%s"] = %s', modPrefix, lcId, sec)
			end
			ab01fpDirty[lcId] = sec
			t[ref] = sec
			dirtyActorRefs[ref] = nil
		end
	end
	dirtyActorRefs = t
end


-- reset in loaded()
local visitedCells = {}

local function clearVisitedCells()
	for k, v in pairs(visitedCells) do
		if v then
			visitedCells[k] = nil
		end
	end
	visitedCells = {}
end

local function deleteFootprints(cell)
	local parent = cell.staticObjectsRoot
	local children = parent.children
	local child
	local count = 0
	local t = os.time()
	local logLevel4 = logLevel >= 4
	local logLevel3 = logLevel >= 3
	local ref
	local deleteCount = 0
	for i = 1, #children do
		child = children[i]
		if child then
			if child.name then
				-- not exact comparison as most of them are like "CLONE ab01fpsomething"
				if string.find(child.name, fpStaPrefix, 1, true) then
					--- parent:detachChild(child) -- no more needed if we delete the reference
					ref = child:getGameReference()
					if ref then
						if logLevel4 then
							mwse.log('%s deleteFootprints("%s") before child.name = "%s", ref = "%s", ref.modified = %s, ref.disabled = %s, ref.deleted = %s',
								modPrefix, cell.editorName, child.name, ref.id, ref.modified, ref.disabled, ref.deleted)
						end
						if not ref.disabled then
							ref:delete()
							deleteCount = deleteCount + 1
							if ref then
								ref.modified = false -- important!!!
								if logLevel4 then
									mwse.log('%s deleteFootprints("%s") after child.name = "%s", ref = "%s", ref.modified = %s, ref.disabled = %s, ref.deleted = %s',
										modPrefix, cell.editorName, child.name, ref.id, ref.modified, ref.disabled, ref.deleted)
								end
							end
						end
					end
					count = count + 1
				end
			end
		end
	end
	if logLevel3 then
		if count > 0 then
			t = os.time() - t -- it is fast even with logging
			mwse.log('%s: deleteFootprints() %08d footprint nodes found, %08d footprint references deleted from "%s" cell in %f seconds.',
				modPrefix, count, deleteCount, cell.editorName, t)
		end
	end
end

local function checkCellFootprints(cell, now)
	local lastVisited = visitedCells[cell]
	if lastVisited then
		local diff = now - lastVisited
		if diff > footprintDuration then
			if logLevel >= 4 then
				mwse.log('%s: checkCellFootprints("%s") cell not visited for %s seconds, delete footprints.',
					modPrefix, cell.editorName, diff)
			end
			visitedCells[cell] = nil
			deleteFootprints(cell)
		end
	else
		visitedCells[cell] = now
	end
end

local function cellChanged(e)
	local now = tes3.getSimulationTimestamp() -- in game simulated hours, taking timescale into account
	local previousCell = e.previousCell
	if previousCell then
		checkCellFootprints(previousCell, now)
	end
	local cell = e.cell
	checkCellFootprints(cell, now)

	if doPack then
		packDirtyActorRefs()
	end
	if not (
		dirtyExterior
		or dirtyInterior
	)
	or (not dirtyWeather) then
		badWeather = false
		return
	end
	if cellHasWeather(cell) then
		checkBadWeather()
	end
end


local function loaded()
	player = tes3.player
	player1stPerson = tes3.player1stPerson

	-- clear dirtyActorRefs table
	clearDirtyActorRefs()
	clearVisitedCells()

	local data = player.data or {}
	local ab01fpDirty = data.ab01fpDirty
	if ab01fpDirty then
		local actorRef
		local doLog = logLevel >= 4
		local playerPos = player.position
		-- rebuild dirtyActorRefs table from player.data.ab01fpDirty
		for actorRefId, sec in pairs(ab01fpDirty) do
			actorRef = tes3.getReference(actorRefId)
			if actorRef then
				if actorRef.position:distance(playerPos) <= 16384 then
					if doLog then
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
local fpSndSides = {'left', 'right'}

local tes3_effect_levitate = tes3.effect.levitate
local tes3_effect_slowFall = tes3.effect.slowFall

---local lastFootprintId


local function addSound(e)
	if noFootprints then
		return
	end
	local funcPrefix = string.format("%s addSound(e)", modPrefix)

	local sound = e.sound
	if not sound then
		if logLevel > 0 then
			mwse.log('%s warning: no e.sound, skip', funcPrefix)
		end
		return
	end
	local actorRef = e.reference
	if not actorRef then
		return -- it happens!!!
	end

	local actorRefId = actorRef.id

	if actorRef == player1stPerson then
		if logLevel >= 5 then
			mwse.log('%s: replacing "%s" with "%s"', funcPrefix, actorRefId, player.id)
		end
		actorRef = player
	end

	local actorObj = actorRef.object

	local logLevel5 = logLevel >= 5

	--[[if logLevel5 then
		mwse.log('%s: actorRef = "%s"', funcPrefix, actorRefId)
	end]]

	local actorIsPlayer = (actorRef == player)

	if actorIsPlayer then
		if not playerFootprints then
			if logLevel >= 4 then
				mwse.log('%s: "%s" is player, player footprints disabled, skip', funcPrefix, actorRefId)
			end
			return
		end
	end

	local objType = actorObj.objectType

	if objType == tes3_objectType_npc then
		if not npcFootprints then
			if logLevel >= 4 then
				mwse.log('%s: "%s" is NPC, NPC footprints disabled, skip', funcPrefix, actorRefId)
			end
			return
		end
	elseif objType == tes3_objectType_creature then
		if not creatureFootprints then
			if logLevel >= 4 then
				mwse.log('%s: "%s" is creature, creature footprints disabled, skip', funcPrefix, actorRefId)
			end
			return
		end
	else
		if logLevel >= 5 then
			mwse.log('%s: "%s" is not some npc/creature, skip', funcPrefix, actorRefId)
		end
		return
	end

	local actorMesh = actorObj.mesh
	if (not actorMesh)
	or (actorMesh == '') then
		if logLevel5 then
			mwse.log('%s: "%s" actor with no mesh, skip', funcPrefix, actorRefId)
		end
		return
	end

	local mobile = actorRef.mobile
	if not mobile then
		if logLevel > 0 then
			mwse.log('%s: warning no actorRef.mobile, skip', funcPrefix)
		end
		return
	end

	-- skip these creatures early
	if actorObj.swims
	or actorObj.flies then
		if not actorObj.walks then
			if not actorObj.biped then
				if logLevel5 then
					mwse.log('%s: "%s" swimming/flying creature, skip', funcPrefix, actorRefId)
				end
				return
			end
		end
	end

	if mobile.underwater then
		if logLevel5 then
			mwse.log('%s: "%s".underwater, getInWaterDepth, skip', funcPrefix, actorRefId)
		end
		getInWaterDepth({actRef = actorRef}) -- upgrade dirtyActorRefs[actorRef]
		return
	end

	if not mobile.canJump then
-- includes dead, knocked down, knocked out, paralyzed, jumping, falling, swimming, flying
		if not mobile.isSwimming then
			if logLevel5 then
				mwse.log('%s: not "%s".canJump, skip', funcPrefix, actorRefId)
			end
			return
		end
	end

-- canJump is not reliable enough
	local effects = mobile:getActiveMagicEffects({effect = tes3_effect_levitate})
	if effects then
		if effects[1] then
			if logLevel5 then
				mwse.log('%s: "%s" levitate effect, skip', funcPrefix, actorRefId)
			end
			return
		end
	end
	effects = mobile:getActiveMagicEffects({effect = tes3_effect_slowFall})
	if effects then
		if effects[1] then
			if logLevel5 then
				mwse.log('%s: "%s" slowFall effect, skip', funcPrefix, actorRefId)
			end
			return
		end
	end

	local lcSndId = string.lower(sound.id)
	if mobile.waterWalking > 0 then -- waterWalking is a number!
		if (lcSndId == 'footwaterleft')
		or (lcSndId == 'footwaterright') then
			if logLevel5 then
				mwse.log('%s: "%s" waterwalking sound, skip', funcPrefix, actorRefId)
			end
			return
		end
	end

	if e.isVoiceover then
		if logLevel5 then
			mwse.log('%s: "%s" e.isVoiceover, skip', funcPrefix, actorRefId)
		end
		return
	end

	if logLevel5 then
		mwse.log('%s: actor = "%s"', funcPrefix, actorRefId)
	end

	local depth = getInWaterDepth({actRef = actorRef}) -- also upgrades dirtyActorRefs[actorRef]
	if depth >= minWaterDepth then
		if logLevel >= 4 then
			mwse.log('%s: "%s" in water depth (%s) >= minWaterDepth (%s), skip',
				funcPrefix, actorRefId, depth, minWaterDepth)
		end
		return
	end

	if not actorIsPlayer then
		local dist = mobile.playerDistance
		if dist then
			if dist > maxDistance then
				if logLevel5 then
					mwse.log('%s: "%s".playerDistance (%s) > maxDistance (%s), skip',
						funcPrefix, actorRefId, dist, maxDistance)
				end
				return
			end
		else -- something wrong
			if logLevel > 0 then
				mwse.log('%s warning: "%s".playerDistance = %s, skip', funcPrefix, actorRefId, dist)
			end
			return
		end
	end

	local fnam = sound.filename
	if not fnam then
		if logLevel > 0 then
			mwse.log('%s warning: sound.filename = "%s", skip', funcPrefix, fnam)
		end
		return
	end
	local lcFilename = back2slash(string.lower(fnam)) -- converting to avoid risk of invalid escape sequence on string processing

	if not (
		string.startswith(lcFilename, 'fx/')
		or string.startswith(lcFilename, 'cr/')
	) then -- skip non-standard sounds
		if logLevel5 then
			mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s" not starting with "fx/" or "cr/", skip', funcPrefix, actorRefId, sound.id, fnam)
		end
		return
	end

	if logLevel >= 4 then
		mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s"', funcPrefix, actorRefId, sound.id, fnam)
	end

	local fpStaType, fpStaSide

	-- try and match special case walk[lr] first
	local fpSndType, fpSndSide = string.match(lcFilename, "(walk)([lr])_") -- e.g. 'fx/foot/walkl_md.wav'
	if logLevel >= 4 then
		mwse.log('%s: fpSndType = "%s", fpSndSide = "%s"', funcPrefix, fpSndType, fpSndSide)
	end

	if fpSndSide then
		fpStaSide = string.upper(fpSndSide) -- 'L' or 'R'
	else
		fpSndType = nil
	end

	if not fpSndType then
		fpSndType = string.multifind(lcFilename, fpSndTypes, 1, true)
	end
	if not fpSndType then
		if logLevel5 then
			mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s" not a standard foot sound type, skip',
				funcPrefix, actorRefId, sound.id, fnam)
		end
		return
	end

	if logLevel >= 3 then
		mwse.log('%s: actorRef = "%s", sound = "%s", fnam = "%s"', funcPrefix, actorRefId, sound.id, fnam)
	end

	if not fpStaSide then
		for i = 1, #fpSndSides do
			if string.find(lcSndId, fpSndSides[i], 1, true) then
				fpSndSide = fpSndSides[i]
				fpStaSide = fpStaSides[i]
				if logLevel >= 4 then
					mwse.log('%s: string.find("%s", "%s", 1, true)', funcPrefix, lcSndId, fpSndSide)
				end
				break
			end
		end
	end

	if not fpSndSide then
		if logLevel5 then
			mwse.log('%s: fpSndSide not found, skip', funcPrefix)
		end
		return
	end
	if not fpStaSide then
		if logLevel5 then
			mwse.log('%s: fpStaSide not found, skip', funcPrefix)
		end
		return
	end

	if objType == tes3_objectType_npc then
		local isBodyFallSound = (lcSndId == 'body fall large')
			or (lcSndId == 'body fall medium')
			or (lcSndId == 'body fall small')
-- fpStaTypes = 'Anml','Boot','Boot2','Foot','Hoof','Paw','Rept','Skel','Taln'}
		if isBodyFallSound then
			fpStaType = 'Boot'
		elseif lcSndId == 'defaultland' then
			fpStaType = 'Foot'
		end
		if fpStaType then -- falling NPC or animal
			placeBaseFootprint(actorRef, fpStaType, fpStaSides[1]) --L
			timer.start({duration = 0.1, type = timer.real, callback = function ()
				placeBaseFootprint(actorRef, fpStaType, fpStaSides[2]) --R
			end})
			return
		end

		if mobile.werewolf then
			fpStaType = 'Paw'
		else -- look for equipped boots
			local equippedBootsStack = tes3.getEquippedItem({actor = actorRef,
				objectType = tes3_objectType_armor, slot = tes3_armorSlot_boots})
			if equippedBootsStack then
				local weightClass = equippedBootsStack.object.weightClass
				if weightClass > 0 then
					fpStaType = 'Boot2'
				else
					fpStaType = 'Boot'
				end
			else -- no boots equipped, look for equipped shoes
				local equippedShoesStack = tes3.getEquippedItem({actor = actorRef,
					objectType = tes3_objectType_clothing, slot = tes3_clothingSlot_shoes})
				if equippedShoesStack then
					fpStaType = 'Boot'
				else -- no shoes equipped, check race
					fpStaType = 'Foot' -- default
					local race = actorObj.race
					if race then
						if race.isBeast then
							local lcRaceId = string.lower(race.id)
							if lcRaceId == 'argonian' then
								fpStaType = 'Rept'
							else
								fpStaType = 'Paw'
							end -- if lcRaceId
						end -- if race.isBeast
					end -- if race
				end -- if equippedShoesStack
			end -- if equippedBootsStack
		end -- if mobile.werewolf
		if logLevel >= 3 then
			mwse.log('%s: fpSndType = "%s" lcFilename = "%s"', funcPrefix, fpSndType, lcFilename)
		end
		placeBaseFootprint(actorRef, fpStaType, fpStaSide)

		return
	end

	-- remaining creature processing below

	local lcMeshName = getFileName(string.lower(actorMesh)) -- e.g. 'bear_black_larger'
	local creStaType = creStaTypes[lcMeshName] -- e.g. 'Paw'
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
	local fpId = string.format("%s_%s", lcMeshName, string.lower(fpStaSide)) -- e.g. new fpId is now 'earth golem_r'
	if not (fpId == lastFootprintId) then
		lastFootprintId = fpId
		doLog = logLevel >= 2
	end
	if doLog then
		mwse.log('%s: fpId = "%s"', funcPrefix, fpId)
	end

	-- skip practice dummy/mannequins/archery target creatures
	if not string.multifind(lcMeshName, {'dumm','mann','target'}, 1, true) then
		local fpStatic = fpBaseStatics[fpId]
		if fpStatic then
			if fpStatic > 1 then -- foot mesh already found, object already created and stored
				placeFootprint(actorRef, fpId, fpStaSide) -- place it
			end
			return -- already processed but no mesh found, skip
		end

		local filePath = getFilePath(lcMeshName) -- e.g. "wormgod/"
		if doLog then
			mwse.log('%s: filePath = "%s"', funcPrefix, filePath)
		end
		local fpMeshPath = string.format("%s%s.nif", filePath, fpId) -- add .nif e.g. now "wormgod/Earth Golem_R.nif"

		if tes3.getFileExists('Meshes/'..fpMeshPath) then
			if doLog then
				mwse.log('%s: tes3.loadMesh("%s")', funcPrefix, fpMeshPath)
			end
			local fpMesh = tes3.loadMesh(fpMeshPath)
			if fpMesh then -- e.g. a special "wormgod\earth golem_r.nif" foot mesh is found
				local fpObj = tes3.createObject({objectType = tes3_objectType_static, id = fpId, mesh = fpMesh})
				if fpObj then
					fpObj.sceneNode.name = fpStaPrefix
					fpBaseStatics[fpId] = 2 -- flag for created/available object
					placeFootprint(actorRef, fpId, fpStaSide) -- place it
					return
				end
			end
		end

	end

	fpBaseStatics[fpId] = 1 -- flag for processed but mesh not found/object not created
	]]
end -- addSound(e)


local function referenceDeactivated(e)
	local ref = e.reference
	if dirtyActorRefs[ref] then
		if logLevel >= 4 then
			mwse.log('%s: referenceDeactivated() dirtyActorRefs["%s"] = nil', modPrefix, ref.id)
		end
		dirtyActorRefs[ref] = nil
		doPack = true
	end
end

local function death(e)
	local ref = e.reference
	if dirtyActorRefs[ref] then
		if logLevel >= 4 then
			mwse.log('%s: death() dirtyActorRefs["%s"] = nil', modPrefix, ref.id)
		end
		dirtyActorRefs[ref] = nil
		doPack = true
	end
end



local function modConfigReady()

	local function createConfigVariable(varId)
		return mwse.mcm.createTableVariable{id = varId, table = config}
	end

	worldObjectRoot = tes3.game.worldObjectRoot
	worldPickRoot = tes3.game.worldPickRoot
	---assert(worldPickRoot)
	worldLandscapeRoot = tes3.game.worldLandscapeRoot

	local function createFootprintObjects()
		local objId, objMesh, obj, typ, side, s
	-- fpStaTypes = {'Anml','Boot','Boot2','Foot','Hoof','Paw','Rept','Skel','Taln'}
		local doLog = logLevel >= 5
		for i = 1, #fpStaTypes do
			typ = fpStaTypes[i] -- e.g. 'Paw'
			for j = 1, 2 do
				side = fpStaSides[j] -- e.g. 'L'
				objId = string.format("%s%s%s", fpStaPrefix, typ, side) -- e.g. 'ab01fpPawL'
				objMesh = string.format("%s/%s_%s.nif", resourcePath, string.lower(typ), string.lower(side)) -- e.g. 'abot/fp/paw_l.nif'
				obj = tes3.createObject({objectType = tes3_objectType_static, id = objId, mesh = objMesh})
				if doLog then
					if obj then
						s = 'success'
					else
						s = 'failed'
					end
					mwse.log('%s: "%s" creation from "meshes/%s" %s', modPrefix, objId, objMesh, s)
				end
			end
		end
	end
	createFootprintObjects()

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		playerFootprints = config.playerFootprints
		npcFootprints = config.npcFootprints
		creatureFootprints = config.creatureFootprints
		maxDistance = config.maxDistance
		dirtyExterior = config.dirtyExterior
		dirtyInterior = config.dirtyInterior
		dirtyWeather = config.dirtyWeather
		dirtyWater = config.dirtyWater
		dirtyTexture = config.dirtyTexture
		footprintDuration = config.footprintDuration
		dirtyDuration = config.dirtyDuration
		inWaterTimerDelay = config.inWaterTimerDelay
		logLevel = config.logLevel
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
		dirtyEnabled = dirtyWater
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

	local info = [[Actors footprints]]

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

	local function getDescriptionYesNo(frmt, variableId)
		return string.format(frmt, yesOrNo[defaultConfig[variableId]])
	end

	controls:createYesNoButton{
		label = 'Player footprints',
		description = getDescriptionYesNo('Enable player footprints. Default: %s.', 'playerFootprints'),
		variable = createConfigVariable('playerFootprints')
	}
	controls:createYesNoButton{
		label = 'NPCs footprints',
		description = getDescriptionYesNo('Enable NPCs footprints. Default: %s.', 'npcFootprints'),
		variable = createConfigVariable('npcFootprints')
	}
	controls:createYesNoButton{
		label = 'Creatures footprints',
		description = getDescriptionYesNo('Enable creatures footprints. Default: %s.', 'creatureFootprints'),
		variable = createConfigVariable('creatureFootprints')
	}

	controls:createSlider({
		label = 'Footprints max distance',
		description = getDescription('Max distance from player for footprints spawning.\nDefault: %s.', 'maxDistance'),
		variable = createConfigVariable('maxDistance')
		,min = 512, max = 15384, step = 1, jump = 10
	})

	controls:createYesNoButton{
		label = 'Dirty feet in exteriors/interiors with bad weather',
		description = getDescriptionYesNo('Enables dirty feet in exteriors/interiors with bad weather.\nDefault: %s.', 'dirtyExterior'),
		variable = createConfigVariable('dirtyExterior')
	}

	controls:createYesNoButton{
		label = 'Dirty feet in interiors',
		description = getDescriptionYesNo('Enables having still dirty feet for a while after entering interiors.\nDefault: %s.', 'dirtyInterior'),
		variable = createConfigVariable('dirtyInterior')
	}

	controls:createYesNoButton{
		label = 'Dirty feet in bad weather',
		description = getDescriptionYesNo('Enables dirty feet in bad weather (e.g. raining, snowing).\nDefault: %s.', 'dirtyWeather'),
		variable = createConfigVariable('dirtyWeather')
	}

	controls:createYesNoButton{
		label = 'Dirty feet when wet',
		description = getDescriptionYesNo('Enables dirty feet when wet from wading water..\nDefault: %s.', 'dirtyWater'),
		variable = createConfigVariable('dirtyWater')
	}

	controls:createYesNoButton{
		label = 'Dirty feet from dirty/sticky surfaces',
		description = getDescriptionYesNo([[Enables dirty feet from walking over a dirty/sticky surface
e.g. mud, snow, lava, sand...
Default: %s]], 'dirtyTexture'),
		variable = createConfigVariable('dirtyTexture')
	}

	controls:createSlider{
		label = 'Footprints duration: %s simulated game hours',
		description = getDescription([[Duration of footprints in simulated game hours.
Default: %s.
Effective only when some "Dirty feet" option is enabled.
Note: no footprint reference data is added to game saves, and any visible footprint is discarded on game executable restart.]],
'footprintDuration'),
		variable = createConfigVariable('footprintDuration'),
		min = 1, max = 48, step = 1, jump = 5,
	}
	controls:createSlider{
		label = 'Dirty feet duration: %s sec',
		description = getDescription([[Duration in real time seconds of dirty feet
(e.g. from wading in water, walking on snow...)
Default: %s.
Effective only when some "Dirty feet" option is enabled.]], 'dirtyDuration'),
		variable = createConfigVariable('dirtyDuration'),
		min = 10, max = 300, step = 1, jump = 10,
	}

	controls:createSlider{
		label = 'Wet state detection timer delay',
		description = getDescription([[Timer delay (in real time seconds) to detect actor in water/dripping wet feet.
Default: %s.
Effective only when some "Dirty feet" option is enabled.
Updates on reload.]], 'inWaterTimerDelay'),
		variable = createConfigVariable('inWaterTimerDelay'),
		min = 1, max = 5, step = 1, jump = 1,
	}

	controls:createSlider{
		label = 'Priority',
		description = getDescription([[addSound() event priority.
As this mods works detecting standard movement sounds, it must be higher than priority for addSound() event
used by other loaded mods that could stop/replace the same sounds.
Default: %s.
If this mod does not seem to work, you could try increasing this value.]], 'priority'),
		variable = createConfigVariable('priority'),
		min = 1000, max = 100000, step = 1, jump = 10,
	}

	-- controls:createYesNoButton{
		-- label = 'Look for extra meshes',
		-- description = getDescription([[Look for extra feet meshes for special creatures footprints.
-- Default: %s.
-- Only enable in case extra/future expansion
-- "<creature_mesh_name>_l.nif",
-- "<creature_mesh_name>_r.nif"
-- special footprint meshes are present.]], 'lookForExtraMeshes'),
		-- variable = createConfigVariable('lookForExtraMeshes')
	-- }

	controls:createDropdown({
		label = 'Logging level:',
		options = {
			{ label = '0. Off', value = 0 },
			{ label = '1. Low', value = 1 },
			{ label = '2. Medium', value = 2 },
			{ label = '3. High', value = 3 },
			{ label = '4. Higher', value = 4 },
			{ label = '5. Max', value = 5 },
		},
		variable = createConfigVariable('logLevel'),
		description = [[Logging level. Default: 0. Off.]]
	})

	event.register('save', save)
	event.register('loaded', loaded)
	event.register('cellChanged', cellChanged)
	event.register('weatherChangedImmediate', weatherChanged)
	event.register('weatherTransitionFinished', weatherChanged)
	event.register('referenceDeactivated', referenceDeactivated)
	event.register('death', death)

-- must be higher priority of other mods blocking vanilla sounds
	event.register('addSound', addSound, {priority = configPriority})

	mwse.mcm.register(template)
end
event.register('modConfigReady', modConfigReady)
