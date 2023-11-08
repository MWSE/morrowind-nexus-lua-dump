

local this = {}


local pathPrefix = "Clone.scripts.CloningAvatar"
local rightBlock
local button_block
local cloneData  = require(pathPrefix .. ".common.cloneData")
local playerCloneData
local selectedId
function this.init()
    this.id_menu = tes3ui.registerID("zhac_clone:MenuTextInput")
    this.id_input = tes3ui.registerID("zhac_clone:MenuTextInput_Text")
    this.id_ok = tes3ui.registerID("zhac_clone:MenuTextInput_Ok")
    this.id_cancel = tes3ui.registerID("zhac_clone:MenuTextInput_Cancel")
end

local clonePaneData
-- Create window and layout. Called by onCommand.
function this.createWindow()
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end

    -- Create window and frame
    local menu = tes3ui.createMenu( { id = this.id_menu, fixedFrame = true})
    menu.alpha = 1.0

    -- Create label for the select menu
    local inputLabel = menu:createLabel { text = "Select your Clone" }
    inputLabel.borderBottom = 5

    -- Create layout
    local mainBlock = menu:createBlock()
    mainBlock.flowDirection = "left_to_right"
    mainBlock.autoHeight = true
    mainBlock.autoWidth = true

    local leftBlock = mainBlock:createBlock()
    leftBlock.flowDirection = "top_to_bottom"
    leftBlock.autoHeight = true
    leftBlock.autoWidth = true

    rightBlock = mainBlock:createBlock()
    rightBlock.flowDirection = "top_to_bottom"
    rightBlock.autoHeight = true
    rightBlock.autoWidth = true

    -- Create select menu
    local scrollPane = leftBlock:createVerticalScrollPane({ id = "myPane" })
    local paneItems = cloneData.getMenuData()
    clonePaneData = paneItems
    local activeCloneData
    playerCloneData = cloneData.getCloneDataForNPC(tes3.player)
    for _, value in ipairs(paneItems) do
        if value.info.isAlive == true then
            local text = value.name
            if value.id == playerCloneData.id then
                text = value.name .. " (controlled)"
            end
            local createdPane = scrollPane:createTextSelect({ text = text, id = value.id })
            if playerCloneData and value.id == playerCloneData.id then
                createdPane.widget.state = tes3.uiState.active
                activeCloneData = value
            end
            createdPane:register("mouseClick", function(e)
                local id = e.widget.id
                if id == playerCloneData.id then
                    button_block:findChild(this.id_ok).disabled = true
                    button_block:findChild(this.id_ok).visible = false
                else
                    button_block:findChild(this.id_ok).disabled = false
                    button_block:findChild(this.id_ok).visible = true
                end
                selectedId = id
                for _, child in ipairs(e.source.parent.children) do
                    child.widget.state = tes3.uiState.normal
                end
                for index, value in ipairs(clonePaneData) do
                    if value.id == id then
                      --  rightBlock:findChild("health").text = value.info.health
                        rightBlock:findChild("location").text = value.info.loc
                    end
                end
                e.source.widget.state = tes3.uiState.active
            end)
        end
    end

    -- Create labels on the right
    local label1
    local label2
    local label3
    if activeCloneData then
       -- label1 = rightBlock:createLabel { text = activeCloneData.info.health, id = "health" }
        label2 = rightBlock:createLabel { text = activeCloneData.info.loc, id = "location" }
    else
       -- label1 = rightBlock:createLabel { text = "", id = "health" }
        label2 = rightBlock:createLabel { text = "", id = "location" }
    end
    label2.minWidth = 350
    scrollPane.width = 300
    scrollPane.autoHeight = true
    scrollPane.childAlignX = 0.5
    scrollPane.childAlignY = 0.5
    scrollPane.positionY = 8
    scrollPane.minWidth = 250
    scrollPane.minHeight = 300
    scrollPane.autoWidth = true
    scrollPane.autoHeight = true

    button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = -1.0      -- right content alignment

    local button_cancel = button_block:createButton { id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton { id = this.id_ok, text = "Control Selected" }
    if activeCloneData then
        local id = activeCloneData.id
        if id == playerCloneData.id then
            button_block:findChild(this.id_ok).disabled = true
            button_block:findChild(this.id_ok).visible = false
        else
            button_block:findChild(this.id_ok).disabled = false
            button_block:findChild(this.id_ok).visible = true
        end
    end

    button_cancel:register(tes3.uiEvent.mouseClick, this.onCancel)
    menu:register(tes3.uiEvent.keyEnter, this.onOK) -- only works when text input is not captured
    button_ok:register(tes3.uiEvent.mouseClick, this.onOK)
    -- Register key events
    menu:register("keyEnter", this.onOK)
    menu:register("keyEsc", this.onCancel)

    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
end

-- OK button callback.
function this.onOK(e)
    if not selectedId then
        return
    end
    local destActor = cloneData.getCloneObject(selectedId)
    if tes3.player.id == destActor.id then
        error("Player and dest are the same")
    end
    cloneData.transferPlayerData(tes3.player, destActor, true)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        -- Copy text *before* the menu is destroyed

        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

-- Cancel button callback.
function this.onCancel(e)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

-- Keydown callback.
function this.onCommand(e)
    local t = tes3.getPlayerTarget()
    if (t) then
        t = t.object.baseObject or t.object -- Select actor base object

        if (t.name) then
            this.item = t
            this.createWindow()
        end
    end
end

event.register(tes3.event.initialized, this.init)
--   event.register(tes3.event.keyDown, this.onCommand, { filter = tes3.scanCode["/"] }) -- "/" key
return this
