local core = require("openmw.core")

local fProjectileThrownStoreChance = core.getGMST("fProjectileThrownStoreChance")

local checks = {}

checks.arrowAOEEnchanted = function(weapon)
    local enchantId = weapon.type.records[weapon.recordId].enchant
    if not enchantId then return false end

    local effects = core.magic.enchantments.records[enchantId].effects
    for _, effect in ipairs(effects) do
        if effect.area > 0 then
            return true
        end
    end
    return false
end

checks.randomRoll = function(stickChance)
    if stickChance == 0 then
        return true
    elseif stickChance < 0 then
        stickChance = fProjectileThrownStoreChance / 100
    end
    return math.random() > stickChance
end

return checks
