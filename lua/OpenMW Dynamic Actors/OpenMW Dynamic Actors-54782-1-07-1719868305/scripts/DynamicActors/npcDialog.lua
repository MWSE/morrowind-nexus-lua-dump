local core = require("openmw.core")
local animation = require("openmw.animation")
local self = require("openmw.self")
local util = require("openmw.util")
local types = require("openmw.types")
local ai = require("openmw.interfaces").AI
local I = require("openmw.interfaces")

local baseIdle = {
	{ "isMale", false, 1, "handhippose", {loops=100, priority=1, blendmask=11, speed=0.5} },
	{ "isMale", true, 1, "readypose", {loops=4, priority=1, blendmask=3} },
		}

local greeting = {
	{ "class", "^guard", 2, "armsatback", {loops=3, priority=2, blendmask=12} },
	{ "class", "^ordinator", 2, "armsatback", {loops=3, priority=2, blendmask=12} },
	{ "isMale", true, 1, "armsfolded", {loops=3, priority=2, blendmask=12} },
		}

local poseShifts = {
		{ {
	{ "armsakimbo", {loops=5, priority=2, blendmask=12} },
	{ "idle2", {priority=3, speed=2} },
		},
		{
	{ "armsfolded", {loops=4, priority=2, blendmask=12} },
	{ "idle8", {priority=3, speed=2} },
		} },
		{ {
	{ "armsatback", {loops=5, priority=2, blendmask=12} },
	{ "idle2", {priority=3, speed=2} },
		},
		{
	{ "armsatback", {loops=3, priority=2, blendmask=12} },
	{ "idle8", {priority=3, speed=2} },
		} }
	}

local poseShiftType = 0
local anim = {name=nil, opt={}}
local animcount = 0
local dialogTarget = nil
local turningEnabled, resetPosRot = false, false
local turningToTarget = false
local bipedal = false
local logging = false
local animkna = false
if self.type == types.NPC then
	animkna = types.NPC.races.record(types.NPC.record(self).race).isBeast == true
end
local guard = false
if self.type == types.NPC and types.NPC.record(self).class == "guard" then guard = true end
local voice = {isPlay=false, noanim=true}
if animation.hasGroup(self, "idlespeak") then voice.noanim = false end


local function playHandler(g, o)
	if animkna then
		if g == "handhippose" then o.blendmask = 8 end
	end
	animation.playBlended(self, g, o)
end

local function shiftPose(e)
	if voice.isPlay or poseShiftType == 0 then return end
	if e == "playBase" then
		if anim.name and anim.opt.loops > 50 then playHandler(anim.name, anim.opt) end
		return
	end
	if anim.name then animation.cancel(self, anim.name) end
	local name, options = nil, nil
	if math.random(10) < 6 then
	name, options = table.unpack(poseShifts[poseShiftType][1][1])
	playHandler(name, options)
	name, options = table.unpack(poseShifts[poseShiftType][1][2])
	playHandler(name, options)
	else
	name, options = table.unpack(poseShifts[poseShiftType][2][1])
	playHandler(name, options)
	name, options = table.unpack(poseShifts[poseShiftType][2][2])
	playHandler(name, options)
	end
end

local function checkRecord(k, v)
	local eval = types.NPC.record(self)[k]
	if type(v) == "string" then
		if string.find(eval:lower(), v) then return true end
	elseif eval == v then
		return true
	end
	return false
end

local function forcePause()
	local aipack, force = ai.getActivePackage(), false
	if aipack == nil then return false end
--	if guard and aipack.type == "Unknown" and aipack.target == nil then force=true end
	if aipack.type == "Combat" or aipack.type == "Pursue" then force = true end
	if force then core.sendGlobalEvent("dynForcePause") end
	return force
end

local function initNPCdiag(data)
	if forcePause() then return end
	local idleSet = 5
	dialogTarget, turningEnabled, resetPosRot, idleSet, logging = table.unpack(data)
	if not idleSet or idleSet == 0 then poseShiftType = 0 return end
	if idleSet < 3 then poseShiftType = 0 end
	local static = true
	local aipack = ai.getActivePackage()
	if aipack ~= nil then
		if logging then print(self, aipack.destPosition, aipack.target, aipack.type) end
		if aipack.destPosition ~= util.vector3(0,0,0) then static = false end
	else print("No AI package")
	end
	core.sendGlobalEvent("actorMonitor", { actor=self, reset=static })
	bipedal = self.type == types.NPC or self.type == types.Creature.TYPE.Humanoid
	if not bipedal then return end
	for i=1, #baseIdle do
		local k, v, shift, name, options = table.unpack(baseIdle[i])
		local m = checkRecord(k, v)
		if m then
			anim.name, anim.opt = name, options
			if animkna then anim.name = nil else playHandler(name, options) end
			poseShiftType = shift
			break
		end
	end

	for i=1, #greeting do
		k, v, shift, name, options = table.unpack(greeting[i])
		m = checkRecord(k, v)
		if m then
			playHandler(name, options)
			poseShiftType = shift
			break
		end
	end

end

local function closeNPCdiag()
	if animation.hasAnimation(self) then
		if anim.name then animation.cancel(self, anim.name) end
		if voice.isPlay then animation.cancel(self, "idlespeak") end
	end
	dialogTarget = nil
	bipedal, animcount, poseShiftType = false, 0, 0
	core.sendGlobalEvent("dynRemoveScript", { object = self, script = "scripts/DynamicActors/npcDialog.lua" })
end



local function onUpdate(dt)
	if forcePause() then return end
    if dialogTarget and turningEnabled then
        self.controls.movement = 0
        self.controls.sideMovement = 0
        local deltaPos = dialogTarget.position - self.position
        local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
        local deltaYaw = math.atan2(destVec.x, destVec.y)
        if math.abs(deltaYaw) < math.rad(10) then
            turningToTarget = false
        elseif math.abs(deltaYaw) > math.rad(30) then
            turningToTarget = true
        end
        if turningToTarget then
            self.controls.yawChange = util.clamp(deltaYaw, -dt * 2.5, dt * 2.5)
        else
            self.controls.yawChange = 0
        end
    end
	if animkna or poseShiftType == 0 or voice.noanim then return end
	if voice.isPlay and not core.sound.isSayActive(self) then
--		animation.cancel(self, "idlespeak")
		animation.setLoopingEnabled(self, "idlespeak", false)
		if anim.name then playHandler(anim.name, anim.opt) end
		voice.isPlay = false
	elseif not voice.isPlay and core.sound.isSayActive(self) then
		if anim.name then animation.cancel(self, anim.name) end
		animation.playBlended(self, "idlespeak", {loops=20, priority=1, speed=1.5})
		voice.isPlay = true
	end
end


return {
	eventHandlers = {
	initNPCdiag = initNPCdiag,
	closeNPCdiag = closeNPCdiag,
	shiftPose = shiftPose
	},
    engineHandlers = { onUpdate = onUpdate, },
}
