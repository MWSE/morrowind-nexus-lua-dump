local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local util = require("openmw.util")

--	local aux_util = require("openmw_aux.util")

local actorSpeed = types.Actor.getCurrentSpeed
local isPlaying = anim.isPlaying

local swaps
local noCheck = true
local AI = {}
local moveControl = false
local playSwaps, maxTurn
local disabled = true
local block = false
local walk = {
	controllerEnabled = false,
	id="", opt={}, maxSpeed=10,
	f = "walkforward", noble = "walkforward_noble",
	walkfOpt = { loops=200, forceLoop=true, priority=5 }
}

local logLevel = 0


local function debug(m, l)
	if logLevel >= (l or 1) then		print(m)		end
end

local function playHandler(g, o)
	if g == "armsfolded" then
		if anim.isPlaying(self, "torch") or anim.isPlaying(self, "idlestorm") then
			g = "armsakimbo"
		end
	end
	anim.playBlended(self, g, o)
end

local function walkHandler(g, o)
	local clone = {}
	for k, v in pairs(o) do		clone[k] = v		end
	walk.speed = actorSpeed(self)
	o.speed = math.min(walk.maxSpeed, walk.speed / walk.velocity)
	walk.parent = g			g = walk.wander

	-- Bugfix for spellcast group cancelling custom walk anim
	if anim.isPlaying(self, g) then
		if g == walk.playing and walk.playOptions.blendMask ~= o.blendMask then
			o.startPoint = anim.getCompletion(self, g)
			anim.cancel(self, g)
		end
	end

	walk.playOptions = clone
	walk.playing = g
	noCheck = false

	playHandler(g, o)

	local p = o.priority
	if type(p) == "number" then
		p = { [0] = p, [1] = p, [2] = p, [3] = p }
	end
	p[2] = p[2] - 1			p[3] = p[3] - 1
	o.priority = p			o.blendMask = 0
	o.startKey = "start"		o.stopKey = "loop start"	o.forceLoop = true
	o.speed = 0.2			o.startPoint = 0

	anim.playBlended(self, walk.parent, o)
	o.skip = true
	
	return false

end

local function switchHandler(g, o)
	local switch = swaps[g]
	-- debug logging
	if logLevel > 1 and g ~= "torch" then
		print(g, o.priority, o.loops, switch)
	end
	if switch then
		if not switch.priority or switch.priority == o.priority then
			if switch.modify then
				for k, v in pairs(switch.modify) do	o[k] = v	end
			end
			local canPlay = true
			if switch.interval then
				local t = switch.nextPlay
				if not t or t < core.getSimulationTime() then
					switch.nextPlay = core.getSimulationTime() + switch.interval
				else
					canPlay = false
				end
			end
			if switch.n then
				switch = switch[math.random(switch.n)] or switch
			end
			if switch.masks then
				switch.opt.blendMask = switch.masks[math.random(#switch.masks)]
			end
			if switch.id and canPlay then
				if switch.priority ~= 0 then
					anim.cancel(self, switch.id)
				end
				playHandler(switch.id, switch.opt)
			end
		end
	end
end

-- local function switchAnimation(g, o)
I.ODAR.addPlayBlendedAnimationHandler(function (g, o)

	if playSwaps and swaps[g] then
		switchHandler(g, o)
	end

	if g == "walkforward" and moveControl then
		return walkHandler(g, o)
	end

end)


local function initSwaps(e)
	if type(e) ~= "table" or e.settings then
		return
	end
--	print(aux_util.deepToString(e, 5))

	disabled = false			swaps = e
	if e.odar_wander then
		walk.wander = e.odar_wander.id		walk.velocity = e.odar_wander.velocity
		walk.speedCap = e.odar_wander.maxSpeed or 10
		walk.controllerEnabled = true
	else
		walk.wander = nil		walk.controllerEnabled = false
	end
	if e.odar_config then
		walk.controllerEnabled = e.odar_config.move and walk.controllerEnabled
		playSwaps = e.odar_config.anims == true
	end
	AI = I.ODAR.getAIStatus()
	AI.wander = AI.type == "Wander" and type(AI.distance) == "number"

--	debug("swap table loaded")
end

-- core.sendGlobalEvent("sendSwaps", self)

local function stopWalk()
	noCheck = true
	if not walk.playing then	return		end
	anim.cancel(self, walk.playing)
	walk.playing = nil
	debug("WALK CANCEL", 2)
end

local function updateAI()
	maxTurn = nil
	if disabled or not AI.wander or not swaps then
		playSwaps = false		moveControl = false
		return
	end

	playSwaps = swaps.odar_config.anims == true
	moveControl = walk.controllerEnabled and not (
		types.Actor.activeEffects(self):getEffect("levitate").magnitude > 0
		or types.Actor.isSwimming(self) or self.controls.sneak
		)
	if not moveControl then
		return
	end

--	debug("WANDER ACTIVE", 2)
	local d = AI.distance
	if d == 0 then
		maxTurn = math.pi
		return
	end

	local s = ( d < 300 and 0.5) or (d < 500 and 0.6) or (d < 700 and 0.7)
		or (d < 1000 and 0.70) or 0.9
	s = math.min(s, walk.speedCap)
	maxTurn = s <= 0.6 and 1.5 or s <= 0.7 and 1.75 or 2
	maxTurn = maxTurn * math.pi
	local group = s == 0.5 and swaps.walkforward_05
	group = group or (s <= 0.7 and swaps.walkforward_07)
	group = group or swaps.odar_wander
	walk.wander = group.id			walk.velocity = group.velocity or 154
	walk.maxSpeed = s * 154 / walk.velocity

	if anim.getActiveGroup(self, 0) == walk.f and not walk.playing then
		debug("WALK OVERRIDE")
		local o = { loops=1000, forceLoop=true, priority=5 }
		o.startPoint = anim.getCompletion(self, walk.f)
		anim.cancel(self, walk.f)
		walkHandler(walk.f, o)
	end
end

I.ODAR.addHandler("onSecond", updateAI)
I.ODAR.addHandler("AIChange", function(p)
	debug(("AI PACKAGE UPDATE %s"):format(p.type))
	AI = p
	AI.wander = p.type == "Wander" and type(p.distance) == "number"
	updateAI()
end)

-- updateAI()
local timer = math.random(100) / 100 + 1
local ctrls = self.controls

local function onUpdate(dt)
	if dt == 0 then		return		end
	timer = timer + dt
	if timer > 2 then
		timer = 0	block = false
	--	updateAI()
	end

	if maxTurn then
		local yaw = ctrls.yawChange
		if yaw ~= 0 then
			local max = maxTurn * dt
			if yaw > max then
				ctrls.yawChange = max
			elseif yaw < -max then
				ctrls.yawChange = -max
			end
		end
	end

	if noCheck then			return		end

	if not isPlaying(self, walk.parent) then
		stopWalk()
	elseif actorSpeed(self) ~= walk.speed then
		walk.speed = actorSpeed(self)
		anim.setSpeed(self, walk.playing, math.min(walk.maxSpeed, walk.speed / walk.velocity))
	end
end

local function onActive()
	disabled = swaps == nil
end


return {
	engineHandlers = { onUpdate = onUpdate, onInit = initSwaps },
	eventHandlers = {
		initSwaps = initSwaps,
		odarEnabled = function(e)
			disabled = type(swaps) ~= "table" or e == false
			updateAI()
			debug(("ODAR enabled %s"):format(not disabled))
		end,
		updateAI = updateAI
	--	showSwaps = function()	return swaps		end,
	},
	interfaceName = "anim",
	interface = {
		version = 100,
		logLevel = function(e)	logLevel = e		end,
		disable = function(e)
			disabled = type(swaps) ~= "table" or e
		end,
--[[
		swaps = function()		return swaps		end,
		walk = function()		return walk		end,
		ai = function()			return AI		end,
		status = function()
			return disabled, playSwaps, moveControl, maxTurn
		end
--]]
	}
}
