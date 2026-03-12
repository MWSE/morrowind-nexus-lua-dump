local core = require("openmw.core")
local self = require("openmw.self")
local types = require('openmw.types')
local camera = require('openmw.camera')
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local checks = require("scripts.ArrowStick.utils.checks")
local camUtil = require("scripts.ArrowStick.utils.camera")

local settings = storage.globalSection("SettingsArrowStick")

local rotOffset = 0
local arrowId
local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
local arrow = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.Ammunition)

local function placeNewArrow()

    local xRot = camera.getPitch() - math.rad(rotOffset)
    local zRot = camUtil.getRotation(self.rotation).z -- math.rad(rotOffset2)
    local cast, cast2 = camUtil.getObjInCrosshairs(self, nil, false, nil)

    -- Fired arrows will go through solid items, so need to check if it would have hit an NPC,
    -- otherwise you can get it stuck in a bottle, but still hit someone.
    if not cast.hitPos
        or (cast.hitObject and (cast.hitObject.type == types.NPC or cast.hitObject.type == types.Creature))
        or (cast2.hitObject and (cast2.hitObject.type == types.NPC or cast2.hitObject.type == types.Creature))
    then
        return
    end

    local hitWater = self.cell.waterLevel and cast.hitPos.z < self.cell.waterLevel
    local waterCheck = settings:get("stickUnderwater") or not hitWater
    if not waterCheck then return end

    local newRot = camUtil.createRotation(xRot, 0, zRot)
    local newPos = cast.hitPos
    core.sendGlobalEvent("placeArrow", {
        rotation = newRot,
        id = arrowId,
        position = newPos,
        actor = self.object,
        -- for Impact Effects
        weapon = weapon,
        hitObj = cast.hitObject,
    })
end

local function attackMade(groupName, key)
    if key == "shoot start" then
        -- gotta get them in advance
        -- otherwise last arrow won't stick
        weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        arrow  = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.Ammunition)
    elseif key == "shoot release" then
        if not (weapon and weapon.type == types.Weapon) then return end

        local ehcnantCheck = settings:get("stickAOEEnchants") or not checks.arrowAOEEnchanted(weapon)
        local rollCheck = checks.successfulRoll(settings)
        if not (ehcnantCheck or rollCheck) then return end

        local weaponType = weapon.type.record(weapon).type
        local isBow      = weaponType == types.Weapon.TYPE.MarksmanBow
        local isCrossbow = weaponType == types.Weapon.TYPE.MarksmanCrossbow
        local isThrown   = weaponType == types.Weapon.TYPE.MarksmanThrown

        if isBow or isCrossbow then
            rotOffset = 0
        elseif isThrown then
            rotOffset = 180
            arrow = weapon
        else
            return
        end

        if not arrow then return end
        arrowId = arrow.recordId
    end
end

local function onFrame()
    if arrowId then
        placeNewArrow()
        arrowId = nil
    end
end

I.AnimationController.addTextKeyHandler("bowandarrow", attackMade)
I.AnimationController.addTextKeyHandler("crossbow", attackMade)
I.AnimationController.addTextKeyHandler("throwweapon", attackMade)

return {
    engineHandlers = {
        onFrame = onFrame
    }
}
