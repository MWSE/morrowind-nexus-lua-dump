--[[
    Mod: TES3UI TextInput
    Author: Hrnchamd
]]
--

local this = {}


function this.init()
    this.id_menu = tes3ui.registerID("example:MenuTextInput")
    this.id_input = tes3ui.registerID("example:MenuTextInput_Text")
    this.id_ok = tes3ui.registerID("example:MenuTextInput_Ok")
    this.id_cancel = tes3ui.registerID("example:MenuTextInput_Cancel")
end event.register(tes3.event.initialized, this.init)


-- Create window and layout. Called by onCommand.
function this.createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end

    -- Create window and frame
    local menu = tes3ui.createMenu { id = this.id_menu, fixedFrame = true }

    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0

    -- Create layout
    local input_label = menu:createLabel { text = "Rename your container" }
    input_label.borderBottom = 5

    local input_block = menu:createBlock {}
    input_block.width = 300
    input_block.autoHeight = true
    input_block.childAlignX = 0.5 -- centre content alignment

    local border = input_block:createThinBorder {}
    border.width = 300
    border.height = 30
    border.childAlignX = 0.5
    border.childAlignY = 0.5

    local input = border:createTextInput { id = this.id_input, placeholderText = this.item.name }
    input.borderLeft = 5
    input.borderRight = 5
    input.widget.lengthLimit = 31 -- TextInput custom properties
    input.widget.eraseOnFirstKey = true

    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0       -- right content alignment

    local button_cancel = button_block:createButton { id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton { id = this.id_ok, text = tes3.findGMST("sOK").value }

    -- Events
    button_cancel:register(tes3.uiEvent.mouseClick, this.onCancel)
    menu:register(tes3.uiEvent.keyEnter, this.onOK) -- only works when text input is not captured
    input:register(tes3.uiEvent.keyEnter, this.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, this.onOK)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
    tes3ui.acquireTextInput(input) -- automatically reset when menu is closed
end

-- OK button callback.
function this.onOK()
    local old
    local menu = tes3ui.findMenu(this.id_menu)
    if (menu) then
        -- Copy text *before* the menu is destroyed
        local name = menu:findChild(this.id_input).text
        menu:destroy()
        if not tes3ui.getMenuOnTop() then
            tes3ui.leaveMenuMode()
        end
        old = this.item.name
        this.item.name = name
        this.item.modified = true
        tes3.messageBox { message = old .. " renamed to " .. name }
    end
end

-- Cancel button callback.
function this.onCancel()
    local menu = tes3ui.findMenu(this.id_menu)
    if (menu) then
        menu:destroy()
    end
    if not tes3ui.getMenuOnTop() then
        tes3ui.leaveMenuMode()
    end
end

-- Trigger callback.
---@param item tes3alchemy
function this.onCommand(item)
    local t = item
    if (t and t.name) then
        this.item = t
        this.createWindow()
    end
end

return this

