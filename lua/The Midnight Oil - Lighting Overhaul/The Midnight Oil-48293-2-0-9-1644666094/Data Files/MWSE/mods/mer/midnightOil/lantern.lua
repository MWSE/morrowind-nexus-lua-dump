local common = require("mer.midnightOil.common")


local function isPlayerUnderWater()
    local cell = tes3.getPlayerCell()
    if cell.hasWater then
        local waterHeight = cell.waterLevel or 0
        local playerZ = tes3.player.position.z
        local height = playerZ - waterHeight
        if height < -90 then
            return true
        end
    end
    return false
end

local function preventExpiring(light)
    if light then
        if light.itemData then
            --only for lanterns and lamps, not torches
            if common.isOilLantern(light.object) or common.isCandleLantern(light.object) then
                if ( light.object.time and light.object.time > 0 ) and light.itemData.timeLeft < 1 then
                    tes3.messageBox("%s has run out.", light.object.name)
                    tes3.mobilePlayer:unequip{item = light.object}
                end
            end
        end
    end
end

local function preventDrowning(light)
    if light then
        if isPlayerUnderWater() then
            tes3.player.mobile:unequip{ item = light.object }
        end
    end
end

local function simulateSaveLights()
    if not common.modActive() then return end
    local light = tes3.getEquippedItem{
        actor = tes3.player,
        objectType = tes3.objectType.light
    }
    preventExpiring(light)
    preventDrowning(light)
end
event.register("simulate", simulateSaveLights)


local function blockEquip(e)
    if not common.modActive() then return end
    if common.isCarryableLight(e.item) then
        if e.itemData and e.itemData.timeLeft < 1 then
            tes3.messageBox("%s has run out.", e.item.name)
            return false
        end
        if isPlayerUnderWater() then
            tes3.messageBox("You can't equip lights while underwater.")
            return false
        end
    end
end
event.register("equip", blockEquip)


-- turn off lights that are placed in the world which have no time left
local function turnOffPlacedLightsNoFuel(e)
    if not common.modActive() then return end
    if common.isCarryableLight(e.reference.object) then
        local hasTimeLeft = (
            not e.reference.itemData or
            e.reference.itemData.timeLeft > 1
        )
        if not hasTimeLeft then
           common.removeLight(e.reference)
        end
    end
end

event.register("referenceSceneNodeCreated", turnOffPlacedLightsNoFuel)