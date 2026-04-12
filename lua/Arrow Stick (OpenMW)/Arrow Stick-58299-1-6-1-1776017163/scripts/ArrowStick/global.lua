local world = require("openmw.world")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local core = require("openmw.core")

local IE = require("scripts.ArrowStick.utils.impactEffects")
local consts = require("scripts.ArrowStick.utils.consts")

local settings = storage.globalSection("SettingsArrowStick")
local settingsImpactEffects = storage.globalSection("SettingsArrowStick_impactEffects")
local arrowDespawnScript = "scripts/ArrowStick/customArrow.lua"

local shotArrows = {}

local function placeNewArrow(data)
    local id = data.id
    local pos = data.position
    local rot = data.rotation
    local player = data.actor
    local waterPos = data.waterPos
    local hitWater = player.cell.waterLevel and pos.z < player.cell.waterLevel

    local material
    if I.impactEffects then
        material = IE.getMaterial(data.hitObj, hitWater)
        if settingsImpactEffects:get("impactEffects") then
            I.impactEffects.spawnEffect({
                material = material,
                hitPos = hitWater and waterPos or pos,
            })
        end
    end

    local waterCheck = hitWater and not settings:get("stickUnderwater")
    local materialCheck = material
        and settingsImpactEffects:get("checkMaterial")
        and consts.unstickableMaterials[material]
    local arrowSticked = not (waterCheck or materialCheck)

    local newArrow = world.createObject(id)
    newArrow:teleport(player.cell.name, pos, rot)
    if not arrowSticked then
        newArrow:setScale(0)
    end

    if arrowSticked and settings:get("despawnArrows") then
        newArrow:addScript(arrowDespawnScript)
        shotArrows[newArrow.id] = newArrow
    end

    core.sendGlobalEvent("ArrowStick_ArrowPlaced", {
        ---@diagnostic disable-next-line: assign-type-mismatch
        arrowSticked = arrowSticked,
        item = newArrow,
        -- for Impact Effects
        material = material,
    })
end

local function arrowPlaced(eventData)
    if I.impactEffects and I.impactEffects.playSoundEffect then
        I.impactEffects.playSoundEffect({
            material = eventData.material,
            soundTarget = eventData.item,
        })
    end

    if not eventData.arrowSticked then
        eventData.item:remove()
    end
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
    arrow:removeScript(arrowDespawnScript)
end

return {
    engineHandlers = {
        onActivate = onActivate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        ArrowStick_PlaceNewArrow = placeNewArrow,
        ArrowStick_ArrowInactive = arrowInactive,
        ArrowStick_ArrowPlaced = arrowPlaced,
    }
}
