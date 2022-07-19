-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200122) then
    local function warning()
        tes3.messageBox(
            "[Tiered Magicka ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------
local function getTierForSpell(spell)
    local tier = math.round(math.floor(spell.magickaCost / 20), 0)
    if (tier <= 0) then
        return 1
    end
    return tier
end

-- Using the given spell, calculate player's tier relative to spell schools in spell.
local function getTierForPlayer(spell)
    local totalCost = 0
    local attributes = {}
    for _, effect in pairs(spell.effects) do
        if (effect.id ~= -1) then
            totalCost = totalCost + effect.cost
        end
    end
    for _, effect in pairs(spell.effects) do
        if (effect.id ~= -1) then
            local magicEffect = tes3.getMagicEffect(effect.id)
            local skill = magicEffect.skill
            local attribute = tes3.getSkill(skill).attribute
            local cost = effect.cost
            local proportion = cost / totalCost
            attributes[attribute] = (attributes[attribute] or 0) + proportion
            --mwse.log("Attribute %s, Cost %s, Total Cost %s, Proportion %s", attribute, cost, totalCost, proportion)
        end
    end

    local sum = 0
    for attribute, proportion in pairs(attributes) do
        local current = tes3.mobilePlayer.attributes[attribute + 1].current
        sum = sum + current * proportion
        --mwse.log("Attribute %s, Current %s, Proportion %s, new sum %s", attribute, current, proportion, sum)
    end

    local tier = math.round(math.floor(sum / table.size(attributes)) / 10, 0)
    --mwse.log("Tier %s, Sum %s, Number Attributes %s", tier, sum, table.size(attributes))
    if (tier <= 0) then
        return 1
    end
    return tier
end

local function onUiSpellTooltip(e)
    local spellTier = getTierForSpell(e.spell)
    local playerTier = getTierForPlayer(e.spell)

    local outerBlock = e.tooltip:createBlock()
	outerBlock.flowDirection = "top_to_bottom"
    outerBlock.widthProportional = 1
    outerBlock.autoHeight = true
    outerBlock.borderAllSides = 4

    outerBlock:createDivider()

    local innerBlock = outerBlock:createBlock()
	innerBlock.flowDirection = "left_to_right"
    innerBlock.widthProportional = 1
    innerBlock.autoHeight = true
    innerBlock.borderAllSides = 0

        local tierText = "Spell Tier: " .. spellTier
        local tierColor = tes3ui.getPalette("normal_color")
        if (spellTier > playerTier) then
            tierColor = tes3ui.getPalette("negative_color")
        end
        local tierLabel = innerBlock:createLabel({ text = tierText })
        tierLabel.color = tierColor
        tierLabel.borderAllSides = 4

    local innerPlayerBlock = outerBlock:createBlock()
    innerPlayerBlock.flowDirection = "left_to_right"
    innerPlayerBlock.widthProportional = 1
    innerPlayerBlock.autoHeight = true
    innerPlayerBlock.borderAllSides = 0

        local playerTierText = "Caster Tier: " .. playerTier
        local playerTierLabel = innerPlayerBlock:createLabel({ text = playerTierText })
        playerTierLabel.borderAllSides = 4
end
event.register("uiSpellTooltip", onUiSpellTooltip)

local function onSpellCast(e)
    local spellTier = getTierForSpell(e.source)
    local playerTier = getTierForPlayer(e.source)
    if (spellTier > playerTier) then
        e.castChance = 0
        tes3.messageBox("Your spellcasting tier is too low to cast this spell.")
    end
end
event.register("spellCast", onSpellCast)

local function initialized()
    print("[Tiered Magicka: INFO] Tiered Magicka Initialized")
end

event.register("initialized", initialized)