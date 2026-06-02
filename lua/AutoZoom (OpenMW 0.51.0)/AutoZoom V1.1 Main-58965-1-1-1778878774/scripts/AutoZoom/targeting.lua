local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local settings = require('scripts.AutoZoom.settings')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')

local constants = require('scripts.AutoZoom.constants')

local triggerKeyByType = {}

local function addTriggerType(typeTable, settingKey)
    if typeTable ~= nil then
        triggerKeyByType[typeTable] = settingKey
    end
end

addTriggerType(types.NPC, 'triggerNPC')
addTriggerType(types.Creature, 'triggerCreatures')
addTriggerType(types.Activator, 'triggerActivators')
addTriggerType(types.Container, 'triggerContainers')
addTriggerType(types.Door, 'triggerDoors')
addTriggerType(types.Weapon, 'triggerWeapons')
addTriggerType(types.Armor, 'triggerArmor')
addTriggerType(types.Clothing, 'triggerClothing')
addTriggerType(types.Ingredient, 'triggerIngredients')
addTriggerType(types.Book, 'triggerBooks')
addTriggerType(types.Light, 'triggerLights')
addTriggerType(types.Miscellaneous, 'triggerMisc')
addTriggerType(types.Potion, 'triggerPotions')
addTriggerType(types.Lockpick, 'triggerLockpicks')
addTriggerType(types.Probe, 'triggerProbes')
addTriggerType(types.Repair, 'triggerRepairs')
addTriggerType(types.Apparatus, 'triggerApparatus')

local function isInteractable(object)
    if object == nil then
        return false
    end

    local settingKey = triggerKeyByType[object.type]
    if settingKey == nil then
        return false
    end

    return settings.get(settingKey) == true
end

local function getObjectUnderCrosshair()
    local origin = camera.getPosition()
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    if origin == nil or direction == nil then
        return nil
    end
    local targetPoint = origin + direction * constants.RAY_DISTANCE
    local hit = nearby.castRenderingRay(origin, targetPoint, { ignore = self.object })

    if hit and hit.hit then
        return hit.hitObject
    end

    return nil
end

return {
    isInteractable = isInteractable,
    getObjectUnderCrosshair = getObjectUnderCrosshair,
}
