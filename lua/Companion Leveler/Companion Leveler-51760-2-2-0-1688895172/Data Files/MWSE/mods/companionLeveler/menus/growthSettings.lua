local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local growth = {}

function growth.createWindow(reference)
    growth.id_menu = tes3ui.registerID("kl_growth_menu")
    growth.id_label = tes3ui.registerID("kl_growth_label")
    growth.id_spell = tes3ui.registerID("kl_growth_spell_btn")
    growth.id_ability = tes3ui.registerID("kl_growth_ability_btn")
    growth.id_blacklist = tes3ui.registerID("kl_growth_blacklist_btn")


    log = logger.getLogger("Companion Leveler")
    log:debug("Growth Settings menu initialized.")

    growth.reference = reference

    local menu = tes3ui.createMenu { id = growth.id_menu, fixedFrame = true }
    local modData = func.getModData(reference)


    --Labels
    local label = menu:createLabel { text = "Growth Settings", id = growth.id_label }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 34


    --Button Block
    local growth_block = menu:createBlock { id = "kl_growth_block" }
    growth_block.width = 236
    growth_block.height = 150
    growth_block.flowDirection = "top_to_bottom"


    -- Buttons
    local button_spell = growth_block:createButton { id = growth.id_spell, text = "Spell Learning" }
    button_spell.borderLeft = 41
    if modData.spellLearning == true then
        button_spell.text = "Spell Learning: Yes"
    else
        button_spell.text = "Spell Learning: No"
    end

    local button_ability = growth_block:createButton { id = growth.id_ability, text = "Ability Learning" }
    button_ability.borderLeft = 34
    if modData.abilityLearning == true then
        button_ability.text = "Ability Learning: Yes"
    else
        button_ability.text = "Ability Learning: No"
    end

    local button_blacklist = growth_block:createButton { id = growth.id_blacklist, text = "Blacklist" }
    button_blacklist.borderLeft = 61
    if modData.blacklist == true then
        button_blacklist.text = "Blacklist: Yes"
    else
        button_blacklist.text = "Blacklist: No"
    end

    local button_cancel = growth_block:createButton { id = growth.id_cancel, text = tes3.findGMST("sCancel").value }
    button_cancel.borderLeft = 84


    button_spell:register(tes3.uiEvent.mouseClick, growth.onSpell)
    button_ability:register(tes3.uiEvent.mouseClick, growth.onAbility)
    button_blacklist:register(tes3.uiEvent.mouseClick, growth.onBlacklist)
    button_cancel:register("mouseClick", function() menu:destroy() end)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(growth.id_menu)
end

function growth.onSpell(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_spell)

        if button.text == "Spell Learning: Yes" then
            button.text = "Spell Learning: No"
            modData.spellLearning = false
            log:info("" .. growth.reference.object.name .. ": spell learning feature disabled.")
        else
            button.text = "Spell Learning: Yes"
            modData.spellLearning = true
            log:info("" .. growth.reference.object.name .. ": spell learning feature enabled.")
        end
    end
end

function growth.onAbility(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_ability)

        if button.text == "Ability Learning: Yes" then
            button.text = "Ability Learning: No"
            modData.abilityLearning = false
            log:info("" .. growth.reference.object.name .. ": ability learning feature disabled.")
        else
            button.text = "Ability Learning: Yes"
            modData.abilityLearning = true
            log:info("" .. growth.reference.object.name .. ": ability learning feature enabled.")
        end
    end
end

function growth.onBlacklist(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_blacklist)
        
        if button.text == "Blacklist: Yes" then
            button.text = "Blacklist: No"
            modData.blacklist = false
            log:info("" .. growth.reference.object.name .. " removed from blacklist.")
        else
            button.text = "Blacklist: Yes"
            modData.blacklist = true
            log:info("" .. growth.reference.object.name .. " added to blacklist.")
        end
    end
end

return growth