local Syntax = require("mer.theGuarWhisperer.components.Syntax")
local StatsBlock = require("mer.theGuarWhisperer.ui.components.StatsBlock")
local common = require("mer.theGuarWhisperer.common")

---@class GuarWhisperer.UI
local UI = {}

UI.ids = {
    menu = "TheGuarWhisperer_menu",
    outerBlock = "TheGuarWhisperer_outerBlock",
    titleBlock = "TheGuarWhisperer_titleBlock",
    title = "TheGuarWhisperer_title",
    subtitle = "TheGuarWhisperer_subtitle",
    mainBlock = "TheGuarWhisperer_mainBlock",
    buttonsBlock = "TheGuarWhisperer_buttonsBlock",
    infoBlock = "TheGuarWhisperer_infoBlock",
    bottomBlock = "TheGuarWhisperer_bottomBlock",
    closeButton = "TheGuarWhisperer_closeButton",
}
UI.menuWidth = 200
UI.menuHeight = 200
UI.padding = 8

-- Register with Right Click Menu Exit
local RCME = include("mer.RightClickMenuExit")
if RCME then
    RCME.registerMenu{
        menuId = UI.ids.menu,
        buttonId = UI.ids.closeButton
    }
end

local function closeMenu()
    tes3ui.findMenu(UI.ids.menu):destroy()
    tes3ui.leaveMenuMode()
end

---@param guar GuarWhisperer.GuarCompanion
local function getSubtitleText(guar)
    return guar:format("Уровень %d {male}%s",
        guar.stats:getLevel(),
        guar.genetics:isBaby() and " (Baby)" or ""
    )
end

---@param guar GuarWhisperer.GuarCompanion
local function getDescriptionText(guar)
    return guar:format("{name} {isHappy}. {He} {trustsYou}.")
end

---@param guar GuarWhisperer.GuarCompanion
function UI.showStatusMenu(guar)
    local menu = tes3ui.createMenu{ id = UI.ids.menu, fixedFrame = true }
    menu.visible = false
    menu.autoWidth = true
    menu.autoHeight = true
    tes3ui.enterMenuMode(UI.ids.menu)

    --Outer block
    local outerBlock = menu:createBlock{ id = UI.ids.outerBlock}
    do
        outerBlock.autoHeight = true
        outerBlock.autoWidth = true
        outerBlock.flowDirection = "top_to_bottom"

         --title block
        local titleBlock = outerBlock:createBlock{ id = UI.ids.titleBlock}
        do
            titleBlock.widthProportional = 1.0
            titleBlock.autoHeight = true
            titleBlock.paddingBottom = UI.padding
            titleBlock.flowDirection = "top_to_bottom"

            local titleText = guar:getName()
            local title = titleBlock:createLabel{ id = UI.ids.title, text = titleText }
            do
                title.absolutePosAlignX = 0.5
                title.color = tes3ui.getPalette("header_color")
            end

            local subtitleText = getSubtitleText(guar)
            do
                local subtitle = titleBlock:createLabel{ id = UI.ids.subtitle, text = subtitleText}
                subtitle.absolutePosAlignX = 0.5
            end

            local descriptionText = getDescriptionText(guar)
            local description = outerBlock:createLabel{text = descriptionText}
            description.wrapText = true
            description.justifyText = "center"
            description.widthProportional = 1.0
            description.maxWidth = 200
        end

        StatsBlock.new{ parent = outerBlock, guar = guar, inMenu = true }

        --Bottom Block close button
        local bottomBlock = outerBlock:createBlock{ id = UI.ids.bottomBlock }
        do
            bottomBlock.flowDirection = "left_to_right"
            bottomBlock.autoHeight = true
            bottomBlock.widthProportional = 1.0
            bottomBlock.childAlignX = 1.0

            local closeButton = bottomBlock:createButton{ id = UI.ids.closeButton, text = "Закрыть"}
            closeButton.absolutePosAlignX = 1.0
            closeButton.borderAllSides = 2
            closeButton.borderTop = 7
            closeButton:register("mouseClick", closeMenu )
        end
    end



    --update and display after a frame so everything is where its fucking supposed to be
    timer.frame.delayOneFrame(function()
        menu.visible = true
        menu:updateLayout()
    end)
end

return UI