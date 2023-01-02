--[[ Copying of books using inkwell & quill-pen.
	Part of Morrowind Crafting 3
	Toccatta and Drac, c/r 2019 ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)
local skillModule = require("OtherSkills.skillModule")
local mc = require("Morrowind_Crafting_3.mc_common")

local this = {}
local skillID = "mc_Crafting"
local UID_ListPane, UID_ListLabel , UID_ClassLabelm, UID_GroupLabel
local UID_buttonClass, UID_buttonGroup
local ingred, menu, ttemp, ttl, itemDesc, lastDup
local onFilterClass, onFilterGroup
local textFilter = ""
local copyMethod -- 0=inkwell, 1=printing press

-- Register IDs
UID_ListPane = tes3ui.registerID("CopyingMenu::List")
UID_ListLabel = tes3ui.registerID("CopyingMenu::ListBlockLabel")
UID_filterText = tes3ui.registerID("CopyingMenu::Input")

function this.init()
	this.id_menu = tes3ui.registerID("CopyingMenu")
	this.id_menulist = tes3ui.registerID("Copyinglist")
	this.id_cancel = tes3ui.registerID("Copying_cancel")
end

local function getDiff(id)
	local thing = tes3.getObject(id)
	local diff = 3 * (math.round(math.sqrt(thing.value),0))
	return diff
end

local function getRecipe(id)
	local obj = tes3.getObject(id)
	local value = obj.value
	local pages = 1
	local paper = ""
	local recipe = {}

	if obj.type == tes3.bookType.book then
		if value >= 3 and value < 100 then
			pages = math.max (1, (0.9 * value - 10 ))
			pages = math.ceil(pages / 5)
			recipe = {
				ingreds = {
					{id = "ingred_guar_hide_01", count = 1},
					{id = "mc_chitin_strips", count = 1},
					{id = "mc_chitin_glue", count = 1},
					{id = "misc_spool_01", count = 1, consumed = false},
					{id = "sc_paper plain", count = pages}
					},
			taskTime = 0.1 * pages
			}
		elseif value >= 100 and value < 300 then
			pages = math.round(0.9 * value - 50, 0 )
			if pages <= 100 then
				paper = "sc_paper plain"
				pages = math.ceil(pages/5)
			else
				paper = "mc_parchment"
				pages = math.ceil(pages / 20)
			end
			recipe = {
				ingreds = {
					{id = "ingred_scamp_skin_01", count = 1},
					{id = "ingred_ash_salts_01", count = 1 },
					{id = "mc_chitin_strips", count = 1},
					{id = "mc_chitin_glue", count = 1},
					{id = "misc_spool_01", count = 1, consumed = false},
					{id = paper, count = pages}
				},
			taskTime = 0.1 * pages
			}
					
		elseif  value >= 300 then
			pages = math.round(0.9 * value - 225, 0 )
			if pages <= 100 then
				paper = "sc_paper plain"
				pages = math.ceil(pages/5)
			elseif pages > 400 then
				paper = "mc_vellum"
				pages = math.ceil(pages / 60)
			else
				paper = "mc_parchment"
				pages = math.ceil(pages / 20)
			end
			recipe = {
				ingreds = {
					{id = "ingred_daedra_skin_01", count = 1},
					{id = "mc_chitin_strips", count = 1},
					{id = "mc_chitin_glue", count = 1},
					{id = "misc_spool_01", count = 1, consumed = false},
					{id = paper, count = pages}
				},
			taskTime = 0.1 * pages
			}
		else
			recipe = {
				ingreds = {
					{id = "sc_paper plain", count = 1},
					{id = "misc_spool_01", count = 1, consumed = false},
				},
			taskTime = 0.1
			}
			mwse.log("[MC3 Error] Valuation recipe - "..id)
		end
	elseif obj.type == tes3.bookType.scroll then
		pages = (0.9 * value)
		if value > 100 then
			pages = math.ceil(pages/60)
			paper = "mc_vellum"
		elseif value > 25 then
			pages = math.ceil(pages/20)
			paper = "mc_parchment"
		else
			pages = math.ceil (pages/5)
			paper =  "sc_paper plain"
		end

		if pages > 1 then
				recipe = {
					ingreds = {
						{id = "mc_chitin_glue", count = 1},
						{id = paper, count = pages}
						},
				taskTime = 0.1 * pages
				}
		else
				recipe = {
					ingreds = {
						{id = paper, count = pages}
						},
				taskTime = 0.1 * pages
				}
		end
	else
		mwse.log("[MC3 Book Copy] - Unknown book/scroll type, '"..obj.id.."'")
	end
	return recipe
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
	config = mwse.loadConfig(configPath)
	local thing = e.source:getPropertyObject("CopyingMenu:Index")
	local SkillValue = mc.fetchSkill(skillID)
	
	if mc.skillCheck(skillID, getDiff(thing.id)) == true then -- Succeeded
		tes3.messageBox({ message = "Created "..thing.name })
		tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 0.9 }
		tes3.addItem({ reference = tes3.player, item = thing.id, count = 1, playSound = false })
		mc.skillReward(skillID, SkillValue, getDiff(thing.id))
	else
		tes3.messageBox({ message = "Failed: Your materials were ruined in the attempt." })
		tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 0.9 }
	end
	-- Whether succeed or fail, materials were used up
	for i, xt in ipairs(getRecipe(thing.id).ingreds) do
		if xt.count > 0 then
			if (xt.consumed ~= false) then
				tes3.removeItem({ reference = tes3.player, item = xt.id, count = xt.count, playSound = false })
			end
		end
	end
	-- 'use up' time ; printing press takes 1/4 the time *if* copying the same item as previously, this game session
	if copyMethod == 0 then
		mc.timePass(getRecipe(thing.id).taskTime)
	elseif (copyMethod == 1) then
		if (thing.id == lastDup) then
			mc.timePass(getRecipe(thing.id).taskTime/4) -- After first printed (this gamesession), printing press makes further copies in 1/4 time
		else
			mc.timePass(getRecipe(thing.id).taskTime)
		end
	end
	lastDup = thing.id
	
	tes3ui.forcePlayerInventoryUpdate()
	menu:destroy()
	this.createWindow()
end

local function showCopyingTooltip(e)
	config = mwse.loadConfig(configPath)
	local thing = e.source:getPropertyObject("CopyingMenu:Index")
	local skillValue = skillModule.getSkill(skillID).value
	local itemDesc
	local diff = getDiff(thing.id)
	local effDifficulty = diff * mc.calcAttr().modInt * mc.calcAttr().modAgi
	local effSkill = skillValue * mc.calcAttr().modHealth * mc.calcAttr().modFatigue * mc.calcAttr().modLuck
	itemDesc = thing.name
	local tipmenu = tes3ui.createTooltipMenu()
	local showtip = tipmenu:createLabel({ text = " "..itemDesc.." " })
	showtip.color = tes3ui.getPalette("header_color")
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = string.format("Weight: %.2g", thing.weight) })
	local showtip = tipmenu:createLabel({ text = string.format("Value: %.0f", thing.value) })
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Requires:" })
	for itip, xt in ipairs(getRecipe(thing.id).ingreds) do
		ingred=tes3.getObject(xt.id)
		if (ingred) then
			local showtip = tipmenu:createLabel({ text = " "..ingred.name.."  ("
			..mwscript.getItemCount({ reference = "player", item = xt.id }).." of "..math.max(xt.count, 1)..")  " })
		end
	end
	local showtip = tipmenu:createLabel({ text = " " }) --spacer
	local showtip = tipmenu:createLabel({ text = "Difficulty: "..mc.ttDifficulty(diff)})
	local showtip = tipmenu:createLabel({ text = "Chance of Success: "..mc.ttChance(skillID, getDiff(thing.id)) })
end

-- Create window and layout. Called by onCommand.
function this.createWindow()
    -- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.alpha = 0.75
	menu.text = "Copying Text"
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
		filterBlock.height = 24
		filterBlock.childAlignX = 1.0  -- left content alignment
		filterBlock.borderBottom = 2
		
		local filterLabel = filterBlock:createLabel({ text = ""})
		filterLabel.borderRight = 2
		local filterInputBorder = filterBlock:createThinBorder{}
		filterInputBorder.height = 24
		filterInputBorder.widthProportional = 0.5
		filterInputBorder.childAlignX = 1.0 -- 0.5
		filterInputBorder.childAlignY = 0.5
		
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
			
	-- Run through inventory, create button for each book or whatever
	local list=menu:createVerticalScrollPane({ id = UID_ListPane })
	ttl = 0
	for index, x in pairs(tes3.player.object.inventory) do
		-- Set up 'original' sort order
		thing = tes3.getObject(x.object.id) -- tes3.getObject(x.baseObject.id)
		if thing.objectType == (tes3.objectType.book) and (thing.enchantment == nil) and (thing.script == nil) then
			itemDesc = thing.name
			if textFilter == "Filter by name:" then
				textFilter = ""
			end
			ttemp = thing.id
			if ttemp then
				ttemp=true
				if thing.id == "sc_paper plain" or thing.id == "mc_parchment" or thing.id == "mc_vellum" then ttemp = false end
				if thing.id == "sc_paper plain" or thing.id == "sc_paper parchment" or thing.id == "sc_paper vellum" then ttemp = false end
				if thing.value > 2000 then ttemp = false end

				if textFilter ~= nil and textFilter ~= "" and not string.find(string.upper(itemDesc),string.upper(textFilter), 1, true) then
					ttemp = false
				end
				if ttemp == true then
					-- Now check to see if player has the necessary materials
					haveMaterial = true
					for itip, xt in ipairs(getRecipe(thing.id).ingreds) do
						ingred=tes3.getObject(xt.id)
						if (ingred) then
							if tes3.getItemCount({ reference = tes3.player, item = xt.id }) < xt.count then
								haveMaterial = false
							end
						end
					end
					local itemBlock = list:createBlock({})
					itemBlock.flowDirection = "left_to_right"
					itemBlock.widthProportional = 1.0
					itemBlock.autoHeight = true
					itemBlock.borderAllSides = 3
					itemBlock:setPropertyObject("CopyingMenu:Index", thing)
					if haveMaterial == true then
						itemBlock:register("mouseClick", onClickSelectedItem)
					end
					itemBlock:register("help", showCopyingTooltip)
					local image = itemBlock:createImage({ path = string.format("icons/%s", thing.icon) })
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
	button_block.childAlignY = 0.5
	button_block.childAlignX = 1.0  -- left content alignment
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



UIID_CraftingMenu_ListBlock_Label = tes3ui.registerID("CopyingMenu:ListBlockLabel")
event.register("initialized", this.init)

local function onEquip(e)
	if (e.item.id == "Misc_Inkwell") or (e.item.id == "T_De_BlueWareInkWell01") then
		copyMethod = 0
		if tes3.getItemCount({ reference = tes3.player, item = "Misc_Quill" }) < 1 then
			tes3.messageBox("You'll need a quill pen in order to actually write out the copy.")
			return false
		end
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuInventory"))
		this.createWindow()
		return false
	end
end
event.register("equip", onEquip)

local function onActivate(e)
	if (e.activator == tes3.player) then
		if (e.target.object.id == "mc_printpress01_p") or (e.target.object.id == "mc_printpress01_perm") then
			copyMethod = 1
			if mc.uninstalling() == false then
				this.createWindow()
				return false
			end
		end
    end
end
event.register("activate", onActivate)