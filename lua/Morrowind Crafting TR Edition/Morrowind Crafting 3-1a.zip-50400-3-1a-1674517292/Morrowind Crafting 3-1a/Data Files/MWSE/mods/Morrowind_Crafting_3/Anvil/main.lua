--[[ Smith weapons & armor, and scrap same.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

-- recipes for smithing materials per filters: item class, material
local smithRecipes = require("Morrowind_Crafting_3.Anvil.smithing_recipes")
local scrapRecipes = require("Morrowind_Crafting_3.Anvil.scrapping_recipes")
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")
local rr = include("mer.RealisticRepair.interop")
local this = {}
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel, UID_spacerLabel
local UID_buttonClass, UID_buttonGroup, UID_filterText
local sClass, sGroup = "All", "All"
local thing, ingred, menu, ttemp, ttl, itemDesc, currentKit, smithing
local dq = false
local onFilterClass, onFilterGroup
local SelectScrappingItem -- Must be forward-declared like this
local smithTextFilter = ""
local sortBy = "Normal"
local tClass = { "All", "Armor", "Weapon" }
local tClassIdx = 1
local tGroup = { "All", "Adamantium", "Daedric", "Daedric Steel", "Dwemer", "Ebony", "Glass", "Imperial",
				"Indoril", "Iron", "Nordic", "Orcish", "Royal", "Silver", "Steel" }
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
UID_ListPane = tes3ui.registerID("SmithingMenu::List")
UID_ListLabel = tes3ui.registerID("SmithingMenu::ListBlockLabel")
UID_classLabel = tes3ui.registerID("SmithingMenu::menuLabel")
UID_groupLabel = tes3ui.registerID("SmithingMenu::menuLabel")
UID_filterText = tes3ui.registerID("SmithingMenu::Input")
UID_spacerLabel = tes3ui.registerID("spacerLabel")

function this.init()
	this.id_menu = tes3ui.registerID("smithing")
	this.id_menulist = tes3ui.registerID("smithlist")
	this.id_cancel = tes3ui.registerID("anvil_cancel")
	this.btn_sClass = tes3ui.registerID("sClassbtn")
	this.btn_sGroup = tes3ui.registerID("sGroupbtn")
	this.buttonGroup = tes3ui.registerID("btnGroup")
	this.id_scrap = tes3ui.registerID("btnScrap")
	this.btn_sort = tes3ui.registerID("smithBtnSort")

	smithRecipes = mc.cleanDeprecated(smithRecipes)
	scrapRecipes = mc.cleanDeprecated(scrapRecipes)

	-- Sort initial loading by obectID
	table.sort(smithRecipes, sortInitial)
	--
	smithRecipes = mc.getAddInFiles("Smithing", smithRecipes) -- Get Smithing add-in recipes
	smithRecipes = mc.cleanDeprecated(smithRecipes)
	scrapRecipes = mc.getAddInFiles("Scrapping", scrapRecipes) -- Get Scrapping add-in recipes
	scrapRecipes = mc.cleanDeprecated(scrapRecipes)

end

local function onSort()
	if sortBy == "Normal" then
		table.sort(smithRecipes, sortDifficulty )
		sortBy = "Difficulty"
	elseif sortBy == "Difficulty" then
		table.sort(smithRecipes, sortOriginal )
		sortBy = "Normal"
	end
	menu:destroy()
	this.createWindow()
end

local function countHammers(htype) -- Count # of hammers in inventory; if htype = 'ALL' then count all, else just GM+
    local hammercount = mwscript.getItemCount({ reference = "player", item = "repair_grandmaster_01" })
        + mwscript.getItemCount({ reference = "player", item = "repair_secretmaster_01a" })
        + mwscript.getItemCount({ reference = "player", item = "repair_secretmaster_01" })
	if htype == "ALL" then
		hammercount = hammercount 
		+ mwscript.getItemCount({ reference = "player", item = "hammer_repair" })
		+ mwscript.getItemCount({ reference = "player", item = "repair_journeyman_01" })
		+ mwscript.getItemCount({ reference = "player", item = "repair_master_01" })
	end
    return hammercount
end

local function removeHammers(gmcount)
    for idx = 1, gmcount do
        if mwscript.getItemCount({ reference = "player", item = "repair_grandmaster_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "repair_grandmaster_01", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "repair_secretmaster_01a" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "repair_secretmaster_01a", count = 1, playSound = false })
        elseif mwscript.getItemCount({ reference = "player", item = "repair_secretmaster_01" }) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "repair_secretmaster_01", count = 1, playSound = false })
        else
            mwse.log({ message = "Bad hammer count in daedric scrapping!" })
            break
        end
    end
end

local function filterScrapCandidates(e)
    local isit = false
	local objectHold, localThing
	localThing = tes3.getObject(e.item.id)
if localThing.objectType == tes3.objectType.weapon then
	--mwse.log(localThing.type.." "..localThing.mesh)
end
-- mwse.log(localThing.mesh.."  "..e.item.id)
    for idx, x in ipairs(scrapRecipes) do
		--objectHold = tes3.getObject(x.id)
		--if objectHold == nil then mwse.log("Bad item detected: "..x.id) end
        if x.id == e.item.id then
			isit = true
			break
        end
    end
    return isit
end

local function onScrap(e)
	if countHammers("ALL") > 0 then
		tes3ui.leaveMenuMode()
		menu:destroy()
		smithing = 1
		SelectScrappingItem()
	else
		tes3.messageBox({ message = "You cannot break metal objects into scrap without a hammer of some sort." })
	end
end

-- -----------------------------------------------
local function onMenuInventorySelectActivated(e) -- Adding a 'switch' button to the showInventorySelect menu
    if (not e.newlyCreated) then
        return
    end
	if ( smithing == 0 or not smithing ) then
		return
	end
	local cancelButton = e.element:findChild(tes3ui.registerID("MenuInventorySelect_button_cancel"))
	cancelButton.text = tes3.findGMST("sCancel").value
	local buttonContainer = cancelButton.parent
	local swSmithButton

	swSmithButton = buttonContainer:createButton({ id = "btnInventorySelectSwitchToSmithing", text = "Switch to Smithing" })
	local label = buttonContainer:createLabel({ id = UID_spacerLabel, text = "" })
	label.widthProportional = 1.0
    swSmithButton:register("mouseClick", function(clickEvent)
        -- Give the button its normal click behaviour.
		clickEvent.source:forwardEvent(clickEvent)
        -- Should clobber the showInventorySelect menu & open the Smithing menu in its place
		this.createWindow()
        cancelButton:triggerEvent("mouseClick")
    end)
    -- Move the new button to the start of the container.
    buttonContainer:reorderChildren(0, -2, 2)
end
event.register("uiActivated", onMenuInventorySelectActivated, { filter = "MenuInventorySelect" } )
-- -----------------------------------------------

local function onScrapInventoryItemSelected(e)
	config = mwse.loadConfig(configPath)
    local batchSize, gmhammers, yieldcount, timerCount, batchCap
	if e.item == nil then
		--smithing = 0
        return false
	end
	if mc3_timeOut then 
		-- do nothing
	else
  	  	for idx, x in ipairs(scrapRecipes) do
			if x.id == e.item.id then
				timerCount = x.taskTime
  	          --We got one!   Now ensure that the user has enough to actually scrap
				batchSize = math.floor(e.count / x.qtyReq)
				batchCap = math.floor(24/ timerCount)
				if (batchSize > batchCap) and (config.tasktime == true) then
					batchSize = batchCap
					tes3.messageBox({ message = "You can only manage to scrap "..batchSize.." in a 24-hour period."})
				end
  	          gmhammers = countHammers("GM")
  	          if batchSize < 1 then
  	              tes3.messageBox({ message = "You need at least "..(x.qtyReq).." in order to be able to scrap this." })
  	              break
   	          end
   	           yieldcount = x.yieldCount
   	           --[[Check to see if is a daedric item; if so, require GM hammer or better be present in inventory
   	             and if not, reject ]]--
   	         if x.yieldID == "mc_daedric_ebony" then
   	             if gmhammers == 0 then
   	                 tes3.messageBox({ message = "You have no appropriate hammers for this task." })
   	                 break
  	              elseif batchSize > gmhammers then --If not enough hammers, then limit batches to the number *of* hammers
   	                 batchSize = gmhammers
  	              end
  	              if dq == false then
  	                  yieldcount = yieldcount - 1 --1 daedric ebony, rest is regular ebony
  	                  if yieldcount > 0 then
	                      tes3.addItem({ reference = tes3.player, item = "ingred_raw_ebony_01", count = batchSize * yieldcount, playSound = false })
     	               end
    	                tes3.addItem({ reference = tes3.player, item = "mc_daedric_ebony", count = batchSize, playSound = false })
    	            else
    	                tes3.addItem({ reference = tes3.player, item = "mc_daedric_ebony", count = batchSize * yieldcount, playSound = false })
    	            end
    	            removeHammers(batchSize)
    	        else
    	        -- Got this far, must be enough. Add the material to the player's inventory
    	            tes3.addItem({ reference = tes3.player, item = x.yieldID, count = batchSize * yieldcount, playSound = false })
					if (x.byproduct) then
						for byIdx, bx in ipairs(x.byproduct) do
							tes3.addItem({ reference = tes3.player, item = bx.id, count = batchSize * bx.yield})
						end
					end
    	            -- Now remove the item(s) from player's inventory
    	        end
    	        tes3.removeItem({ reference = tes3.player, item = e.item, count = batchSize * x.qtyReq, itemData = e.itemData, playSound = false })
    	        tes3.playSound{ sound = "Repair", volume = 1.0, pitch = 0.9 }
				--[[
    	        timer.delayOneFrame(function()
					tes3.playSound{ sound = "Pack", volume = 1.0, pitch = 0.9 }
				end)
				]]
    	    end
		end
		mc.timePass(timerCount * batchSize)
	end
    ttemp = tes3ui.forcePlayerInventoryUpdate
    timer.frame.delayOneFrame(SelectScrappingItem)
end
 
SelectScrappingItem = function()
    tes3ui.showInventorySelectMenu({
		id = "smithScrapping",
		text = "Scrapping",
        title = "Select Item(s) to Scrap",
        noResultsText = "No scrappable items found.",
		noResultsCallback = this.createWindow,
        filter = filterScrapCandidates,
		height = 720,
        callback = onScrapInventoryItemSelected
    })
end

-- Buttons
-- Cancel button
local function onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		smithing = 0
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function onClickSmithingItem(e)
	if mc3_timeOut then
		-- do nothing
	else
		config = mwse.loadConfig(configPath)
		local recipeNum = e.source:getPropertyInt("SmithingMenu:Index")
		local smithSkill = mc.fetchSkill("mc_Smithing")
		local thing = tes3.getObject(smithRecipes[recipeNum].id)
	
		if mc.skillCheck("mc_Smithing", smithRecipes[recipeNum].difficulty) == true then -- Succeeded
			tes3.messageBox({ message = "Created "..thing.name })
			tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
			tes3.addItem({ reference = tes3.player, item = smithRecipes[recipeNum].id, count = smithRecipes[recipeNum].yieldCount, playSound = false })
			mc.skillReward("mc_Smithing", smithSkill, smithRecipes[recipeNum].difficulty)
		else
			tes3.messageBox({ message = "Failed: your materials were ruined in the attempt." })
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
		end
		-- Whether succeed or fail, materials were used up
		for i, xt in ipairs(smithRecipes[recipeNum].ingreds) do
			if xt.count > 0 then
				if xt.id == "mc_crucible" then
					-- do nothing
				elseif xt.id == "mc_carpentry_kit" then
					-- do nothing
				else
					if (xt.consumed ~= false) then
						tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
						if xt.id == "misc_spool_01" then
							tes3.addItem({ reference = tes3.player, item = "mc_spool_empty", count = xt.count, playSound = false })
						end
					end
				end
			end
		end
		mc.timePass(smithRecipes[recipeNum].taskTime)
	end
	tes3ui.leaveMenuMode()
	menu:destroy()
	tes3ui.forcePlayerInventoryUpdate()
	this.createWindow()
end

local function onFilterClass()
	if mc.getShift() == true then
		tClassIdx = tClassIdx - 1
		if tClassIdx < 1 then tClassIdx = #tClass end
	else
		tClassIdx = tClassIdx + 1
		if tClassIdx > #tClass then tClassIdx = 1 end
	end
	sClass = tClass[tClassIdx]
	sGroup = tGroup[tGroupIdx]
	menu:destroy()
	this.createWindow()
end

local function onFilterGroup()
	if mc.getShift() == true then
		tGroupIdx = tGroupIdx - 1
		if tGroupIdx < 1 then tGroupIdx = #tGroup end
		if (tGroupIdx == 3) and (dq ~= true) then tGroupIdx = 2 end			
	else
		tGroupIdx = tGroupIdx + 1
		if tGroupIdx > #tGroup then tGroupIdx = 1 end
		if (tGroupIdx == 3) and (dq ~= true) then tGroupIdx = 4 end
	end
	sGroup = tGroup[tGroupIdx]
	menu:destroy()
	this.createWindow()
end

local function showSmithingTooltip(e)
	config = mwse.loadConfig(configPath)
	local itemDesc
	local recipeNum = e.source:getPropertyInt("SmithingMenu:Index")
	local smithSkill = skillModule.getSkill("mc_Smithing").value
	local effDifficulty = smithRecipes[recipeNum].difficulty * mc.calcAttr().modInt * mc.calcAttr().modAgi
	local effSkill = smithSkill * mc.calcAttr().modHealth * mc.calcAttr().modFatigue * mc.calcAttr().modLuck
	
	thing = tes3.getObject(smithRecipes[recipeNum].id)
	itemDesc = thing.name
	if smithRecipes[recipeNum].alias then
		itemDesc = smithRecipes[recipeNum].alias
	end
	local tipmenu = tes3ui.createTooltipMenu()
	local showtip = tipmenu:createLabel({ text = " "..thing.name.." " })
	showtip.color = tes3ui.getPalette("header_color")
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	if smithRecipes[recipeNum].yieldCount > 1 then
		local showtip = tipmenu:createLabel({ text = "Yields " .. smithRecipes[recipeNum].yieldCount })
	end
	local showtip = tipmenu:createLabel({ text = string.format("Weight: %.2g", thing.weight) })
	local showtip = tipmenu:createLabel({ text = string.format("Value: %.0f", thing.value) })
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Requires:" })
	for itip, xt in ipairs(smithRecipes[recipeNum].ingreds) do
		ingred=tes3.getObject(xt.id)
		if ingred == nil then mwse.log("[MC3] Bad Ingredient for "..thing.id.." - ("..xt.id..")") end
		local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
		..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count,1)..")  " })
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(smithRecipes[recipeNum].difficulty) })
	local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance("mc_Smithing", smithRecipes[recipeNum].difficulty) })
end
	
-- Create window and layout. Called by onCommand.
function this.createWindow()
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Smithing"
	menu.width = 650
	menu.height = 740
	menu.minWidth = 650
	menu.minHeight = 740
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	smithing = 1

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
		filterInputBorder.widthProportional = 0.5
		filterInputBorder.height = 24
		filterInputBorder.childAlignX = 0.5
		filterInputBorder.childAlignY = 0.5
		filterInputBorder.absolutePosAlignY = 0.5
		
		local filterTextInput = filterInputBorder:createTextInput({ id = UID_filterText })
		filterTextInput.borderLeft = 5
		filterTextInput.borderRight = 5
		filterTextInput.widget.lengthLimit = 20
		filterTextInput.widget.eraseOnFirstKey = true
		if smithTextFilter == "" then
			smithTextFilter = "Filter by name:"
		end
		filterTextInput.text = smithTextFilter
		
		filterTextInput.widthProportional = 0.5
		filterTextInput:register("keyEnter", 
			function()
			local text = filterTextInput.text
			if text == "Filter by name:" then
				text = ""
			end
			if (text == "") then
				smithTextFilter = ""
			else
				smithTextFilter = text
			end
			menu:destroy()
			this.createWindow()
			end )
		local buttonClass = filterBlock:createButton{ id = this.btn_sClass, text = "Class: " .. sClass }
		local buttonGroup = filterBlock:createButton{ id = this.btn_sGroup, text = "Group: "..sGroup }
		buttonClass:register("mouseClick", onFilterClass)
		buttonClass.widthProportional = 0.5
		buttonGroup:register("mouseClick", onFilterGroup)
		buttonGroup.widthProportional = 1.0
	
	-- Run through recipes, create button for each weapon or armor piece
	local list=menu:createVerticalScrollPane({ id = UID_ListPane })
	ttl = 0
	for index, x in ipairs(smithRecipes) do
		if x.place == nil then
			x.place = index
		end
		ttemp = tes3.getObject(x.id)
		if ttemp then
			ttemp=true
			thing = tes3.getObject(x.id)
			itemDesc = thing.name
			if x.alias then
				itemDesc = x.alias
			end
			if smithTextFilter == "Filter by name:" then
				smithTextFilter = ""
			end
			if smithTextFilter ~= nil and smithTextFilter ~= "" and not string.find(string.upper(itemDesc),string.upper(smithTextFilter), 1, true) then
				ttemp = false
			end
			if sClass ~= "All" and sClass ~= x.class then 
				ttemp = false 
			end
			if sGroup ~= "All" and sGroup ~= x.group then
				ttemp = false
			end
			if dq ~= true and x.group == "Daedric" then
				ttemp = false
			end
			if x.unlock ~= nil then
				if (tes3.getJournalIndex{id=x.unlock.id}) < x.unlock.index then
					ttemp = false
				end
			end
			if ttemp == true then
				-- Now check to see if player has the necessary materials
				haveMaterial = true
				for itip, xt in ipairs(smithRecipes[index].ingreds) do
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
				itemBlock:setPropertyInt("SmithingMenu:Index", index)
				if haveMaterial == true then
					itemBlock:register("mouseClick", onClickSmithingItem)
				end
				itemBlock:register("help", showSmithingTooltip)
				local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
				image.consumeMouseEvents = false
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
    button_block.childAlignX = 1.0  -- right content alignment
	
	local button_scrap = button_block:createButton{ id = this.id_scrap, text = "Switch to Scrapping" }
	local button_repair
	if ((rr ~= nil) and (rr.showRepairMenu)) then
		button_repair = button_block:createButton{ id = this.id_scrap, text = "Switch to Repair" }
		button_repair:register("mouseClick", rr.showRepairMenu)
	end
	local button_sort = button_block:createButton{ id = this.btn_sort, text = "Sorted: "..sortBy }
	local label = button_block:createLabel({ id = UID_spacerLabel, text = "" })
	label.widthProportional = 1.0
	local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	
	-- Events
    button_cancel:register("mouseClick", onCancel)
	button_scrap:register("mouseClick", onScrap)
	button_sort: register("mouseClick", onSort)

	-- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(this.id_menu)
	tes3ui.acquireTextInput(filterTextInput)
end

UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("ScrappingMenu:ListBlockLabel")
event.register("initialized", this.init)

--local function onEquip(e)
--	smithing = 0
--end
--event.register("equip", onEquip)

local function onActivate(e)
	if (e.activator == tes3.player) then
		if e.target.object.id == "mc_anvil_p" then
			if mc.uninstalling() == false then
				if not tes3.menuMode() then
					currentKit = e.target
				end
				-- check to see that the player has at least *some* sort of hammer
				if (countHammers("ALL")) == 0 then 
					tes3.messageBox("You need a hammer to do anything with an anvil.")
					return false 
				end
				-- check to see if the ritual for creating Daedric ebony has been completed (true/false)
				dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
				this.createWindow()
				return false
			end
		elseif e.target.object.id == "mc_anvil_perm" then
			if not tes3.menuMode() then
				currentKit = e.target
			end
			-- check to see that the player has at least *some* sort of hammer
			if (countHammers("ALL")) == 0 then 
				tes3.messageBox("You need a hammer to do anything with an anvil.")
				return false 
			end
			-- check to see if the ritual for creating Daedric ebony has been completed (true/false)
			dq = (tes3.getJournalIndex{id="MC_daedric_quest"} == 100)
			this.createWindow()
			return false
		else
			smithing = 0
		end
    end
end
event.register("activate", onActivate)