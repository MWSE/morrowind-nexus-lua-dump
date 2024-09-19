local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    data.knifeThrower = data.knifeThrower or {
        buffed = false,
    }
    return data
end

return {
    id = "knifeThrower",
    name = "Knife Thrower",
    description = (
        "You spent your formative years as a knife thrower at the circus. " ..
        "Your Marksman skill increases by 10 when a throwing weapon is equipped."
    ),
    callback = function()
        local function onEquip(e)
            local data = getData()
            if data.currentBackground == "knifeThrower" then
                timer.delayOneFrame(
                    function()
                        if e.item.objectType == tes3.objectType.weapon then
                            if e.item.type == tes3.weaponType.marksmanThrown then
                                if not data.knifeThrower.buffed then
                                    data.knifeThrower.buffed = true
                                    tes3.modStatistic({
                                        reference = tes3.player,
                                        skill = tes3.skill.marksman,
                                        value = 10
                                    })
                                end
                            end

                        end
                    end,
                    timer.real
                )
            end
        end


        local function onUnequip(e)
            local data = getData()
            if e.item.objectType == tes3.objectType.weapon then
                if e.item.type == tes3.weaponType.marksmanThrown then
                    if data.knifeThrower.buffed then
                        data.knifeThrower.buffed = false
                        tes3.modStatistic({
                            reference = tes3.player,
                            skill = tes3.skill.marksman,
                            value = -10
                        })
                    end
                end
            end
        end

        local equippedItem = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if equippedItem then
            onEquip({ item = equippedItem.object })
        end

        event.unregister("equip", onEquip)
        event.register("equip", onEquip)
        event.unregister("unequipped", onUnequip)
        event.register("unequipped", onUnequip)
    end
}