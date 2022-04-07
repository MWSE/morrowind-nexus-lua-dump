--[[
Avoid actors getting stuck while opening doors /abot
]]

-- begin configurable parameters
local defaultConfig = {
doorAntiStuck = true,
logLevel = 2, -- 0 = Minimum, 1 = Low, 2 = Medium
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

local colliding = false -- used in collision() event, reset in loaded()

local tes3_objectType_door = tes3.objectType.door
local tes3_actionFlag_doorJammedOpening = tes3.actionFlag.doorJammedOpening

local math_pi = math.pi
local rad2degMul = 180 / math_pi
---local half_pi = math_pi * 0.5

local collDist, collSin, collCos
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
	if not doorRef:testActionFlag(tes3_actionFlag_doorJammedOpening) then
		return
	end
	if tes3.getLocked({reference = doorRef}) then
		return
	end
	local radAngleTo = actorRef:getAngleTo(doorRef)
	if logLevel > 1 then
		mwse.log('%s: "%s" angle to "%s" = %s deg', modPrefix, actorRef.id, doorRef.id, radAngleTo * rad2degMul)
	end
	if radAngleTo >= math_pi then
		return
	end
	local mobile = actorRef.mobile
	if not colliding then
		colliding = true
		local angle = doorRef.facing
		collSin = math.sin(angle)
		collCos = math.cos(angle)
		local doorBounds = doorRef.object.boundingBox
		if doorBounds then
			local max = doorBounds.max
			local min = doorBounds.min
			local doorWidth = math.max(max.y - min.y, max.x - min.x)
			collDist = doorWidth * doorRef.scale
		else
			collDist = 128
		end
		if logLevel > 0 then
			mwse.log('%s: "%s" colliding with "%s", moving actor back %s units while disabling collision...', modPrefix, actorRef.id, doorRef.id, collDist)
		end
		mobile.mobToMobCollision = false -- else if more than one they get stuck each other
		timer.start({duration = 1.5, callback = function ()
			if mobile then
				if logLevel > 0 then
					mwse.log('%s: "%s" collision restored', modPrefix, actorRef.id)
				end
				mobile.mobToMobCollision = true
			end
			colliding = false
		end})
	end
	-- move actor back while opening the door
	mobile.position.x = mobile.position.x - (collDist * collSin)
	mobile.position.y = mobile.position.y - (collDist * collCos)

end

local function loaded()
	player = tes3.player
	colliding = false
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
		},
		variable = createConfigVariable("logLevel"),
		description = [[Debug logging level. Default: 0. Off.]]
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady) -- happens before initialized()