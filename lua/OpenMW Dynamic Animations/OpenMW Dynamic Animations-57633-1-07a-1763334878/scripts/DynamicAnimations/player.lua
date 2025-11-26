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

local logSpam = false
local spamNames = { ["torch"] = true, ["idle1h"] = true, ["idle2c"] = true, ["idlehh"] = true }
local spamNames = {}

local cam = { getMode = camera.getMode, first = camera.MODE.FirstPerson }
local view = cam.getMode()		cam.inFirst = view == cam.first
local noWalking
local noUpdate = true

local activeOverride
local walk = {
	id="", opt={}, maxSpeed=1000,
	dynamic = { maxSpeed = 1000 },
	f = "walkforward", f_ = "^walkforward_",
	noble = "walkforward_noble",
	endPoint = 0,
	playOptions = { loops=200, forceLoop=true, priority=5 },
	parentOptions = { loops=200, forceLoop=true, priority=5 },
	slowWalk = { id="walkforward_spd07", velocity=130 }
}

local config = require("scripts.DynamicAnimations.configPlayer")
local playerAnims = config.initGroups(walk)

local settings = storage.playerSection("Settings_ODAR_cat01")
local function updateSettings()
	local g = playerAnims[settings:get("walkMale") or ""]
	walk.custom = g and g.id and { id=g.id, velocity=g.velocity or 154 } or nil
	activeOverride = walk.custom
end

updateSettings()
settings:subscribe(async:callback(updateSettings))


--	DEV OPTIONS
local logLevel = 0
walk.speedAdjust = false
local disabled = false



local function debug(m, level)
	if logLevel >= (level or 1) then	print(m)		end
end

local playBlendedHandlers = {}
local function onPlayBlendedAnimation(g, o)
    for i = #playBlendedHandlers, 1, -1 do
        local h = playBlendedHandlers[i].fn(g, o)
        if type(o.newGroupName) == "string" then
            g = o.newGroupName
            o.newGroupName = nil
        end
        if h == false then
            return g
        end
    end
    return g
end

local function playBlendedAnimation(g, o)
	if disabled then return end
	if logLevel > 1 then
		if not spamNames[g] then
			print(g, o.priority, o.blendMask)
		else
			if not logSpam then
				logSpam = true
				print(g, o.priority, o.blendMask)
			end
		end
	end
	local swap = onPlayBlendedAnimation(g, o)
	if o.skip then
		return
	end

	if swap ~= g then
		anim.playBlended(self, swap, o)
		o.skip = true
		return false
	end
end

local function walkHandler(g, o)
	walk.adjustWalkMask(g, o)
--	print(aux_util.deepToString(o, 3))
	if disabled then			return		end
	if g ~= "walkforward" then		return		end

	local clone = {}
	for k, v in pairs(o) do		clone[k] = v		end
	walk.playOptions = clone
	if not activeOverride then		return		end

	walk.speed = actorSpeed(self)		walk.velocity = activeOverride.velocity
	o.speed = math.min(walk.maxSpeed, walk.speed) / walk.velocity
	walk.parent = g			g = activeOverride.id
	walk.playing = g
	noUpdate = false

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
	walk.parentOptions = o

	anim.playBlended(self, walk.parent, o)
	o.skip = true
	
	return false

end

I.AnimationController.addPlayBlendedAnimationHandler(function (g, o)
	if noWalking or cam.inFirst then
		return
	end
	local cancel
	if g:find("^walk") or g:find("^runwalk") then
		cancel = walkHandler(g, o)
	else
		walk.adjustAnims(g, o)
	end
	if cancel ~= false then
		cancel = playBlendedAnimation(g, o)
	end
	return cancel
end)

local function setMaxSpeed(force)
	if noWalking then	activeOverride = nil		end
	local max = walk.custom and walk.custom.maxSpeed or walk.dynamic.maxSpeed
	max = math.min(types.Actor.getWalkSpeed(self), max)
	if max == walk.maxSpeed and not force then
		return
	end
	walk.maxSpeed = max		walk.speed = 0
	debug(("MAXSPEED %s"):format(max))
	if not noWalking then
		activeOverride = walk.custom or (walk.speedAdjust and max < 154 * 0.75 and walk.slowWalk)
	end
	local old = walk.playing or (anim.isPlaying(self, walk.f) and walk.f)
	if old and activeOverride and old ~= activeOverride.id then
		walk.playOptions.startPoint = anim.getCompletion(self, old)
		anim.cancel(self, old)
		anim.cancel(self, walk.f)
		debug("WALK OVERRIDE")
		walkHandler(walk.f, walk.playOptions)
	end
end

local timer = math.random(200) / 100
local playerCell = self.cell

local function cellChanged()
	if playerCell ~= self.cell then
		playerCell = self.cell
		if walk.speedAdjust and playerCell.id:find(" shack") then
			walk.dynamic.maxSpeed = 110
		else
			walk.dynamic.maxSpeed = 1000
		end
		setMaxSpeed()
	end
end

local function onUpdate(dt)
	if dt == 0 or disabled then		return			end
	timer = timer - dt
	if timer < 0 then
		timer = 1
		noWalking = types.Actor.activeEffects(self):getEffect("levitate").magnitude > 0
			or types.Actor.isSwimming(self)
	--	cam.inFirst = cam.getMode() == cam.first
		cellChanged()
		setMaxSpeed()
		if anim.getActiveGroup(self, 0) == "idle" then
			if walk.idleTimer ~= 0 then
				if not walk.idleTimer then
					walk.idleTimer = core.getSimulationTime() + 2.9
					anim.setSpeed(self, "idle", 1)
				elseif walk.idleTimer < core.getSimulationTime() then
					walk.idleTimer = 0
					anim.setSpeed(self, "idle", 0.5)
				end
			end
		else
			walk.idleTimer = nil
		end
	end
	if noUpdate then		return		end

--[[
	if timer < 1 then
		timer = 5 + math.random(200) / 100
		logSpam = false
	end
--]]

	if not anim.isPlaying(self, walk.parent) then
	--	print(walk.parent, walk.playing, types.Actor.getStance(self), ctrls.movement)
		noUpdate = true
		anim.cancel(self, walk.playing)
		walk.playing = nil
		debug("WALK CANCEL", 2)
	elseif not activeOverride then
		noUpdate = true
		if not noWalking then
			walk.playOptions.startPoint = anim.getCompletion(self, walk.playing)
			walk.playOptions.speed = actorSpeed(self) / 154
			anim.cancel(self, walk.playing)
			anim.cancel(self, walk.parent)
			anim.playBlended(self, walk.parent, walk.playOptions)
		--	walk.playing = walk.parent
			walk.playing = nil
			debug("WALK RESTART")
		end
	end
	if noUpdate then		return		end

	if actorSpeed(self) ~= walk.speed then
		walk.speed = actorSpeed(self)
		anim.setSpeed(self, walk.playing, math.min(walk.maxSpeed, walk.speed) / walk.velocity)
	end
end

local function onFrame(dt)
	if dt == 0 then		return			end

	if view ~= cam.getMode() then
		view = cam.getMode()
		cam.inFirst = view == cam.first
	end
end


return {
	engineHandlers = {
		onFrame = onFrame,
		onUpdate = onUpdate,
	},
	eventHandlers = {
		OMWMusicCombatTargetsChanged = function(e)
			if e.actor and next(e.targets) then
				e.actor:sendEvent("odarEvent", {event="updateAI"})
			end
		end,
		UiModeChanged = function(e)
			if e.oldMode == I.UI.MODE.ChargenClassReview then
				debug("RACE FINALIZED")
				playerAnims = config.initGroups(walk)		updateSettings()
			end
			cellChanged()
		end
	},

	interfaceName = "ODAR",
	interface = {
		version = 100,
		addPlayBlendedAnimationHandler = function(handler, name)
			if type(name) ~= "string" then name = tostring(#playBlendedHandlers + 1) end
			playBlendedHandlers[#playBlendedHandlers + 1] = {id=name, fn=handler}
			print("ODAR handler "..name.." registered.")
		end,

		setMaxSpeed = function(e)
			if not disabled and type(e) == "number" then
				walk.dynamic.maxSpeed = e
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
			e.maxSpeed = type(e.maxSpeed) == "number" and e.maxSpeed or 1000
			e.id = e.groupName		e.velocity = velocity
			walk.custom = e
			setMaxSpeed(true)
		end,
		setLogLevel = function(e)	logLevel = e			end,
		getLocomotions = function()	return playerAnims		end,
		enabled = function(e)		disabled = not e		end,
--[[
		walk = function()		return walk			end,
--]]
	}
}
