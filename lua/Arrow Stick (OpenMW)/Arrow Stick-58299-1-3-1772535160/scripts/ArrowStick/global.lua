local _, world = pcall(require, "openmw.world")
local _, async = pcall(require, "openmw.async")
local util = require("openmw.util")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local time = require("openmw_aux.time")
local core = require("openmw.core")
local types = require("openmw.types")

local settings = storage.globalSection("SettingsArrowStick")
local shotArrows = {}
local xrot
local xpos

local delayedImpactEffect = time.registerTimerCallback("ArrowStick_ImpactEffect",
    function(params)
        I.impactEffects.spawnEffect({
            material = params.hitObj
                and I.impactEffects.getMaterialByObject(params.hitObj)
                or "Dirt",
            hitPos = params.hitPos
        })
    end
)

local function addImpactEffects(weapon, hitPos, hitObj, playerPos)
    local weaponType = weapon.type.record(weapon).type
    local isThrown   = weaponType == types.Weapon.TYPE.MarksmanThrown
    local projectileSpeed
    if isThrown then
        projectileSpeed = core.getGMST("fThrownWeaponMaxSpeed")
    else
        projectileSpeed = core.getGMST("fProjectileMaxSpeed")
    end

    local delta = playerPos - hitPos
    local distance = delta:length()

    time.newSimulationTimer(
        distance / projectileSpeed,
        delayedImpactEffect,
        { hitObj = hitObj, hitPos = hitPos }
    )
end

local function rotateArrow(data)
    local obj = data.obj
    data.obj:teleport(obj.cell, obj.position, data.rotation)
end

local function onItemActive(item)
    if xrot and xpos then
        async:newUnsavableSimulationTimer(0.1, function()
            item:teleport(item.cell.name, xpos, xrot)
            xrot = nil
        end)
    end
end

local function placeArrow(data)
    async:newUnsavableSimulationTimer(0.1, function()
        local id = data.id
        local pos = data.position
        local rot = data.rotation
        local player = data.actor
        -- print(id, pos, rot)

        local temppos = util.vector3(pos.x, pos.y, pos.z - 1000)
        local newArrow = world.createObject(id)
        newArrow:teleport(player.cell.name, temppos, rot)

        xrot = rot
        xpos = util.vector3(pos.x, pos.y, pos.z)

        if settings:get("despawnArrows") then
            newArrow:addScript("scripts/ArrowStick/customArrow.lua")
            shotArrows[newArrow.id] = newArrow
        end

        if I.impactEffects and settings:get("impactEffectsIntegration") then
            addImpactEffects(data.weapon, pos, data.hitObj, player.position)
        end
    end)
end

local function onSave()
    return {
        shotArrows = shotArrows
    }
end

local function onLoad(saveData)
    shotArrows = saveData.shotArrows or {}
end

local function onActivate(obj, actor)
    if shotArrows[obj.id] then
        shotArrows[obj.id] = nil
    end
end

local function arrowInactive(id)
    local arrow = shotArrows[id]
    shotArrows[id] = nil
    if not arrow or not arrow:isValid() then return end
    arrow:remove()
end

return {
    engineHandlers = {
        onItemActive = onItemActive,
        onActivate = onActivate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        rotateArrow = rotateArrow,
        placeArrow = placeArrow,
        arrowInactive = arrowInactive,
    }
}
