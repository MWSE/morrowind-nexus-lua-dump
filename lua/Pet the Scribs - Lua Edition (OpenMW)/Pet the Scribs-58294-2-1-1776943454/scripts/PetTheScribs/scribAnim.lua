local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local core = require("openmw.core")
local self = require("openmw.self")

I.AnimationController.playBlendedAnimation(
    "idle3",
    {
        startKey = 'start',
        stopKey = 'stop',
        ---@diagnostic disable-next-line: assign-type-mismatch
        priority = anim.PRIORITY.Scripted,
        autoDisable = true,
        blendMask = anim.BLEND_MASK.All,
        speed = 1
    }
)

core.sendGlobalEvent("PetTheScribs_detachMe", self)
