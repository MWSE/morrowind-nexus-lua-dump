--[[
Avoid actors getting stuck while opening doors
]]

-- begin configurable parameters
local defaultConfig = {
doorAntiStuck = 1, -- 0 = disabled, 1 = only handy actors, 2 = all actors
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
}
-- end configurable parameters
local author = 'abot'
local modName = 'Doors Anti Stuck'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
---assert(config)

 -- set in modConfigReady()
local antiStuck
local logLevel, logLevel1, logLevel2, logLevel3

local function updateFromConfig()
	antiStuck = config.doorAntiStuck
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end
updateFromConfig()

 -- set in loaded()
local player

local movingCollidingActor -- used in collision() event, reset in loaded()

local tes3_objectType_door = tes3.objectType.door
local tes3_actionFlag_doorJammedOpening = tes3.actionFlag.doorJammedOpening
local tes3_actionFlag_doorJammedClosing = tes3.actionFlag.doorJammedClosing
local tes3_actionFlag_useEnabled = tes3.actionFlag.useEnabled

local tes3_actorType_creature = tes3.actorType.creature
---local tes3_actorType_npc = tes3.actorType.npc
local tes3_creatureType_normal = tes3.creatureType.normal
---local tes3_creatureType_undead = tes3.creatureType.undead

--[[local function getStartingAngle(ref)
	local globalVar = tes3.findGlobal('TimeScale')
	local temp = globalVar.value
	tes3.runLegacyScript({command = "set TimeScale to GetStartingAngle Z", reference = ref,
		source = tes3.compilerSource.console})
	local result = globalVar.value
	globalVar.value = temp
	return result * deg2radMul
end]]

local backDistX, backDistY
local tryCount = 0

local function normalized0_360(angleDeg)
	local result = angleDeg % 360
	if result < 0 then
		result = result + 360
	end
	return result
end

local math_pi = math.pi

local function getTimerRef(e)
	local timer = e.timer
	if not timer then
		return
	end
	local data = timer.data
	if not data then
		return
	end
	local handle = data.handle
	if not handle then
		return
	end
	if not handle.valid then
		return
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function ab01doanstPT1(e)
	movingCollidingActor = nil
	local mobRef = getTimerRef(e)
	if not mobRef then
		return
	end
	local mob = mobRef.mobile
	if not mob then
		return
	end
	if logLevel2 then
		mwse.log('%s: "%s" mobToMobCollision restored', modPrefix, mobRef.id)
	end
	mob.mobToMobCollision = true
end

local xy_max_ori = math.rad(11)

local function collision(e)
	if antiStuck == 0 then
		return
	end
	local doorRef = e.target
	if not doorRef then -- silly, but it happens
		return
	end
	local doorObj = doorRef.object
	if not (doorObj.objectType == tes3_objectType_door) then
		return
	end
	local actorRef = e.reference
	if not actorRef then
		return -- better safe than sorry
	end
	if actorRef == player then
		return
	end
	if doorRef.destination then
		return
	end
	if doorObj.script
	and ( not doorRef:testActionFlag(tes3_actionFlag_useEnabled) ) then
		return -- skip scripted OnActivate doors
	end
	local lockNode = doorRef.lockNode
	if lockNode
	and	lockNode.locked then
		return
	end
	local cell = actorRef.cell
	if not cell then -- it may happen
		return
	end
	local cellName = cell.editorName

	-- thanks NullCascade for adding this
	local doorStartingOrientation = doorRef.startingOrientation

	if (math.abs(doorStartingOrientation.x) >= xy_max_ori)
	and (math.abs(doorStartingOrientation.y) >= xy_max_ori) then
		if logLevel2 then
			mwse.log('%s: "%s" "%s" actor colliding with non-vertical-rotating door "%s", skip',
				modPrefix, cellName, actorRef.id, doorRef.id)
		end
		return -- skip those pesky non-vertical-rotation doors e.g. telvanni slave pods
	end

	 -- facing range could be e.g. > PI if place in the CS
	local actorRadFacing = actorRef.facing
	local actorRadAngleToDoor = actorRef:getAngleTo(doorRef)
	if logLevel3 then
		mwse.log('%s: "%s" "%s" actor facing = %s deg, actor angle to door "%s" = %s deg', modPrefix, cellName, actorRef.id, math.deg(actorRadFacing), doorRef.id, math.deg(actorRadAngleToDoor))
	end
	if math.abs(actorRadAngleToDoor) >= math_pi then
		return
	end

	local mobile = actorRef.mobile
	if mobile.movementCollision == false then
		if logLevel1 then
			mwse.log('%s: "%s" "%s" colliding actor with "%s" has movementCollision = false, skip',
				modPrefix, cellName, actorRef.id, doorRef.id)
		end
		return -- skip actors with movement collision disabled
	end

	local doorStartingAngle = doorStartingOrientation.z
	local doorStartingAngleDeg = normalized0_360(math.deg(doorStartingAngle))

	-- in theory facing is [0, 2PI] radians for non actors but better safe than sorry
	local doorCurrAngleDeg = normalized0_360(math.deg(doorRef.facing))

	local angleDiffDeg = math.abs(doorCurrAngleDeg - doorStartingAngleDeg)
	if logLevel3 then
		mwse.log('%s: "%s" "%s" %s doorStartingAngle = %s, doorCurrAngle = %s, angleDiff = %s',
			modPrefix, cellName, doorRef.id, doorRef.position, doorStartingAngleDeg, doorCurrAngleDeg, angleDiffDeg)
	end
	local doorOpenedEnough = (angleDiffDeg >= 65)

	if movingCollidingActor then
		---if not (mobile == movingCollidingActor) then
			---return
		---end
		-- move actor back while opening the door

		---if doorRef:testActionFlag(tes3_actionFlag_doorJammedOpening)
		---or doorRef:testActionFlag(tes3_actionFlag_doorJammedClosing) then
			if tryCount < 7 then
				tryCount = tryCount + 1
				local pos = mobile.position:copy()
				mobile.position.x = pos.x - (backDistX / tryCount)
				mobile.position.y = pos.y - (backDistY / tryCount)
				if logLevel1 then
					mwse.log('%s: "%s" moving "%s" actor colliding with "%s" from %s back to %s...',
						modPrefix, cellName, actorRef.id, doorRef.id, pos, mobile.position)
				end
			else
				tryCount = 0
				if not doorOpenedEnough then
					if doorRef:testActionFlag(tes3_actionFlag_doorJammedClosing)
					or (not doorRef:testActionFlag(tes3_actionFlag_doorJammedOpening)) then
						if logLevel1 then
							mwse.log('%s: "%s" "%s" activating jammed door "%s"...', modPrefix, cellName, actorRef.id, doorRef.id)
						end
						actorRef:activate(doorRef)
					end
				--[[else
					if logLevel1 then
						mwse.log('%s: "%s" removing "%s" collision with door "%s"...', modPrefix, cellName, actorRef.id, doorRef.id)
					end
					mobile.movementCollision = false]]
				end
			end
		---end

		return
	end

	if mobile.actorType == tes3_actorType_creature then
		local crea = mobile.reference.baseObject
		if (not crea.biped)
		and (not crea.usesEquipment)
		and (crea.type == tes3_creatureType_normal)
		and (antiStuck < 2) then
			if logLevel2 then
				mwse.log('%s: "%s" creature "%s" colliding with "%s" is unable to handle door opening, skip...',
					modPrefix, cellName, actorRef.id, doorRef.id)
			end
			return -- skip less handy creatures
		end
		if not doorOpenedEnough then
			if logLevel2 then
				mwse.log('%s: "%s" "%s" creature colliding with "%s", activating the door...', modPrefix, cellName, actorRef.id, doorRef.id)
			end
			actorRef:activate(doorRef) -- enforce it as creatures are often not smart enough to open the door
		end
	end

	if doorOpenedEnough then
		return
	end

	local doorBounds = doorRef.object.boundingBox
	local doorWidth
	if doorBounds then
		local doorBoundsMax = doorBounds.max
		local doorBoundsMin = doorBounds.min
		doorWidth = math.max(doorBoundsMax.y - doorBoundsMin.y, doorBoundsMax.x - doorBoundsMin.x)
	else -- loading doors may be one-facing and have no boundingBox
		doorWidth = 128
	end
	doorWidth = doorWidth * doorRef.scale
	local boundSize_y = mobile.boundSize.y * actorRef.scale
	local backDist = doorWidth - (boundSize_y * 0.5)
	backDistX = backDist * math.sin(actorRadFacing)
	backDistY = backDist * math.cos(actorRadFacing)

	local actorRefId = actorRef.id
	if logLevel2 then
		mwse.log('%s: "%s" "%s" actor mobToMobCollision disabled', modPrefix, cellName, actorRefId)
	end

	mobile.mobToMobCollision = false -- else if more than one they get stuck each other
	movingCollidingActor = mobile
	local refHandle = tes3.makeSafeObjectHandle(actorRef)
	timer.start({duration = 2, callback = 'ab01doanstPT1',
		data = {handle = refHandle}	})
end

local initDone = false
local function initOnce()
	if initDone then
		return
	end
	initDone = true
	event.register('collision', collision)
end

local function loaded()
	player = tes3.player
	movingCollidingActor = nil
	initOnce()
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable({id = varId, table = config})
end

local function modConfigReady()

	if type(config.doorAntiStuck) == 'boolean' then
		config.doorAntiStuck = defaultConfig.doorAntiStuck
	end

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		updateFromConfig()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage({
		label = "Preferences",
		postCreate = function(self)
			local width1 = 1.2
			local width2 = 2 - width1 -- total width must be 2
			local sideBlock = self.elements.sideToSideBlock
			sideBlock.children[1].widthProportional = width1
			sideBlock.children[2].widthProportional = width2
		end
	})

	local info = [[Avoid actors getting stuck while opening doors]]
	local sidebar = preferences.sidebar
	sidebar:createInfo({text = info})

	local controls = preferences:createCategory({label = mcmName})

	---controls:createInfo({text = "mcmName"})

	controls:createDropdown({
		label = "Doors Anti Stuck:",
		options = {
			{ label = "0. Disabled", value = 0 },
			{ label = "1. Handy actors only", value = 1 },
			{ label = "2. All actors", value = 2 },
		},
		variable = createConfigVariable("doorAntiStuck"),
		description = [[Doors Anti Stuck. Default: 1. Handy actors only.
Toggle mod Doors Anti Stuck feature. When enabled, actors should move back a little instead of getting stuck while trying to open a door.
"1. Handy Actors only" means only actors able to manipulate the doors will be affected, this is the most realistic option, but
"2. All actors" may be useful for those times when e.g. a rat is blocking a door opening]]
	})

	controls:createDropdown({
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
		},
		variable = createConfigVariable("logLevel"),
		description = "Debug logging level. Default: 0. Off."
	})
	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
 -- happens before initialized()
event.register('modConfigReady', modConfigReady)

event.register('initialized',
function ()
	timer.register('ab01doanstPT1', ab01doanstPT1)
	event.register('loaded', loaded)
end, {doOnce = true})

