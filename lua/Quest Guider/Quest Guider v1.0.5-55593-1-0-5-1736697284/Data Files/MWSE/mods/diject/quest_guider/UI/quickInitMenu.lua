local config = include("diject.quest_guider.config")

local this = {}

function this.show()
    local menu = tes3ui.createMenu{ id = "qGuider_qickInit", fixedFrame = true, }
    local menuEl = menu:getContentElement()
    menuEl.widthProportional = nil
    menuEl.heightProportional = nil
    menuEl.autoHeight = true
    menuEl.autoWidth = false
    menuEl.width = 600
    menuEl.childAlignX = 0
    menuEl.alpha = 1

    local headerBlock = menu:createBlock{}
    headerBlock.autoHeight = true
    headerBlock.widthProportional = 1
    headerBlock.childAlignX = 0.5

    local headerLabel = headerBlock:createLabel{}
    headerLabel.text = "Quest Guider"
    headerLabel.font = 1
    headerLabel.borderBottom = 10

    local function add(text, table, value)
        local btnBlock = menu:createBlock{}
        btnBlock.autoHeight = true
        btnBlock.widthProportional = 1
        btnBlock.borderBottom = 5
        btnBlock.flowDirection = tes3.flowDirection.leftToRight

        local btn = btnBlock:createButton{text = "Yes"}

        local labelBlock = btnBlock:createBlock{}
        labelBlock.autoWidth = false
        labelBlock.autoHeight = true
        labelBlock.width = 550

        local label = labelBlock:createLabel{text = text}
        label.autoHeight = true
        label.autoWidth = false
        label.widthProportional = 1
        label.wrapText = true

        btn:register(tes3.uiEvent.mouseClick, function (e)
            table[value] = not table[value]
            menu:updateLayout()
        end)

        menu:registerBefore(tes3.uiEvent.preUpdate, function (e)
            btn.text = table[value] and "Yes" or "No"
        end)
    end

    add("Integrate the mod to the Journal menu", config.data.journal, "enabled")
    add("Auto track quest objects when a new journal entry has been added", config.data.tracking.quest, "enabled")
    add("Integrate tracking info to the Map menu", config.data.map, "enabled")
    add("Mark quest givers on the map (the mod doesn't check if you can take these quests)", config.data.tracking.giver, "enabled")
    add("Show a tooltip about quest info on objects", config.data.tooltip.object, "enabled")
    add("Show a tooltip on doors about quest objects that are in the cell that the door leads to", config.data.tooltip.door, "enabled")

    local closeBtnBlock = menu:createBlock{}
    closeBtnBlock.autoHeight = true
    closeBtnBlock.widthProportional = 1
    closeBtnBlock.flowDirection = tes3.flowDirection.leftToRight
    closeBtnBlock.childAlignX = 1

    local closeBtn = closeBtnBlock:createButton{text = "Close"}
    closeBtn:register(tes3.uiEvent.mouseClick, function (e)
        config.save()
        menu:destroy()
    end)

    menu:updateLayout()
    menu:updateLayout()
end

return this