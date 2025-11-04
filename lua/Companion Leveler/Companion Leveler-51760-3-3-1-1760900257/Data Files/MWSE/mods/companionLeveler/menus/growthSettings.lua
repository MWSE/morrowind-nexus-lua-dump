local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")


local growth = {}


function growth.createWindow(reference)
    growth.id_menu = tes3ui.registerID("kl_growth_menu")
    growth.id_label = tes3ui.registerID("kl_growth_label")
    growth.id_spell = tes3ui.registerID("kl_growth_spell_btn")
    growth.id_ability = tes3ui.registerID("kl_growth_ability_btn")
    growth.id_attribute = tes3ui.registerID("kl_growth_att_btn")
    growth.id_skill = tes3ui.registerID("kl_growth_skill_btn")
    growth.id_blacklist = tes3ui.registerID("kl_growth_blacklist_btn")
    growth.id_power_level = tes3ui.registerID("kl_growth_power_btn")


    log = logger.getLogger("Companion Leveler")
    log:debug("Growth Settings menu initialized.")

    local root = require("companionLeveler.menus.root")

    growth.reference = reference

    local menu = tes3ui.createMenu { id = growth.id_menu, fixedFrame = true }
    local modData = func.getModData(reference)


    --Labels
    local label = menu:createLabel { text = "Growth Settings", id = growth.id_label }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 34


    --Main Button Block---------------------------------------------------------------------------------------------
    local growth_block = menu:createBlock { id = "kl_growth_block" }
    growth_block.width = 236
    growth_block.height = 165
    growth_block.flowDirection = "top_to_bottom"


    --Buttons
    local button_spell = growth_block:createButton { id = growth.id_spell, text = "Spell Learning" }
    button_spell.borderLeft = 41
    if modData.spellLearning == true then
        button_spell.text = "Spell Learning: " .. tes3.findGMST("sYes").value .. ""
    else
        button_spell.text = "Spell Learning: " .. tes3.findGMST("sNo").value .. ""
    end

    local button_ability = growth_block:createButton { id = growth.id_ability, text = "Ability Learning" }
    button_ability.borderLeft = 34
    if modData.abilityLearning == true then
        button_ability.text = "Ability Learning: " .. tes3.findGMST("sYes").value .. ""
    else
        button_ability.text = "Ability Learning: " .. tes3.findGMST("sNo").value .. ""
    end

    local button_attribute = growth_block:createButton { id = growth.id_attribute, text = "Attribute Training" }
    button_attribute.borderLeft = 26
    if modData.attributeTraining == true then
        button_attribute.text = "Attribute Training: " .. tes3.findGMST("sYes").value .. ""
    else
        button_attribute.text = "Attribute Training: " .. tes3.findGMST("sNo").value .. ""
    end

    local button_skill = growth_block:createButton { id = growth.id_skill, text = "Skill Training" }
    button_skill.borderLeft = 41
    if modData.skillTraining == true then
        button_skill.text = "Skill Training: " .. tes3.findGMST("sYes").value .. ""
    else
        button_skill.text = "Skill Training: " .. tes3.findGMST("sNo").value .. ""
    end

    local button_blacklist = growth_block:createButton { id = growth.id_blacklist, text = "Blacklist" }
    button_blacklist.borderLeft = 61
    if modData.blacklist == true then
        button_blacklist.text = "Blacklist: " .. tes3.findGMST("sYes").value .. ""
    else
        button_blacklist.text = "Blacklist: " .. tes3.findGMST("sNo").value .. ""
    end

    ----Bottom Button Block-----------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 1.0

	local button_root = button_block:createButton { text = "Main Menu" }
	button_root.borderRight = 66

	local button_cancel = button_block:createButton { id = growth.id_cancel, text = tes3.findGMST("sCancel").value }


    --Events
    button_spell:register(tes3.uiEvent.mouseClick, growth.onSpell)
    button_ability:register(tes3.uiEvent.mouseClick, growth.onAbility)
    button_attribute:register(tes3.uiEvent.mouseClick, growth.onAttribute)
    button_skill:register(tes3.uiEvent.mouseClick, growth.onSkill)
    button_blacklist:register(tes3.uiEvent.mouseClick, growth.onBlacklist)
    button_root:register("mouseClick", function() menu:destroy() root.createWindow(reference) end)
    button_cancel:register("mouseClick", function() tes3ui.leaveMenuMode() menu:destroy() end)

    --Final Setup
    menu:updateLayout()
    tes3ui.enterMenuMode(growth.id_menu)
end

function growth.onSpell(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_spell)

        if button.text == "Spell Learning: " .. tes3.findGMST("sYes").value .. "" then
            button.text = "Spell Learning: " .. tes3.findGMST("sNo").value .. ""
            modData.spellLearning = false
            log:info("" .. growth.reference.object.name .. ": spell learning feature disabled.")
        else
            button.text = "Spell Learning: " .. tes3.findGMST("sYes").value .. ""
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

        if button.text == "Ability Learning: " .. tes3.findGMST("sYes").value .. "" then
            button.text = "Ability Learning: " .. tes3.findGMST("sNo").value .. ""
            modData.abilityLearning = false
            log:info("" .. growth.reference.object.name .. ": ability learning feature disabled.")
        else
            button.text = "Ability Learning: " .. tes3.findGMST("sYes").value .. ""
            modData.abilityLearning = true
            log:info("" .. growth.reference.object.name .. ": ability learning feature enabled.")
        end
    end
end

function growth.onAttribute(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_attribute)

        if button.text == "Attribute Training: " .. tes3.findGMST("sYes").value .. "" then
            button.text = "Attribute Training: " .. tes3.findGMST("sNo").value .. ""
            modData.attributeTraining = false
            log:info("" .. growth.reference.object.name .. ": will no longer train attributes.")
        else
            button.text = "Attribute Training: " .. tes3.findGMST("sYes").value .. ""
            modData.attributeTraining = true
            log:info("" .. growth.reference.object.name .. ": will now train attributes.")
        end
    end
end

function growth.onSkill(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_skill)

        if button.text == "Skill Training: " .. tes3.findGMST("sYes").value .. "" then
            button.text = "Skill Training: " .. tes3.findGMST("sNo").value .. ""
            modData.skillTraining = false
            log:info("" .. growth.reference.object.name .. ": will no longer train skills.")
        else
            button.text = "Skill Training: " .. tes3.findGMST("sYes").value .. ""
            modData.skillTraining = true
            log:info("" .. growth.reference.object.name .. ": will now train skills.")
        end
    end
end

function growth.onBlacklist(e)
    local menu = tes3ui.findMenu(growth.id_menu)
    local modData = func.getModData(growth.reference)

    if (menu) then
        local button = menu:findChild(growth.id_blacklist)
        
        if button.text == "Blacklist: " .. tes3.findGMST("sYes").value .. "" then
            button.text = "Blacklist: " .. tes3.findGMST("sNo").value .. ""
            modData.blacklist = false
            log:info("" .. growth.reference.object.name .. " removed from blacklist.")
        else
            button.text = "Blacklist: " .. tes3.findGMST("sYes").value .. ""
            modData.blacklist = true
            log:info("" .. growth.reference.object.name .. " added to blacklist.")
        end
    end
end


return growth