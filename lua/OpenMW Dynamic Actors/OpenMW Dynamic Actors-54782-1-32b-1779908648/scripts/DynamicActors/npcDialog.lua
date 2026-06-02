local core = require("openmw.core")
local anim = require("openmw.animation")
local self = require("openmw.self")
local util = require("openmw.util")
local types = require("openmw.types")
local ai = require("openmw.interfaces").AI
local I = require("openmw.interfaces")

if not self:isActive() then
	core.sendGlobalEvent("DynamicActors",
		{ event="removeScript", object=self, script="scripts/dynamicactors/npcdialog.lua" })
	return
end

local Actor = {
	getStance = types.Actor.getStance,
	stanceNone = types.Actor.STANCE.Nothing,
	isNPC = types.NPC.objectIsInstance,
	isCreature = types.Creature.objectIsInstance,
	record = self.type.records[self.recordId],
	isSayActive = core.sound.isSayActive,
	getActiveGroup = anim.getActiveGroup,
	controls = self.controls,
}

local filters = {}

filters.priorityArms = { [2] = 2, [3] = 2 }

filters.baseIdle = {
	{ "isMale", false, "handhippose", {loops=100, priority=1, blendMask=15, speed=0.5}, 1 },
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
			{ "armsgesture_greet", {loops=1, priority=2, blendMask=12} },
			{ "armsakimbo", {loops=1, priority=2, blendMask=4} },
		}, nil, 1
	}
}

filters.poseShifts = {
		{ {
	{ id="armsakimbo", opt={loops=1, priority=2, blendMask=12}, delay=9 },
	{ id="idle2_copy", opt={priority=2, speed=1.5} },
		},
		{
	{ id="armsfolded", opt={loops=1, priority=2, blendMask=12}, delay=2.5 },
	{ id="idle8_copy", opt={priority=2, speed=2} },
		} },

		{ {
	{ id="armsakimbo", opt={loops=1, priority=2, blendMask=12}, delay=9 },
	{ id="idle2_copy", opt={priority=2, speed=1.5} },
		},
		{
	{ id="armsatback", opt={loops=1, priority=2, blendMask=12}, delay=2.5 },
	{ id="idle8_copy", opt={priority=2, speed=2} },
		} }
	}

local beastBlendMasks = {
--	handhippose = 0, armsakimbo = 12, readypose = 12,
	armsfolded = 12, armsatback = 12, armssunshield = 8,
	armsalmapray = 12, posealma3 = 0, idle2_copy = 0, idle7_copy = 12, idle8_copy = 12
	}

local armAnims = { armsfolded=true, posealma3=true }

local poseShiftType = 0
local poseTable, infoList
local idleAnim = { name=nil, opt={} }

interop = {}

local dialogTarget = nil
local turningEnabled, resetPosRot, visibleShield, validAnim
local animQueue = { timer = 10 }

local voice = {
	disabled = true,
	options = {loops=20, speed=1, blendMask=2, priority={[1] = 4}},
	baseAnim = "", baseBone = anim.BONE_GROUP.LowerBody,
	groups = {
		base = "idlespeak",
		posealma3 = "",
		handhippose = "idlespeak_handhip",
		readypose = "idlespeak_ready",
	}
}
local isBeast, isGuard

if Actor.isNPC(self) then
	local npcRace = Actor.record.race
	isBeast = types.NPC.races.records[npcRace].isBeast
	isGuard = Actor.record.class == "guard"
	if npcRace == "wood elf" then
		voice.options.speed = 1.5
	end
-- print(isBeast, npcRace)
	if isBeast then
		voice.groups = { base = "idlespeak", idle3 = "", idle9 = "" }
		voice.options.blendMask = 3		voice.options.priority = {[0]=4, [1]=4}
		voice.baseAnim = ""	voice.baseBone = anim.BONE_GROUP.RightArm
	elseif not Actor.record.isMale and anim.hasGroup(self, "idlespeak_idlef") then
		voice.groups = {
			base = "idlespeak",
			posealma3 = "",
			handhippose = "idlespeak_handhip",
			readypose = "idlespeak_ready",
			idle = "idlespeak_idlef",
		--	idle4 = "idlespeak_idlef",
			idle5 = "idlespeak_handhip",
			idle7 = "idlespeak_idlef",
			idle7_copy = "idlespeak_idlef",
			idle8 = "idlespeak_idlef",
			idle8_copy = "idlespeak_idlef",
			armsakimbo = "idlespeak_idlef",
			armsalmapray = "idlespeak_idlef",
			armsfolded = "idlespeak_idlef",
			armsatback = "idlespeak_idlef",
			armssunshield = "idlespeak_idlef",
		}
	end

end


local function addHandlers(m)
	local skipFn = function() end
	for _, v in ipairs
		{ "onUpdate", "closeDialog", "DialogueResponse", "onQuestUpdate", "onInfoGetText" }
			do
		m[v] = m[v] or skipFn
	end
end

local plugin = {}		addHandlers(plugin)
local logLevel = 0

local function debug(m, l)
	if logLevel >= (l or 1) then		print(m)		end
end

local function playHandler(g, o)
	if not validAnim or Actor.getStance(self) ~= Actor.stanceNone then
		return
	end

	o.blendMask = o.blendMask or 15
	local mask = visibleShield and 11
	mask = mask or ((anim.isPlaying(self, "idlestorm") or anim.isPlaying(self, "torch")) and 11)
	if mask then
		mask = util.bitAnd(o.blendMask, mask)
		g = (not armAnims[g]) and g or "armsakimbo"
	end
	if isBeast then
		if g:find("_copy$") then g = g:gsub("_copy$", "")	end
		mask = util.bitAnd(mask or o.blendMask, beastBlendMasks[g] or 15)
--		print(g, mask, o.blendMask)
	end
	if mask == 0 then		return			end

	if anim.isPlaying(self, g) then
		if not g:find("^arms") then
			o.startPoint = anim.getCompletion(self, g)
		end
		anim.cancel(self, g)
	end
	local savedMask = o.blendMask		o.blendMask = mask or o.blendMask
	anim.playBlended(self, g, o)
	o.startPoint = nil			o.blendMask = savedMask
end

local idleGroups = { idle=true, idle2_copy=true, idle7_copy=true, idle8_copy=true,
	handhippose=true, readypose=true, posealma3=true, idlespeak=true }
for i = 2, 9 do		idleGroups["idle"..i] = true			end

local function hasValidAnim()
	local leg = Actor.getActiveGroup(self, 0)
	local valid = idleGroups[leg] or leg:find("^turn") or leg:find("^walk") or leg:find("^run")
		or leg:find("^arms")
--	if not valid then	print("NOT VALID ANIM", leg)		end
	return valid
end

local function shiftPose(e)
--	if voice.playing or poseShiftType == 0 then	return		end
	if poseShiftType == 0 or not validAnim then
		return
	end
	if e == "playBase" then
		if idleAnim.name and idleAnim.opt.loops > 50 then playHandler(idleAnim.name, idleAnim.opt) end
		return
	end
	if idleAnim.name then anim.cancel(self, idleAnim.name) end
	local newPose = poseTable[math.random(#poseTable)]
--	local name, options = table.unpack(newPose[1])
--	playHandler(name, options)
	animQueue.play = newPose[1]
	animQueue.time = core.getSimulationTime() + (animQueue.play.delay or 0)
	playHandler(newPose[2].id, newPose[2].opt)
end

filters.evals = {
	faction = function(o) return next(types.NPC.getFactions(o)) end
}

local function checkFilters(t)
	if not Actor.isNPC(self) then		return		end
	for i=1, #t do
		local k, v, name, options, shift = table.unpack(t[i])
		local m = false
		local eval = filters.evals[k]
		if eval then
			_, eval = eval(self)
		else
			eval = Actor.record[k]
		end
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
	if forcePause() or not anim.hasAnimation(self) then
		return
	end

	local idleSet, path, logging
	dialogTarget, resetPosRot, idleSet, path = table.unpack(data)
	logLevel = data.logging and 1 or logLevel
	turningEnabled = data.isMobile
	interop = {self=self, player=dialogTarget, lookAt=dialogTarget}
	local aipack = ai.getActivePackage()
	if aipack then
		if (aipack.type == "Wander" and aipack.distance and aipack.distance > 0)
			or (aipack.type == "Travel" and aipack.destPosition) then
			turningEnabled = true
		end
	end
	if data.groups then
		for _, v in ipairs(data.groups) do
			if v == "all" or anim.isPlaying(self, v) then
				debug(("Found blocked anim group %s"):format(v))
				idleSet = 0		turningEnabled = false
				break
			end
		end
	end

--	local bipedal = self.type == types.NPC or Actor.record.isBiped
--	print(Actor.record.type, types.Creature.TYPE.Humanoid)
--	if Actor.record.type == types.Creature.TYPE.Humanoid then bipedal = true	end
--	if not bipedal then return end

	local var = interop
	if path then
		plugin = require(path) or {}
		infoList = plugin.infoList
		addHandlers(plugin)
		if plugin.getVariableStore then plugin.getVariableStore(var) end
	end
	if data.greeting then
		data.greeting.event = "DialogueResponse"
		self:sendEvent("DynamicActors", data.greeting)
	end

	if idleSet == 0 or (Actor.isCreature(self) and not path) then
		poseShiftType = 0
		return
	end

	visibleShield = (data.shields or not anim.hasBone(self, "Bip01 AttachShield"))
		and types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)

	local static = true
	if aipack ~= nil then
		debug(("%s %s %s %s"):format(self, aipack.destPosition, aipack.target, aipack.type))
		if aipack.destPosition ~= util.vector3(0,0,0) then static = false end
	else
		debug("No AI package")
	end
	core.sendGlobalEvent("actorMonitor", { actor=self, reset=static })

	validAnim = hasValidAnim()
	if not validAnim then
		debug("Unknown animation playing. Blocking initial idle.")
	end

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
		local rnd = math.random(#name)
		name, options = table.unpack(name[rnd])
	end

	if name then
		poseShiftType = shift or 1
		playHandler(name, options)
	end
	if idleSet < 3 then poseShiftType = 0		end
	if poseShiftType > 0 then poseTable = filters.poseShifts[poseShiftType]		end
	if idleSet > 0 and anim.hasGroup(self, "idlespeak") then
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
	core.sendGlobalEvent("DynamicActors",
		{ event="removeScript", object = self, script = "scripts/DynamicActors/npcDialog.lua" })
	plugin.closeDialog(dialogTarget)
	dialogTarget = nil
	poseShiftType = 0
end

local bodyParts = { legs=1, chest=2, leftarm=4, rightarm=8, botharms=12, armschest=14, legschest=3 }

local function getBodyPart(mask)
	return type(mask) == "string" and bodyParts[mask:lower()] or 15
end

local events = {}

function events.DialogueResponse(e)
	plugin.DialogueResponse(e)
	if not infoList then 		return		end
	local playlist = infoList[e.infoId]
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
	debug(("Play plugin anim %s %s"):format(name, mask))
	playHandler(name, o)
end

function events.onInfoGetText(e)
	plugin.onInfoGetText(e)
	events.DialogueResponse{ infoId = e.info.id }
end

function events.onQuestUpdate(e)
	debug(("Quest %s %s"):format(e.questId, e.questStage))
	plugin.onQuestUpdate(e.questId, e.questStage)
end


local function onUpdate(dt)
	if dt == 0 then					return		end
	if (not dialogTarget) or forcePause() then	return		end
	validAnim = hasValidAnim()
	local turningToTarget = false
	if turningEnabled and validAnim then
		local deltaPos = dialogTarget.position - self.position
		local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
		local deltaYaw = math.atan2(destVec.x, destVec.y)
		if math.abs(deltaYaw) > math.rad(20) then
			turningToTarget = true
			local bezier = (4 * math.abs(deltaYaw) / math.pi) ^ 2
			local v = bezier * math.pi / 2
			v = util.clamp(v, math.rad(40), 5)
			v = v * dt
			Actor.controls.yawChange = util.clamp(deltaYaw, -v, v)
		end
	end
	if not turningToTarget then
		Actor.controls.yawChange = 0
	end
	Actor.controls.movement = 0
	Actor.controls.sideMovement = 0

	if not validAnim then
		if voice.playing then
			anim.cancel(self, voice.playing)
			voice.playing = nil
		end
		return
	end

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

	if voice.disabled or Actor.getStance(self) ~= Actor.stanceNone then
		if voice.playing then
			anim.cancel(self, voice.playing)
			voice.playing = nil
		end
		return
	end
	if voice.playing and not Actor.isSayActive(self) then
		anim.cancel(self, voice.playing)
		voice.playing = nil
	elseif voice.playing and Actor.getActiveGroup(self, voice.baseBone) ~= voice.baseAnim then
		voice.baseAnim = Actor.getActiveGroup(self, voice.baseBone)
		local newIdle = voice.groups[voice.baseAnim] or voice.groups.base
		debug(("%s %s"):format(voice.playing, newIdle))
		if newIdle == "" then
			anim.cancel(self, voice.playing)
			voice.playing = nil
		elseif voice.playing ~= newIdle then
			voice.options.startPoint = anim.getCompletion(self, voice.playing)
			anim.cancel(self, voice.playing)
			anim.playBlended(self, newIdle, voice.options)
			voice.playing = newIdle
		end
	elseif not voice.playing and Actor.isSayActive(self) then
		voice.baseAnim = Actor.getActiveGroup(self, voice.baseBone)
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
		DynamicActors = function(e)
			if e.event and events[e.event] then events[e.event](e)		end
		end
	},
}
