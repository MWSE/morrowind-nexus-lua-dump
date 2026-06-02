local I = require("openmw.interfaces")
local anim = require("openmw.animation")

local function onScribPetted()
    I.AnimationController.playBlendedAnimation(
        "petit",
        {
            startKey = 'start',
            stopKey = 'stop',
            ---@diagnostic disable-next-line: assign-type-mismatch
            priority = {
                [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.Torso] = anim.PRIORITY.Scripted,
            },
            autoDisable = true,
            blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso + anim.BLEND_MASK.RightArm +
            anim.BLEND_MASK.LowerBody,
            speed = 1
        }
    )
end

return {
    eventHandlers = {
        PetTheScribs_ScribPetted = onScribPetted,
    }
}
