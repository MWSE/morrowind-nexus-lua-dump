local core = require("openmw.core")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local self = require("openmw.self")
local camera = require("openmw.camera")

local ctrls = self.controls
local Actor = {
	getStance = types.Actor.getStance,
	stanceNone = types.Actor.STANCE.Nothing,
	isSwimming = types.Actor.isSwimming,
	activeEffects = types.Actor.activeEffects(self),
	isWerewolf = types.NPC.isWerewolf,
}

local logSpam = false
local spamNames = { ["torch"] = true, ["idle1h"] = true, ["idle2c"] = true, ["idlehh"] = true }
local spamNames = {}

local cam = { getMode = camera.getMode, first = camera.MODE.FirstPerson }
local camMode = cam.getMode()		local inFirst = camMode == cam.first

local disabled = false

local handlers = { viewChange={}, combatChange={}, statusChange={} }

local getStance = types.Actor.getStance
local getCamMode = camera.getMode
local status = { inFirst = getCamMode() == cam.first }
local statusChange, isSneaking, actorStance


--	DEV OPTIONS
local logLevel = 0


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
            break
        end
    end
    return g
end

local function playBlendedAnimation(g, o)
	if camMode ~= getCamMode() then
		camMode = getCamMode()
		local intoFirst = camMode == cam.first
		if inFirst ~= intoFirst then
			inFirst = intoFirst		status.inFirst = intoFirst
			statusChange = true		status.viewChange = true
		--	statusChange = true		status.armatureChange = true
			for _, v in ipairs(handlers.viewChange) do
				v(intoFirst)
			end
			debug("ODAR VIEW CHANGE")
		end
	end
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
	if swap ~= g and not o.skip then
		anim.playBlended(self, swap, o)
		o.skip = true
		return false
	end
end


I.AnimationController.addPlayBlendedAnimationHandler(playBlendedAnimation)


local function onFrame(dt)
	if dt <= 0 then		return			end

	if camMode ~= getCamMode() then
		camMode = getCamMode()
		local intoFirst = camMode == cam.first
		if inFirst ~= intoFirst then
			inFirst = intoFirst		status.inFirst = intoFirst
			statusChange = true		status.viewChange = true
			for _, v in ipairs(handlers.viewChange) do
				v(intoFirst)
			end
			debug("ODAR VIEW CHANGE")
		end
	end
end

local function onUpdate(dt)
	if dt <= 0 then		return		end
	local change = statusChange
	if isSneaking ~= ctrls.sneak then
		change = true
		isSneaking = ctrls.sneak		status.sneak = isSneaking
	end
	if actorStance ~= getStance(self) then
		change = true
		actorStance = getStance(self)		status.stance = actorStance
	end
	if change then
		statusChange = false
		for _, v in ipairs(handlers.statusChange) do
			v(status)
		end
		status.viewChange = false
	--	status.armatureChange = false
		debug("ODAR STATUS UPDATE")
	end
end
onUpdate(1)

local attackers, inCombat = {}

return {
	engineHandlers = {
	--	onFrame = onFrame,
		onUpdate = onUpdate
	},
	eventHandlers = {
		OMWMusicCombatTargetsChanged = function(e)
			if not e.actor or not next(e.targets) then
				return
			end
			e.actor:sendEvent("odarEvent", {event="updateAI"})
			if not next(handlers.combatChange) then
				return
			end
			local attack
			for _, v in ipairs(e.targets) do
				if v == self.object then
					attack = true		break
				end
			end
			attackers[e.actor.id] = attack
			attack = (next(attackers) ~= nil)
			if inCombat ~= attack then
				inCombat = attack
				debug("ODAR INCOMBAT "..attack)
				for _, v in ipairs(handlers.combatChange) do
					v(attack)
				end
			end
		end,
	},

	interfaceName = "ODAR",
	interface = {
		version = 111,
		addPlayBlendedAnimationHandler = function(handler, name)
			if type(name) ~= "string" then name = tostring(#playBlendedHandlers + 1) end
			playBlendedHandlers[#playBlendedHandlers + 1] = {id=name, fn=handler}
			debug("ODAR handler "..name.." registered.")
		end,
		addEventHandler = function(eventName, handler)
			local event = handlers[eventName]
			if event then
				event[#event + 1] = handler
			end
		end,

		setLogLevel = function(e)	logLevel = e			end,
		enabled = function(e)		disabled = not e		end,

	--	debug = function()		return { attackers, status }		end
	}
}
