--[[ Crafting of items using Smelter.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for (creating items) per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.Smelter.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "mc_Smithing"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonClass, UID_buttonGroup
local sGroup, sClass = "All", "All"
local thing, ingred, menu, ttemp, ttl, tempCount, itemDesc
local dq = false
local onFilterClass, onFilterGroup
local textFilter = ""
local sortBy = "Normal"
local onClickSelectedItem_part_2
local tGroup = { "All", "Ores", "Scrap", "Special" }
local tGroupIdx = 1

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
UID_ListPane = tes3ui.registerID("SmeltingMenu::List")
UID_ListLabel = tes3ui.registerID("SmeltingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("SmeltingMenu::menuLabel")
UID_groupLabel = tes3ui.registerID("Smelting::menuLabel")
UID_filterText = tes3ui.registerID("SmithingMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("SmeltingMenu")
	this.id_menulist = tes3ui.registerID("Smeltinglist")
	this.id_cancel = tes3ui.registerID("Smelting_cancel")
	--this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")
	this.btn_sort = tes3ui.registerID("BtnSort")

	Recipes = mc.cleanDeprecated(Recipes)
	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)
	--
	Recipes = mc.getAddInFiles("Smelter", Recipes) -- Get add-in recipes
	Recipes = mc.cleanDeprecated(Recipes)
end

-- Buttons
-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
		menu = null
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

local function onSort()
	if sortBy == "Normal" then
		table.sort(Recipes, sortDifficulty )
		sortBy = "Difficulty"
	elseif sortBy == "Difficulty" then
		table.sort(Recipes, sortOriginal )
		sortBy = "Normal"
	end
	if (menu) then
		menu:destroy()
	end
	this.createWindow()
end

local function onClickSelectedItem_part_2(recipeNum, qty, menu)
	config = mwse.loadConfig(configPath)
	--local recipeNum = e.source:getPropertyInt("SmeltingMenu:Index")
	local SkillValue = mc.fetchSkill(skillID)
	local batchCap = 1
	local thing = tes3.getObject(Recipes[recipeNum].id)
	local batchCount = qty
	if config.tasktime == true then
		if Recipes[recipeNum].taskTime > 0 then
			batchCap = math.floor(24 / Recipes[recipeNum].taskTime)
		else
			batchCap = batchCount
		end
		if batchCount > batchCap then
			batchCount = batchCap
			tes3.messageBox({ message = "You cannot manage more than "..batchCount.." in a 24-hour period." })
		end
	end
	if config.tasktime == true then
		mc.timePass(Recipes[recipeNum].taskTime * batchCount)
	end
	-- Ensure that all necessary materials are available in inventory -------------------------------------------------------------------------------
	for i,xt in ipairs(Recipes[recipeNum].ingreds) do
		if xt.id == "AnyDremoraSoul" then
			 
		elseif xt.id == "Magicka" then
		
		elseif mwscript.getItemCount({ reference = "player", item = xt.id }) < math.max(xt.count, 1) then
			batchCount = 0
		end
	end
	if batchCount > 0 then
		if mc.skillCheck(skillID, Recipes[recipeNum].difficulty) == true then -- Succeeded
			tes3.messageBox({ message = "Created "..thing.name.." (x"..(Recipes[recipeNum].yieldCount * batchCount)..")" })
			tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
			--mwscript.addItem({ reference = "player", item = Recipes[recipeNum].id, count = (Recipes[recipeNum].yieldCount * batchCount) })
			tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].id, 
				count = (Recipes[recipeNum].yieldCount * batchCount), playSound = false })
			if Recipes[recipeNum].byproduct then
				tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].byproduct[1].id, 
					count = Recipes[recipeNum].byproduct[1].yield, playSound = false })
			end
			if Recipes[recipeNum].skillCap then
				if SkillValue < Recipes[recipeNum].skillCap then
					mc.skillReward(skillID, SkillValue, Recipes[recipeNum].difficulty)
				end
			end 
		else
			tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end
		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(Recipes[recipeNum].ingreds) do
			if xt.count > 0 then
				if xt.id == "AnyDremoraSoul" then
					mc.removeDremoraSoul(xt.count)
				elseif xt.id == "Magicka" then
					--tes3.modStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = -50 })	
					tes3.modStatistic({ reference = tes3.mobilePlayer, name = "magicka", current = (-1*xt.count) })
				else
					if (xt.consumed ~= false) then
						tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count * batchCount, playSound = false })
					end
				end
			end
		end
		tes3ui.forcePlayerInventoryUpdate()
		if (menu) then
			menu:destroy()
			menu = nil
		end
		this.createWindow()
	end
end

local function qtySlider(recipeNum, maxNumber, menu)
    this.id_SliderMenu = tes3ui.registerID("qtySlider")
    local testItem = "Slider" 
	local menuQS = tes3ui.createMenu{ id = this.id_SliderMenu, fixedFrame = true }
	passValue = maxNumber
    menuQS.alpha = 0.75
	menuQS.text = "Crafting"
	menuQS.width = 400
	menuQS.height = 50
	menuQS.minWidth = 400
    menuQS.minHeight = 50

    local pBlock = menuQS:createBlock()
    pBlock.widthProportional = 1.0
    pBlock.heightProportional = 1.0
    pBlock.childAlignX = 0.5
    pBlock.flowDirection = "left_to_right"

    local slider = pBlock:createSlider({ current = maxNumber, min = 0, max = maxNumber, step = 1, jump = 2 })
    slider.widthProportional = 1.5
    pBlock.childAlignY = 0.6
    local sNumber = pBlock:createLabel({ text = " ("..string.format("%5.0f", maxNumber)..")" })
    sNumber.widthProportional = 1.0
    sNumber.height = 24
    local sOK = pBlock:createButton({ text = " OK "})
    sOK.widthProportional = 0.5
    local sCancel = pBlock:createButton({ text = "Cancel" })
    sCancel.widthProportional = 1.0

    slider:register("PartScrollBar_changed", function(e)
        --testItem = slider:getPropertyInt("PartScrollBar_current") + 1 --params.min
        sNumber.text = string.format(" (%5.0f", slider:getPropertyInt("PartScrollBar_current"))..")"
        passValue = slider:getPropertyInt("PartScrollBar_current")
        end) 
    sCancel:register("mouseClick",
        function()
            tes3ui.leaveMenuMode()
			menuQS:destroy()
			menuQS = nil
			passValue = 0
            return false
        end
        )
    sOK: register("mouseClick", 
        function()
            tes3ui.leaveMenuMode()
			menuQS:destroy()
			menuQS = nil
			onClickSelectedItem_part_2(recipeNum, passValue, menu)
        end
        )
    -- Final setup
    menuQS:updateLayout()
    tes3ui.enterMenuMode(this.id_SliderMenu)
end

local function onClickSelectedItem(e)
	if mc3_timeOut then
		-- do nothing
	else
		config = mwse.loadConfig(configPath)
		local recipeNum = e.source:getPropertyInt("SmeltingMenu:Index")
		local SkillValue = mc.fetchSkill(skillID)
		local thing = tes3.getObject(Recipes[recipeNum].id)
		local batchCount = 1
		local tempCount

		-- First, determine if the player has reached or passed a skillcap. If so, check to see if the item is capable of mass production. If so, do it & skip skillcheck.
		if SkillValue >= Recipes[recipeNum].skillCap and Recipes[recipeNum].autocomplete == true then
			batchCount = math.floor(mwscript.getItemCount({ reference = "player", item = Recipes[recipeNum].ingreds[1].id }) / Recipes[recipeNum].ingreds[1].count )
		end
		if batchCount == 1 then
			onClickSelectedItem_part_2(recipeNum, batchCount, menu)
		elseif batchCount > 1 then
			if mc.getShift() == true then -- Shift held down; do task as much as possible
				--batchCount = 1000
				for idt, xt1 in pairs(Recipes[recipeNum].ingreds) do
					tempCount = math.floor(mwscript.getItemCount({ reference = "player", 
						item = Recipes[recipeNum].ingreds[1].id }) / Recipes[recipeNum].ingreds[1].count )
					if tempCount < batchCount then batchCount = tempCount end
				end
				onClickSelectedItem_part_2(recipeNum, batchCount, menu)
			else
				qtySlider(recipeNum, batchCount, menu)
			end
		else
			-- User selected 0, do nothing
		end
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
	menu = null
	this.createWindow()
end

local function showSmeltingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc
	local recipeNum = e.source:getPropertyInt("SmeltingMenu:Index")
	local skillValue = skillModule.getSkill(skillID).value
	local effDifficulty = Recipes[recipeNum].difficulty * mc.calcAttr().modInt * mc.calcAttr().modAgi
	local effSkill = skillValue * mc.calcAttr().modHealth * mc.calcAttr().modFatigue * mc.calcAttr().modLuck
	
	thing = tes3.getObject(Recipes[recipeNum].id)
	itemDesc = thing.name
	if Recipes[recipeNum].alias then
		itemDesc = Recipes[recipeNum].alias
	end
	local tipmenu = tes3ui.createTooltipMenu()
	local showtip = tipmenu:createLabel({ text = " "..itemDesc.." " })
	showtip.color = tes3ui.getPalette("header_color")
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	if Recipes[recipeNum].yieldCount > 1 then
		local showtip = tipmenu:createLabel({ text = "Yields " .. Recipes[recipeNum].yieldCount })
	end
	local showtip = tipmenu:createLabel({ text = string.format("Weight: %.2g", thing.weight) })
	local showtip = tipmenu:createLabel({ text = string.format("Value: %.0f", thing.value) })
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Requires:" })
	for itip, xt in ipairs(Recipes[recipeNum].ingreds) do
		ingred=tes3.getObject(xt.id)
		if xt.id == "AnyDremoraSoul" then
			local showtip = tipmenu:createLabel({ text = "Any Dremora Soul ("
			..mc.countDremoraSouls().." of "..xt.count..")  " })
		elseif xt.id == "Magicka" then
			local showtip = tipmenu:createLabel({ text = "Magicka ("
			..mc.fetchMagicka().." of "..xt.count..")  " })
		else
			local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
			..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count, 1)..")  " })
		end
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(Recipes[recipeNum].difficulty) })
	local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(skillID, Recipes[recipeNum].difficulty) })
end
	
-- Create window and layout. Called by onCommand.
function this.createWindow()
	local usesDaedric
	local SkillValue = mc.fetchSkill(skillID)
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Smelting"
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
			menu = null
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
	ttl = 0
	for index, x in ipairs(Recipes) do
		-- Set up 'original' sort order
		if x.place == nil then
			x.place = index
		end
		ttemp = tes3.getObject(x.id)
		thing = tes3.getObject(x.id)
		itemDesc = thing.name
		if textFilter == "Filter by name:" then
			textFilter = ""
		end
		if ttemp then
			ttemp=true
			--if sClass ~= "All" and sClass ~= x.class then 
			--	ttemp = false 
			--end
			if sGroup ~= "All" and sGroup ~= x.group then
				ttemp = false
			end
			if textFilter ~= nil and textFilter ~= "" and not string.find(string.upper(itemDesc),string.upper(textFilter), 1, true) then
				ttemp = false
			end
			if x.autocomplete == true then
				if x.skillCap > SkillValue then
					ttemp = false
				end
			end
			usesDaedric = false
			if ttemp == true then
				if x.alias then
					itemDesc = x.alias
				end
				-- Now check to see if player has the necessary materials
				haveMaterial = true
				for itip, xt in ipairs(Recipes[index].ingreds) do
					ingred = tes3.getObject(xt.id)
					if xt.id == "mc_daedric_ebony" or x.id == "mc_daedric_ebony" or x.id == "mc_dae_ebony_ingot" then
						usesDaedric = true
					end
					if xt.id == "AnyDremoraSoul" then
						if mc.countDremoraSouls() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "Magicka" then
						--if mc.fetchMagicka() < 50 then
						if mc.fetchMagicka() < xt.count then
							haveMaterial = false
						end
					else
						if mwscript.getItemCount({ reference = "player", item = xt.id }) < xt.count then
							haveMaterial = false
						end
					end
				end

				if (usesDaedric == true and dq == true) or usesDaedric == false then
					local itemBlock = list:createBlock({})
					itemBlock.flowDirection = "left_to_right"
					itemBlock.widthProportional = 1.0
					itemBlock.autoHeight = true
					itemBlock.borderAllSides = 3
					itemBlock:setPropertyInt("SmeltingMenu:Index", index)
					if haveMaterial == true then
						itemBlock:register("mouseClick", onClickSelectedItem)
					end
					itemBlock:register("help", showSmeltingTooltip)
					local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
					--image.consumeMouseEvents = false
					local label = itemBlock:createLabel({ id = UID_ListLabel, text = itemDesc })
					label.borderLeft = 10
					label.consumeMouseEvents = false
					ttl = ttl + 1
				end
			end
		end
	end
	if ttl == 0 then -- No entries showed up, do not show just a blank screen
		local itemBlock = list:createBlock({})
		itemBlock.flowDirection = "left_to_right"
		itemBlock.widthProportional = 1.0
		itemBlock.height = 400
		--itemBlock.autoHeight = true
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
	local button_sort = button_block:createButton{ id = this.btn_dort, text = "Sorted: "..sortBy }
	local label = button_block:createLabel{ id = "SpacerLabel", text = "" }
	label.widthProportional = 1.0
    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
	button_cancel:register("mouseClick", onCancel)
	button_sort: register("mouseClick", onSort)

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(filterTextInput)
end



UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("SmeltingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onActivate(e)
	if (e.activator == tes3.player) then
		if e.target.object.id == "mc_smelter_p" then
			if mc.uninstalling() == false then
				if not tes3.menuMode() then
				end
				dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
				this.createWindow()
				return false
			end
		elseif e.target.object.id == "mc_smelter_perm" then
			dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
			this.createWindow()
			return false
		end
    end
end
event.register("activate", onActivate)
