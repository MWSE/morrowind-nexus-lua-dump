--[[
    Handles the UI code for the command menu
]]
local this = {}

local commandMenuId = tes3ui.registerID("Commander_Tooltip")
local commonUI = require("mer.theGuarWhisperer.ui")


local function createCommandContainer(cMenu, parentBlock)
    local outerBlock = parentBlock:createBlock({})
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true
    outerBlock.paddingAllSides = 0
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.childAlignX = 0.5

    --Title
    local titleText = cMenu.currentPage.getTitle(cMenu)
    local title = outerBlock:createLabel{ text = titleText }
    title.color = tes3ui.getPalette("header_color")

    return outerBlock
end


local function createContextList(cMenu, parentBlock)
    local container = createCommandContainer(cMenu, parentBlock)
    --label
    for i, command in ipairs(cMenu.commandList) do
        local text = command.label(cMenu)

        local label = container:createLabel{ text = text}
        label.alignX = 0.5
        if i == cMenu.index then
            if command.doSteal then
                label.color = tes3ui.getPalette("negative_color")
            else
                label.color = tes3ui.getPalette("normal_color")
            end
        else
            label.color = tes3ui.getPalette("disabled_color")
        end
    end
end 

local function createCommandList(cMenu, parentBlock)
    local container = createCommandContainer(cMenu, parentBlock)
    --label
    for i, command in ipairs(cMenu.commandList) do
        local text = command.label(cMenu)

        local label = container:createTextSelect{ text = text}
        label.alignX = 0.5
        if command.doSteal then
            label.color = tes3ui.getPalette("negative_color")
        end
        label:register("mouseClick", function()
            local index = i
            this.destroyCommandMenu()
            cMenu.index = index
            cMenu:performAction()
        end)
        label:register("help", function()
            commonUI.createTooltip(text, command.description)
        end)
    end
end


function this.createCommandMenu(cMenu)

    local menu = tes3ui.createMenu{ id = commandMenuId, fixedFrame = true }
    menu.autoWidth = true
    menu.autoHeight = true

    tes3ui.enterMenuMode(commandMenuId)
    timer.frame.delayOneFrame(function()
        cMenu:checkCommandState()
        createCommandList(cMenu, menu)
        menu:updateLayout()
    end)
end

function this.destroyContextMenu()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        
        local contextMenu = menu:findChild(commandMenuId)
        if contextMenu then
            contextMenu:destroy()
        end
    end
end

function this.destroyCommandMenu()
    local menu = tes3ui.findMenu(commandMenuId)
    if menu then 
        menu:destroy()
        tes3ui.leaveMenuMode()
    end
end

function this.createContextMenu(cMenu)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local contextMenu = menu:findChild(commandMenuId)
        local activeCommand = cMenu:getActiveCommand()
        local target =  tes3.getPlayerTarget()
        if cMenu.activeCompanion and activeCommand and not ( target and target ~= cMenu.activeCompanion.reference ) then
            --refresh contextMenu
            if contextMenu then
                contextMenu:destroy()
            end
            contextMenu = menu:createBlock{ id = commandMenuId }
            contextMenu.autoHeight = true
            contextMenu.autoWidth = true
            contextMenu.absolutePosAlignX = 0.5
            contextMenu.layoutOriginFractionY = 0.60
            --background
            local labelBackground = contextMenu:createRect({color = {0, 0, 0}})
            labelBackground.autoHeight = true
            labelBackground.autoWidth = true
                --border
            local labelBorder = labelBackground:createThinBorder({})
            labelBorder.autoHeight = true
            labelBorder.autoWidth = true
            labelBorder.paddingAllSides = 10
            labelBorder.flowDirection = "top_to_bottom"
            labelBorder.childAlignX = 0.5
            createContextList(cMenu, labelBorder)
        else
            if contextMenu then
                contextMenu:destroy()
            end
        end
    end
end

return this