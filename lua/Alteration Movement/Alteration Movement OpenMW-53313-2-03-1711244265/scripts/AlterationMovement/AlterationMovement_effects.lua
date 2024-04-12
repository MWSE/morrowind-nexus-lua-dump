local input = require('openmw.input')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local alterationMovementSettings = storage.playerSection("SettingsAlterationMovement")


local function isFalling()
    local isFlying = false
    local levEffect = types.Actor.activeEffects(self):getEffect("levitate") --Checks the player for the levitate effect.
    if levEffect and levEffect.magnitude > 0 then                           --If the levitate is appied, then we are flying.
        isFlying = true
    end
    if not isFlying and not types.Actor.isOnGround(self) and (not types.Actor.isSwimming(self) or alterationMovementSettings:get("allowWaterTakeoff")) then
        --If we are:
        --Not flying/levitating
        --Not on the ground
        --Not swimming(unless water takeoff is enabled)
        --Then:
        return true
    else
        return false
    end
end
return {

    levitate = {
        id = "levitate",--ID of the effect we named
        effectId = "levitate",--actual ID of the effect
        name = "levitate",--Text that is showed when it is learned
        magnitude = 10,--What magnitude to set
        action = input.ACTION.Jump,--Action that triggers this
        qualifier = isFalling, --Only apply if this function returns true
       -- spell = "lack_am_levitate1"--Spell that is applied
    },
    slowfall = {

        id = "slowfall",
        effectId = "slowfall",
        name = "slow fall",
        magnitude = 10,
        action = input.ACTION.Sneak,
        qualifier = isFalling,
     --   spell = "lack_am_slowfall1"
    }
}
