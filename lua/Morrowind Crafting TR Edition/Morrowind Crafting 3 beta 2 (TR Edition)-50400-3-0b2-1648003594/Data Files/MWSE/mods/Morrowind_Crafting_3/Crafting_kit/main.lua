--[[ Crafting of items using Crafting kit.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for (creating items) per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.Crafting_kit.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "mc_Crafting"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonClass, UID_buttonGroup
local sGroup, sClass = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc, currentKit
local dq = false
local onFilterClass, onFilterGroup
local textFilter = ""
local sortBy = "Normal"
local tGroupIdx = 1
local tGroup = { "All", "Apparatus", "Containers", "Glassware", "Lighting", "Wicker", "Miscellaneous" }

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
UID_ListPane = tes3ui.registerID("CraftingMenu::List")
UID_ListLabel = tes3ui.registerID("CraftingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("CraftingClass::menuLabel")
UID_groupLabel = tes3ui.registerID("CraftingGroup::menuLabel")
UID_filterText = tes3ui.registerID("CraftingFilterMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("CraftingMenu")
	this.id_menulist = tes3ui.registerID("Craftinglist")
	this.id_cancel = tes3ui.registerID("Crafting_cancel")
	this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")

	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)
	--
	Recipes = mc.getAddInFiles("Crafting", Recipes) -- Get add-in recipes
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

local function onClickSelectedItem(e)
	config = mwse.loadConfig(configPath)
	if mc3_timeOut then
		 --do nothing
	else
		local recipeNum = e.source:getPropertyInt("CraftingMenu:Index")
		local SkillValue = mc.fetchSkill(skillID)
		local thing = tes3.getObject(Recipes[recipeNum].id)
		local effSkillID = skillID

		if (Recipes[recipeNum].group == "Apparatus") and (mc.getSkill("alchemy").current < mc.getSkill(skillID).current) then 
			effSkillID = "alchemy" 
		end 
	
		if mc.skillCheck(effSkillID, Recipes[recipeNum].difficulty) == true then -- Succeeded
			tes3.messageBox({ message = "Created "..thing.name })
			tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
			tes3.addItem({ reference = tes3.player, item = Recipes[recipeNum].id, count = Recipes[recipeNum].yieldCount, playSound = false })
			mc.skillReward(skillID, SkillValue, Recipes[recipeNum].difficulty)
		else
			tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end
		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(Recipes[recipeNum].ingreds) do
			if xt.count > 0 then
				if xt.id == "Thread" then
					-- do nothing
				else
					if (xt.consumed ~= false) then
						tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
					end
				end
			end
		end
		if config.tasktime == true then
			tes3.advanceTime({ hours = Recipes[recipeNum].taskTime })
		end
	end
	tes3ui.forcePlayerInventoryUpdate()
	menu:destroy()
	this.createWindow()
end

--[[
local function onFilterClass()
	if sClass == "All" then
		sClass = "Tools"
	elseif sClass == "Tools" then
		sClass = "Glass"
	elseif sClass == "Kitchen" then
		sClass = "Kitchen"
	elseif sClass == "Extravagant" then
		sClass = "Exquisite"
	elseif sClass == "Exquisite" then
		sClass = "Flawless"
	--elseif sClass == "Group5" then
	--	sClass = "Group6"
	else
		sClass = "All"
	end
	menu:destroy()
	this.createWindow()
end
]]--

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

local function showCraftingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc
	local recipeNum = e.source:getPropertyInt("CraftingMenu:Index")
	local skillValue = skillModule.getSkill(skillID).value
	local effDifficulty = Recipes[recipeNum].difficulty * mc.calcAttr().modInt * mc.calcAttr().modAgi
	local effSkill = skillValue * mc.calcAttr().modHealth * mc.calcAttr().modFatigue * mc.calcAttr().modLuck
	local effSkillID = skillID
	
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
		if xt.id == "AnyCloth" then
			local showtip = tipmenu:createLabel({ text = " Any <XXX> ("
			..mc.countCloth().." of "..xt.count..")  " })
		elseif xt.id == "Thread" then
			local showtip = tipmenu:createLabel({ text = "Thread ("
			..mwscript.getItemCount({ reference = "player", item = "misc_spool_01" }).." of "..xt.count..")  " })
		else
			if ingred == nil then mwse.log("[MC3] Bad Ingredient for "..thing.id.." - ("..xt.id..")") end
			local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
			..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count, 1)..")  " })
		end
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(Recipes[recipeNum].difficulty) })
	if (Recipes[recipeNum].group == "Apparatus") and (mc.getSkill("alchemy").current < mc.getSkill(skillID).current) then 
		effSkillID = "alchemy"
	end
	local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(effSkillID, Recipes[recipeNum].difficulty) })
	if (effSkillID == "alchemy") then
		if config.casualmode == false then
			local showtip = tipmenu:createLabel({ text = "Limited by Alchemy Skill!" })
		end
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
	menu.text = "Crafting"
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
					ingred = tes3.getObject(xt.id)
					if xt.id == "AnyCloth" then
						if mc.countCloth() < xt.count then
							haveMaterial = false
						end
					elseif xt.id == "Thread" then
						-- do nothing
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
				itemBlock:setPropertyInt("CraftingMenu:Index", index)
				if haveMaterial == true then
					itemBlock:register("mouseClick", onClickSelectedItem)
				end
				itemBlock:register("help", showCraftingTooltip)
				--if thing.id == "Any<XXX>" then
				--	local image = itemBlock:createImage({ path = "icons/m/misc_cloth00.tga" }) -- substitute icon-ID
				--else
					local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
				--end
				--image.consumeMouseEvents = false
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



UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("CraftingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onEquip(e)
	--if (e.activator == tes3.player) then
		if e.item.id == "mc_crafting_kit" then
			tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
            --currentKit = e.item.reference
			dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
			this.createWindow()
			return false
		end
    --end
end
event.register("equip", onEquip)

--[[
local function mc_<objectname>_p_activate(e)
	if (e.activator == tes3.player) then
		if ( e.target.object.id == "<ObjectID>_p" ) then
			this.createWindow()
			return false
		end
   end
end
event.register("activate", mc_spinningwheel_p_activate)
]]--