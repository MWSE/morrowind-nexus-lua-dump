local core = require("openmw.core")
local self = require("openmw.self")
local types = require('openmw.types')
local camera = require('openmw.camera')
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local time = require("openmw_aux.time")

local checks = require("scripts.ArrowStick.utils.checks")
local camUtil = require("scripts.ArrowStick.utils.camera")

local settings = storage.globalSection("SettingsArrowStick")
local fThrownWeaponMaxSpeed = core.getGMST("fThrownWeaponMaxSpeed")
local fProjectileMaxSpeed = core.getGMST("fProjectileMaxSpeed")

local rotOffset = 0
local arrowId
local weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
local arrow = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.Ammunition)

local delayedPlaceNewArrow = time.registerTimerCallback(
    "ArrowStick_PlaceNewArrow",
    function(params)
        core.sendGlobalEvent("ArrowStick_PlaceNewArrow", params)
    end
)

local function placeNewArrow()
    local xRot = camera.getPitch() - math.rad(rotOffset)
    local zRot = camUtil.getRotation(self.rotation).z -- math.rad(rotOffset2)
    local cast, cast2, cast3 = camUtil.getObjInCrosshairs(self, nil, false, nil, settings:get("enableScatter"))

    -- Fired arrows will go through solid items, so need to check if it would have hit an NPC,
    -- otherwise you can get it stuck in a bottle, but still hit someone.
    if not cast.hitPos
        or (cast.hitObject and (cast.hitObject.type == types.NPC or cast.hitObject.type == types.Creature))
        or (cast2.hitObject and (cast2.hitObject.type == types.NPC or cast2.hitObject.type == types.Creature))
    then
        return
    end

    local arrowPos = cast.hitPos
    local eventParams = {
        rotation = camUtil.createRotation(xRot, 0, zRot),
        id = arrowId,
        position = arrowPos,
        actor = self.object,
        waterPos = cast3.hitPos,
        -- for Impact Effects
        weapon = weapon,
        hitObj = cast.hitObject,
    }

    local weaponType = weapon.type.record(weapon).type
    local isThrown = weaponType == types.Weapon.TYPE.MarksmanThrown
    local projectileSpeed = isThrown
        and fThrownWeaponMaxSpeed
        or fProjectileMaxSpeed
    local distanceDelta = self.position - arrowPos
    local distance = distanceDelta:length()

    time.newSimulationTimer(
        distance / projectileSpeed,
        delayedPlaceNewArrow,
        eventParams
    )
end

local function attackMade(groupName, key)
    if key == "shoot start" then
        -- gotta get them in advance
        -- otherwise last arrow won't stick
        weapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
        arrow  = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.Ammunition)
    elseif key == "shoot release" then
        if not (weapon and weapon.type == types.Weapon) then return end

        local ehcnantCheck = not settings:get("stickAOEEnchants") and checks.arrowAOEEnchanted(weapon)
        local rollCheck = checks.randomRoll(settings:get("stickChance"))
        if rollCheck or ehcnantCheck then return end

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
