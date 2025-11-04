local core = require("openmw.core")
local anim = require("openmw.animation")
local self = require("openmw.self")
local util = require("openmw.util")
local types = require("openmw.types")
local ai = require("openmw.interfaces").AI
local I = require("openmw.interfaces")

if not self.isActive then
	core.sendGlobalEvent("dynamicActors",
		{ event="removeScript", object=self, script="scripts/dynamicactors/npcdialog.lua" })
	return
end

local filters = {}

filters.priorityArms = { [2] = 2, [3] = 2 }

filters.baseIdle = {
	{ "isMale", false, "handhippose", {loops=100, priority=1, blendMask=11, speed=0.5}, 1 },
	{ "isMale", true, "readypose", {loops=4, priority=1, blendMask=3}, 1 },
		}

filters.greeting = {
	{ "class", "ordinator", "armsalmapray", {priority=2}, 2 },
	{ "name", "ordinator", "armsalmapray", {priority=2}, 2 },
--	{ "faction", "temple", "armsalmapray", {priority=2}, 2 },
	{ "class", "^guard", "armsatback", {loops=3, priority=2, blendMask=12}, 2 },
--	{ "class", "^ordinator", "armsatback", {loops=3, priority=2, blendMask=12}, 2 },
	{ "isMale", true, {
			{ "armsakimbo", {loops=3, priority=2, blendMask=12} },
			{ "armsfolded", {loops=3, priority=2, blendMask=12} },
			{ "idle7_copy", {priority=2, blendMask=8} },
			{ "armsfolded", {loops=3, priority=2, blendMask=12} },
			{ "armsakimbo", {loops=3, priority=2, blendMask=8} },
		}, nil, 1
	},
	{ "isMale", false, {
			{ "posealma3", {loops=1, priority=2} },
			{ "armsakimbo", {loops=1, priority=2, blendMask=12} },
			{ "posealma3", {loops=1, priority=2} },
			{ "armsakimbo", {loops=1, priority=2, blendMask=4} },
		}, nil, 1
	}
}

filters.poseShifts = {
		{ {
	{ id="armsakimbo", opt={loops=1, priority=2, blendMask=12}, delay=7 },
	{ id="idle2_copy", opt={priority=2, speed=2} },
		},
		{
	{ id="armsfolded", opt={loops=1, priority=2, blendMask=12}, delay=2.5 },
	{ id="idle8_copy", opt={priority=2, speed=2} },
		} },

		{ {
	{ id="armsakimbo", opt={loops=1, priority=2, blendMask=12}, delay=7 },
	{ id="idle2_copy", opt={priority=2, speed=2} },
		},
		{
	{ id="armsatback", opt={loops=1, priority=2, blendMask=12}, delay=2.5 },
	{ id="idle8_copy", opt={priority=2, speed=2} },
		} }
	}

local beastBlendMasks = {
	["handhippose"] = 0, ["armsfolded"] = 12, ["armsakimbo"] = 12,
	["armsatback"] = 12, ["armssunshield"] = 12, ["readypose"] = 12,
	armsalmapray = 12, posealma3 = 0, idle2_copy = 0, idle7_copy = 12, idle8_copy = 12
	}

local armAnims = { armsfolded = true, posealma3 = true }

local poseShiftType = 0
local poseTable, infoList
local plugin = {}
local idleAnim = {name=nil, opt={}}

interop = {}

local dialogTarget = nil
local turningEnabled, resetPosRot = false, false
local logging = false
local animQueue = { timer = 10 }

local voice = {
	disabled = true,
	options = {loops=20, speed=1, blendMask=2, priority={[1] = 4}},
	baseAnim = "",
	groups = {
		base = "idlespeak",
		posealma3 = "",
		handhippose = "idlespeak_handhip",
		readypose = "idlespeak_ready",
	}
}
local isBeast, isGuard

if types.NPC.objectIsInstance(self) then
	local npcRace = types.NPC.records[self.recordId]
	if npcRace then npcRace = npcRace.race			end
	if npcRace then
		isBeast = types.NPC.races.record(npcRace).isBeast == true
		isGuard = types.NPC.records[self.recordId].class == "guard"
		if npcRace == "nord" or npcRace == "wood elf" then voice.speed = 1.5		end
	end

	if not isBeast and not types.NPC.records[self.recordId].isMale then
		voice.groups = {
			base = "idlespeak",
			posealma3 = "",
			handhippose = "idlespeak_handhip",
			readypose = "idlespeak_ready",
			idle = "idlespeak_idlef",
			idle4 = "idlespeak_idlef",
			idle5 = "idlespeak_handhip",
			idle7 = "idlespeak_idlef",
			idle8 = "idlespeak_idlef",
			armsakimbo = "idlespeak_idlef",
			armsalmapray = "idlespeak_idlef",
			armsfolded = "idlespeak_idlef",
			armsatback = "idlespeak_idlef",
			armssunshield = "idlespeak_idlef",
		}
	end

end


local function debug(m)		if logging then print(m)	end		end

local function playHandler(g, o)
	if isBeast then
		if g:find("_copy$") then g = g:gsub("_copy$", "")	end
		local v = beastBlendMasks[g]
		if v then
			if not o.blendMask then o.blendMask = 12	end
			o.blendMask = util.bitAnd(v, o.blendMask)
--			print(g, v, o.blendMask)
		end
	end
	local check = anim.isPlaying
	if armAnims[g] and (check(self, "torch") or check(self, "idlestorm")) then
		g = "armsakimbo"
	end
	if o.blendMask == 0 then return end
	anim.playBlended(self, g, o)
end

local function shiftPose(e)
--	if voice.playing or poseShiftType == 0 then	return		end
	if poseShiftType == 0 then	return		end
	if e == "playBase" then
		if idleAnim.name and idleAnim.opt.loops > 50 then playHandler(idleAnim.name, idleAnim.opt) end
		return
	end
	if idleAnim.name then anim.cancel(self, idleAnim.name) end
	local newPose = poseTable[math.random(#poseTable)]
--	local name, options = table.unpack(newPose[1])
--	playHandler(name, options)
	animQueue.play = newPose[1]		animQueue.time = core.getSimulationTime() + (animQueue.play[3] or 0)
	playHandler(newPose[2].id, newPose[2].opt)
end

filters.evals = {
	faction = function(o) return next(types.NPC.getFactions(o)) end
	}

local function checkFilters(t)
	if self.type ~= types.NPC then return		end
	for i=1, #t do
		local k, v, name, options, shift = table.unpack(t[i])
		local m = false
		local eval = filters.evals[k]
		if eval then _, eval = eval(self) else eval = types.NPC.record(self)[k] end
		if type(eval) == type(v) then
			if type(v) == "string" and string.find(eval:lower(), v) then m = true
			elseif eval == v then m = true end
		end
		if m then return name, options, shift		end
	end
end

local function forcePause()
	local aipack, pause = ai.getActivePackage(), false
	if aipack == nil then		return pause		end
--	if isGuard and aipack.type == "Unknown" and aipack.target == nil then force=true end
	local t = aipack.type
	if t == "Combat" or t == "Pursue" or t == "Flee" then
		pause = true
	end
	if pause then core.sendGlobalEvent("dynForcePause")		end
	return pause
end

local function initNPCdiag(data)
	if forcePause() or not anim.hasAnimation(self) then	return		end
	local idleSet, path
	dialogTarget, turningEnabled, resetPosRot, idleSet, logging, path = table.unpack(data)
	interop = {self=self, player=dialogTarget, lookAt=dialogTarget}
	if data.groups then
		for _, v in ipairs(data.groups) do
			if v == "all" or anim.isPlaying(self, v) then
				if logging then print("Found blocked anim group", v)		end
				idleSet = 0		turningEnabled = false
				break
			end
		end
	end

--	local bipedal = self.type == types.NPC or self.type.records[self.recordId].isBiped
--	print(self.type.records[self.recordId].type, types.Creature.TYPE.Humanoid)
--	if self.type.records[self.recordId].type == types.Creature.TYPE.Humanoid then bipedal = true	end
--	if not bipedal then return end

	local var = interop
	if path then
		plugin = require(path)
		infoList = plugin.infoList
		if plugin.getVariableStore then plugin.getVariableStore(var) end
	else
		plugin = {}
	end
	local handlers = { "onUpdate", "onQuestUpdate", "onInfoGetText", "closeDialog" }
	handlers.fn = function()	end
	for _, v in ipairs(handlers) do
		plugin[v] = plugin[v] or handlers.fn
	end

	if not idleSet or idleSet == 0 then
		poseShiftType = 0
		return
	end
	if self.type ~= types.NPC and not path then
		return
	end

	local static = true
	local aipack = ai.getActivePackage()
	if aipack ~= nil then
		if logging then print(self, aipack.destPosition, aipack.target, aipack.type) end
		if aipack.destPosition ~= util.vector3(0,0,0) then static = false end
	else
		if logging then print("No AI package")		end
	end
	core.sendGlobalEvent("actorMonitor", { actor=self, reset=static })

	local name, options, shift
	if plugin.baseIdle then
		name, options, shift = table.unpack(plugin.baseIdle)
	end
	if not name then
		name, options, shift = checkFilters(filters.baseIdle)
	end
	if name then
		poseShiftType = shift or 1
		if not isBeast then
			idleAnim.name, idleAnim.opt = name, options
			playHandler(name, options)
		end
	end

	if plugin.greeting then
		name, options, shift = table.unpack(plugin.greeting)
	else
		name, options, shift = checkFilters(filters.greeting)
	end
	if type(name) == "table" then
--		local rnd = 1 + math.floor(#name * math.random(99) / 100)
		local rnd = math.random(#name)
		greet = name[rnd]
--		print(rnd)
		name, options = table.unpack(greet)
	end

	if name then
		poseShiftType = shift or 1
		playHandler(name, options)
	end
	if idleSet < 3 then poseShiftType = 0		end
	if poseShiftType > 0 then poseTable = filters.poseShifts[poseShiftType]		end
	if idleSet > 0 and anim.hasGroup(self, "idlespeak") and not isBeast then
		voice.disabled = false
	end

end

local function closeNPCdiag()
	if anim.hasAnimation(self) then
		if voice.playing then
			anim.cancel(self, voice.playing)
		end
		if idleAnim.name then
			anim.setLoopingEnabled(self, idleAnim.name, false)
		end
	end
	core.sendGlobalEvent("dynamicActors",
		{ event="removeScript", object = self, script = "scripts/DynamicActors/npcDialog.lua" })
	plugin.closeDialog(dialogTarget)
	dialogTarget = nil
	poseShiftType = 0
end

local bodyParts = { legs=1, chest=2, leftarm=4, rightarm=8, arms=12, armschest=14, legschest=3 }

local function getBodyPart(mask)
	return type(mask) == "string" and bodyParts[mask:lower()] or 15
end

local events = {}

function events.onInfoGetText(e)
	plugin.onInfoGetText(e)
	if not infoList then 		return		end
	local playlist = infoList[e.info.id]
	if not playlist then		return		end
	local play, name, o
	local mask = playlist.bodypart
	if type(playlist.func) == "function" then
		play, name, o = playlist.func()
		if play == false then	return		end
	end
	name = name or playlist.name
	if type(name) ~= "string" then	return		end
	name = name:lower()
	if not o then o = playlist.options end
	o = o or {}
	o.blendMask = o.blendMask or getBodyPart(mask)
	o.priority = o.priority or 4
	debug(("Play plugin anim"):format(name, mask))
	playHandler(name, o)
end

function events.onQuestUpdate(e)
	debug(("Quest %s %s"):format(e.questId, e.questStage))
	plugin.onQuestUpdate(e.questId, e.questStage)
end


local function onUpdate(dt)
	if dt == 0 then					return		end
	if (not dialogTarget) or forcePause() then	return		end
	local turningToTarget = false
	if turningEnabled then
	--	self.controls.movement = 0
	--	self.controls.sideMovement = 0
		local deltaPos = dialogTarget.position - self.position
		local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
		local deltaYaw = math.atan2(destVec.x, destVec.y)
		if math.abs(deltaYaw) > math.rad(20) then
			turningToTarget = true
			local bezier = (4 * math.abs(deltaYaw) / math.pi) ^ 2
			local v = bezier * math.pi / 2
			v = util.clamp(v, math.rad(40), 5)
			v = v * dt
			self.controls.yawChange = util.clamp(deltaYaw, -v, v)
		end
	--	if not turningToTarget then
	--		self.controls.yawChange = 0
	--	end
	end
	if not turningToTarget then
		self.controls.yawChange = 0
	end
	self.controls.movement = 0
	self.controls.sideMovement = 0
	plugin.onUpdate(dt)
	if animQueue.time and animQueue.time < core.getSimulationTime() then
		playHandler(animQueue.play.id, animQueue.play.opt)
		animQueue.time = nil
	end
	animQueue.timer = animQueue.timer - dt
	if animQueue.timer < 0 then
		animQueue.timer = 35
	--	shiftPose()
	end
	if voice.disabled then		return		end

	if voice.playing and not core.sound.isSayActive(self) then
		anim.cancel(self, voice.playing)
		voice.playing = nil
	elseif voice.playing and anim.getActiveGroup(self, 0) ~= voice.baseAnim then
		voice.baseAnim = anim.getActiveGroup(self, 0)
		local newIdle = voice.groups[voice.baseAnim] or voice.groups.base
		debug(voice.playing, newIdle)
		if newIdle == "" then
			anim.cancel(self, voice.playing)
			voice.playing = nil
		elseif voice.playing ~= newIdle then
			voice.options.startPoint = anim.getCompletion(self, voice.playing)
			anim.cancel(self, voice.playing)
			anim.playBlended(self, newIdle, voice.options)
			voice.playing = newIdle
		end
	elseif not voice.playing and core.sound.isSayActive(self) then
		voice.baseAnim = anim.getActiveGroup(self, 0)
		local g = voice.groups[voice.baseAnim] or voice.groups.base
		if g ~= "" then
			debug(g)
			voice.options.startPoint = 0
			anim.playBlended(self, g, voice.options)
			voice.playing = g
		end
	end
end


return {
	engineHandlers = { onUpdate = onUpdate },
	eventHandlers = {
		initNPCdiag = initNPCdiag,
		closeNPCdiag = closeNPCdiag,
		shiftPose = shiftPose,
		dynInfoEvent = events.onInfoGetText,
		dynamicActors = function(e)
			if e.event and events[e.event] then events[e.event](e)		end
		end
	},
}
