local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")

local abList = {}

function abList.createWindow(reference)
    abList.id_menu = tes3ui.registerID("kl_abList_menu")
    abList.reference = reference


    log = logger.getLogger("Companion Leveler")
    log:debug("Ability List menu initialized.")


    local menu = tes3ui.createMenu { id = abList.id_menu, fixedFrame = true }
    menu.alpha = 1.0

    local modData = func.getModData(reference)

    --Create layout
    local label = menu:createLabel { text = "Ability List:" }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 12


    local abList_block = menu:createBlock { id = "kl_abList_block" }
    abList_block.autoWidth = true
    abList_block.autoHeight = true

    local border = abList_block:createThinBorder {}
    border.width = 270
    border.height = 566
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 270
    pane.height = 566
    pane.widget.scrollbarVisible = true

    --Populate Pane
    if reference.object.objectType ~= tes3.objectType.creature and modData.metamorph == false then
        for i = 1, #tables.abListNPC do
            local spellObject = tes3.getObject(tables.abListNPC[i])
            local listItem

            if modData.abilities[i] == true then
                listItem = pane:createTextSelect({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
                func.abilityColor(listItem, i, true)
            else
                listItem = pane:createLabel({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
                listItem.color = tables.colors["grey"]
            end

            func.abilityTooltip(listItem, i, true)

            if modData.abilities[i] == true then
                listItem:register("mouseClick", function() abList.onSelect(spellObject.id) end)
            end

            --Show Unlearned?
            if config.showUnlearned == false then
                if modData.abilities[i] == false then
                    listItem:destroy()
                end
            end
        end
    else
        for i = 1, #tables.abList do
            local spellObject = tes3.getObject(tables.abList[i])
            local listItem

            if modData.abilities[i] == true then
                listItem = pane:createTextSelect({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
                func.abilityColor(listItem, i, false)
            else
                listItem = pane:createLabel({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
                listItem.color = tables.colors["grey"]
            end

            func.abilityTooltip(listItem, i, false)

            if modData.abilities[i] == true then
                listItem:register("mouseClick", function() abList.onSelect(spellObject.id) end)
            end

            --Show Unlearned?
            if config.showUnlearned == false then
                if modData.abilities[i] == false then
                    listItem:destroy()
                end
            end
        end
    end

    --sort
    pane:getContentElement():sortChildren(function(c, d)
        return c.text < d.text
    end)

    --Button Block
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 0.5
    button_block.borderTop = 12

    local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

    --Events
    button_ok:register(tes3.uiEvent.mouseClick, abList.onOK)
end

function abList.forget(e)
    local menu = tes3ui.findMenu(abList.id_menu)
    local dialog = tes3ui.findMenu("MenuDialog")

    if menu then
        if e.button == 0 then
            tes3.removeSpell({ reference = abList.reference, spell = abList.spell.id})

            if abList.reference.object.objectType == tes3.objectType.creature then
                --Creature
                for i = 1, #tables.abList do
                    if abList.spell.id == tables.abList[i] then
                        local modData = func.getModData(abList.reference)
                        modData.abilities[i] = false
                    end
                end
            else
                --NPC
                for i = 1, #tables.abListNPC do
                    if abList.spell.id == tables.abListNPC[i] then
                        local modData = func.getModData(abList.reference)
                        modData.abilities[i] = false
                    end
                end
            end

            func.clMessageBox("" .. abList.reference.object.name .. " forgot the " .. abList.spell.name .. " ability.")

            abList.onOK()
            local sMenu = tes3ui.findMenu("kl_sheet_menu")
            sMenu:destroy()

            --Dialogue prevents leaveMenuMode for some reason
            if dialog then
                dialog:destroy()
            end

            tes3ui.leaveMenuMode()

            timer.delayOneFrame(function()
                timer.delayOneFrame(function()
                    timer.delayOneFrame(function()
                        func.updateIdealSheet(abList.reference)
                    end)
                end)
            end)
        end
    end
end

function abList.onSelect(id)
    local menu = tes3ui.findMenu(abList.id_menu)
    if menu then
        local spell = tes3.getObject(id)
        abList.spell = spell
        tes3.messageBox({ message = "Forget " .. spell.name .. "?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = abList.forget })
    end
end

function abList.onOK()
    local menu = tes3ui.findMenu(abList.id_menu)

    if menu then
        menu:destroy()
    end
end


return abList