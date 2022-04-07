--[[ Crafting of items using campfire/cookfire.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for (creating items) per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.Cooking.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "mc_Cooking"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonClass, UID_buttonGroup
local sGroup, sClass = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc, eObjectRef, itemObject, ingredSwap
local dq = false
local onFilterClass, onFilterGroup
local textFilter = ""
local sortBy = "Normal"
local tGroupIdx = 1
local tGroup = { "All", "Hot Dishes", "Grilled Meats", "Soups and Stews", "Baked Goods", "Miscellaneous" }

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
UID_ListPane = tes3ui.registerID("CookingMenu::List")
UID_ListLabel = tes3ui.registerID("CookingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("CookingClass::menuLabel")
UID_groupLabel = tes3ui.registerID("CookingGroup::menuLabel")
UID_filterText = tes3ui.registerID("CookingFilterMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("CookingMenu")
	this.id_menulist = tes3ui.registerID("Cookinglist")
	this.id_cancel = tes3ui.registerID("Cooking_cancel")
	this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")
	this.btn_sort = tes3ui.registerID("BtnSort")

	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)

	-- Load AddIns
	Recipes = mc.getAddInFiles("Cooking", Recipes) -- Get  add-in recipes
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

local function onPickup() -- When called, salvage the cookfire/campfire, put out
	local scrapBack = math.random(2,3)
	tes3.setEnabled({ reference = itemObject, enabled = false })
	objX = itemObject.position.x
	objY = itemObject.position.y
	objZ = itemObject.position.z
	tes3.setGlobal("mc_move_x", objX)
	tes3.setGlobal("mc_move_y", objY)
	tes3.setGlobal("mc_move_z", objZ)
	tes3.setGlobal("mc_move_complete", 1)
	--[[ Trigger a crime if applicable.
	if (not tes3.hasOwnershipAccess({ target = itemObject })) then
		tes3.setItemIsStolen({ item = itemObject.baseObject.id, from = tes3.getOwner(itemObject), stolen = true })
		tes3.triggerCrime({ type = 5, victim = tes3.getOwner(itemObject), value = itemObject.baseObject.value })
	end
	]]--
	timer.delayOneFrame(function()
		mwscript.setDelete({ reference = itemObject, delete = true })
	end)
	tes3.addItem({ reference = tes3.player, item = "mc_log_scrap", count = scrapBack }) -- Place 2-3 scrap into player's inventory
	tes3.messageBox("You were able to recover "..scrapBack.." scrapwood logs.")
	--Need to disable and 'setdelete 1' the mc_logfire_act activator *********
	tes3ui.forcePlayerInventoryUpdate()
	menu:destroy()
end

local function onClickSelectedItem(e)
	config = mwse.loadConfig(configPath)
	if mc3_timeOut then
		-- do nothing
	else
		local recipeNum = e.source:getPropertyInt("CookingMenu:Index")
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
				tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].byproduct[1].id, count = Recipes[recipeNum].byproduct[1].yield, playSound = false })
			end
		else
			if math.random() < 0.01 then
				tes3.messageBox({ message = "Failed: A rat snuck in and stole your ingredients when you weren't looking." })
			else
				tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
			end
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end

		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(Recipes[recipeNum].ingreds) do
			if xt.count > 0 then
				if xt.id == "AnyMushroom" then
					mc.removeMushroom(xt.count)
				elseif xt.id == "KwamaEgg" then
					mc.removeKwamaEgg(xt.count)
				elseif xt.id == "SmallBowl" then
					mc.removeSmallBowl(xt.count)
				elseif xt.id == "Thread" then
					-- do nothing
				elseif xt.id == "AnyRedMeat" then
					mc.removeRedMeat(xt.count)
				elseif xt.id == "Onion" then
					mc.removeOnion(xt.count)
				elseif xt.id == "Garlic" then
					mc.removeGarlic(xt.count)
				elseif xt.id == "Potato" then
					mc.removePotato(xt.count)
				else
					if (xt.consumed ~= false) then
						tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
					end
				end
			end
		end
		mc.timePass(Recipes[recipeNum].taskTime)
	end
	tes3ui.forcePlayerInventoryUpdate()
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

	--menu:destroy()
	--this.createWindow()
end

local function showCookingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc
	local recipeNum = e.source:getPropertyInt("CookingMenu:Index")
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
		elseif xt.id == "Onion" then
			local showtip = tipmenu:createLabel({ text = "Onion ("
			..mc.countOnion().." of "..xt.count..")  " })
		elseif xt.id == "Potato" then
			local showtip = tipmenu:createLabel({ text = "Potato ("
			..mc.countPotato().." of "..xt.count..")  " })
		elseif xt.id == "Garlic" then
			local showtip = tipmenu:createLabel({ text = "Garlic ("
			..mc.countGarlic().." of "..xt.count..")  " })
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
	local showPickup = 1
	local button_pickup
	if (not tes3.hasOwnershipAccess({ target = itemObject })) then
		showPickup = 0
	end
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
	end
	
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Cooking"
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
					elseif xt.id == "Garlic" then
						if mc.countGarlic() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "Onion" then
						if mc.countOnion() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "Potato" then
						if mc.countPotato() < xt.count then
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
				itemBlock:setPropertyInt("CookingMenu:Index", index)
				if haveMaterial == true then
					itemBlock:register("mouseClick", onClickSelectedItem)
				end
				itemBlock:register("help", showCookingTooltip)
				if thing.id == "AnyMushroom" then
					itemDesc = "Any Mushroom" -- No icon
				elseif thing.id == "KwamaEgg" then
					itemDesc = "Kwama Egg (large or small)" -- No icon
				elseif thing.id == "SmallBowl" then
					itemDesc = "Small Wooden Bowl"
				elseif thing.id == "AnyRedMeat" then
					itemDesc = "Any Red Meat"
				elseif thing.id == "Garlic" then
					itemDesc = "Garlic"
				elseif thing.id == "Onion" then
					itemDesc = "Onion"
				elseif thing.id == "Potato" then
					itemDesc = "Potato"
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
	if showPickup == 1 then
		button_pickup = button_block:createButton{ id = "FirePickupButton", text = "Pick Up"}
	end
	local button_sort = button_block:createButton{ id = this.btn_dort, text = "Sorted: "..sortBy }
	local label = button_block:createLabel{ id = "SpacerLabel", text = "" }
	label.widthProportional = 1.0
    local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
	button_cancel:register("mouseClick", onCancel)
	if (showPickup == 1) then
		button_pickup:register("mouseClick", onPickup)
	end

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(filterTextInput)
	button_sort: register("mouseClick", onSort)
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("CookingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function mc_tool_activate(e)
	if (e.activator == tes3.player) then
		if ( e.target.object.id == "mc_logfire" ) or ( e.target.object.id == "mc_campfire" ) or ( e.target.object.id == "mc_campfire_perm" ) or ( e.target.object.id == "lm_cookstove" ) then
			eObjectRef = e.target.object
			itemObject = e.target
			ingredSwap = mwscript.getItemCount({ reference = "player", item = "mc_racer_raw" })
			if ingredSwap > 0 then
				tes3.removeItem({ reference = tes3.player, item = "mc_racer_raw", count = ingredSwap, playSound = false })
				tes3.addItem({ reference = tes3.player, item = "T_IngFood_MeatCliffracer_01", count = ingredSwap, playSound = false })
			end
			ingredSwap = mwscript.getItemCount({ reference = "player", item = "mc_guar_raw" })
			if ingredSwap > 0 then
				tes3.removeItem({ reference = tes3.player, item = "mc_guar_raw", count = ingredSwap, playSound = false })
				tes3.addItem({ reference = tes3.player, item = "T_IngFood_MeatGuar_01", count = ingredSwap, playSound = false })
			end
			ingredSwap = mwscript.getItemCount({ reference = "player", item = "mc_kagouti_raw" })
			if ingredSwap > 0 then
				tes3.removeItem({ reference = tes3.player, item = "mc_kagouti_raw", count = ingredSwap, playSound = false })
				tes3.addItem({ reference = tes3.player, item = "T_IngFood_MeatKagouti_01", count = ingredSwap, playSound = false })
			end
			this.createWindow()
			return false
		end
   end
end
event.register("activate", mc_tool_activate)