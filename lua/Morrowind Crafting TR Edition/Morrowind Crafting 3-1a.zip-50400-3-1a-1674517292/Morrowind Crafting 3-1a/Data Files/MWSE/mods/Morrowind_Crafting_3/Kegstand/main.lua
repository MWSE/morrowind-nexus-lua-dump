--[[ Crafting of items using Loom.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for weaving materials per filters: item class, material
local Recipes = require("Morrowind_Crafting_3.kegstand.recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}, thisKeg
local skillID = "mc_Cooking"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonClass, UID_buttonGroup
local sGroup, sClass = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc
local onFilterClass, onFilterGroup
local textFilter = ""
local sortBy = "Normal"
local tGroup = { "All", "Liquors" }
local tGroupIdx = 1

Recipes = mc.cleanDeprecated(Recipes)

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
UID_ListPane = tes3ui.registerID("brewingMenu::List")
UID_ListLabel = tes3ui.registerID("brewingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("brewingMenu::menuLabel")
UID_groupLabel = tes3ui.registerID("brewingMenu::menuLabel")
UID_filterText = tes3ui.registerID("brewingMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("brewingMenu")
	this.id_menulist = tes3ui.registerID("brewingList")
	this.id_cancel = tes3ui.registerID("brewing_cancel")
	--this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")
	this.btn_sort = tes3ui.registerID("BtnSort")

	-- Sort initial loading by obectID
	table.sort(Recipes, sortInitial)
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
	local success = false, newObj
	if mc3_timeOut then
		-- do nothing
	else
		config = mwse.loadConfig(configPath)
		local recipeNum = e.source:getPropertyInt("brewingMenu:Index")
		local SkillValue = mc.fetchSkill(skillID)
		local thing = Recipes[recipeNum].id -- was tes3.getObject(Recipes[recipeNum].id)
		local batchSize = Recipes[recipeNum].yieldCount -- was Recipes[recipeNum].yieldCount
		
		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(Recipes[recipeNum].ingreds) do -- was ipairs(Recipes[recipeNum].ingreds) do
			if xt.count > 0 then
				tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
				if xt.id == "misc_spool_01" then
					tes3.addItem({ reference = tes3.player, item = "mc_spool_empty", count = xt.count, playSound = false })
				end
			end
		end

		if mc.skillCheck(skillID, Recipes[recipeNum].difficulty) == true then -- Succeeded
			tes3.messageBox({ message = "Started "..Recipes[recipeNum].alias })
			tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
			-- Now place the appropriate 'in use' kegstand and disable/destroy the current *******************************
			local myGlobal = tes3.findGlobal("mc_scaler")
			local newScale = thisKeg.scale
			myGlobal.value = newScale
			newObj = tes3.createReference{
				object = Recipes[recipeNum].id,
				position = thisKeg.position:copy(),
				orientation = thisKeg.orientation:copy(),
				cell = thisKeg.cell,
				scale = newScale
			}
			newObj:updateSceneGraph()
            thisKeg:delete()
			success = true
			-- ***********************************************************************************************************
			mc.skillReward(skillID, SkillValue, Recipes[recipeNum].difficulty)
		else
			tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end
		
		if config.tasktime == true then
			mc.timePass(Recipes[recipeNum].taskTime)
		end
	end
	tes3ui.forcePlayerInventoryUpdate()
	menu:destroy()
	onCancel()
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

local function showBrewingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc, prodThing2
	local recipeNum = e.source:getPropertyInt("brewingMenu:Index")
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
	prodThing2 = tes3.getObject(Recipes[recipeNum].product)
	local image2 = tipmenu:createImage({ path = string.format("icons/%s", prodThing2.icon) })
	showtip.color = tes3ui.getPalette("header_color")
	--local showtip = tipmenu:createLabel({ text = " " }) --spacer
	if Recipes[recipeNum].yieldCount > 1 then
		local showtip = tipmenu:createLabel({ text = "Yields " .. Recipes[recipeNum].yieldCount })
	end

	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Requires:" })
	for itip, xt in ipairs(Recipes[recipeNum].ingreds) do
		ingred=tes3.getObject(xt.id)
		local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
		..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count, 1)..")  " })
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(Recipes[recipeNum].difficulty) })
	local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(skillID, Recipes[recipeNum].difficulty) })
end
	
-- Create window and layout. Called by onCommand.
function this.createWindow()
	local prodThing1, prodThing2
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Kegstand - Brewing"
	menu.width = 500
	menu.height = 600
	menu.minWidth = 500
	menu.minHeight = 600
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2

	-- Show buttons for filters
	local haveMaterial, ingred
	local filterBlock = menu:createBlock({})
		filterBlock.childAlignX = 0.0  -- left content alignment
		filterBlock.childAlignY = 0.5
		filterBlock.widthProportional = 1.0
		filterBlock.flowDirection = "left_to_right"
		filterBlock.autoHeight = true
		
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
		prodThing1 = tes3.getObject("mc_kegstand")
		prodThing2 = tes3.getObject(x.product)
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
			if x.unlock ~= nil then
				if (tes3.getJournalIndex{id=x.unlock.id}) < x.unlock.index then
					ttemp = false
				end
			end
			if ttemp == true then
				if x.alias then
					itemDesc = x.alias
				end
				-- Now check to see if player has the necessary materials
				haveMaterial = true
				for itip, xt in ipairs(Recipes[index].ingreds) do
					ingred = tes3.getObject(xt.id)
					if mwscript.getItemCount({ reference = "player", item = xt.id }) < xt.count then
						haveMaterial = false
					end
				end
				local itemBlock = list:createBlock({})
				itemBlock.flowDirection = "left_to_right"
				itemBlock.widthProportional = 1.0
				itemBlock.autoHeight = true
				itemBlock.borderAllSides = 3
				itemBlock:setPropertyInt("brewingMenu:Index", index)
				if haveMaterial == true then
					itemBlock:register("mouseClick", onClickSelectedItem)
				end
				itemBlock:register("help", showBrewingTooltip)
				local image1 = itemBlock:createImage({ path = string.format("icons/%s", prodThing1.icon) })
				local image2 = itemBlock:createImage({ path = string.format("icons/%s", prodThing2.icon) })
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
	local button_sort = button_block:createButton{ id = this.btn_sort, text = "Sorted: "..sortBy }
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



UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("ScrappingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onActivate(e)
	thisKeg = e.target
	if (e.activator == tes3.player) then
		if e.target.object.id == "mc_kegstand_p" then
			if mc.uninstalling() == false then
				this.createWindow()
				return false
			end
		elseif e.target.object.id == "mc_kegstand_perm" then
			this.createWindow()
			return false
		end
    end
end
event.register("activate", onActivate)
