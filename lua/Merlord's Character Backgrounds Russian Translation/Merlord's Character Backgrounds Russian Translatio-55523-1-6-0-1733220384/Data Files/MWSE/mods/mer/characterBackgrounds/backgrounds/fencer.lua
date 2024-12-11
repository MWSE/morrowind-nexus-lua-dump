return {
    id = "fencer",
    name = "Мастер фехтования",
    description = (
        "Вы посвятили свою жизню искусству фехтования. " ..
        "Когда вы вооружены одноручным длинным клинком, оставив вторую руку свободной, " ..
        "ваш навык Длинных клинков увеличивается на 20 пунктов."
    ),

    callback = function()
        local getData = function()
            local data = tes3.player.data.merBackgrounds
            data.fencer = data.fencer or {
                offhandEquipped = false,
                swordEquipped = false,
                buffed = false
            }
            return data
        end
        local function updateFencing()
            local data = getData()
            local isFencing = (
                data.fencer.swordEquipped and
                not data.fencer.offHandEquipped
            )

            if isFencing then
                if not data.fencer.buffed then
                    data.fencer.buffed = true
                    tes3.modStatistic({
                        reference = tes3.player,
                        skill = tes3.skill.longBlade,
                        value = 20
                    })
                end
            else
                if data.fencer.buffed then
                    data.fencer.buffed = false
                    tes3.modStatistic({
                        reference = tes3.player,
                        skill = tes3.skill.longBlade,
                        value = -20
                    })
                end
            end
        end

        local function isOffhand(item)
            return item.objectType == tes3.objectType.armor
                and item.slot == tes3.armorSlot.shield
                    or
                item.objectType == tes3.objectType.light
        end

        ---@param e { reference: tes3reference, item: any }
        local function onEquip(e)
            local data = getData()
            if e.reference == tes3.player and data.currentBackground == "fencer" then
                timer.delayOneFrame(function()
                    if e.item.objectType == tes3.objectType.weapon then
                        data.fencer.swordEquipped = ( e.item.type == tes3.weaponType.longBladeOneHand )
                    end
                    if isOffhand(e.item) then
                        data.fencer.offHandEquipped = true
                    end
                    updateFencing()
                end)
            end
        end

        local function onUnequip(e)
            local data = getData()
            if e.reference == tes3.player and data.currentBackground == "fencer" then

                if e.item.objectType == tes3.objectType.weapon then
                    data.fencer.swordEquipped = false
                end
                if isOffhand(e.item) then
                    data.fencer.offHandEquipped = false
                end
                updateFencing()
            end
        end

        local equippedItem = tes3.getEquippedItem{
            actor = tes3.player,
            objectType = tes3.objectType.weapon
        }
        if equippedItem then
            onEquip({ reference = tes3.player, item = equippedItem.object })
        end

        event.unregister("equip", onEquip)
        event.register("equip", onEquip)
        event.unregister("unequipped", onUnequip)
        event.register("unequipped", onUnequip)
    end
}