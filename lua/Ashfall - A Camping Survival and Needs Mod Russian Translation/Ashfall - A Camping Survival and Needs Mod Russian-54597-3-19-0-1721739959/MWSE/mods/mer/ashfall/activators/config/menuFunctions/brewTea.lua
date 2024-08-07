local common = require ("mer.ashfall.common.common")
local HeatUtil = require("mer.ashfall.heat.HeatUtil")
local teaConfig = common.staticConfigs.teaConfig
local skillConfigs = require("mer.ashfall.config.skillConfigs")
return {
    text = "Заварить чай",
    showRequirements = function(ref)
        if not ref.supportsLuaData then return false end
        local isKettle = ref.data.utensil == "kettle"
            or common.staticConfigs.kettles[ref.object.id:lower()]
        local hasWater = ref.data.waterAmount and ref.data.waterAmount > 0
        return isKettle and hasWater and ref.data.waterType == nil
    end,
    tooltip = function()
        return common.helper.showHint(
            "Вы можете заварить чай, перетаскивая травы прямо на чайник."
        )
    end,
    callback = function(campfire)
        timer.delayOneFrame(function()
            common.data.inventorySelectTeaBrew = true
            common.helper.showInventorySelectMenu{
                title = "Заварить чай:",
                noResultsText = "У вас нет подходящих ингредиентов.",
                filter = function(e)
                    return teaConfig.teaTypes[e.item.id:lower()] ~= nil
                end,
                callback = function(e)
                    common.data.inventorySelectTeaBrew = nil
                    if e.item then
                        campfire.data.waterType = e.item.id:lower()
                        campfire.data.teaProgress = 0
                        local currentHeat = campfire.data.waterHeat or 0
                        local newHeat = math.max(0, (campfire.data.waterHeat - 10))
                        HeatUtil.setHeat(campfire.data, newHeat, campfire)

                        common.skills.survival:exercise(skillConfigs.survival.brewTea.skillGain)

                        tes3.removeItem{
                            reference = e.reference,
                            item = e.item,
                            itemData = e.itemData
                        }
                        tes3ui.forcePlayerInventoryUpdate()
                        tes3.playSound{ reference = tes3.player, sound = "ashfall_water" }
                        event.trigger("Ashfall:UpdateAttachNodes", { reference = campfire})
                    end
                end
            }
            timer.delayOneFrame(function()
                common.data.inventorySelectTeaBrew = nil
            end)
        end)
    end
}