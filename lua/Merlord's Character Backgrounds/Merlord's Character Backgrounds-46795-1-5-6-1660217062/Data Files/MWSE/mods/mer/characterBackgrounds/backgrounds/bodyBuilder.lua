local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    data.bodyBuilder = data.bodyBuilder or {
        wearingShirt = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.clothing,
            slot = tes3.clothingSlot.shirt
        } ~= nil,
        wearingCuirass = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.armor,
            slot = tes3.armorSlot.cuirass
        } ~= nil,
        buffed = false,
        debuffed = false
    }
    return data
end

return {
    id = "bodyBuilder",
    name = "Bodybuilder",
    description = (
        "You have an incredible body. When you show it off, people can't help but swoon. " ..
        "When you are not wearing a shirt or chestpiece, you gain +10 to Personality. " ..
        "Unfortunately, your body is the most interesting thing about you, and when not " ..
        "mesmerized by your good looks, people quickly realize how boring you are. " ..
        "When wearing a shirt or chest piece, you suffer a -10 penalty to Personality. "
    ),
    callback = function()
        local function checkChest()
            local data = getData()
            if data.currentBackground == "bodyBuilder" then

                --Shirtless
                if not data.bodyBuilder.wearingShirt and not data.bodyBuilder.wearingCuirass then
                    --add buff
                    if not data.bodyBuilder.buffed then
                        data.bodyBuilder.buffed = true
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = 10
                        })
                    end

                    --remove debuff
                    if data.bodyBuilder.debuffed then
                        data.bodyBuilder.debuffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = 10
                        })
                    end

                --wearing shirt
                else
                    --add debuff
                    if not data.bodyBuilder.debuffed then
                        data.bodyBuilder.debuffed = true
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = -10
                        })
                    end

                    --remove buff
                    if data.bodyBuilder.buffed then
                        data.bodyBuilder.buffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            attribute = tes3.attribute.personality,
                            value = -10
                        })
                    end
                end
            end
        end

        local function onEquip(e)
            local data = getData()
            if data.currentBackground == "bodyBuilder" then
                timer.delayOneFrame(
                    function()
                        local isShirt = (
                            e.item.objectType == tes3.objectType.clothing and
                            e.item.slot == tes3.clothingSlot.shirt
                        )
                        if isShirt then
                            data.bodyBuilder.wearingShirt = true
                        end

                        local isCuirass = (
                            e.item.objectType == tes3.objectType.armor and
                            e.item.slot == tes3.armorSlot.cuirass
                        )
                        if isCuirass then
                            data.bodyBuilder.wearingCuirass = true
                        end
                        if isShirt or isCuirass then
                            checkChest()
                        end

                    end,
                    timer.real
                )
            end
        end


        local function onUnequip(e)
            local data = getData()
            if data.currentBackground == "bodyBuilder" then
                local isShirt = (
                    e.item.objectType == tes3.objectType.clothing and
                    e.item.slot == tes3.clothingSlot.shirt
                )
                if isShirt then
                    data.bodyBuilder.wearingShirt = false
                end

                local isCuirass = (
                    e.item.objectType == tes3.objectType.armor and
                    e.item.slot == tes3.armorSlot.cuirass
                )
                if isCuirass then
                    data.bodyBuilder.wearingCuirass = false
                end
                if isShirt or isCuirass then
                    checkChest()
                end
            end
        end
        checkChest()

        event.unregister("equip", onEquip)
        event.register("equip", onEquip)
        event.unregister("unequipped", onUnequip)
        event.register("unequipped", onUnequip)
    end
}