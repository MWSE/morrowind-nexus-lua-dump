local core = require("openmw.core")
local animation = require("openmw.animation")
local self = require("openmw.self")
local util = require("openmw.util")
local types = require("openmw.types")
local ai = require("openmw.interfaces").AI
local I = require("openmw.interfaces")

local filters = {}

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
			{ "posealma3", {loops=1, priority=3} },
			{ "armsakimbo", {loops=1, priority=2, blendMask=12} },
			{ "posealma3", {loops=1, priority=3} },
			{ "armsakimbo", {loops=1, priority=2, blendMask=4} },
		}, nil, 1
	}
}

filters.poseShifts = {
		{ {
	{ "armsakimbo", {loops=3, priority=2, blendMask=12} },
	{ "idle2_copy", {priority=3, speed=2} },
		},
		{
	{ "armsfolded", {loops=3, priority=2, blendMask=12} },
	{ "idle8_copy", {priority=3, speed=2} },
		} },

		{ {
	{ "armsakimbo", {loops=5, priority=2, blendMask=12} },
	{ "idle2_copy", {priority=3, speed=2} },
		},
		{
	{ "armsatback", {loops=3, priority=2, blendMask=12} },
	{ "idle8_copy", {priority=3, speed=2} },
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
local anim = {name=nil, opt={}}

interop = {}

local dialogTarget = nil
local turningEnabled, resetPosRot = false, false
local logging = false
local voice = {isPlay=false, noanim=true, speed=1}
if animation.hasGroup(self, "idlespeak") then voice.noanim = false		end

local isBeast, isGuard
local npcRace = types.NPC.records[self.recordId]
if npcRace then npcRace = npcRace.race			end
if npcRace then
	isBeast = types.NPC.races.record(npcRace).isBeast == true
	isGuard = types.NPC.records[self.recordId].class == "guard"
	if npcRace == "nord" or npcRace == "wood elf" then voice.speed = 1.5		end
end


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
	local check = animation.isPlaying
	if armAnims[g] and (check(self, "torch") or check(self, "idlestorm")) then
		g = "armsakimbo"
	end
	if o.blendMask == 0 then return end
	animation.playBlended(self, g, o)
end

local function shiftPose(e)
	if voice.isPlay or poseShiftType == 0 then	return		end
	if e == "playBase" then
		if anim.name and anim.opt.loops > 50 then playHandler(anim.name, anim.opt) end
		return
	end
	if anim.name then animation.cancel(self, anim.name) end
	local rand = poseTable[math.random(#poseTable)]
	local name, options = table.unpack(rand[1])
	playHandler(name, options)
	name, options = table.unpack(rand[2])
	playHandler(name, options)
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
	if forcePause() or not animation.hasAnimation(self) then return end
	local idleSet, path
	dialogTarget, turningEnabled, resetPosRot, idleSet, logging, path = table.unpack(data)
	interop = {self=self, player=dialogTarget, lookAt=dialogTarget}
	if data.groups then
		for _, v in ipairs(data.groups) do
			if v == "all" or animation.isPlaying(self, v) then
				if logging then print("Found blocked anim group", v)		end
				idleSet = 0		turningEnabled = false
				break
			end
		end
	end
	if not idleSet or idleSet == 0 then
		poseShiftType = 0
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

--	local bipedal = self.type == types.NPC or self.type.records[self.recordId].isBiped
--	print(self.type.records[self.recordId].type, types.Creature.TYPE.Humanoid)
--	if self.type.records[self.recordId].type == types.Creature.TYPE.Humanoid then bipedal = true	end
--	if not bipedal then return end
	if self.type ~= types.NPC and not path then return		end

	local var = interop
	if path then
		plugin = require(path)
		infoList = plugin.infoList
		if plugin.getVariableStore then plugin.getVariableStore(var) end
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
			anim.name, anim.opt = name, options
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

--[[
	name = nil
	if plugin.greeting then
		name, options, shift = table.unpack(plugin.greeting)
		greet = table.unpack(plugin.greeting)
	end
	if not  then
		name, options, shift = checkFilters(filters.greeting)
	end
--]]

	if name then
		poseShiftType = shift or 1
		playHandler(name, options)
	end
	if idleSet < 3 then poseShiftType = 0		end
	if poseShiftType > 0 then poseTable = filters.poseShifts[poseShiftType]		end

end

local function closeNPCdiag()
	if animation.hasAnimation(self) then
		if voice.isPlay then animation.cancel(self, "idlespeak") end
		if anim.name then
--			animation.cancel(self, anim.name)
--			playHandler("idle", {priority=1})
			animation.setLoopingEnabled(self, anim.name, false)
		end
	end
	core.sendGlobalEvent("dynRemoveScript", { object = self, script = "scripts/DynamicActors/npcDialog.lua" })
	if plugin.closeDialog then plugin.closeDialog(dialogTarget)		end
	dialogTarget = nil
	poseShiftType = 0
end

local bodyParts = { legs=1, chest=2, leftarm=4, rightarm=8, arms=12, armschest=14, legschest=3 }

local function getBodyPart(mask)
	if type(mask) ~= "string" then return 15 end
	local m = bodyParts[mask:lower()] or 15
	return m
end

local function onInfoGetText(e)
	if plugin.onInfoGetText then plugin.onInfoGetText(e) end
	if not infoList then return end
	local playlist = infoList[e.info.id]
	if not playlist then return end
	local play, name, o
	local mask = playlist.bodypart
	if type(playlist.func) == "function" then
		play, name, o = playlist.func()
		if play == false then return end
	end
	if not name then name = playlist.name end
	if type(name) ~= "string" then return end
	name = name:lower()
	if not o then o = playlist.options end
	o = o or {}
	if not o.blendMask then o.blendMask = getBodyPart(mask) end
	if not o.priority then o.priority = 4 end
	if logging then print("Play plugin anim", name, mask) end
	playHandler(name, o)
end


local function onUpdate(dt)
	if dt == 0 then		return		end
	if (not dialogTarget) or forcePause() then	return		end
	local turningToTarget = false
    if turningEnabled then
--        self.controls.movement = 0
--        self.controls.sideMovement = 0
        local deltaPos = dialogTarget.position - self.position
        local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
        local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) > math.rad(20) then
            turningToTarget = true
		local bezier = (4 * math.abs(deltaYaw) / math.pi) ^ 2
		local v = 2.5 * bezier
		v = util.clamp(v, math.rad(40), 5)
		v = v * dt
            self.controls.yawChange = util.clamp(deltaYaw, -v, v)
        end
--        if not turningToTarget then
--            self.controls.yawChange = 0
--        end
    end
	if not turningToTarget then
		self.controls.yawChange = 0
	end
	self.controls.movement = 0
	self.controls.sideMovement = 0
	if plugin.onUpdate then plugin.onUpdate(dt) end
	if isBeast or poseShiftType == 0 or voice.noanim then return end
	if voice.isPlay and not core.sound.isSayActive(self) then
--		animation.cancel(self, "idlespeak")
		animation.setLoopingEnabled(self, "idlespeak", false)
		if anim.name then playHandler(anim.name, anim.opt) end
		voice.isPlay = false
	elseif not voice.isPlay and core.sound.isSayActive(self) then
		if anim.name then animation.cancel(self, anim.name) end
		animation.playBlended(self, "idlespeak", {loops=20, priority=1, speed=voice.speed})
		voice.isPlay = true
	end
end


return {
	eventHandlers = {
	initNPCdiag = initNPCdiag,
	closeNPCdiag = closeNPCdiag,
	shiftPose = shiftPose,
	dynInfoEvent = onInfoGetText
	},
    engineHandlers = { onUpdate = onUpdate },
}
