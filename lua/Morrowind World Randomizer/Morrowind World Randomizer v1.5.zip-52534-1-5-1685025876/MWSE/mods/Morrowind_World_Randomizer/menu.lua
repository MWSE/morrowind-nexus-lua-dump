local config = include("Morrowind_World_Randomizer.config")

local this = {}

this.uniqueItemsOptionsId = tes3ui.registerID("menu:MWR:uniqueItemOptions")
this.i18n = nil

function this.uniqueItemOptions(resultFunction)
    if (tes3ui.findMenu(this.uniqueItemsOptionsId) ~= nil) then
        return
    end

    local menu = tes3ui.createMenu{ id = this.uniqueItemsOptionsId, fixedFrame = true }

    menu.alpha = 1.0
    menu.minWidth = 400
    menu.width = 400
    menu.autoHeight = true
    menu.positionX = menu.width / -2
    menu.positionY = menu.height / 2

    menu:register("unfocus", function(e)
        return false
    end)

    local textLabel = menu:createLabel{text = this.i18n("modConfig.message.uniqueItems")}
    textLabel.wrapText = true
    local urlLabel = menu:createHyperlink{text = "DRIP", url = "https://www.nexusmods.com/morrowind/mods/51242"}
    urlLabel.borderBottom = 5

    local button_block = menu:createBlock()
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 1.0

    local button_ok = button_block:createButton{ text = this.i18n("messageBox.enableRandomizer.button.yes") }
    local button_cancel = button_block:createButton{ text = this.i18n("messageBox.enableRandomizer.button.no") }

    button_cancel:register(tes3.uiEvent.mouseClick, function()
        tes3ui.leaveMenuMode()
        menu:destroy()
        if resultFunction then resultFunction(false) end
    end)
    button_ok:register(tes3.uiEvent.mouseClick, function()
        tes3ui.leaveMenuMode()
        menu:destroy()
        if resultFunction then resultFunction(true) end
    end)

    menu:updateLayout()
    tes3ui.enterMenuMode(this.uniqueItemsOptionsId)
end

return function(i18n)
    this.i18n = i18n
    return this
end