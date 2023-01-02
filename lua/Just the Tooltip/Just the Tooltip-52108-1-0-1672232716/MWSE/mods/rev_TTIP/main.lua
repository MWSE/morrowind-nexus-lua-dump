local this = {}
local config = require("rev_TTIP.config")


-- MCM --

local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Just the Tooltip")
	template:saveOnClose("rev_TTIP", config)
    local page = template:createPage()
    local category = page:createCategory("Settings")
    category:createKeyBinder{
        label = "Assign Keybind for Tooltip Menu",
        description = "Use this option to select the key which will open the tooltip menu. Default is K.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "ttip",
            table = config,
            defaultSetting = {
                keyCode = tes3.scanCode.k,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }    
	category:createKeyBinder{
        label = "Assign Keybind for Collection Marking",
        description = "Use this option to select the key which will mark all instances of an item with a green 'collected' mark. Default is C.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "collect",
            table = config,
            defaultSetting = {
                keyCode = tes3.scanCode.c,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)




function this.init()
    this.id_menu = tes3ui.registerID("tooltipper:menuTextInput")
    this.id_input = tes3ui.registerID("tooltipper:menuTextInput_Text")
    this.id_ok = tes3ui.registerID("tooltipper:menuTextInput_OK")
    this.id_temp = tes3ui.registerID("tooltipper:menuTextInput_Temp")
    this.id_delete = tes3ui.registerID("tooltipper:menuTextInput_Delete")
    this.id_cancel = tes3ui.registerID("tooltipper:menuTextInput_Cancel")
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
    local input_label = menu:createLabel{ text = "Tooltip:" }
    input_label.borderBottom = 5

    local input_block = menu:createBlock{}
    input_block.width = 500
    input_block.autoHeight = true
    input_block.childAlignX = 0.5  -- centre content alignment

    local border = input_block:createThinBorder{}
    border.width = 500
    border.height = 30
    border.childAlignX = 0.5
    border.childAlignY = 0.5

    local input = border:createTextInput{ id = this.id_input }
    input.text = this.item.name  -- initial text
    input.borderLeft = 5
    input.borderRight = 5
    input.widget.lengthLimit = 63  -- TextInput custom properties
    input.widget.eraseOnFirstKey = true

    local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0  -- right content alignment

    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
    local button_ok = button_block:createButton{ id = this.id_ok, text = "Permanent"}
    local button_temp = button_block:createButton{ id = this.id_ok, text = "Temporary" }
    local button_delete = button_block:createButton{ id = this.id_ok, text = "Remove Tooltip" }
	
	
	button_cancel:register("mouseClick", this.onCancel)
    menu:register("keyEnter", this.onOK) -- only works when text input is not captured
    input:register("keyEnter", this.onOK)
    button_ok:register("mouseClick", this.onOK)
    button_temp:register("mouseClick", this.onTemp)
    button_delete:register("mouseClick", this.onDel)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
    tes3ui.acquireTextInput(input) -- automatically reset when menu is closed


end

function this.onOK(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		-- Copy text *before* the menu is destroyed
		local tooltip = menu:findChild(this.id_input).text

		tes3ui.leaveMenuMode()
		menu:destroy()
		
		if not this.item.itemData then
			this.item.itemData = tes3.addItemData({to = ref, item = item})
		end
		this.item.itemData.data.customTooltip = tooltip
		
		tes3ui.refreshTooltip()
	end
end

function this.onDel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then

		tes3ui.leaveMenuMode()
		menu:destroy()
		
		if not this.item.itemData then
			this.item.itemData = tes3.addItemData({to = ref, item = item})
		end
		if tes3.player.itemData.data.rev_TTIP.items[this.item.id] then tes3.player.itemData.data.rev_TTIP.items[this.item.id] = nil end
		
		this.item.itemData.data.customTooltip = nil
		
		tes3ui.refreshTooltip()
	end
end

function this.onTemp(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		-- Copy text *before* the menu is destroyed
		local tooltip = menu:findChild(this.id_input).text

		tes3ui.leaveMenuMode()
		menu:destroy()
		
		if not this.item.itemData then
			this.item.itemData = tes3.addItemData({to = ref, item = item})
		end
		this.item.itemData.tempData.customTooltip = tooltip
		
		tes3ui.refreshTooltip()
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

function this.onCollect(e)
    local t = tes3.getPlayerTarget()
    if (t) then
		this.item = t
		tes3.player.itemData.data.rev_TTIP.items[t.id] = true
		tes3.messageBox({message = "Item marked"})
    end

end

local function onTooltip(e)
    local name = (e.itemData and e.itemData.data.customTooltip)
    local tempName = (e.itemData and e.itemData.tempData.customTooltip)
	if name then
		local tooltip = e.tooltip:createLabel({text = e.itemData.data.customTooltip})
		--collected.color = {0.5,1.0,0.0}
	end	
	if tempName then
		local tooltip = e.tooltip:createLabel({text = e.itemData.data.customTooltip})
	end
	
	if tes3.player.itemData.data.rev_TTIP.items[e.object.id] then
		local collected = e.tooltip:createLabel({text = "Collected"})
		collected.color = {0.5,1.0,0.0}
	end
end

local function loadedCallback(e)
	if tes3.player.itemData.data.rev_TTIP == nil then tes3.player.itemData.data.rev_TTIP = {} end
	if tes3.player.itemData.data.rev_TTIP.items == nil then tes3.player.itemData.data.rev_TTIP.items = {} end
end

event.register("initialized", this.init)
event.register(tes3.event.keyDown, this.onCommand, { filter = config.ttip.keyCode })
event.register(tes3.event.keyDown, this.onCollect, { filter = config.collect.keyCode })
event.register(tes3.event.uiObjectTooltip, onTooltip)
event.register(tes3.event.loaded, loadedCallback)