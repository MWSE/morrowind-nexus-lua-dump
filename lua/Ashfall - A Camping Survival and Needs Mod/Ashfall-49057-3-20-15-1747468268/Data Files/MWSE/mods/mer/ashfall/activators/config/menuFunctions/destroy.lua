local common = require ("mer.ashfall.common.common")

return {
    text = "Destroy Campfire",
    showRequirements = function(reference)
        if not reference.supportsLuaData then return false end
        return (
            not reference.data.grillId and
            not reference.data.utensilId and
            not reference.data.isLit and
            not reference.data.supportsId and
            not reference.data.bellowsId and
            (reference.data.dynamicConfig and reference.data.dynamicConfig.campfire == "dynamic")
        )
    end,
    callback = function(campfire)
        campfire.data.destroyed = true

        if not campfire.data.isLit  then
            local recoveredFuel =  math.floor(campfire.data.fuelLevel * 0.5)
            if recoveredFuel >= 1 then
                local woodId = "ashfall_firewood"
                tes3.addItem{
                    reference = tes3.player,
                    item = woodId,
                    count = recoveredFuel,
                    playSound = false,
                    showMessage = true
                }
            end

            local charcoal = campfire.data.charcoalLevel or 0
            local recoveredCoal = math.floor(charcoal * 0.75)
            recoveredCoal = math.clamp(recoveredCoal, 0, common.staticConfigs.maxWoodInFire)
            if recoveredCoal > 1 then
                local coalId = "ashfall_ingred_coal_01"
                tes3.addItem{
                    reference = tes3.player,
                    item = coalId,
                    count = recoveredCoal,
                    playSound = false,
                    showMessage = true
                }
            end
        end
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        event.trigger("Ashfall:fuelConsumer_Extinguish", {fuelConsumer = campfire})
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
        common.helper.yeet(campfire)
    end
}