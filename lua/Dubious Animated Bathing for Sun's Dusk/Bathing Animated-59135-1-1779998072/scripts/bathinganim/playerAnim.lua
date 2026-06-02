local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local self = require('openmw.self')
local types = require('openmw.types')

local animations = { "wash1r", "wash2r", "wash2l", "wash3" }
local current_index = 0

local function removeSoapHandler(groupname, key)
    if key == 'stop' then
        anim.removeVfx(self, "dbsbath1")
    end
end

I.AnimationController.addTextKeyHandler('wash1r', removeSoapHandler)
I.AnimationController.addTextKeyHandler('wash2r', removeSoapHandler)
I.AnimationController.addTextKeyHandler('wash2l', removeSoapHandler)
I.AnimationController.addTextKeyHandler('wash3', removeSoapHandler)

local function onSunsDusk_finishedBath()
    current_index = current_index + 1
    if current_index > #animations then
        current_index = 1
    end
    
    local chosen_anim = animations[current_index]

    I.AnimationController.playBlendedAnimation(
        chosen_anim,
        {
            startKey = 'start',
            stopKey = 'stop',
            priority = {
                [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
            },
            autoDisable = true,
            blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm + anim.BLEND_MASK.LowerBody,
            speed = 1
        }
    )

    anim.addVfx(self, 'meshes/dbs/hand_soap_01.nif', {
        loop = true,
        vfxId = "dbsbath1",
        boneName = "Weapon Bone",
    })
end

return {
    eventHandlers = {
        SunsDusk_finishedBath = onSunsDusk_finishedBath,
    }
}
