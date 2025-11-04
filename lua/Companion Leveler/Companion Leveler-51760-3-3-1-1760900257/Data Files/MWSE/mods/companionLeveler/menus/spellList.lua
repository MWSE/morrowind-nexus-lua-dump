local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local tables = require("companionLeveler.tables")

local spList = {}

function spList.createWindow(reference)
    spList.id_menu = tes3ui.registerID("kl_spList_menu")
    spList.id_label = tes3ui.registerID("kl_spList_label")
    spList.id_title = tes3ui.registerID("kl_spList_ok")
    spList.id_pane = tes3ui.registerID("kl_spList_pane")
    spList.reference = reference
    spList.modData = func.getModData(reference)

    log = logger.getLogger("Companion Leveler")
    log:debug("Spell List menu initialized.")


    local menu = tes3ui.createMenu { id = spList.id_menu, fixedFrame = true }
    menu.alpha = 1.0

    --Create layout
    local label = menu:createLabel { text = "Spell List:", id = spList.id_label }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 12


    local spList_block = menu:createBlock { id = "kl_spList_block" }
    spList_block.autoWidth = true
    spList_block.autoHeight = true

    local border = spList_block:createThinBorder {}
    border.width = 270
    border.height = 566
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 270
    pane.height = 566
    pane.widget.scrollbarVisible = true

    --Populate Pane
    local spellList = tes3.getSpells({ target = reference, spellType = 0, getRaceSpells = false, getBirthsignSpells = false })

    --Equipped Spells
    local equippedLabel = pane:createLabel({ text = "Equipped:" })
    equippedLabel.borderBottom = 12
    equippedLabel.color = { 1.0, 1.0, 1.0 }

    for i = 1, #spellList do
        local listItem = pane:createTextSelect({ text = spellList[i].name, id = "kl_spList_listItem_" .. i .. "" })

        listItem:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu { spell = spellList[i] }

            local contentElement = tooltip:getContentElement()
            contentElement.paddingAllSides = 12
            contentElement.childAlignX = 0.5
            contentElement.childAlignY = 0.5
        end)

        listItem:register("mouseClick", function() spList.onSelect(spellList[i].id) end)
    end

    --Unequipped Spells
    local unequippedLabel = pane:createLabel({ text = "Unequipped:" })
    unequippedLabel.borderBottom = 12
    unequippedLabel.borderTop = 12
    unequippedLabel.color = { 1.0, 1.0, 1.0 }

    for i = 1, #spList.modData.unusedSpells do
        local spell = tes3.getObject(spList.modData.unusedSpells[i])
        local listItem = pane:createTextSelect({ text = spell.name, id = "kl_spList_listItem_" .. i .. "" })

        listItem:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu { spell = spell }

            local contentElement = tooltip:getContentElement()
            contentElement.paddingAllSides = 12
            contentElement.childAlignX = 0.5
            contentElement.childAlignY = 0.5
        end)

        listItem:register("mouseClick", function() spList.onSelect2(spell.id) end)
    end

    --Active Effects
    local activeEffectsLabel = pane:createLabel({ text = "Active Effects:" })
    activeEffectsLabel.borderBottom = 12
    activeEffectsLabel.borderTop = 12
    activeEffectsLabel.color = { 1.0, 1.0, 1.0 }

    local effects = reference.mobile:getActiveMagicEffects({})
    local sources = {}
    for i = 1, #effects do
        local found = false
        for n = 1, #sources do
            if effects[i].instance.source == sources[n] then
                found = true
                break
            end
        end

        if not found then
            table.insert(sources, effects[i].instance.source)

            if effects[i].instance.source.isAbility == false then
                local listItem = pane:createTextSelect({ text = "" .. effects[i].instance.source.name .. " : " .. math.round(effects[i].duration - effects[i].effectInstance.timeActive) .. "s", id = "kl_spList_effect_" .. i .. "" })
                listItem.widget.idle = tables.colors["pink"]

                listItem:register("help", function(e)
                    local tooltip = tes3ui.createTooltipMenu({ spell = effects[i].instance.source })

                    local contentElement = tooltip:getContentElement()
                    contentElement.paddingAllSides = 12
                    contentElement.childAlignX = 0.5
                    contentElement.childAlignY = 0.5
                end)
            end
        end

        --local listItem = pane:createTextSelect({ text = tes3.getMagicEffect(effects[i].effectId).name, id = "kl_spList_effect_" .. i .. "" })

        -- listItem:register("help", function(e)
        --     local tooltip = tes3ui.createTooltipMenu()

        --     local contentElement = tooltip:getContentElement()
        --     contentElement.paddingAllSides = 12
        --     contentElement.childAlignX = 0.5
        --     contentElement.childAlignY = 0.5

        --     local name = contentElement:createLabel({ text = "" .. effects[i].instance.source.name .. "" })
        --     local magnitude = contentElement:createLabel({ text = "" .. math.round(effects[i].effectInstance.effectiveMagnitude) .. "pts" })
        --     local duration = contentElement:createLabel({ text = "" .. math.round(effects[i].duration - effects[i].effectInstance.timeActive) .. "s" })
        --     if effects[i].instance.source.isAbility then
        --         duration.text = "Ability"
        --     end
        -- end)
    end

    --Button Block
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 0.5
    button_block.borderTop = 12

    local button_ok = button_block:createButton { id = spList.id_ok, text = tes3.findGMST("sOK").value }

    --Events
    button_ok:register(tes3.uiEvent.mouseClick, spList.onOK)
end

function spList.forget(e)
    local menu = tes3ui.findMenu(spList.id_menu)
    if menu then
        if e.button == 0 then
            tes3.removeSpell({ reference = spList.reference, spell = spList.spell.id})
            spList.modData.unusedSpells[#spList.modData.unusedSpells + 1] = spList.spell.id
            func.clMessageBox("" .. spList.reference.object.name .. " unequipped the " .. spList.spell.name .. " spell.")
            menu:destroy()
            spList.createWindow(spList.reference)
        end
    end
end

function spList.remember(e)
    local menu = tes3ui.findMenu(spList.id_menu)
    if menu then
        if e.button == 0 then
            tes3.addSpell({ reference = spList.reference, spell = spList.spell.id})
            for i = 1, #spList.modData.unusedSpells do
                if spList.modData.unusedSpells[i] == spList.spell.id then
                    table.remove(spList.modData.unusedSpells, i)
                    break
                end
            end
            func.clMessageBox("" .. spList.reference.object.name .. " equipped the " .. spList.spell.name .. " spell.")
            menu:destroy()
            spList.createWindow(spList.reference)
        end
    end
end

function spList.onSelect(id)
    local menu = tes3ui.findMenu(spList.id_menu)
    if menu then
        local spell = tes3.getObject(id)
        spList.spell = spell
        tes3.messageBox({ message = "Unequip " .. spell.name .. "?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = spList.forget })
    end
end

function spList.onSelect2(id)
    local menu = tes3ui.findMenu(spList.id_menu)
    if menu then
        local spell = tes3.getObject(id)
        spList.spell = spell
        tes3.messageBox({ message = "Equip " .. spell.name .. "?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = spList.remember })
    end
end

function spList.onOK()
    local menu = tes3ui.findMenu(spList.id_menu)

    if menu then
        menu:destroy()
    end
end

return spList