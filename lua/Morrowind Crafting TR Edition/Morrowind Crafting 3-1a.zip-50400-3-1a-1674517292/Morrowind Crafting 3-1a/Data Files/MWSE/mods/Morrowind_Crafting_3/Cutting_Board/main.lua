--[[ Crafting of items using cutting board.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for (creating items) per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.Cutting_Board.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "mc_Cooking"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel, UID_spacerLabel
local UID_buttonClass, UID_buttonGroup
local sGroup, sClass = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc, currentKit
local dq = false
local onFilterClass, onFilterGroup
local textFilter = ""
local eObjectRef
local sortBy = "Normal"
local tGroupIdx = 1
local tGroup = { "All", "Cold Dishes", "Sandwiches", "Miscellaneous" }

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
UID_ListPane = tes3ui.registerID("CuttingMenu::List")
UID_ListLabel = tes3ui.registerID("CuttingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("CuttingClass::menuLabel")
UID_groupLabel = tes3ui.registerID("CuttingGroup::menuLabel")
UID_filterText = tes3ui.registerID("CuttingFilterMenu::Input")
UID_spacerLabel = tes3ui.registerID("SpacerLabel")

function this.init()
	this.id_menu = tes3ui.registerID("CuttingMenu")
	this.id_menulist = tes3ui.registerID("Cuttinglist")
	this.id_cancel = tes3ui.registerID("Cutting_cancel")
	this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")
	this.btn_pickup = tes3ui.registerID("btnPickUp")
	this.btn_sort = tes3ui.registerID("BtnSort")

	Recipes = mc.cleanDeprecated(Recipes)
	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)
	--
	Recipes = mc.getAddInFiles("CuttingBoard", Recipes) -- Get add-in recipes
	Recipes = mc.cleanDeprecated(Recipes)
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

local function onClickSelectedItem(e)
	if mc3_timeOut then
		--do nothing
	else
		local recipeNum = e.source:getPropertyInt("CuttingMenu:Index")
		local SkillValue = mc.fetchSkill(skillID)
		local thing = tes3.getObject(Recipes[recipeNum].id)
		local modDifficulty = 1.0

		if Recipes[recipeNum].modifier and mwscript.getItemCount({ reference = "player", item = Recipes[recipeNum].modifier }) > 0 then
			modDifficulty = 0.8
		end
		if mc.skillCheck(skillID, (Recipes[recipeNum].difficulty * modDifficulty)) == true then -- Succeeded
			tes3.messageBox({ message = "Created "..thing.name })
			tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
			tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].id, count = Recipes[recipeNum].yieldCount, playSound = false })
			mc.skillReward(skillID, SkillValue, (Recipes[recipeNum].difficulty * modDifficulty))
			if Recipes[recipeNum].byproduct then -- making this item gives something else as a by-product
				tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].byproduct.id, count = Recipes[recipeNum].byproduct.yield, playSound = false })
			end
		else
			tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end
		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(Recipes[recipeNum].ingreds) do
			if xt.count > 0 then
				if xt.id == "AnyMushroom" then
					mc.removeAnyMushroom(xt.count)
				elseif xt.id == "KwamaEgg" then
					mc.removeKwamaEgg(xt.count)
				elseif xt.id == "SmallBowl" then
					mc.removeSmallBowl(xt.count)
				elseif xt.id == "Thread" then
					-- do nothing
				elseif xt.id == "AnyRedMeat" then
					mc.removeRedMeat(xt.count)
				else
					if (xt.consumed ~= false) then
						tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
					end
				end
			end
		end
		mc.timePass(Recipes[recipeNum].taskTime)
		tes3ui.forcePlayerInventoryUpdate()
		menu:destroy()
		this.createWindow()
	end
end

local function onPickup() -- When called, pick up the cutting board & place in player's inventory
	--local objectRef = tes3.getPlayerTarget()
	tes3.setEnabled({ reference = eObjectRef, enabled = false }) -- Should set current cutting board to disabled
	-- Trigger a crime if applicable.
	if (not tes3.hasOwnershipAccess({ target = eObjectRef })) then
		tes3.setItemIsStolen({ item = eObjectRef.baseObject.id, from = tes3.getOwner(eObjectRef), stolen = true })
		tes3.triggerCrime({ type = 5, victim = tes3.getOwner(eObjectRef), value = eObjectRef.baseObject.value })
	end
	timer.delayOneFrame(function()
		mwscript.setDelete({ reference = eObjectRef, delete = true })
	end)
	tes3.addItem({ reference = tes3.player, item = "mc_cutting_board", count = 1 }) -- Place one into player's inventory
	tes3ui.forcePlayerInventoryUpdate()
	menu:destroy()
end

local function sortDifficulty(a, b)
	if a.difficulty < b.difficulty then
		return true
	elseif a.difficulty > b.difficulty then
		return false
	else
		return a.difficulty < b.difficulty
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
	menu:destroy()
	this.createWindow()
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

local function showCuttingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc
	local recipeNum = e.source:getPropertyInt("CuttingMenu:Index")
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
		if xt.id == "AnyMushroom" then
			local showtip = tipmenu:createLabel({ text = " Any Mushroom ("
			..mc.countMushroom().." of "..xt.count..")  " })
		elseif xt.id == "AnyRedMeat" then
			local showtip = tipmenu:createLabel({ text = "Any Red Meat ("
			..mc.countRedMeat().." of "..xt.count..")  " })
		elseif xt.id == "Thread" then
			local showtip = tipmenu:createLabel({ text = "Thread ("
			..mwscript.getItemCount({ reference = "player", item = "misc_spool_01" }).." of "..xt.count..")  " })
		elseif xt.id == "KwamaEgg" then
			local showtip = tipmenu:createLabel({ text = "Kwama Egg ("
			..mc.countKwamaEgg().." of "..xt.count..")  " })
		elseif xt.id == "SmallBowl" then
			local showtip = tipmenu:createLabel({ text = "Small Bowl ("
			..mc.countSmallBowl().." of "..xt.count..")  " })
		else
			local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
			..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count, 1)..")  " })
		end

	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(Recipes[recipeNum].difficulty) })
	-- check to see if this dish has a modifying tool, and if the player currently has one
	if Recipes[recipeNum].modifier and (mwscript.getItemCount({ reference = "player", item = Recipes[recipeNum].modifier }) > 0 ) then
		local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(skillID, Recipes[recipeNum].difficulty * 0.8) })
		local showtip = tipmenu:createLabel({ text = "(Modified by: "..tes3.getObject(Recipes[recipeNum].modifier).name..")" })
	else
		local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(skillID, Recipes[recipeNum].difficulty) })
	end
end
	
-- Create window and layout. Called by onCommand.
function this.createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Cutting"
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
		
		local filterLabel = filterBlock:createLabel({ text = ""})
		filterLabel.borderRight = 2
		local filterInputBorder = filterBlock:createThinBorder{}
		filterInputBorder.widthProportional = 0.4
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
		
		filterTextInput.widthProportional = 0.4
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
		--buttonClass:register("mouseClick", onFilterClass)
		--buttonClass.widthProportional = 0.75
		local buttonGroup = filterBlock:createButton{ id = this.btn_sGroup, text = "Group: " .. sGroup }
		buttonGroup:register("mouseClick", onFilterGroup)
		buttonGroup.widthProportional = 0.6
	
	-- Run through recipes, create button for each weapon or armor piece
	local list=menu:createVerticalScrollPane({ id = UID_ListPane })
	ttl = 0
	for index, x in ipairs(Recipes) do
		-- Set up 'original' sort order
		if x.place == nil then
			x.place = index
		end
		thing = tes3.getObject(x.id)
		if thing then
			itemDesc = thing.name
		end
		if x.alias then
			itemDesc = x.alias
		end
		if textFilter == "Filter by name:" then
			textFilter = ""
		end
		ttemp = tes3.getObject(x.id)
		if ttemp then
			ttemp=true
			if sClass ~= "All" and sClass ~= x.class then 
				ttemp = false 
			end
			if sGroup ~= "All" and sGroup ~= x.group then
				ttemp = false
			end
			if textFilter ~= nil and textFilter ~= "" and not string.find(string.upper(itemDesc),string.upper(textFilter), 1, true) then
				ttemp = false
			end
			if dq ~= true and x.ingreds[1].id == "mc_daedric_ebony" then
				ttemp = false
			end
			if x.unlock ~= nil then
				if (tes3.getJournalIndex{id=x.unlock.id}) < x.unlock.index then
					ttemp = false
				end
			end
--[[
			if x.id == "AnyMushroom" and mc.countMushroom() < x.count then
					ttemp = false
			end
			if x.id == "KwamaEgg" and mc.countKwamaEgg() < x.count then
				ttemp = false
			end
			if x.id == "SmallBowl" and mc.countSmallBowl() < x.count then
				ttemp = false
			end
]]--
			if ttemp == true then
				-- Now check to see if player has the necessary materials
				haveMaterial = true
				for itip, xt in ipairs(Recipes[index].ingreds) do
					--ingred = tes3.getObject(xt.id)
					if xt.id == "KwamaEgg" then
						if mc.countKwamaEgg() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "AnyMushroom" then
						if mc.countMushroom() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "SmallBowl" then
						if mc.countSmallBowl() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "AnyRedMeat" then
						if mc.countRedMeat() < xt.count then
							haveMaterial = false
						end
					else
						if mwscript.getItemCount({ reference = "player", item = xt.id }) < xt.count then
							haveMaterial = false
						end
					end
				end
				local itemBlock = list:createBlock({})
				itemBlock.flowDirection = "left_to_right"
				itemBlock.widthProportional = 1.0
				itemBlock.autoHeight = true
				itemBlock.borderAllSides = 3
				itemBlock:setPropertyInt("CuttingMenu:Index", index)
				if haveMaterial == true then
					itemBlock:register("mouseClick", onClickSelectedItem)
				end
				itemBlock:register("help", showCuttingTooltip)
				if thing.id == "AnyMushroom" then
					itemDesc = "Any Mushroom" -- No icon
				elseif thing.id == "KwamaEgg" then
					itemDesc = "Kwama Egg (large or small)" -- No icon
				elseif thing.id == "SmallBowl" then
					itemDesc = "Small Wooden Bowl"
				elseif thing.id == "AnyRedMeat" then
					itemDesc = "Any Red Meat"
				else
					local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
				end
				local label = itemBlock:createLabel({ id = UID_ListLabel, text = itemDesc })
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
		itemBlock.childAlignX = 0.5 -- Center
		itemBlock.childAlignY = 0.5
	end
	
	local button_block = menu:createBlock{}
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
	button_block.childAlignX = 1.0  -- left content alignment
	local button_pickup = button_block:createButton{ id = this.btn_pickup, text = "Pick Up" }
	local button_sort = button_block:createButton{ id = this.btn_sort, text = "Sorted: "..sortBy }
	local label = button_block:createLabel({ id = UID_spacerLabel, text = "" })
	label.widthProportional = 1.0
    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
	button_cancel:register("mouseClick", onCancel)
	button_pickup:register("mouseClick", onPickup)
	button_sort: register("mouseClick", onSort)	

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(filterTextInput)
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("CuttingMenu:ListBlockLabel")
event.register("initialized", this.init)
--[[
local function onEquip(e)
	--if (e.activator == tes3.player) then
		if (e.item.id == "<Activator>") then

			tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
            currentKit = e.item.reference
			dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
			this.createWindow()
			return false
		end
    --end
end
event.register("equip", onEquip)
]]--

local function mc_tool_activate(e)
	if (e.activator == tes3.player) then
		if ( e.target.object.id == "mc_cutting_board" ) then
			eObjectRef = e.target
			this.createWindow()
			return false
		end
   end
end
event.register("activate", mc_tool_activate)