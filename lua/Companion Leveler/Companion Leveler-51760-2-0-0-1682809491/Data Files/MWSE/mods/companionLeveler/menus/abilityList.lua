local config = require("companionLeveler.config")
local tables = require("companionLeveler.tables")
local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")

local abList = {}

function abList.createWindow(reference)
    abList.id_menu = tes3ui.registerID("kl_abList_menu")
    abList.id_label = tes3ui.registerID("kl_abList_label")
    abList.id_title = tes3ui.registerID("kl_abList_ok")
    abList.id_pane = tes3ui.registerID("kl_abList_pane")


    log = logger.getLogger("Companion Leveler")
    log:debug("Ability List menu initialized.")


    local menu = tes3ui.createMenu { id = abList.id_menu, fixedFrame = true }

    local modData = func.getModData(reference)

    --Create layout
    local label = menu:createLabel { text = "" .. reference.object.name .. "'s Ability List:", id = abList.id_label }
    label.borderBottom = 12


    local abList_block = menu:createBlock { id = "kl_abList_block" }
    abList_block.autoWidth = true
    abList_block.autoHeight = true

    local border = abList_block:createThinBorder {}
    border.width = 212
    border.height = 600
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 212
    pane.height = 600
    pane.widget.scrollbarVisible = true

    --Populate Pane
    if reference.object.objectType ~= tes3.objectType.creature then
        for i = 1, #tables.abListNPC do
            local spellObject = tes3.getObject(tables.abListNPC[i])

            local listItem = pane:createLabel({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
            listItem.color = { 0.35, 0.35, 0.35 }

            listItem:register("help", function(e)
                local tooltip = tes3ui.createTooltipMenu { spell = spellObject }

                local contentElement = tooltip:getContentElement()
                contentElement.paddingAllSides = 12
                contentElement.childAlignX = 0.5
                contentElement.childAlignY = 0.5

                tooltip:createDivider()

                tooltip:createLabel { text = tables.abDescriptionNPC[i] }

                if tables.abDescriptionNPC2[i] ~= "" then
                    local helpLabel2 = tooltip:createLabel { text = tables.abDescriptionNPC2[i] }
                    helpLabel2.borderTop = 8
                end
            end)

            if modData.abilities[i] == true then
                listItem.color = { 1.0, 1.0, 1.0 }
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

            local listItem = pane:createLabel({ text = spellObject.name, id = "kl_abList_listItem_" .. i .. "" })
            listItem.color = { 0.35, 0.35, 0.35 }

            listItem:register("help", function(e)
                local tooltip = tes3ui.createTooltipMenu { spell = spellObject }

                local contentElement = tooltip:getContentElement()
                contentElement.paddingAllSides = 12
                contentElement.childAlignX = 0.5
                contentElement.childAlignY = 0.5

                tooltip:createDivider()

                tooltip:createLabel { text = tables.abDescription[i] }

                local helpLabel2 = tooltip:createLabel { text = tables.abDescription2[i] }
                helpLabel2.borderTop = 8
            end)

            if modData.abilities[i] == true then
                listItem.color = { 1.0, 1.0, 1.0 }
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

    local button_ok = button_block:createButton { id = abList.id_ok, text = tes3.findGMST("sOK").value }

    --Events
    button_ok:register(tes3.uiEvent.mouseClick, abList.onOK)
end

function abList.onOK()
    local menu = tes3ui.findMenu(abList.id_menu)

    if menu then
        menu:destroy()
    end
end

return abList
