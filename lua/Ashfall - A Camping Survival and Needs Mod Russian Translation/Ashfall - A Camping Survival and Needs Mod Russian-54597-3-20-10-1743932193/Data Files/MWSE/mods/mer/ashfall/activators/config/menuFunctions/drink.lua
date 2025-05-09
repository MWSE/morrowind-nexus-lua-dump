local common = require ("mer.ashfall.common.common")
local logger = common.createLogger("action:drink")
local CampfireUtil = require ("mer.ashfall.camping.campfire.CampfireUtil")
local LiquidContainer = require("mer.ashfall.liquid.LiquidContainer")
local thirstController = require("mer.ashfall.needs.thirstController")
local teaConfig = common.staticConfigs.teaConfig

---@param liquidContainer Ashfall.LiquidContainer
local function canDrink(liquidContainer)
    if not liquidContainer then return false end
    if not liquidContainer:hasWater() then
        return false
    end
    if liquidContainer:isWater() then
        return true
    end
    if liquidContainer:isBrewedTea() then
        return true
    end
    return false
end

return {
    text = "Пить",
    ---@param reference tes3reference
    showRequirements = function(reference)
        local liquidContainer = LiquidContainer.createFromReference(reference)
        return canDrink(liquidContainer)
    end,
    ---@param reference tes3reference
    enableRequirements = function(reference)
        local liquidContainer = LiquidContainer.createFromReference(reference)
        if not liquidContainer then return false end
        return not (liquidContainer:isBoiling())
    end,
    tooltipDisabled = {
        text = "Слишком горячо, чтобы пить. Подождите, пока остынет, или сначала перелейте в контейнер."
    },
    ---@param reference tes3reference
    callback = function(reference)

        local safeRef = tes3.makeSafeObjectHandle(reference)
        if not safeRef then
            logger:error("Could not create safe reference")
            return
        end

        local function doDrink()
            if not safeRef:valid() then
                logger:error("Reference is not valid")
                return
            end

            local liquidContainer = LiquidContainer.createFromReference(safeRef:getObject())
            if not liquidContainer then
                logger:error("Could not create liquid container from reference %s", reference.id)
                return
            end

            --tes3.playSound{ reference = tes3.player, sound = "Swallow" }
            --local maxCapacity = CampfireUtil.getWaterCapacityFromReference(reference)
            --local amountToDrink = math.min(maxCapacity, reference.data.waterAmount)
            local amountDrank = thirstController.drinkAmount{ amount = liquidContainer.waterAmount, waterType = liquidContainer:getLiquidType(),}
            --reference.data.waterAmount = reference.data.waterAmount - amountDrank
            liquidContainer:reduce(amountDrank)
            if liquidContainer:isTea() then
                if amountDrank > 0 then
                    event.trigger("Ashfall:DrinkTea", { teaType = reference.data.waterType, amountDrank = amountDrank, heat = reference.data.waterHeat })
                end
            end
            event.trigger("Ashfall:UpdateAttachNodes", { reference = reference})
        end

        local utensilNames = {
            kettle = "Чайник",
            cookingPot = "Кстрюля"
        }
        if reference.data.waterType == "dirty" then
            tes3ui.showMessageMenu{
                message = "Эта вода грязная.",
                buttons = {
                    {
                        text = "Всё равно выпить",
                        callback = function() doDrink() end
                    },
                },
                cancels = true,
            }
        else
            doDrink()
        end
    end
}