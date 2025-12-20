local config = require("mer.realisticRepair.config")

event.register("damaged", function(e)
    if not config.enableLootDamage then return end
    if e.mobile.health.current <= 0 then
    --Damage Armor
        for _, slot in pairs(tes3.armorSlot) do
            local armor = tes3.getEquippedItem{
                actor = e.reference,
                objectType = tes3.objectType.armor,
                slot = slot
            }
            if armor then
                local conditionMulti = ( math.random(config.mcm.minCondition, config.mcm.maxCondition) / 100 )
                armor.itemData.condition = armor.itemData.condition * conditionMulti
            end
        end
        --Damage Weapon
        local weapon = tes3.getEquippedItem{
            actor = e.reference,
            objectType = tes3.objectType.weapon,
        }
        if weapon and weapon.itemData then
            local conditionMulti = ( math.random(config.mcm.minCondition, config.mcm.maxCondition) / 100 )
            weapon.itemData.condition = weapon.itemData.condition * conditionMulti
        end
    end
end)