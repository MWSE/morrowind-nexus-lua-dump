local constants = require("JosephMcKean.MistyStep.constants")
local config = require("JosephMcKean.MistyStep.config")
local log = require("JosephMcKean.MistyStep.log")

local mistyStepSpell = tes3.getObject(constants.SPELL_ID)
if not mistyStepSpell then
    mistyStepSpell = tes3.createObject({
        id = constants.SPELL_ID,
        objectType = tes3.objectType.spell
    })
    tes3.setSourceless(mistyStepSpell)
    mistyStepSpell.name = "Misty Step"
    mistyStepSpell.magickaCost = constants.MAGICKA_COST

    mistyStepSpell.effects[1].id = tes3.effect.mistyStep
    mistyStepSpell.effects[1].rangeType = tes3.effectRange.self
end
---@cast mistyStepSpell tes3spell

local enchantment = tes3.getObject(constants.ENCHANTMENT_ID)
if not enchantment then
    enchantment = tes3.createObject({
        id = constants.ENCHANTMENT_ID,
        objectType = tes3.objectType.enchantment,
        castType = tes3.enchantmentType.castOnce,
        chargeCost = constants.MAGICKA_COST,
        maxCharge = constants.MAGICKA_COST
    })
    enchantment.effects[1].id = tes3.effect.mistyStep
    enchantment.effects[1].rangeType = tes3.effectRange.self
    tes3.setSourceless(enchantment)
end
---@cast enchantment tes3enchantment

local scroll = tes3.getObject(constants.SCROLL_ID)
if not scroll then
    scroll = tes3.createObject({
        id = constants.SCROLL_ID,
        objectType = tes3.objectType.book
    })
    tes3.setSourceless(scroll)
    scroll.name = "Scroll of Misty Step"
    scroll.value = 112
    scroll.weight = 0.2
    scroll.icon = "m\\tx_scroll_01.tga"
    scroll.mesh = "m\\text_scroll_01.nif"
    scroll.type = tes3.bookType.scroll
    scroll.enchantment = enchantment
end
---@cast scroll tes3book

local scrollLeveledList = tes3.getObject("random_scroll_all")
if scrollLeveledList and scrollLeveledList.objectType ==
    tes3.objectType.leveledItem then
    ---@cast scrollLeveledList tes3leveledItem
    scrollLeveledList:insert(scroll, 1)
    log:debug("Inserted Misty Step scroll into random_scroll_all leveled list")
else
    log:error(
        "Could not find random_scroll_all leveled list to insert Misty Step scroll")
end

--- @param e activateEventData
local function addSpellToMerchant(e)
    if (e.activator ~= tes3.player) then return end
    if (e.target.object.objectType ~= tes3.objectType.npc) then return end
    local npc = e.target.object
    ---@cast npc tes3npc
    if npc.aiConfig.offersSpells then
        if config.spellMerchants[e.target.id] or
            config.spellMerchants[e.target.baseObject.id] then
            local wasAdded = tes3.addSpell({
                reference = e.target,
                spell = mistyStepSpell,
                updateGUI = false
            })
            if wasAdded then
                log:debug("Added Misty Step spell to %s", e.target.id)
            end
        end
    end

    if config.scrollMerchants[e.target.id] or
        config.scrollMerchants[e.target.baseObject.id] then
        if npc.aiConfig.bartersBooks then
            tes3.addItem({reference = e.target, item = scroll, count = -1})
            if npc.inventory:contains(scroll) then
                log:debug("Added Misty Step scroll to %s's inventory",
                          e.target.id)
            end
        end
    end
end
event.register(tes3.event.activate, addSpellToMerchant)
