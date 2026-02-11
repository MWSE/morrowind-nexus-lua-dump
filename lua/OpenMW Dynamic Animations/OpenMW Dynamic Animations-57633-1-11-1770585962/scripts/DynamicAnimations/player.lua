local core = require("openmw.core")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local self = require("openmw.self")
local async = require("openmw.async")
local camera = require("openmw.camera")
local storage = require("openmw.storage")

local ctrls = self.controls
local actorSpeed = types.Actor.getCurrentSpeed
local Actor = {
	getWalkSpeed = types.Actor.getWalkSpeed,
	getRunSpeed = types.Actor.getRunSpeed,
	getStance = types.Actor.getStance,
	stanceNone = types.Actor.STANCE.Nothing,
	isSwimming = types.Actor.isSwimming,
	activeEffects = types.Actor.activeEffects(self),
	isWerewolf = types.NPC.isWerewolf,
	races = types.NPC.races.records,
	npcRecords = types.NPC.records
}

local logSpam = false

local inFirst = camera.getMode() == camera.MODE.FirstPerson
local noWalking
local skipUpdate = true

local activeOverride
local move = {
	f = "walkforward", f_ = "^walkforward_",
	noble = "walkforward_noble",
	walkSpeed = -1.0, runSpeed = -1.0,
	g="", opt={},
	dynamic = { maxSpeed = 10000 },
	endPoint = 0,
	playOptions = { loops=200, forceLoop=true, priority=5 },
	parentOptions = { loops=200, forceLoop=true, priority=5 },
	slowWalk = { g="walkforward_spd07", velocity=130 }
}

local config = require("scripts.DynamicAnimations.configPlayer")
local playerAnims = config.initGroups(move)
local Anims = require("scripts.DynamicAnimations.playerAnimations")

local locomotions = inFirst and Anims.firstPerson or Anims.thirdPerson
local overrides = {}
local disabled = false

local settings = storage.playerSection("Settings_ODAR_cat01")
local function updateSettings()
	disabled = not settings:get("p_odarEnabled")
	local g = playerAnims[settings:get("walkMale") or ""]
	if g and g.g then
		move.custom = { g=g.g, max=10000, velocity=g.velocity or 154 }
		Anims.thirdPerson.walkforward = move.custom
	else
		move.custom = nil
	end
	Anims.enableFirst = settings:get("p_odarEnabled_1st")
--	Anims.enableFirst = settings:get("p_odarEnabled")
	Anims.useLowerSneak = Anims.enableFirst and settings:get("p_useLowerSneak")
	local max = Anims.enableFirst and settings:get("p_maxWalkSpeed") or 10000
	Anims.firstPerson.maxWalk = max
	Anims.firstPerson.maxRun = max * 1.5
	move.walkSpeed = -1.0
end

updateSettings()
settings:subscribe(async:callback(updateSettings))


--	DEV OPTIONS
local logLevel = 0
move.speedAdjust = false



local function debug(m, level)
	if logLevel >= (level or 1) then	print(m)		end
end

local function moveHandler(g, o)
--	print(aux_util.deepToString(o, 3))
	if o.priority ~= 5 then		return			end

	move.adjustWalkMask(g, o)
	local clone = {}
	for k, v in pairs(o) do		clone[k] = v		end
	move.playOptions = clone
	activeOverride = overrides[g]
	if not activeOverride then		return		end

	move.speed = actorSpeed(self)		move.velocity = activeOverride.velocity
	o.speed = math.min(activeOverride.max, move.speed) / move.velocity
--[[
	local startKey = anim.getTextKeyTime(self, g..": start") == anim.getTextKeyTime(self, g..": loop start")
		and "loop start" or o.startKey or nil
--]]
	move.parent = g			g = activeOverride.g
	move.playing = g
	skipUpdate = false

	-- Bugfix for spellcast group cancelling custom walk anim
	if anim.isPlaying(self, g) then
		o.startPoint = anim.getCompletion(self, g)
		anim.cancel(self, g)
	end
	anim.playBlended(self, g, o)

	local p = o.priority
	if type(p) == "number" then
		p = { [0] = p, [1] = p, [2] = p, [3] = p }
	end
	p[2] = p[2] - 1			p[3] = p[3] - 1
	o.priority = p			o.blendMask = 0
	o.startKey = "start"		o.stopKey = "loop start"	o.forceLoop = true
	o.speed = 0.2			o.startPoint = 0
	move.parentOptions = o

	anim.playBlended(self, move.parent, o)
	o.skip = true
	
	return false

end


I.ODAR.addPlayBlendedAnimationHandler(function (g, o)
	local runHandlers
	if not noWalking and locomotions[g] then
		runHandlers = moveHandler(g, o)
	elseif not inFirst then
		move.adjustAnims(g, o)
	end
	return runHandlers
end, "animations")


local function setMaxSpeed(force)
	if noWalking then
		activeOverride = nil
		return
	end
	if move.walkSpeed == Actor.getWalkSpeed(self)
		and move.runSpeed == Actor.getRunSpeed(self)
		and not force then
		return
	end

	debug("MAXSPEEDS UPDATE")
	move.walkSpeed = Actor.getWalkSpeed(self)
	move.runSpeed = Actor.getRunSpeed(self)
	overrides = {}

	if inFirst then
		if Anims.enableFirst then
			Anims.setOverrides(move, locomotions, overrides)
		end
		return
	end

	local max = move.custom and move.custom.maxSpeed or locomotions.dynamicWalk.maxSpeed
	max = math.min(move.walkSpeed, max)
	local activeWalk = move.custom
			or (move.speedAdjust and max < 154 * 0.75 and move.slowWalk)
			or nil
	overrides.walkforward = activeWalk
	if max == locomotions.maxWalk and not force then
		return
	end

	locomotions.maxWalk = max		move.speed = 0
	debug(("3P MAXSPEED %s"):format(max))
	if not activeWalk then		return		end

	activeWalk.max = max
	local old = move.playing or (anim.isPlaying(self, move.f) and move.f)
	if old and old ~= activeWalk.g then
		move.playOptions.startPoint = anim.getCompletion(self, old)
		anim.cancel(self, old)
		anim.cancel(self, move.f)
		debug("WALK OVERRIDE")
		moveHandler(move.f, move.playOptions)
	end
end

local timer = math.random(200) / 100
local playerCell = self.cell

local function cellChanged()
	if playerCell ~= self.cell then
		playerCell = self.cell
		if move.speedAdjust and playerCell.id:find(" shack") then
			Anims.thirdPerson.dynamicWalk.maxSpeed = 110
		else
			Anims.thirdPerson.dynamicWalk.maxSpeed = 10000
		end
		setMaxSpeed()
	end
end

local function onUpdate(dt)
	if dt <= 0 then			return			end
	timer = timer - dt
	if timer < 0 then
		timer = 1
		noWalking = disabled or Actor.isSwimming(self) or Actor.isWerewolf(self)
			or Actor.activeEffects:getEffect("levitate").magnitude > 0
		if noWalking ~= Anims.noWalking then
			Anims.noWalking = noWalking
			if noWalking then	Anims.cancelAll()		end
		end
		cellChanged()
		setMaxSpeed()
		Anims.idleController()
	end
	if skipUpdate then		return			end

--[[
	if timer < 1 then
		timer = 5 + math.random(200) / 100
		logSpam = false
	end
--]]

	if not anim.isPlaying(self, move.parent) then
	--	print(move.parent, move.playing, Actor.getStance(self), ctrls.movement)
		skipUpdate = true
		anim.cancel(self, move.playing)
		move.playing = nil
		debug("WALK CANCEL", 2)
	elseif not activeOverride then
		skipUpdate = true
		if move.playing then
			move.playOptions.startPoint = anim.getCompletion(self, move.playing)
			move.playOptions.speed = actorSpeed(self) / 154
			anim.cancel(self, move.playing)
			anim.cancel(self, move.parent)
			anim.playBlended(self, move.parent, move.playOptions)
			move.playing = nil
			debug("WALK RESTART")
		end
	end
	if skipUpdate then		return		end

	if actorSpeed(self) ~= move.speed then
		move.speed = actorSpeed(self)
		anim.setSpeed(self, move.playing, math.min(activeOverride.max, move.speed) / move.velocity)
	end
end

I.ODAR.addEventHandler("viewChange", function(intoFirst)
	inFirst = intoFirst
	if intoFirst then
		locomotions = Anims.firstPerson
	else
		locomotions = Anims.thirdPerson
		async:newUnsavableSimulationTimer(0.1, Anims.zillaScale)
	--	Anims.zillaScale()
	end
	skipUpdate = true
	move.playing = nil
	debug("WALK VIEW CHANGE", 1)
	setMaxSpeed(true)
end)

I.ODAR.addEventHandler("statusChange", Anims.sneakController)


return {
	engineHandlers = {
		onUpdate = onUpdate,
	},
	eventHandlers = {
		UiModeChanged = function(e)
			if e.oldMode == I.UI.MODE.ChargenClassReview then
				debug("RACE FINALIZED")
				playerAnims = config.initGroups(move)		updateSettings()
			end
			cellChanged()
		end
	},

	interfaceName = "dAnim",
	interface = {
		version = 111,

		setMaxSpeed = function(e)
			if not disabled and type(e) == "number" then
				Anims.thirdPerson.dynamicWalk.maxSpeed = e
				setMaxSpeed()
			end
		end,
		setWalk = function(e)
			if not(type(e) == "table") or not(type(e.groupName) == "string") then
				updateSettings()
				setMaxSpeed(true)
				return
			end
			local g = e.groupName:lower()
			local p = playerAnims[g]
			local velocity = e.velocity or (p and p.velocity)
			assert(velocity, "Unregistered group must have a velocity")
			e.maxSpeed = type(e.maxSpeed) == "number" and e.maxSpeed or 10000
			e.g = e.groupName		e.velocity = velocity
			move.custom = e
			setMaxSpeed(true)
		end,
		setLogLevel = function(e)	logLevel = e			end,
		getLocomotions = function()	return playerAnims		end,
		enabled = function(e)		disabled = not e		end,
--[[
		move = function()		return move			end,
		anims = function()		return Anims			end,
		actor = function()		return Actor			end,
		over = function()		return overrides		end,
		status = function()		return { inFirst }		end,
--]]
	}
}
