--[[
Avoid actors getting stuck while opening doors /abot
]]

-- begin configurable parameters
local defaultConfig = {
doorAntiStuck = true,
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
local logLevel = config.logLevel
local noAntiStuck = not config.doorAntiStuck

 -- set in loaded()
local player

local movingCollidingActor = false -- used in collision() event, reset in loaded()

local tes3_objectType_door = tes3.objectType.door
local tes3_actionFlag_doorJammedOpening = tes3.actionFlag.doorJammedOpening
local tes3_actionFlag_doorJammedClosing = tes3.actionFlag.doorJammedClosing

local math_pi = math.pi
local rad2degMul = 180 / math_pi
---local double_pi = math_pi * 2.0
---local deg2radMul = math_pi / 180

local tes3_actorType_creature = tes3.actorType.creature
---local tes3_actorType_npc = tes3.actorType.npc
local tes3_creatureType_normal = tes3.creatureType.normal
---local tes3_creatureType_undead = tes3.creatureType.undead

--[[local function getStartingAngle(ref)
	local globalVar = tes3.findGlobal('TimeScale')
	local temp = globalVar.value
	tes3.runLegacyScript({command = "set TimeScale to GetStartingAngle Z", reference = ref})
	local result = globalVar.value
	globalVar.value = temp
	return result * deg2radMul
end]]

local backDistX, backDistY
local tryCount = 0
local function collision(e)
	if noAntiStuck then
		return
	end
	local doorRef = e.target
	if not doorRef then -- silly, but it happens
		return
	end
	if not (doorRef.object.objectType == tes3_objectType_door) then
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
	if tes3.getLocked({reference = doorRef}) then
		return
	end
	local cell = actorRef.cell
	local cellName = cell.name
	if cellName then
		if not cell.isInterior then
			cellName = string.format("%s (%s, %s)", cellName, cell.gridX, cell.gridY)
		end
	end
	local radAngleTo = actorRef:getAngleTo(doorRef)
	local mobile = actorRef.mobile
	local radFacing = mobile.facing
	if logLevel > 1 then
		mwse.log('%s: "%s" "%s" facing = %s deg, angleTo "%s" = %s deg', modPrefix, cellName, actorRef.id, radFacing * rad2degMul, doorRef.id, radAngleTo * rad2degMul)
	end
	if radAngleTo >= math_pi then
		return
	end

	if mobile.movementCollision == false then
		if logLevel > 0 then
			mwse.log('%s: "%s" "%s" colliding actor with "%s" has movementCollision = false, skipping...', modPrefix, cellName, actorRef.id, doorRef.id)
		end
		return -- skip actors with movement collision disabled
	end

	local startingAngle = doorRef.startingOrientation.z -- thanks NullCascade for adding this
	local currAngle = doorRef.facing
	local angleDiff = math.abs(currAngle - startingAngle) * rad2degMul
	if logLevel > 2 then
		mwse.log('%s: "%s" "%s" %s startingAngle = %s, currAngle = %s, angleDiff = %s',
			modPrefix, cellName, doorRef.id, doorRef.position, startingAngle*rad2degMul, currAngle*rad2degMul, angleDiff)
	end
	local doorOpenedEnough = angleDiff >= 65

	if movingCollidingActor then
		-- move actor back while opening the door

		---if doorRef:testActionFlag(tes3_actionFlag_doorJammedOpening)
		---or doorRef:testActionFlag(tes3_actionFlag_doorJammedClosing) then
			if tryCount < 6 then
				tryCount = tryCount + 1
				local pos = mobile.position:copy()
				mobile.position.x = pos.x - (backDistX / tryCount)
				mobile.position.y = pos.y - (backDistY / tryCount)
				if logLevel > 0 then
					mwse.log('%s: "%s" moving "%s" actor colliding with "%s" from %s back to %s...',
						modPrefix, cellName, actorRef.id, doorRef.id, pos, mobile.position)
				end
			else
				tryCount = 0
				if not doorOpenedEnough then
					if doorRef:testActionFlag(tes3_actionFlag_doorJammedClosing)
					or (not doorRef:testActionFlag(tes3_actionFlag_doorJammedOpening)) then
						if logLevel > 0 then
							mwse.log('%s: "%s" "%s" activating jammed door "%s"...', modPrefix, cellName, actorRef.id, doorRef.id)
						end
						actorRef:activate(doorRef)
					end
				--[[else
					if logLevel > 0 then
						mwse.log('%s: "%s" removing "%s" collision with door "%s"...', modPrefix, cellName, actorRef.id, doorRef.id)
					end
					mobile.movementCollision = false]]
				end
			end
		---end

		return
	end

	if mobile.actorType == tes3_actorType_creature then
		local crea = mobile.object
		if not crea.biped then
			if not crea.usesEquipment then
				if crea.type == tes3_creatureType_normal then
					if logLevel > 0 then
						mwse.log('%s: "%s" creature "%s" colliding with "%s" is unable to handle door opening, skip...',
							modPrefix, cellName, actorRef.id, doorRef.id)
					end
					return -- skip less handy creatures
				end
			end
		end
		if not doorOpenedEnough then
			if logLevel > 0 then
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
		local max = doorBounds.max
		local min = doorBounds.min
		doorWidth = math.max(max.y - min.y, max.x - min.x)
	else
		doorWidth = 128
	end
	doorWidth = doorWidth * doorRef.scale
	local boundSize_y = mobile.boundSize.y * actorRef.scale
	local backDist = doorWidth - (boundSize_y * 0.5)
	local angle = radFacing
	backDistX = backDist * math.sin(angle)
	backDistY = backDist * math.cos(angle)

	if logLevel > 1 then
		mwse.log('%s: "%s" "%s" actor mobToMobCollision disabled', modPrefix, cellName, actorRef.id)
	end
	mobile.mobToMobCollision = false -- else if more than one they get stuck each other

	movingCollidingActor = true
	timer.start({duration = 2, callback =
		function ()
			if mobile then
				if logLevel > 1 then
					mwse.log('%s: "%s" mobToMobCollision restored', modPrefix, actorRef.id)
				end
				mobile.mobToMobCollision = true
				---mobile.movementCollision = true
			end
			movingCollidingActor = false
		end
	})
end

local function loaded()
	player = tes3.player
	movingCollidingActor = false
end

local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	event.register('collision', collision)
	event.register('loaded', loaded)

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		logLevel = config.logLevel
		noAntiStuck = not config.doorAntiStuck
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label = "Preferences",
		postCreate = function(self)
			local width1 = 1.2
			local width2 = 2 - width1 -- total width must be 2
			local sideBlock = self.elements.sideToSideBlock
			sideBlock.children[1].widthProportional = width1
			sideBlock.children[2].widthProportional = width2
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = [[Avoid actors getting stuck while opening doors]]}

	local controls = preferences:createCategory{label = mcmName}

	controls:createInfo({text = ""})

	controls:createYesNoButton{
		label = "Enable Doors Anti Stuck",
		variable = createConfigVariable("doorAntiStuck"),
		description = [[Toggle mod Doors Anti Stuck feature. When enabled, actors should move back a little instead of getting stuck while trying to open a door.]]
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[Debug logging level. Default: 0. Off.]]
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady) -- happens before initialized()