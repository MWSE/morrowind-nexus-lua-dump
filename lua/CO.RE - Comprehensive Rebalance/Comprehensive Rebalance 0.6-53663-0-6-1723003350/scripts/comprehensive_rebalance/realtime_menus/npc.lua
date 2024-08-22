local self = require('openmw.self')
local util = require('openmw.util')

local target = nil

--adapted from UI Modes
local function LookAtTarget(deltatime)
	local deltaPos = target.position - self.position
	local destVec = util.vector2(deltaPos.x, deltaPos.y):rotate(self.rotation:getYaw())
	local deltaYaw = math.atan2(destVec.x, destVec.y)
	if math.abs(deltaYaw) < math.rad(10) then
		self.controls.yawChange = 0
	else
		self.controls.yawChange = util.clamp(deltaYaw, -deltatime * 2.5, deltatime * 2.5)
	end
end

local function OnDialogStarted(t)
    self:enableAI(false) --attempted fix for guards repeatedly talking to you when you get arrested. This sucks though because it stops "surprise" attacks in dialogue
	target = t
	--print("Received Started Event")
end

local function OnDialogStopped(t)
    self:enableAI(true)
	target = nil
	--print("Received Stopped Event")
end

local function onUpdate(deltatime)
    if target then
        self.controls.movement = 0
        self.controls.sideMovement = 0
		LookAtTarget(deltatime)
    end
end

return {
    eventHandlers = {
        DialogueStarted = OnDialogStarted,
        DialogueStopped = OnDialogStopped,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    },
}
