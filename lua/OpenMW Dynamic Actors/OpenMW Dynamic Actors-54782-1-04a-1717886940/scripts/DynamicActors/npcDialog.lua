local core=require("openmw.core")
local animation = require("openmw.animation")
local self = require("openmw.self")
local util = require("openmw.util")
local types = require("openmw.types")
local ai = require("openmw.interfaces").AI
local I = require("openmw.interfaces")

local animtypes = {
	{ "isMale", false, 1, "handhippose", {loops=100, priority=1, blendmask=11, speed=0.5} },
	{ "class", "^guard", 2, "armsatback", {loops=8, priority=1, blendmask=12} },
	{ "class", "^ordinator", 2, "armsatback", {loops=8, priority=1, blendmask=12} },
	{ "isMale", true, 1, "armsfolded", {loops=5, priority=1, blendmask=12} },
		}

local poseShifts = {
		{ {
	{ "idle2", {priority=3, speed=2} },
	{ "armsakimbo", {loops=10, priority=2, speed=0.5, blendmask=12} }
		},
		{
	{ "idle8", {priority=3, speed=2} },
	{ "armsfolded", {loops=8, priority=2, blendmask=12} }
		} },
		{ {
	{ "idle2", {priority=3, speed=2} },
	{ "armsatback", {loops=10, priority=2, speed=0.5, blendmask=12} }
		},
		{
	{ "idle8", {priority=3, speed=2} },
	{ "armsatback", {loops=10, priority=2, blendmask=12} }
		} }
	}

local poseShiftType = 0
local anim = ""
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

local function playHandler(g, o)
	if animkna then
		if g == "handhippose" or string.find(g, "^arms") then o.blendmask = 12 end
	end
	animation.playBlended(self, g, o)
end

local function shiftPose()
	if poseShiftType == 0 then return end
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

local function initNPCdiag(data)
	local idleSet = 5
	dialogTarget, turningEnabled, resetPosRot, idleSet, logging = table.unpack(data)
	if not idleSet or idleSet == 0 then poseShiftType = 0 return end
	local aipack, static = ai.getActivePackage(), true
	if aipack ~= nil then
		if logging then print(self, aipack.destPosition, aipack.type) end
	--	print(self, aipack.destPosition, aipack.sideWithTarget, aipack.target, aipack.type)
		if aipack.destPosition ~= util.vector3(0,0,0) then static = false end
	else print("No AI package")
	end
	core.sendGlobalEvent("actorMonitor", { actor=self, reset=static })
	bipedal = self.type == types.NPC or self.type == types.Creature.TYPE.Humanoid
	if not bipedal then return end
	for i=1, #animtypes do
		local k, v, shift, name, options, short = table.unpack(animtypes[i])
		local eval, m = types.NPC.record(self)[k], false
		if type(v) == "string" then
			if string.find(eval:lower(), v) then m = true end
		elseif eval == v then m = true
		end
		if m then
			if short and idleSet < 5 then options.loops = short end
			playHandler(name, options)
			anim = name
			poseShiftType = shift
			if idleSet < 3 then poseShiftType = 0 end
			break
		end
	end

end

local function closeNPCdiag()
	if animation.hasAnimation(self) then animation.cancel(self, anim) end
	dialogTarget = nil
	bipedal, animcount, poseShiftType = false, 0, 0
	core.sendGlobalEvent("dynRemoveScript", { object = self, script = "scripts/DynamicActors/npcDialog.lua" })
end



local function onUpdate(dt)
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
end


return {
	eventHandlers = {
	initNPCdiag = initNPCdiag,
	closeNPCdiag = closeNPCdiag,
	shiftPose = shiftPose
	},
    engineHandlers = { onUpdate = onUpdate, },
}
