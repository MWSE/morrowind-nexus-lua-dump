local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

event.register("damaged", function(e)
    if not config.mcm.enableLootDamage then return end
    if e.mobile.health.current <= 0 then
        logger:debug("Applying death damage to equipped gear for %s", e.reference.object.name)

        for _, slot in pairs(tes3.armorSlot) do
            local armor = tes3.getEquippedItem{
                actor = e.reference,
                objectType = tes3.objectType.armor,
                slot = slot
            }
            if armor then
                local conditionMulti = ( math.random(config.mcm.minCondition, config.mcm.maxCondition) / 100 )
                armor.itemData.condition = armor.itemData.condition * conditionMulti
                logger:debug(" - Damaged armor in slot %s to condition %d",
                    slot, armor.itemData.condition)
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
            logger:debug(" - Damaged weapon %s to condition %d",
                weapon.object.name, weapon.itemData.condition)
        end
    end
end)