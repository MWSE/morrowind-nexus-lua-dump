local core = require("openmw.core")

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

checks.successfulRoll = function(settings)
    local stickChance = settings:get("stickChance")
    if stickChance < 0 then
        stickChance = core.getGMST("fProjectileThrownStoreChance") / 100
    end
    return math.random() < stickChance
end

return checks
