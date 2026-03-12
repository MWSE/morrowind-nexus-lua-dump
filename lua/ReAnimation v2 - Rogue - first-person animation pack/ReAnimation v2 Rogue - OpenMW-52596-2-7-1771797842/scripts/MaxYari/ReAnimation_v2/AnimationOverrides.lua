local mp = "scripts/MaxYari/ReAnimation_v2/"

local omwself = require('openmw.self')
local types = require('openmw.types')
local animation = require('openmw.animation')
local I = require('openmw.interfaces')

local animManager = require(mp .. "scripts/anim_manager")
local gutils = require(mp .. "scripts/gutils")

local attackTypes = { "chop", "slash", "thrust" }

local selfActor = gutils.Actor:new(omwself)

-- TODO duplicate code
local function cloneAnimOptions(opts)
    local newOpts = gutils.shallowTableCopy(opts)
    if type(opts.priority) ~= "number" then
        newOpts.priority = gutils.shallowTableCopy(opts.priority)
    end
    return newOpts
end

-- Available bone-groups:
-- BoneGroup.LeftArm
-- BoneGroup.LowerBody
-- BoneGroup.RightArm
-- BoneGroup.Torso


local function locomotionAnimSpeed()
    local isSneaking = omwself.controls.sneak
    local isRunning = omwself.controls.run

    local moveAnimSpeed = 154.064
    if isSneaking then
        moveAnimSpeed = 33.5452 * 2.8
    elseif isRunning then
        moveAnimSpeed = 222.857
    end

    local maxSpeedMult = 10;
    local speedMult = selfActor:getCurrentSpeed() / moveAnimSpeed;

    return speedMult
end


local animations = {
    {
        parent = nil,
        groupname = "bowandarrow1",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function(self)
            local shootHoldTime = animation.getTextKeyTime(omwself, "bowandarrow: shoot max attack")
            local currentTime = animation.getCurrentTime(omwself, "bowandarrow")

            return currentTime and math.abs(shootHoldTime - currentTime) < 0.001
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            return {
                startkey = "tension start",
                stopkey = "tension end",
                loops = 999,
                forceloop = true,
                autodisable = false,
                priority = animation.PRIORITY.Weapon + 1,
                blendmask = animation.BLEND_MASK.UpperBody,
                blendMask = animation.BLEND_MASK.UpperBody,
                startKey = "tension start",
                stopKey = "tension end",
                forceLoop = true,
                autoDisable = false
            }
        end,
        startOnUpdate = true
    },
    {
        parent = "idle1h",
        groupname = "idle1hsneak",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = cloneAnimOptions(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1

            return opts
        end,
        startOnUpdate = true
    },
    {
        parent = "idle1s",
        groupname = "idle1ssneak",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = cloneAnimOptions(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1
            return opts
        end,
        startOnUpdate = true
    },
    {
        parent = {"idle1s","idle1ssneak","jump1s"},
        groupname = "idleshield",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function()
            return gutils.isAShield(selfActor:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedLeft))
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self, pOptions)
            local opts = cloneAnimOptions(pOptions)
            opts.blendMask = animation.BLEND_MASK.LeftArm
            opts.blendmask = animation.BLEND_MASK.LeftArm

            -- Consider: will changing parent options here somehow undesirably propagate to saved self.parentOptions?
            gutils.expandPriority(pOptions)
            pOptions.priority[animation.BONE_GROUP.LeftArm] = -1

            return opts
        end,
        startOnAnimEvent = true
    },
    {
        parent = { "runforward1s", "runback1s", "runleft1s", "runright1s", "walkforward1s", "walkback1s", "walkleft1s", "walkright1s", "sneakforward1s", "sneakback1s", "sneakleft1s", "sneakright1s" },
        groupname = "runforwardshield",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function()
            return gutils.isAShield(selfActor:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedLeft))
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self, pOptions)
            local opts = cloneAnimOptions(pOptions or self.parentOptions)
            opts.blendMask = animation.BLEND_MASK.LeftArm
            opts.blendmask = animation.BLEND_MASK.LeftArm

            opts.speed = locomotionAnimSpeed()

            if pOptions then
                gutils.expandPriority(pOptions)
                pOptions.priority[animation.BONE_GROUP.LeftArm] = -1
            end

            return opts
        end,
        startOnAnimEvent = true,
        startOnUpdate = true
    },
    {
        parent = nil,
        groupname = "runbounce",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function()
            return selfActor:getCurrentSpeed() > 1 and animManager.isPlaying("weapononehand")
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self, pOptions)
            return {
                startkey = "start",
                stopkey = "stop",
                loops = 999,
                forceloop = true,
                autodisable = false,
                priority = animation.PRIORITY.Movement + 1,
                blendmask = animation.BLEND_MASK.LowerBody,
                speed = locomotionAnimSpeed()
            }
            --opts.priority[animation.BONE_GROUP.Torso] = opts.priority[animation.BONE_GROUP.Torso] + 1
        end,
        startOnUpdate = true
    },
    {
        parent = "idlebow",
        groupname = "idlebowsneak",
        armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson,
        condition = function(self)
            return omwself.controls.sneak
        end,
        stopCondition = function(self)
            return not self:condition()
        end,
        options = function(self)
            local opts = cloneAnimOptions(self.parentOptions)
            opts.loops = 999
            opts.priority = self.parentOptions.priority + 1
            return opts
        end,
        startOnUpdate = true
    }
}


for _, anim in ipairs(animations) do
    I.ReAnimation.addAnimationOverride(anim)
end

I.ReAnimation.addAltAttackAnimations({
    parentAttackGroupname = "weapononehand",
    altAttackGroupname = "weapononehand1",
    armatureType = I.ReAnimation.ARMATURE_TYPE.FirstPerson
})


