local camera = require('openmw.camera')
local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local Weapon = require('openmw.types').Weapon
local I = require('openmw.interfaces')

local function isBowPrepared()
    if Actor.stance(self) ~= Actor.STANCE.Weapon then return false end
    local item = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
    local weaponRecord = item and item.type == Weapon and Weapon.record(item)
    if not weaponRecord then return false end
    return weaponRecord.type == Weapon.TYPE.MarksmanBow or weaponRecord.type == Weapon.TYPE.MarksmanCrossbow
end

local active = false

local counterMin, counterMax = -3, 2
local counter = counterMin
local effectActive = false

local useAimingOffset = false
local combatOffset = util.vector2(-30, -10)
local aimingOffset = util.vector2(-15, 0)

return {
    onUpdate = function(dt, enabledThirdPerson, enabledFirstPerson)
        local enabled = (enabledFirstPerson and camera.getMode() == camera.MODE.FirstPerson) or
                        (enabledThirdPerson and camera.getMode() == camera.MODE.ThirdPerson)
        if active ~= (enabled and isBowPrepared()) then
            active = not active
            if active then
                I.Camera.disableThirdPersonOffsetControl()
                camera.setFocalTransitionSpeed(5.0)
                camera.setFocalPreferredOffset(combatOffset)
            else
                I.Camera.enableThirdPersonOffsetControl()
            end
        end
        if self.controls.use == 0 or not active then
            counter = math.max(counterMin, counter - dt * 2.5)
        else
            counter = math.min(counterMax, counter + dt * 2.5)
        end
        local effect = (math.max(0.1, math.exp(math.min(1, counter)-1)) - 0.1) / 0.9
        camera.setFieldOfView(camera.getBaseFieldOfView() * (1 - 0.5 * effect))
        if camera.getMode() ~= camera.MODE.ThirdPerson then effect = 0 end
        if useAimingOffset ~= (effect > 0.4) and active then
            useAimingOffset = effect > 0.4
            if useAimingOffset then
                camera.setFocalPreferredOffset(aimingOffset)
            else
                camera.setFocalPreferredOffset(combatOffset)
            end
        end
    end
}

