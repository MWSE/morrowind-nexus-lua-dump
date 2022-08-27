local thirstController = require("mer.ashfall.needs.thirstController")
local validTeas = require("JosephMcKean.teaMerchants.validTeas")
local logger = require("JosephMcKean.teaMerchants.logging").createLogger(
                   "addTea")
local teaConfig = require("mer.ashfall.common.common").staticConfigs.teaConfig

-- First time entering a cell, add tea to random Tea Merchants' liquidContainers
local chanceToFill = 1
local fillMin = 25

local function fill(ref, bottleData)
    -- the amount of tea filled should not be higher than the water capacity of the bottle 
    local bottleCapacity = bottleData.capacity
    local fillAmount = math.random(fillMin, bottleCapacity)
    -- if it is Tea Merchant' bottles, it has to be a full bottle of tea
    if ref.id:lower() == "jsmk_misc_com_bottle" then
        fillAmount = bottleCapacity
    end
    ref.data.waterAmount = fillAmount
    -- randomly choose a tea type to fill 
    local waterType = table.choice(validTeas)
    if tes3.getObject(waterType) then
        ref.data.waterType = waterType
        ref.data.teaProgress = 100
        ref.data.waterHeat = math.random(0, 100)
    end
    logger:debug("Filling %s with %s, %s/%s.", ref.object.name,
                 teaConfig.teaTypes[waterType].teaName, fillAmount,
                 bottleCapacity)
    ref.modified = true
end

-- fill bottles, teacups, teapots, etc that already placed in world that are 
-- owned by faction Tea Merchants with tea 
local function addTeaToWorld(e)
    for ref in e.cell:iterateReferences(tes3.objectType.miscItem) do
        local teaOwner = tes3.getOwner(ref)
        if teaOwner and teaOwner.id == "Tea Merchants" or ref.id:lower() ==
            "jsmk_misc_com_bottle" then
            local bottleData = thirstController.getBottleData(ref.object.id)
            local waterAmount = ref.data.waterAmount
            -- If the bottle has bottleData and doesn't has liquid in it fill it with tea 
            if bottleData and not waterAmount then
                if math.random() <= chanceToFill then
                    fill(ref, bottleData)
                end
                -- else if the bottle has liquid in it
            elseif bottleData and waterAmount then
                local isTea = teaConfig.teaTypes[ref.data.waterType] ~= nil
                if isTea then
                    logger:debug(
                        "%s has %s/%s tea inside already, not refilling.",
                        ref.object.name, waterAmount, bottleData.capacity)
                elseif math.random() <= chanceToFill then -- if the liquid is not tea, refill the bottle with tea 
                    fill(ref, bottleData)
                end
            else
                logger:debug("%s does not has bottleData.", ref.object.name)
            end
        end
    end
end
-- add tea to the world upon cell change 
event.register("cellChanged", addTeaToWorld)
