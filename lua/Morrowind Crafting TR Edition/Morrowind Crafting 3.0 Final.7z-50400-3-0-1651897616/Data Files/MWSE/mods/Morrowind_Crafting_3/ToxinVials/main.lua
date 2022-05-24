--[[ Poisoning of marksman weapons using vials.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for (creating items) per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.ToxinVials.recipes")
local skillModule = require("OtherSkills.skillModule") -- Note: envenoming weapons takes no actual skill; included for future
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "Toxin Application"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonGroup
local sGroup = "All"
local thing, ingred, menu, ttemp, ttl, itemDesc
local dq = false
local onFilterClass, onFilterGroup
local textFilter = ""
local sortBy = "Normal"
local toxinVial, toxinName, e, selectedBottle, eObjectRef
local mc_item_pickup, stuff
local tGroupIdx = 1
local tGroup = { "All", "Arrows", "Bolts", "Darts", "Throwing Knives", "Throwing Stars" }

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

local function sortDifficulty(a, b)
	if string.format("%03d %s",a.difficulty, fullName(a)) < string.format("%03d %s",b.difficulty, fullName(b)) then
		return true
	elseif string.format("%03d %s",a.difficulty, fullName(a)) > string.format("%03d %s",b.difficulty, fullName(b)) then
		return false
	else
		return string.format("%03d %s",a.difficulty, fullName(a)) < string.format("%03d %s",b.difficulty, fullName(b))
	end
end

local function sortInitial(a,b)
	if fullName(a) < fullName(b) then
		return true
	elseif fullName(a) > fullName(b) then
		return false
	else
		return fullName(a) < fullName(b)
	end
end

local function sortOriginal(a, b)
	if a.place < b.place then
		return true
	elseif a.place > b.place then
		return false
	else
		return a.place < b.place
	end
end

-- Register IDs
UID_ListPane = tes3ui.registerID("PoisoningMenu::List")
UID_ListLabel = tes3ui.registerID("PoisoningMenu::ListBlockLabel")
UID_groupLabel = tes3ui.registerID("Poisoning::menuLabel")
UID_filterText = tes3ui.registerID("PoisoningMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("PoisoningMenu")
	this.id_menulist = tes3ui.registerID("Poisoninglist")
	this.id_cancel = tes3ui.registerID("Poisoning_cancel")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")

	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)
	--
	Recipes = mc.getAddInFiles("Toxin", Recipes) -- Get add-in recipes
end

-- Buttons
-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function onClickSelectedItem_part_2(recipeNum, batchCount)
	if batchCount > 0 then
		local endProduct
		endProduct = Recipes[recipeNum].poisonedID.."_"..toxinType
		tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
		if Recipes[recipeNum].id == "mc_grenade_case" then
			toxinVial.data.mcDoses = toxinVial.data.mcDoses - (batchCount * 10)
		else
			toxinVial.data.mcDoses = toxinVial.data.mcDoses - batchCount
		end
		tes3.addItem({ reference = tes3.player, item = endProduct, count = batchCount, playSound = false })
		tes3.removeItem({ reference = tes3.player, item = Recipes[recipeNum].id, count = batchCount, playSound = false })
		if batchCount > 1 then
			tes3.messageBox(batchCount.." items poisoned.")
		else
			tes3.messageBox("Item poisoned.")
		end
	end
	tes3ui.leaveMenuMode()
	menu:destroy()
	if toxinVial.data.mcDoses > 0 then
		this.createWindow()
	else -- Nothing left? Remove the toxin vial using itemData, then replace with an empty vial. Do not reopen the menu.
		tes3.addItem({ reference = tes3.player, item = "misc_skooma_vial", count = 1, playSound = false })
		tes3.removeItem({ reference = tes3.player, item = selectedBottle, count = 1, itemData = toxinVial, playSound = false })
	end
end

local function qtySlider(recipeNum, maxNumber)
    this.id_SliderMenu = tes3ui.registerID("qtySlider")
    local testItem = "Slider" 
	local sliderMenu = tes3ui.createMenu{ id = this.id_SliderMenu, fixedFrame = true }
	passValue = -1
    sliderMenu.alpha = 0.75
	sliderMenu.text = "Toxins"
	sliderMenu.width = 400
	sliderMenu.height = 50
	sliderMenu.minWidth = 400
    sliderMenu.minHeight = 50

    local pBlock = sliderMenu:createBlock()
    pBlock.widthProportional = 1.0
    pBlock.heightProportional = 1.0
    pBlock.childAlignX = 0.5
    pBlock.flowDirection = "left_to_right"

	local slider = pBlock:createSlider({ id = "sliderUID", current = 1, max = maxNumber, step = 1, jump = 5 })
	slider.widthProportional = 1.5
    pBlock.childAlignY = 0.6
    local sNumber = pBlock:createLabel({ text = "  ( "..string.format("%5.0f", 0).." )" })
    sNumber.widthProportional = 1.0
    sNumber.height = 24
    local sOK = pBlock:createButton({ text = " OK "})
    sOK.widthProportional = .5
    local sCancel = pBlock:createButton({ text = "Cancel" })
	sCancel.widthProportional = 1.0

    slider:register("PartScrollBar_changed", function(e)
        --testItem = slider:getPropertyInt("PartScrollBar_current") + 1 --params.min
        sNumber.text = string.format("  ( %5.0f", slider:getPropertyInt("PartScrollBar_current")).." )"
        passValue = slider:getPropertyInt("PartScrollBar_current")
        end) 
    sCancel:register("mouseClick",
        function()
            tes3ui.leaveMenuMode()
            sliderMenu:destroy()
			passValue = 0
            return false
        end
        )
    sOK: register("mouseClick", 
        function()
            tes3ui.leaveMenuMode()
            sliderMenu:destroy()
			onClickSelectedItem_part_2(recipeNum, passValue)
        end
        )
    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_SliderMenu)
end

local function onClickSelectedItem(e)
	local recipeNum = e.source:getPropertyInt("PoisoningMenu:Index")
	-- local SkillValue = mc.fetchSkill(skillID) -- no skill involved
	local thing = tes3.getObject(Recipes[recipeNum].id)
	local batchCount = mwscript.getItemCount({ reference = "player", item = Recipes[recipeNum].id })
	if Recipes[recipeNum].id == "mc_grenade_case" then
		if (batchCount * 10) > toxinVial.data.mcDoses then
			batchCount = math.floor(toxinVial.data.mcDoses / 10)
		end
	else
		if batchCount > toxinVial.data.mcDoses then
			batchCount = toxinVial.data.mcDoses
		end
	end
	if batchCount > 1 then 
		qtySlider(recipeNum, batchCount)
	else
		onClickSelectedItem_part_2(recipeNum, batchCount)
	end
end

local function onFilterGroup()
	if mc.getShift() == true then
		tGroupIdx = tGroupIdx - 1
		if tGroupIdx < 1 then tGroupIdx = #tGroup end
	else
		tGroupIdx = tGroupIdx + 1
		if tGroupIdx > #tGroup then tGroupIdx = 1 end
	end
	sGroup = tGroup[tGroupIdx]
	menu:destroy()
	this.createWindow()
end

local function showPoisonTooltip(e)
	local recipeNum = e.source:getPropertyInt("PoisoningMenu:Index")
	local itemDesc, batchCount

	thing = tes3.getObject(Recipes[recipeNum].id)
	itemDesc = thing.name
	if Recipes[recipeNum].alias then
		itemDesc = Recipes[recipeNum].alias
	end
	local tipmenu = tes3ui.createTooltipMenu()
	local showtip = tipmenu:createLabel({ text = " "..itemDesc.." " })
	showtip.color = tes3ui.getPalette("header_color")
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = string.format("Weight: %.2g", thing.weight) })
	local showtip = tipmenu:createLabel({ text = string.format("Value: %.0f", thing.value) })
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	if thing.id == "mc_grenade_case" then
		local showtip = tipmenu:createLabel({ text = "Requires 10 doses from the toxin vial." })
	else
		local showtip = tipmenu:createLabel({ text = "Requires 1 dose from the toxin vial." })
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	batchCount = mwscript.getItemCount({ reference = "player", item = Recipes[recipeNum].id })
	if Recipes[recipeNum].id == "mc_grenade_case" then
		if (batchCount * 10) > toxinVial.data.mcDoses then
			batchCount = math.floor(toxinVial.data.mcDoses / 10)
		end
	else
		if batchCount > toxinVial.data.mcDoses then
			batchCount = toxinVial.data.mcDoses
		end
	end
	local showtip = tipmenu:createLabel({ text = "Available to poison: "..batchCount })
end

-- Create window and layout. Called by onCommand.
function this.createWindow()
	local usesDaedric, ttemp, hasQty, doses
	local SkillValue = mc.fetchSkill(skillID)
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Poisoning"
	menu.width = 500
	menu.height = 600
	menu.minWidth = 500
	menu.minHeight = 600
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2

	-- Show buttons for filters
	local haveMaterial, ingred
	local filterBlock = menu:createBlock({})
		filterBlock.widthProportional = 1.0
		filterBlock.flowDirection = "left_to_right"
		filterBlock.autoHeight = true
		filterBlock.childAlignX = 1.0  -- left content alignment
		filterBlock.childAlignY = 0.5
		
		local filterLabel = filterBlock:createLabel({ text = ""})
		filterLabel.borderRight = 2
		local filterInputBorder = filterBlock:createThinBorder{}
		filterInputBorder.widthProportional = 0.33
		filterInputBorder.height = 24
		filterInputBorder.childAlignX = 0.5
		filterInputBorder.childAlignY = 0.5
		filterInputBorder.absolutePosAlignY = 0.5
		
		local filterTextInput = filterInputBorder:createTextInput({ id = UID_filterText })
		filterTextInput.borderLeft = 5
		filterTextInput.borderRight = 5
		filterTextInput.widget.lengthLimit = 20
		filterTextInput.widget.eraseOnFirstKey = true
		if textFilter == "" then
			textFilter = "Filter by name:"
		end
		filterTextInput.text = textFilter
		
		filterTextInput.widthProportional = 0.33
		filterTextInput:register("keyEnter", 
			function()
			local text = filterTextInput.text
			if text == "Filter by name:" then
				text = ""
			end
			if (text == "") then
				textFilter = ""
			else
				textFilter = text
			end
			menu:destroy()
			this.createWindow()
			end )
		
		--local buttonClass = filterBlock:createButton{ id = this.btn_sClass, text = "Class: " .. sClass }
		local buttonGroup = filterBlock:createButton{ id = this.btn_sGroup, text = "Group: " .. sGroup }
		--buttonClass:register("mouseClick", onFilterClass)
		--buttonClass.widthProportional = 1.0
		buttonGroup:register("mouseClick", onFilterGroup)
		buttonGroup.widthProportional = 0.67

	-- Run through recipes, create button for each weapon or armor piece
	local list=menu:createVerticalScrollPane({ id = UID_ListPane })
	local doses
	ttl = 0
	for index, x in ipairs(Recipes) do
		ttemp = true
		thing = tes3.getObject(x.id)
		if thing then
			itemDesc = thing.name
		else
			itemDesc = "[[ Bad item ID!  "..x.id.." ]]" 
		end
		if textFilter == "Filter by name:" then
			textFilter = ""
		end
		if ttemp == true then
			if sGroup ~= "All" and sGroup ~= x.group then
				ttemp = false
			end
			if textFilter ~= nil and textFilter ~= "" and not string.find(string.upper(itemDesc),string.upper(textFilter), 1, true) then
				ttemp = false
			end
			hasQty = mwscript.getItemCount({ reference = "player", item = x.id })
			if hasQty < 1 then
				ttemp = false
			end
			usesDaedric = false
			if ttemp == true then
				if x.alias then
					itemDesc = x.alias
				end
				-- Now check to see if player has the necessary materials
				local itemBlock = list:createBlock({})
				itemBlock.flowDirection = "left_to_right"
				itemBlock.widthProportional = 1.0
				itemBlock.autoHeight = true
				itemBlock.borderAllSides = 3
				itemBlock:setPropertyInt("PoisoningMenu:Index", index)
				itemBlock:register("mouseClick", onClickSelectedItem)
				itemBlock:register("help", showPoisonTooltip)
				if thing.id == "Any<XXX>" then
					local image = itemBlock:createImage({ path = "icons/m/misc_cloth00.tga" }) -- substitute icon-ID
				else
					local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
				end
				--image.consumeMouseEvents = false
				local label = itemBlock:createLabel({ id = UID_ListLabel, text = string.format("%5.0d ", hasQty)..itemDesc })
				label.borderLeft = 10
				label.consumeMouseEvents = false
				ttl = ttl + 1
			end
		end
	end
	if ttl == 0 then -- No entries showed up, do not show just a blank screen
		local itemBlock = list:createBlock({})
		itemBlock.flowDirection = "left_to_right"
		itemBlock.widthProportional = 1.0
		itemBlock.height = 400
		itemBlock.borderAllSides = 3
		local label = itemBlock:createLabel({ id = UID_ListLabel, text = "No items fit the selected filters." })
		--label.widthProportional = 1.0
		itemBlock.childAlignX = 0.5 -- Center
		itemBlock.childAlignY = 0.5
	end
	
	local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
	button_block.childAlignX = 1.0  -- left content alignment
	doses = toxinVial.data.mcDoses
	local label = button_block:createLabel{ id = "toxinDoses", text = toxinName.." applications remaining: "..doses }
	--local button_sort = button_block:createButton{ id = this.btn_dort, text = "Sorted: "..sortBy }
	local label = button_block:createLabel{ id = "SpacerLabel", text = "" }
	label.widthProportional = 1.0
    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
	button_cancel:register("mouseClick", onCancel)

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(filterTextInput)
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("PoisonMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onEquip(e)
	if string.startswith(string.gsub(e.item.id, "_", "-"),"mc-poison0") then
		toxinType = string.gsub(string.lower(e.item.name), " ", "_")
		selectedBottle = e.item
		toxinVial = e.itemData
		if not toxinVial.data.mcDoses then toxinVial.data.mcDoses = 50 end
		toxinName = selectedBottle.name
		this.createWindow()
		return false
	end
end
event.register("equip", onEquip)
