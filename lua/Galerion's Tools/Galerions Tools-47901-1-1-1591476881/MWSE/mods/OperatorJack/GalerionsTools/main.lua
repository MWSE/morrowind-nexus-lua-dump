-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 2020402) then
    local function warning()
        tes3.messageBox(
            "[Galeron's Tools ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local config = require("OperatorJack.GalerionsTools.config")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    dofile("Data Files\\MWSE\\mods\\OperatorJack\\GalerionsTools\\mcm.lua")
end)

local ids = {
    tool_SoulExtractor = "OJ_GT_SoulExtractor",
    book_Journal = "OJ_GT_Journal",
    journal_GalerionsTools = "OJ_GT_GalerionsTools"
}

local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
        table.sort(a, f)
        local i = 0      -- iterator variable
        local iter = function ()   -- iterator function
            i = i + 1
            if a[i] == nil then return nil
            else return a[i], t[a[i]]
        end
    end
    return iter
end

local function hasEmptySoulGem(ref, id)
    local stack = ref.object.inventory:findItemStack(tes3.getObject(id))
    if (stack) then
        return stack.variables == nil or #stack.variables < stack.count
    end
    return false
end

local creatures = {
    ["Misc_Soulgem_Petty"] = "OJ_GT_PettySoulCreature",
    ["Misc_Soulgem_Lesser"] = "OJ_GT_LessSoulCreature",
    ["Misc_Soulgem_Common"] = "OJ_GT_CommSoulCreature",
    ["Misc_Soulgem_Greater"] = "OJ_GT_GreatSoulCreature",
    ["Misc_Soulgem_Grand"] = "OJ_GT_GrandSoulCreature",
    ["Misc_SoulGem_Azura"] = "OJ_GT_DivSoulCreature"
}
local soulgems = {
    [30] = "Misc_Soulgem_Petty",
    [60] = "Misc_Soulgem_Lesser",
    [120] = "Misc_Soulgem_Common",
    [180] = "Misc_Soulgem_Greater",
    [600] = "Misc_Soulgem_Grand",
    [5000] = "Misc_SoulGem_Azura",
}

local function getEffectCost(effect, isConstantEffect)
    local fEnchantmentConstantDurationMult = tes3.findGMST(tes3.gmst.fEnchantmentConstantDurationMult).value
    local fEffectCostMult  = tes3.findGMST(tes3.gmst.fEffectCostMult).value

    local minMagnitude = effect.min or 1   
    local maxMagnitude = effect.max or 1
    local area = effect.radius or 1
    local baseMagickaCost = effect.object.baseMagickaCost
    local duration = effect.duration or 0
    if (isConstantEffect == true) then
        duration = fEnchantmentConstantDurationMult
    end

    local effectCost = math.floor(((minMagnitude + maxMagnitude) * duration + area) * baseMagickaCost * fEffectCostMult * 0.05)

    if (effectCost < 1) then
        effectCost = 1
    end

    if (effect.rangeType == tes3.effectRange.target) then
        effectCost = effectCost * 1.5
    end

    return effectCost
end

local function hasEmptySoulGemForEnchantmentPoints(soulPoints)
    for soul, soulgemId in pairsByKeys(soulgems) do
        if (soul > soulPoints) then
            local hasEmptySoulGem = hasEmptySoulGem(tes3.player, soulgemId)
            if (hasEmptySoulGem == true) then
                return true, soulgemId
            end
        end
    end

    return false, nil
end

local function getEnchantmentPointsFromEnchantment(enchantment, isConstantEffect)
    local effectCount = enchantment:getActiveEffectCount()
    local enchantmentPoints = 0

    for i = 1, effectCount do
        local effect = enchantment.effects[i]
        local effectCost = getEffectCost(effect, isConstantEffect)
        local compoundedEffectCost = effectCost * (effectCount - i + 1)
        enchantmentPoints = enchantmentPoints + compoundedEffectCost
    end

    return math.floor(enchantmentPoints)
end

local function getCreatureIdForEnchantmentPoints(soulPoints)
    local currentSoulgemId
    for soul, soulgemId in pairsByKeys(soulgems) do
        if (soul > soulPoints) then
            currentSoulgemId = soulgemId
            break
        end
    end
    if currentSoulgemId == nil then
        currentSoulgemId = "Misc_SoulGem_Azura"
    end

    return creatures[currentSoulgemId]
end

local function updateSoulGemOnPlayer(params)
    local soulgemId = params.soulgemId
    local enchantmentPoints = params.enchantmentPoints

    local creatureId = getCreatureIdForEnchantmentPoints(enchantmentPoints)

    tes3.removeItem({
        reference = tes3.player,
        item = soulgemId,
        playSound = false
    })

    tes3.addItem({
        reference = tes3.player,
        item = soulgemId,
        soul = creatureId,
        playSound = false
    })
end

local function getSoulExtractionChance(enchantment)
    local fEnchantmentChanceMult  = tes3.findGMST(tes3.gmst.fEnchantmentChanceMult).value
    local fEnchantmentConstantChanceMult   = tes3.findGMST(tes3.gmst.fEnchantmentConstantChanceMult).value

    local isConstantEffect = (enchantment.castType == tes3.enchantmentType.constant)

    local enchant = tes3.mobilePlayer.enchant.current
    local intelligence = tes3.mobilePlayer.intelligence.current
    local luck = tes3.mobilePlayer.luck.current
    local enchantmentPoints = getEnchantmentPointsFromEnchantment(enchantment, isConstantEffect)
    local chance = 0
    
    chance = (enchant - enchantmentPoints * fEnchantmentChanceMult + 0.2 * intelligence + 0.1 * luck ) 

    if (isConstantEffect == true) then
        chance = chance * fEnchantmentConstantChanceMult 
    end

    chance = chance * (config.chanceModifierPercent / 100.0)

    if (chance < 0) then chance = 0 end
    chance = chance + config.baseChance
    if (chance > 100) then chance = 100 end


    return chance, enchantmentPoints
end

local function filterItems(e)
    if (e.item.objectType == tes3.objectType.book) then
        return false
    end

    return e.item.enchantment ~= nil
end

local function onInventoryItemSelected(e)
    -- Make sure the player selected an item.
    if (e.item == nil) then
        return
    end

    if (e.item.enchantment == nil) then
        tes3.messageBox("The soul extractor failes to initialize. Perhaps the creator would know why. (Please report on Nexus.)")
        return
    end

    local enchantment = tes3.mobilePlayer.enchant.current
    local health = tes3.mobilePlayer.health.current
    if (enchantment <= 15) then
        tes3.messageBox("You are not skilled enough in enchanting to attempt this process. The tool reacts to your attempts and you suddenly feel weaker.")

        tes3.setStatistic({
            reference = tes3.player,
            name ="health",
            current = health - 25
        })
        return
    elseif (enchantment > 15 and enchantment <= 30 and math.random(0, enchantment) <= 15) then
        tes3.messageBox("You attempt to extract the soul out of the enchanted item, but you fail to initiate the process this time. The tool reacts to your attempts and you suddenly feel slightly weaker.")

        tes3.setStatistic({
            reference = tes3.player,
            name = "health",
            current = health - 15
        })
        return
    end

    -- Calculate Values
    local success = false

    local chance, enchantmentPoints = getSoulExtractionChance(e.item.enchantment)
    local hasEmptySoulGemForEnchantmentPoints, soulgemId = hasEmptySoulGemForEnchantmentPoints(enchantmentPoints)

    if (hasEmptySoulGemForEnchantmentPoints == false) then
        tes3.messageBox("You do not have a soulgem big enough to hold the soul of this enchantment.")
        return
    end

    if (math.random(1, 100) <= chance) then
        success = true
    end

    -- Remove enchanted item.
    tes3.removeItem({
        reference = tes3.player,
        item = e.item,
        playSound = false
    });

    if (success == true) then
        tes3.messageBox("You extract a soul from the enchanted item. The item is destroyed during the process.")

        updateSoulGemOnPlayer({
            soulgemId = soulgemId,
            enchantmentPoints = enchantmentPoints
        })

        tes3.playSound({
            sound = "enchant success",
            reference = tes3.player
        })
        
        tes3ui.forcePlayerInventoryUpdate()

        return
    elseif (success == false) then
        tes3.messageBox("You fail to extract a soul from the enchanted item. The item is destroyed during the process.")

        tes3.playSound({
            sound = "enchant fail",
            reference = tes3.player
        })

        tes3ui.forcePlayerInventoryUpdate()

        return
    end
end

local function onExtractorEquip(e)
    if (e.item.id ~= ids.tool_SoulExtractor) then
        return
    end

    tes3ui.showInventorySelectMenu({
		title = "Soul Extraction",
		noResultsText = "No possible items found.",
		filter = filterItems,
        callback = onInventoryItemSelected
    })
    
    -- Mark that we're extracting souls.
    local menuInventorySelect = tes3ui.findMenu(tes3ui.registerID("MenuInventorySelect"))
    if (menuInventorySelect) then
        menuInventorySelect:setPropertyBool("isSoulExtraction", true)
    end

    return false
end
event.register("equip", onExtractorEquip)

local function onUiObjectTooltip(e)
    local menuInventorySelect = tes3ui.findMenu(tes3ui.registerID("MenuInventorySelect"))
    if (not menuInventorySelect or not menuInventorySelect:getPropertyBool("isSoulExtraction")) then
        return
    end

    if (e.object.enchantment == nil) then
        return
    end

    local chance, enchantmentPoints = getSoulExtractionChance(e.object.enchantment)

    
    local outerBlock = e.tooltip:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.widthProportional = 1
    outerBlock.autoHeight = true
    outerBlock.borderAllSides = 4

    local innerBlock = outerBlock:createBlock()
    innerBlock.flowDirection = "left_to_right"
    innerBlock.widthProportional = 1
    innerBlock.autoHeight = true
    innerBlock.borderAllSides = 0

        local enchantmentPointsText = "Enchantment Points: " .. enchantmentPoints
        local label = innerBlock:createLabel({ text = enchantmentPointsText })
        label.borderAllSides = 4

    local innerBlock = outerBlock:createBlock()
    innerBlock.flowDirection = "left_to_right"
    innerBlock.widthProportional = 1
    innerBlock.autoHeight = true
    innerBlock.borderAllSides = 0 

        local extractionText = "Extraction Chance: " .. chance     
        local label = innerBlock:createLabel({ text = extractionText })
        label.borderAllSides = 4
end
event.register("uiObjectTooltip", onUiObjectTooltip)


local function onJournalActivate(e)
    if (e.activator == tes3.player and e.target.object.id == ids.book_Journal) then
        event.unregister("activate", onJournalActivate)

        tes3.updateJournal({
            id = ids.journal_GalerionsTools,
            index = 30
        })
    end
end

local function onLoaded()
    local currentIndex = tes3.getJournalIndex({id = ids.journal_GalerionsTools}) 
    if (currentIndex == nil or currentIndex < 30) then
        event.unregister("activate", onJournalActivate)
        event.register("activate", onJournalActivate)
    end

    print("[Galeron's Tools: INFO] Galeron's Tools Initialized For Save")
end

event.register("loaded", onLoaded)