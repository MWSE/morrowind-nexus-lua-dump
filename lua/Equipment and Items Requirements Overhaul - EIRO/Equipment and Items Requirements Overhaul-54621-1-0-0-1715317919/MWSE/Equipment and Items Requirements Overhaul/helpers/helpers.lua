local mappers = require("Equipment and Items Requirements Overhaul.helpers.mappers")

local attributeSkillMapping = mappers.attributeSkillMapping

-- Tooltip Helper Function
local function createTooltipBlock(e, attrName, attrValue)
    local playerAttribute = attributeSkillMapping[attrName] and attributeSkillMapping[attrName]() or 0
    local meetsRequirement = playerAttribute >= attrValue

    local text = string.format("Requires %s: %u", attrName, attrValue)

    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6

    local label = block:createLabel { text = text }
    label.color = meetsRequirement and tes3ui.getPalette("fatigue_color") or tes3ui.getPalette("health_color")
    label.wrapText = true
end

-- Enchantment Cost Helper Function
local function getEffectiveEnchantmentCost(item)
    if item and item.enchantment then
        local enchantment = item.enchantment
        if enchantment.chargeCost ~= 0 then
            return enchantment.chargeCost
        else
            local totalMagnitude = 0
            for _, effect in ipairs(enchantment.effects) do
                if effect then
                    local magnitude = effect.max or (effect.duration / 10)
                    magnitude = (magnitude == 0) and (effect.duration / 10) or magnitude
                    totalMagnitude = totalMagnitude + magnitude
                end
            end
            return totalMagnitude
        end
    else
        return 0
    end
end


-- Export the helper functions
return {
    createTooltipBlock = createTooltipBlock,
    getEffectiveEnchantmentCost = getEffectiveEnchantmentCost,
}
