local jamrock = require("rev_JAMR.main")

local this = {}

function this.init()
    this.id_menu = tes3ui.registerID("renamer:menuTextInput")
    this.id_input = tes3ui.registerID("renamer:menuTextInput_Text")
    this.id_ok = tes3ui.registerID("renamer:menuTextInput_OK")
    this.id_cancel = tes3ui.registerID("renamer:menuTextInput_Cancel")
end

function this.createWindow()


    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	
	
    -- Create window and frame
    local menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }

    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0

    -- Create layout
    local input_label = menu:createLabel{ text = "Rename:" }
    input_label.borderBottom = 5

    local input_block = menu:createBlock{}
    input_block.width = 300
    input_block.autoHeight = true
    input_block.childAlignX = 0.5  -- centre content alignment

    local border = input_block:createThinBorder{}
    border.width = 300
    border.height = 30
    border.childAlignX = 0.5
    border.childAlignY = 0.5

    local input = border:createTextInput{ id = this.id_input }
    input.text = this.item.name  -- initial text
    input.borderLeft = 5
    input.borderRight = 5
    input.widget.lengthLimit = 31  -- TextInput custom properties
    input.widget.eraseOnFirstKey = true

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0  -- right content alignment

    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton{ id = this.id_ok, text = tes3.findGMST("sOK").value }
	
	
	button_cancel:register("mouseClick", this.onCancel)
    menu:register("keyEnter", this.onOK) -- only works when text input is not captured
    input:register("keyEnter", this.onOK)
    button_ok:register("mouseClick", this.onOK)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
    tes3ui.acquireTextInput(input) -- automatically reset when menu is closed


end

function this.onOK(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		-- Copy text *before* the menu is destroyed
		local name = menu:findChild(this.id_input).text

		tes3ui.leaveMenuMode()
		menu:destroy()
		jamrock.renameItem(this.item,name,tes3.player)
		--jamrock.renameItem(tes3.getPlayerTarget(),"test",tes3.player)
	end
end

function this.onCancel(e)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end


function this.onCommand(e)
    local t = tes3.getPlayerTarget()
    if (t) then
		this.item = t
		this.createWindow()
    end

end

event.register("initialized", this.init)
event.register(tes3.event.key, this.onCommand, { filter = tes3.scanCode.h })