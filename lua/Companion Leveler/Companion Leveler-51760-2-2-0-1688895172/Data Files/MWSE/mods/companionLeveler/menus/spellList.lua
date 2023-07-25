local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")

local spList = {}

function spList.createWindow(reference)
    spList.id_menu = tes3ui.registerID("kl_spList_menu")
    spList.id_label = tes3ui.registerID("kl_spList_label")
    spList.id_title = tes3ui.registerID("kl_spList_ok")
    spList.id_pane = tes3ui.registerID("kl_spList_pane")
    spList.reference = reference


    log = logger.getLogger("Companion Leveler")
    log:debug("Spell List menu initialized.")


    local menu = tes3ui.createMenu { id = spList.id_menu, fixedFrame = true }

    --Create layout
    local label = menu:createLabel { text = "" .. reference.object.name .. "'s Spell List:", id = spList.id_label }
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
            tes3.messageBox("" .. spList.reference.object.name .. " forgot the " .. spList.spell.name .. " spell.")
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
        tes3.messageBox({ message = "Forget " .. spell.name .. "?",
            buttons = { "Yes", "No" },
            callback = spList.forget })
    end
end

function spList.onOK()
    local menu = tes3ui.findMenu(spList.id_menu)

    if menu then
        menu:destroy()
    end
end

return spList
