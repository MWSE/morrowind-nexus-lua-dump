--[[ Mining Cart - holds ores
Part of Morrowind Crafting 3
Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)
local recipes = require("Morrowind_Crafting_3.mining_cart.recipes")
local mc = require("Morrowind_Crafting_3.mc_common")
local UIID_MinecartMenu_ListBlock_Label = tes3ui.registerID("MinecartMenu:ListBlockLabel")
local inInventory = {}
local inCart = {}
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel, UID_spacerLabel
local id_menu, id_menulist, id_cancel, magicCart, contents
local slider = {}
local labelBlockCart = {}
local labelBlockInv = {}
local fb = {}

function init()
	id_menu = tes3ui.registerID("CartMenu")
	id_menulist = tes3ui.registerID("CartList")
	id_cancel = tes3ui.registerID("CartCancel")
    UID_ListPane = tes3ui.registerID("CartMenu::List")
    UID_spacerLabel = tes3ui.registerID("SpacerLabel")
    --Recipes = mc.getAddInFiles("Cart", Recipes) -- Get add-in recipes
end

local function calcEnc()
    local total = 0
    local obj
    for index, x in ipairs(recipes) do
        obj = tes3.getObject(x.id) -- ore reference
        total = total + (inCart[index] * obj.weight)
    end
    return total
end

local function calcVREnc()
    local total = 0
    local obj
    for index, x in ipairs(recipes) do
        obj = tes3.getObject(x.id) -- ore reference
        total = total + (slider[index]:getPropertyInt("PartScrollBar_current") * obj.weight)
    end
    return total
end

-- Buttons
local function onOK(e) -- OK button
    -- Sort out inventories for player and cart as per sliders
    if calcVREnc() > 24000 then
        tes3.messageBox("The mining cart is overfilled. Reduce the encumberance before selecting OK.")
        return false
    end
    -- Insert code to update cart and player inventories
    for index, x in pairs(recipes) do
        local temp 
        temp = (slider[index]:getPropertyInt("PartScrollBar_current") - inCart[index])
        tes3.player.data.mcCart[x.var] = inCart[index] + temp
        if temp > 0 then
            tes3.removeItem({ reference = tes3.player, item = x.id, count = temp, playSound = true })
        elseif temp < 0 then
            temp = temp * (-1)
            tes3.addItem({ reference = tes3.player, item = x.id, count = temp, playSound = true })
        end
    end
    local menu = tes3ui.findMenu(id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function onLoadAll(e)
    -- load all ores from player's inventory
    local done = 0
    local full = false
    local obj
    for index, x in pairs(recipes) do done = done + tonumber(labelBlockInv[index].text) end
    tes3.messageBox("Loading all ores into mining cart.")
    while done > 0 do
        for index, x in pairs(recipes) do
            if (slider[index].widget.max - slider[index].widget.current) > 0 then
                obj = tes3.getObject(x.id)
                if calcVREnc() + obj.weight <= 24000 then
                    slider[index].widget.current = slider[index].widget.current + 1
                    labelBlockCart[index].text = string.format("%5.0f", slider[index].widget.current)
                    labelBlockInv[index].text = string.format("%5.0f", (slider[index].widget.max - slider[index].widget.current))
                    fb.widget.current = calcVREnc()
                    done = done - 1
                else
                    full = true
                    done = 0
                end
            end
        end
    end
end

local function onUnloadAll(e)
    -- Unload all ores to player's inventory ------------------------------------------------------------------------------------------------------------------------------------------
    tes3.messageBox("Unloading all ores from mining cart.")
    for index, x in pairs(recipes) do
		labelBlockCart[index].text = string.format("%5.0f", 0)
		labelBlockInv[index].text = string.format("%5.0f", (inInventory[index] + inCart[index]))
		slider[index].widget.current = 0
    end
	fb.widget.current = calcVREnc()
	fb.widget.fillColor = {0, 0, 1.0}
	-- menu:updateLayout()
	return false
end

local function useCart()
    local obj
    for idx, x in ipairs(recipes) do
        --obj = tes3.getObject(x.id) -- ore reference
        inInventory[idx] = tes3.getItemCount({ reference = tes3.player, item = x.id})
        inCart[idx] = tes3.player.data.mcCart[x.var]
    end
    createWindow()
end

local function fullName(x)
    local ref = tes3.getObject(x.id)
	if ref ~= nil then
		if string.lower(ref.name) == "<deprecated>" then
			mwse.log("[MC3 Init] <Deprecated> ID found: ("..x.id..")")
		end
    	return (x.alias or ref.name):lower()
	else
		if x.invalid ~= true then
			mwse.log("[MC3 Init] Invalid ID found: ("..x.id..")")
		end
		x.invalid = true
		return (x.alias or "<Invalid ID>"):lower()
	end
end

-- Create window and layout. Called by onCommand.
function createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(id_menu) ~= nil) then
        return
    end
	local menu = tes3ui.createMenu{ id = id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Mining Cart"
	menu.width = 400
	menu.height = 600
	menu.minWidth = 400
	menu.minHeight = 600
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
    menu.childAlignX = 0.5
    local titleBlock = menu:createBlock{}
    titleBlock.widthProportional = 1.0
	titleBlock.flowDirection = "left_to_right"
	titleBlock.autoHeight = true
	titleBlock.childAlignX = 0.5  -- center content alignment
    titleBlock.childAlignY = 0.5  -- center vertically in block
    local titleLabel = titleBlock:createLabel({ text = "Bound Mining Cart"})
    titleLabel.borderBottom = 6
    local topBlock = menu:createBlock{}
    topBlock.widthProportional = 1.0
	topBlock.flowDirection = "left_to_right"
	topBlock.autoHeight = true
	topBlock.childAlignX = 0.5  -- center content alignment
    topBlock.childAlignY = 0.5  -- center vertically in block
    
    fb = topBlock:createFillBar({ id = "MiningCartFB", current = calcEnc(), max = 24000 })
    fb.widget.fillColor = {0, 0, 1.0}
    fb.widthProportional = 1.0
    fb.borderBottom = 6

    -- Run through recipes, create textbox, slider & textbox for each ore-type
    local list=menu:createVerticalScrollPane({ id = UID_ListPane })
    for index, x in ipairs(recipes) do
        local nameBlock = list:createBlock{}
        nameBlock.flowDirection = "left_to_right"
        nameBlock.borderTop = 4
        nameBlock.autoHeight = true
        nameBlock.widthProportional = 1.0
        nameBlock.childAlignX = 0.5
        local labelOreName = nameBlock:createLabel({ text = x.alias })
        local oreBlock = list:createBlock{}
        oreBlock.widthProportional = 1.0
        oreBlock.flowDirection = "left_to_right"
        oreBlock.autoHeight = true
        oreBlock.childAlignX = 0.0
        local numberBorder = oreBlock:createThinBorder{}
        numberBorder.childAlignX = 1.0
        numberBorder.height = 20
        numberBorder.widthProportional = 0.5
        numberBorder.borderLeft = 6
        numberBorder.borderRight = 6
        labelBlockInv[index] = numberBorder:createLabel({ text = string.format("%5.0f", inInventory[index]) })
        labelBlockInv[index].borderRight = 6
        slider[index] = oreBlock:createSlider({ id = "sliderUID", current = inCart[index], max = (inInventory[index] + inCart[index]), step = 1, jump = 2 })
	    slider[index].widthProportional = 2.0
        oreBlock.childAlignY = 0.6
        local numberBorderC = oreBlock:createThinBorder{}
        numberBorderC.childAlignX = 1.0
        numberBorderC.height = 20
        numberBorderC.widthProportional = 0.5
        numberBorderC.borderLeft = 6
        numberBorderC.borderRight = 6
        labelBlockCart[index] = numberBorderC:createLabel({ text = string.format("%5.0f", inCart[index]) })
        labelBlockCart[index].borderRight = 6

        slider[index]:register("PartScrollBar_changed", function(e)
            labelBlockCart[index].text = string.format("%5.0f", slider[index]:getPropertyInt("PartScrollBar_current"))
            labelBlockInv[index].text = string.format("%5.0f", (inInventory[index] + inCart[index]) - slider[index]:getPropertyInt("PartScrollBar_current"))
            fb.widget.current = calcVREnc()
            if fb.widget.current > 24000 then fb.widget.fillColor = {1.0, 0, 0} else fb.widget.fillColor = {0, 0, 1.0} end
            menu:updateLayout()
            --passValue = slider:getPropertyInt("PartScrollBar_current")
            end)
    end

    local button_block = menu:createBlock{}
    button_block.borderTop = 6
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
	button_block.childAlignX = 1.0  -- left content alignment
	local button_LoadAll = button_block:createButton{ id = btn_LoadAll, text = "Load All" }
	local label = button_block:createLabel({ id = UID_spacerLabel, text = "" })
    local button_UnloadAll = button_block:createButton{ id = btn_LoadAll, text = "Unload All" }
    local label = button_block:createLabel({ id = UID_spacerLabel, text = "" })
    local button_OK = button_block:createButton{ id = btn_OK, text = tes3.findGMST("sOK").value }
	label.widthProportional = 1.0
    local button_cancel = button_block:createButton{ id = id_cancel, text = tes3.findGMST("sCancel").value }
    button_cancel:register("mouseClick", onCancel)
    button_LoadAll:register("mouseClick", onLoadAll)
    button_UnloadAll:register("mouseClick", onUnloadAll)
    button_OK:register("mouseClick", onOK)
    menu:updateLayout()
    tes3ui.enterMenuMode(id_menu)
end


event.register("initialized", init)

local function onEquip(e)
	--if (e.activator == tes3.player) then
		if e.item.id == "mc_cart" then
			magicCart = e.item
			contents = e.reference
			tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
            if tes3.player.data.mcCart == nil then
				tes3.player.data.mcCart = {}
				for index, x in pairs(recipes) do tes3.player.data.mcCart[x.var] = 0 end
            end
            if tes3.getJournalIndex{ id="mc_miningquest" } <= 100 then
			    useCart()
			    return false
            else
                tes3.removeItem({ reference = tes3.player, item = "mc_cart", count = 1, playSound = false })
                tes3.playSound({ sound = "mysticism cast" })
                tes3.messageBox({ message = "The mining cart fades away, with a whispered \"That is MINE, mortal!\""})
            end
		end
    --end
end
event.register("equip", onEquip)

-- Dropping the cart
local function dropCart(e)
    local permThing, thing
    if e.reference.object.id == "mc_cart" then
        thing = e.reference
        if tes3.player.cell.isInterior == true then
            permThing = tes3.createReference{ object = "mc_cart_blocking",
                    position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                    orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                    cell = tes3.player.cell,
                    scale = thing.scale
                    }
        else
            permThing = tes3.createReference{ object = "mc_cart_blocking",
                    position = tes3vector3.new(thing.position.x, thing.position.y, thing.position.z),
                    orientation = tes3vector3.new(thing.orientation.x, thing.orientation.y, thing.orientation.z),
                    scale = thing.scale
                    }
        end
        --thing:disable()
        tes3.setEnabled ({reference = thing, enabled = false})
        timer.delayOneFrame(function()
                mwscript.setDelete({reference = thing, delete = true })
            end)
    end
end
event.register("itemDropped", dropCart)

local function onActivate(e)
	if (e.activator == tes3.player) then
        local obj, thing
        thing = e.target
		if (e.target.object.id == "mc_cart_blocking") then
            tes3.addItem({ reference = tes3.player, item = "mc_cart", count = 1 }) -- Place one into player's inventory
            tes3ui.forcePlayerInventoryUpdate()
            tes3.setEnabled({ reference = thing, enabled = false })
	        timer.delayOneFrame(function()
                mwscript.setDelete({ reference = thing, delete = true })
            end)
		end
    end
end
event.register("activate", onActivate)