local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")

local spList = {}

function spList.createWindow(reference)
    spList.id_menu = tes3ui.registerID("kl_spList_menu")
    spList.id_label = tes3ui.registerID("kl_spList_label")
    spList.id_title = tes3ui.registerID("kl_spList_ok")
    spList.id_pane = tes3ui.registerID("kl_spList_pane")


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
    border.width = 212
    border.height = 600
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 212
    pane.height = 600
    pane.widget.scrollbarVisible = true

    --Populate Pane
    local spellList = tes3.getSpells({ target = reference, spellType = 0, getRaceSpells = false, getBirthsignSpells = false })

    for i = 1, #spellList do

        local listItem = pane:createLabel({ text = spellList[i].name, id = "kl_spList_listItem_" .. i .. "" })
        listItem.color = { 1.0, 1.0, 1.0 }

        listItem:register("help", function(e)
            local tooltip = tes3ui.createTooltipMenu { spell = spellList[i] }

            local contentElement = tooltip:getContentElement()
            contentElement.paddingAllSides = 12
            contentElement.childAlignX = 0.5
            contentElement.childAlignY = 0.5
        end)
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

function spList.onOK()
    local menu = tes3ui.findMenu(spList.id_menu)

    if menu then
        menu:destroy()
    end
end

return spList
