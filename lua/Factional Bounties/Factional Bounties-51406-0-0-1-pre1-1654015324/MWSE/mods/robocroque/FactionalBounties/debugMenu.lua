local this = {}

local bounties = require 'robocroque.factionalbounties.bounties'
local factions = require 'robocroque.factionalbounties.factions'

function this.init()
    this.id_menu = tes3ui.registerID("factionalBounties:DebugMenu")
    this.id_edit_menu = tes3ui.registerID("factionalBounties:DebugMenu_EditMenu")
    this.id_edit_menu_label = tes3ui.registerID("factionalBounties:DebugMenu_EditMenu_Label")
    this.id_edit_menu_input = tes3ui.registerID("factionalBounties:DebugMenu_EditMenu_Input")

    this.id_menu_edit_buttons = nil
end

function this.createWindow()
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end

    if this.id_menu_edit_buttons == nil then
        this.id_menu_edit_buttons = {}
        for factionName, factionData in pairs(factions) do
            if factionData.tracksOwnCrimes then
                this.id_menu_edit_buttons[factionName] = tes3ui.registerID("factionalBounties:DebugMenu_EditButton_" .. factionName)
            end
        end
    end

    local menu = tes3ui.createMenu{ id = this.id_menu, dragFrame = true }
    menu.width = 600
    menu.height = 400
    menu.text = "Factional Bounties"

    local pane = menu:createVerticalScrollPane()

    local editButtons = {}

    for factionName, factionData in pairs(factions) do
        local faction_block = pane:createBlock()
        faction_block.width = 600
        faction_block.autoHeight = true
        faction_block.childAlignY = 0.5
        
        local faction_label = faction_block:createLabel{ text = factionName }
        faction_label.borderBottom = 5

        if factionData.tracksOwnCrimes then
            editButtons[factionName] = faction_block:createButton{ id = this.id_menu_edit_buttons[factionName], text = "No bounty" }
            editButtons[factionName]:register("mouseClick", function ()
                this.editBounty(factionName)
            end)

            local bounty = bounties.getBounty(factionName)
            if bounty ~= nil then
                editButtons[factionName].text = bounty
            end    
        else
            faction_label.text = faction_label.text .. " (does not track own crimes)"
        end
    end

    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
end

function this.editBounty(factionName)
    if (tes3ui.findMenu(this.id_edit_menu) ~= nil) then
        return
    end

    local menu = tes3ui.createMenu{ id = this.id_edit_menu, fixedFrame = true }

    local input_label = menu:createLabel{ id = this.id_edit_menu_label, text = factionName }
    input_label.borderBottom = 5

    local input_block = menu:createBlock()
    input_block.width = 300
    input_block.autoHeight = true
    input_block.childAlignX = 0.5
    input_block.childAlignY = 0.5

    local border = input_block:createThinBorder()
    border.width = 50
    border.height = 30
    border.childAlignX = 0.5
    border.childAlignY = 0.5

    local input = border:createTextInput{ id = this.id_edit_menu_input }
    input.text = ""
    input.borderLeft = 5
    input.borderRight = 5

    local bounty = bounties.getBounty(factionName)
    if bounty ~= nil then
        input.text = bounty
    end

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0 
    button_block.autoHeight = true
    button_block.childAlignX = 1.0 

    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton{ id = this.id_ok, text = tes3.findGMST("sOK").value }
    
    button_cancel:register("mouseClick", this.onEditCancel)
    button_ok:register("mouseClick", this.onEditOK)
    
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_edit_menu)
    tes3ui.acquireTextInput(input)
end

function this.onEditCancel(e)
    local menu = tes3ui.findMenu(this.id_edit_menu)

    if (menu) then
        menu:destroy()
    end
end

function this.onEditOK(e)
    local debugMenu = tes3ui.findMenu(this.id_menu)
    local editMenu = tes3ui.findMenu(this.id_edit_menu)

    if (editMenu) then
        local factionName = editMenu:findChild(this.id_edit_menu_label).text
        local bounty = editMenu:findChild(this.id_edit_menu_input).text
        local editButton = debugMenu:findChild(this.id_menu_edit_buttons[factionName])

        editMenu:destroy()

        if bounty ~= "" then
            bounties.setBounty(factionName, tonumber(bounty))
            editButton.text = bounty
        else
            bounties.setBounty(factionName, nil)
            editButton.text = "No bounty"
        end
    end
end

-- Keydown callback.
function this.onCommand(e)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        menu:destroy()
        tes3ui.leaveMenuMode()
    else
        this.createWindow()
    end
end

event.register("initialized", this.init)
event.register("keyDown", this.onCommand, { filter = 53 }) -- "/" key