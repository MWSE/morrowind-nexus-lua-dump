local this = {}

this.isMerchant = function(actor)
    local ai = actor.aiConfig

    if ai.bartersAlchemy
    or ai.bartersApparatus
    or ai.bartersArmor
    or ai.bartersBooks
    or ai.bartersClothing
    or ai.bartersEnchantedItems
    or ai.bartersIngredients
    or ai.bartersLights
    or ai.bartersLockpicks
    or ai.bartersMiscItems
    or ai.bartersProbes
    or ai.bartersRepairTools
    or ai.bartersWeapons then
        return true
    else
        return false
    end
end

return this