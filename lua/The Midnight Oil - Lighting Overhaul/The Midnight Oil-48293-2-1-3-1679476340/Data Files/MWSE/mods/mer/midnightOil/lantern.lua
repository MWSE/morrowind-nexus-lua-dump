local common = require("mer.midnightOil.common")

---@return boolean
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

---@param lightObj tes3object|tes3light
---@return boolean
local function isLightWithTime(lightObj)
    return lightObj.time and lightObj.time > 0
end

---@param itemData tes3itemData
---@return boolean
local function isLightRunningOut(itemData)
    return itemData and itemData.timeLeft < 1
end

---@param lightStack tes3equipmentStack
local function preventExpiring(lightStack)
    if lightStack then
        --only for lanterns and lamps, not torches
        if common.isOilLantern(lightStack.object) or common.isCandleLantern(lightStack.object) then
            if isLightWithTime(lightStack.object) and isLightRunningOut(lightStack.itemData) then
                tes3.messageBox("%s has run out.", lightStack.object.name)
                tes3.mobilePlayer:unequip{item = lightStack.object}
            end
        end
    end
end

---@param lightStack tes3equipmentStack
local function preventDrowning(lightStack)
    if lightStack then
        if isPlayerUnderWater() and isLightWithTime(lightStack.object) then
            tes3.mobilePlayer:unequip{ item = lightStack.object }
        end
    end
end

---Prevent lights from fully expiring while in the inventory
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


---Prevent equipping lights that have run out or are underwater
---@param e equipEventData
local function blockEquip(e)
    if not common.modActive() then return end
    if common.isCarryableLight(e.item) then
        if isLightWithTime(e.item) and isLightRunningOut(e.itemData) then
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
---@param e referenceSceneNodeCreatedEventData
local function turnOffPlacedLightsNoFuel(e)
    if not common.modActive() then return end
    if common.isCarryableLight(e.reference.object) then
        if isLightWithTime(e.reference.object) and isLightRunningOut(e.reference.itemData) then
           common.removeLight(e.reference)
        end
    end
end

event.register("referenceSceneNodeCreated", turnOffPlacedLightsNoFuel)