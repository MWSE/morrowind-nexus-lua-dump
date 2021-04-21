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

local function getTierForPlayer()
    local intelligence = tes3.mobilePlayer.intelligence.current
    local willpower = tes3.mobilePlayer.willpower.current
    local tier = math.round(math.floor(intelligence / 2 + willpower / 2) / 15, 0)
    if (tier <= 0) then
        return 1
    end
    return tier
end

local function onUiSpellTooltip(e)
    local spellTier = getTierForSpell(e.spell)
    local playerTier = getTierForPlayer()

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
    local playerTier = getTierForPlayer()
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