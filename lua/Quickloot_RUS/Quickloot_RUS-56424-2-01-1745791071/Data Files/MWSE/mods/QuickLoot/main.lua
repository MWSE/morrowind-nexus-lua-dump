--[[
	Mod Initialization: Morrowind Quick Loot
	Version 2.1.1
	Author: mort
	       
	This file enables Fallout 4-style quick looting, the default key is Z, default take all is X.
]] --

local config = require("QuickLoot.config")
local interop = require("QuickLoot.interop")

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20220501) then
	mwse.log("[QuickLoot] Build date of %s does not meet minimum build date of 2022-05-01.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Мод 'Быстрый лут' требует обновить MWSE. Запустите в корневой папке с игрой файл MWSE-Update.exe.")
		end
	)
	return
end

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("QuickLoot.mcm")
end)

-- -- Load our config file, and fill in default values for missing elements.
-- local config = mwse.loadConfig("Quick Loot")
-- if (config == nil) then
	-- config = defaultConfig
-- else
	-- for k, v in pairs(defaultConfig) do
		-- if (config[k] == nil) then
			-- config[k] = v
		-- end
	-- end
-- end

local svengToggleState = true
local svengDenyLabelState = false
local svengDotBlockState = false

-- State for the currently targetted reference and item.
local currentTarget = nil
local currentIndex = nil

-- True if you're activating from the alternate activate key
local alternateActivate = false

-- True if you just used your default activate key to take an item
local spacebarActivate = 0

-- Keep track of the current inventory size.
local currentInventorySize = nil

-- Keep easy access to the menu.
local quickLootGUI = nil

-- Toggle if you're waiting for a key rebind
local rebindTake = false
local rebindTakeAll = false
local rebindsveng = false

-- Keep track of all the GUI IDs we care about.
local GUIID_MenuContents = nil
local GUIID_QuickLoot_ContentBlock = nil
local GUIID_QuickLoot_DotBlock = nil
local GUIID_QuickLoot_NameLabel = nil
local GUIID_QuickLoot_DenyLabel = nil
local GUIID_QuickLoot_ContentBlock_ItemIcon = nil
local GUIID_QuickLoot_ContentBlock_ItemLabel = nil
local GUIID_QuickLoot_Menu = nil

-- Changes the selection to a new index. Enforces bounds to [1, currentInventorySize].
local function setSelectionIndex(index)
	if (index == currentIndex or index < 1 or index > currentInventorySize) then
		return
	end

	local contentBlock = quickLootGUI:findChild(GUIID_QuickLoot_ContentBlock)
	local dotBlock = quickLootGUI:findChild(GUIID_QuickLoot_DotBlock)
	local children = contentBlock.children
	
	--fixes inventory display on menu open/close
	local container = currentTarget.object
	currentInventorySize = #container.inventory
	
	local range = config.maxItemDisplaySize
	local firstIndex = math.clamp(index - range, 0, index)
	local lastIndex = math.clamp(index + range, index, currentInventorySize)
	
	for i, block in pairs(children) do
		if (i == index) then
			-- If this is the new index, set it to the active color.
			local label = block:findChild(GUIID_QuickLoot_ContentBlock_ItemLabel)
			label.color = tes3ui.getPalette("active_color")
		elseif (i == currentIndex) then
			-- If this is the old index, change the color back to normal.
			local label = block:findChild(GUIID_QuickLoot_ContentBlock_ItemLabel)
			label.color = tes3ui.getPalette("normal_color")
		end
		
		--show or hide items
		--tes3.messageBox("%d %d", firstIndex, lastIndex)
		if ( i < firstIndex or i > (lastIndex)) then
			block.visible = false
		else
			block.visible = true
		end
	end

	if ( lastIndex < currentInventorySize ) then
		local label = contentBlock:createLabel({text = "..."})
		label.absolutePosAlignX = 0.5
	end
	
	if ( firstIndex > 1 ) then
		svengDotBlockState = true	
		dotBlock.visible = true
	else
		svengDotBlockState = false	
		dotBlock.visible = false
	end

	currentIndex = index

	contentBlock:updateLayout()
end

local function canLootObject()
	if (currentTarget == nil) then
		return false
	end

	-- Check for locked/trapped state. If it is either, hide the contents.
	local lockNode = currentTarget.lockNode


	if (lockNode) then
		if ( config.hideLocked == true ) then
			quickLootGUI.visible = false
		end
		
		-- If the container is locked, display lock level.
		if (lockNode.locked) then
			return false, "Уровень замка: " .. lockNode.level
		end

		-- If it's trapped, show that.
		if (lockNode.trap ~= nil and config.hideTrapped == true) then
			return false, tes3.findGMST(tes3.gmst.sTrapped).value
		end
	end

	-- Tell if the container is empty.
	local container = currentTarget.object
	currentInventorySize = #container.inventory
	if (currentInventorySize == 0) then
		return false, "Пусто"
	end
	
	--whitelist overrides onActivate, but is overridden by emptiness (as are we all)
	if config.whitelist[container] then return true end
	
	-- If the chest has an onActivate, don't allow the player to peek inside because it might break the scripts.
	if (currentTarget:testActionFlag(1) == false and config.showScripted == false) then
		return false, "Невозможно просмотреть содержимое"
	end

	return true
end

local function svengToggleItemsList()
   if quickLootGUI == nil then
      return
   elseif config.svengKey.keyCode == 45 then
      return
   end
   
   local contentBlock = quickLootGUI:findChild(GUIID_QuickLoot_ContentBlock)

   if contentBlock ~= nil then
      contentBlock.visible = svengToggleState
      local children = contentBlock.children
      for i = 1, #children do
	 children[i].visible = svengToggleState
	 local subChildren = children[i].children
	 for j = 1, #subChildren do
	       subChildren[j].visible = svengToggleState
	 end
      end
   end
   
   local denyLabel = quickLootGUI:findChild(GUIID_QuickLoot_DenyLabel)
   if denyLabel ~= nil then
      denyLabel.visible = svengToggleState and svengDenyLabelState
      denyLabel.parent.visible = svengToggleState
   end
   
   local dotBlock = quickLootGUI:findChild(GUIID_QuickLoot_DotBlock)
   if dotBlock ~= nil then
      dotBlock.visible = svengToggleState and svengDotBlockState
      local children = dotBlock.children
      for i = 1, #children do
         children[i].visible = svengToggleState
      end
   end
   
   setSelectionIndex(1)
   quickLootGUI:updateLayout()
end

local function svengOnKeyDown(e)
    if config.svengKey.keyCode == 45 then
       return
    end
      
    if e.keyCode ~= config.svengKey.keyCode then
		return
	elseif tes3.menuMode() == true then
	   return
	end
	
	if svengToggleState == false then
	   svengToggleState = true
	else
	   svengToggleState = false
	end
	svengToggleItemsList()
	
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- Refresh the GUI with the currently available items.
local function refreshItemsList()

	-- Kill all our children.
	local contentBlock = quickLootGUI:findChild(GUIID_QuickLoot_ContentBlock)
	contentBlock:destroyChildren()

	local nameLabel = quickLootGUI:findChild(GUIID_QuickLoot_NameLabel)
	nameLabel.text = currentTarget.object.name

	local denyLabel = quickLootGUI:findChild(GUIID_QuickLoot_DenyLabel)

	-- Check to see if we can loot the inventory.
	local canLoot, cantLootReason = canLootObject()
	
	if (not canLoot) then
	    denyLabel.visible = true
		denyLabel.text = cantLootReason
		
		--hide the menu entirely if showplants is false
		if (cantLootReason == "Empty" and config.showPlants == false) then
			if (currentTarget.object.organic == true) then
				quickLootGUI.visible = false
			end
		end

		--contentBlock:createLabel({text = cantLootReason})
		svengDenyLabelState = true
		svengToggleItemsList()
		quickLootGUI:updateLayout()
		return
	else	
		svengDenyLabelState = false	
		denyLabel.visible = false
	end
	quickLootGUI.visible = true
	
	-- Clone the object if necessary.
	currentTarget:clone()
	
	-- Start going over the items in the object's inventory and making elements for them.
	currentIndex = nil
	local container = currentTarget.object
	
	--backup print for loaded inventories
	if (#container.inventory == 0) then
		contentBlock:createLabel({text = "Пусто"})
		quickLootGUI:updateLayout()
		if config.showPlants == false then
			if (container.organic == true) then
				quickLootGUI.visible = false
			end
		end
		return
	end
	
	--hide plant containers if the config says to
	if config.showPlants == false then
		if (container.organic == true) then
			quickLootGUI.visible = false
		end
	end

	for _, stack in pairs(container.inventory) do
		--
		quickLootGUI.visible = true
		local item = stack.object
			
		-- Our container block for this item.
		local block = contentBlock:createBlock({})
		block.flowDirection = "left_to_right"
		block.autoWidth = true
		block.autoHeight = true
		block.paddingAllSides = 3

		-- Store the item/count on the block for later logic.
		block:setPropertyObject("QuickLoot:Item", item)
		block:setPropertyInt("QuickLoot:Count", math.abs(stack.count))
		block:setPropertyInt("QuickLoot:Value", item.value)
		
		-- Item icon.
		local icon = block:createImage({id = GUIID_QuickLoot_ContentBlock_ItemIcon, path = "icons\\" .. item.icon})
		icon.borderRight = 5
		
		local total_price = (item.value)*math.abs(stack.count)
		local total_weight = round((item.weight)*math.abs(stack.count),1)
		
		-- Label text
		local labelText = item.name
		if (math.abs(stack.count) > 1) then
			labelText = item.name .. " (" .. math.abs(stack.count) .. ")"
		else
			labelText = item.name
		end
		
		local label = block:createLabel({id = GUIID_QuickLoot_ContentBlock_ItemLabel, text = labelText})
		label.absolutePosAlignY = 0.5
		
		local goldlabel = block:createLabel({text = " [" .. total_price})
		goldlabel.absolutePosAlignY = 0.5
		
		local goldicon = block:createImage({id = GUIID_QuickLoot_ContentBlock_ItemIcon, path = "icons\\gold.tga"})
		goldicon.absolutePosAlignY = 0.5
		goldicon.borderRight = 5
		goldicon.borderLeft = 5
		
		local weightlabel = block:createLabel({text = "" .. total_weight})
		weightlabel.absolutePosAlignY = 0.5
		
		local weighticon = block:createImage({id = GUIID_QuickLoot_ContentBlock_ItemIcon, path = "icons\\weight.tga"})
		weighticon.absolutePosAlignY = 0.5
		weighticon.borderRight = 5
		weighticon.borderLeft = 5
		
		local endlabel = block:createLabel({text = "]"})
		endlabel.absolutePosAlignY = 0.5
	end

	if ( currentIndex == nil ) then
		setSelectionIndex(1)
	else
		setSelectionIndex(currentIndex)
	end
	
	svengToggleItemsList()
	
	quickLootGUI:updateLayout()
end

-- Creates the GUI and populates it.
local function createQuickLootGUI()
	if (tes3ui.findMenu(GUIID_QuickLoot_Menu)) then
		refreshItemsList()
		return
	end
	
	--
	quickLootGUI = tes3ui.createMenu({id = GUIID_QuickLoot_Menu, fixedFrame = true})
	quickLootGUI.absolutePosAlignX = 0.1 * config.menuX
	quickLootGUI.absolutePosAlignY = 0.1 * config.menuY
	--
	
	local nameBlock = quickLootGUI:createBlock({})
	nameBlock.autoHeight = true
	nameBlock.autoWidth = true
	nameBlock.paddingAllSides = 1
	nameBlock.childAlignX = 0.5
	
	local nameLabel = nameBlock:createLabel({id = GUIID_QuickLoot_NameLabel, text = ''})
	nameLabel.color = tes3ui.getPalette("header_color")
	nameBlock:updateLayout()
    nameBlock.widthProportional = 1.0
	quickLootGUI.minWidth = nameLabel.width
	
	local denyBlock = quickLootGUI:createBlock({})
	denyBlock.autoHeight = true
	denyBlock.autoWidth = true
	denyBlock.paddingAllSides = 1
	denyBlock.childAlignX = 0.5
	denyBlock:createLabel({id = GUIID_QuickLoot_DenyLabel, text = ''})
	denyBlock:updateLayout()
	denyBlock.widthProportional = 1.0
	
	local dotBlock = quickLootGUI:createBlock({id = GUIID_QuickLoot_DotBlock})
	dotBlock.flowDirection = "top_to_bottom"
	dotBlock.widthProportional = 1.0
	dotBlock.autoHeight = true
	dotBlock.paddingAllSides = 3
	
	local dotLabel = dotBlock:createLabel({text = "..."})
	dotLabel.absolutePosAlignX = 0.5
	dotBlock.visible = false
	
	--
	local contentBlock = quickLootGUI:createBlock({id = GUIID_QuickLoot_ContentBlock})
	contentBlock.flowDirection = "top_to_bottom"
	contentBlock.autoHeight = true
	contentBlock.autoWidth = true
	
	-- This is needed or things get weird.
	quickLootGUI:updateLayout()
   	svengToggleState = false
	refreshItemsList()
end

-- Clears the current menu.
local function clearQuickLootMenu(destroyMenu)
	if (destroyMenu == nil) then
		destroyMenu = true
	end

	-- Clear the current target.
	currentTarget = nil
	currentInventorySize = nil

	if (destroyMenu and quickLootGUI) then
		quickLootGUI:destroy()
		quickLootGUI = nil
	end
end

-- Called when the player looks at a new object that would show a tooltip, or transfers off of such an object.
local function onActivationTargetChanged(e)
	-- Bail if we don't have a target or the mod is disabled.
	if config.modDisabled == true then
		return
	end
	
	if ( spacebarActivate > 0 ) then
		spacebarActivate = spacebarActivate - 1
		return
	end
	
	local contentsMenu = tes3ui.findMenu(GUIID_MenuContents)
	
	-- Declone the inventory if they aren't opening the inventory
	if ( currentTarget ~= nil and contentsMenu == nil ) then
		currentTarget.object:onInventoryClose(currentTarget)
	end

	local newTarget = e.current
	
	local targetNil = (newTarget == nil)
	clearQuickLootMenu(targetNil)

	if (targetNil) then
		return
	end

	-- Immediately terminate if item is blacklisted
	local id = newTarget.baseObject.id:lower()
	if config.blacklist[id] then 
		clearQuickLootMenu(true)
		return 
	end
	
	-- We only care about containers (or npcs or creatures)
	if (newTarget.object.objectType ~= tes3.objectType.container) then
		if (newTarget.object.objectType ~= tes3.objectType.npc) then
			if (newTarget.object.objectType ~= tes3.objectType.creature) then
				clearQuickLootMenu(true)
				return
			end
		end
	end
	
	-- -- -- Don't loot alive actors
	if (newTarget.mobile ~= nil) then
		if (newTarget.mobile.health.current ~= nil) then
			if (newTarget.mobile.health.current > 0) then
				clearQuickLootMenu(true)
				return
			end
		end
	end
	
	--Don't loot plants if told not to
	if (config.showPlants == false and newTarget.object.organic) then
		clearQuickLootMenu(true)
		return
	end
	
	-- Don't loot containers if your hands are disabled
	if (tes3.mobilePlayer.attackDisabled) then
		return
	end
	
	--Don't activate quickloot if told otherwise
	if ( interop.skipNextTarget == true ) then
		clearQuickLootMenu(true)
		interop.skipNextTarget = false
		return
	end
	
	currentTarget = newTarget
	createQuickLootGUI(newTarget)
	spacebarActivate = 0 --failsafe
end

local function arrowKeyScroll(e)
	if (currentTarget) then
		if (e.keyCode == 208) then
			setSelectionIndex(currentIndex + 1)
		elseif (e.keyCode == 200 ) then
			setSelectionIndex(currentIndex - 1)
		end
	end
end

-- Called when the mouse wheel scroll is used. Changes the selection.
local function onMouseWheelChanged(e)
	if (currentTarget) then
		if currentIndex == nil then 
			currentIndex = 0
		end
		if (e.delta < 0) then
			setSelectionIndex(currentIndex + 1)
		else
			setSelectionIndex(currentIndex - 1)
		end
	end
end

--makes NPCs react to quicklooting
local function crimeCheck(itemValue)
	local owner = tes3.getOwner(currentTarget)
	
	if (owner) then
		if owner.playerJoined then
			if currentTarget.attachments["variables"].requirement <= owner.playerRank then
				return
			end
		end
		tes3.triggerCrime({
			type = 5,
			victim = owner,
			value = itemValue
		})
	end
end

local function takeItem()
	if (tes3.menuMode()) then
		return
	end
	
	if (canLootObject() == false)  then
		return
	end
	
	if config.modDisabled == true then
		return
	end
	
	if currentTarget == nil then
		return
	end
	
	if currentTarget.lockNode ~= nil then
		if currentTarget.lockNode.trap ~= nil then
			tes3.cast({reference = tes3.getPlayerTarget(),
						target=tes3.player,
						spell=tes3.getPlayerTarget().lockNode.trap
						})
			tes3.getPlayerTarget().lockNode.trap = nil
			return
		end	
	end

	local crimeValue = 0
	local block = quickLootGUI:findChild(GUIID_QuickLoot_ContentBlock).children[currentIndex]
	
	crimeValue = crimeValue + (block:getPropertyInt("QuickLoot:Value") * block:getPropertyInt("QuickLoot:Count"))
	tes3.transferItem({
		from = currentTarget,
		to = tes3.player,
		item = block:getPropertyObject("QuickLoot:Item"),
		count = block:getPropertyInt("QuickLoot:Count"),
	})
	
	crimeCheck(crimeValue)
	
	if config.showMessageBox == true then
		tes3.messageBox({ message = "Взято " .. block:getPropertyInt("QuickLoot:Count") .. " "
		.. block:getPropertyObject("QuickLoot:Item").name })
	end

	local preservedIndex = currentIndex
	refreshItemsList()
	setSelectionIndex(math.clamp(preservedIndex, 1, currentInventorySize))
end

-- Takes all of the currently selected item.
local function takeItemKey(e)
	if e.keyCode ~= config.takeKey.keyCode then
		return
	end
	
	if config.modDisabled == true then
		return
	end
	
	if quickLootGUI == nil then
		return
	end
	
	if config.activateMode == true then
		if tes3.getPlayerTarget() then
			alternateActivate = true
			tes3.player:activate(tes3.getPlayerTarget())
		else
			tes3ui.leaveMenuMode()
		end
	else
		takeItem()
	end
end

-- Takes currently selected item, but with space bar (activate default)
local function takeItemActivate(e)
	if (e.activator ~= tes3.player) then
		return
	end
	if (not canLootObject()) then
		return
	end
	
	if (config.activateMode == true and alternateActivate == false) then
		spacebarActivate = 2
		takeItem()
		return false
	else
		alternateActivate = false
		return
	end
end

local function setDeleteDelay(ref)
	mwscript.setDelete{reference=ref}
end

-- Takes all items from the current target.
local function takeAllItems(e)
	if (tes3.menuMode()) then
		return
	end

	if e.keyCode ~= config.takeAllKey.keyCode then
		return
	end
	
	if config.modDisabled == true then
		return
	end
	
	if quickLootGUI == nil then
		return
	end
	
	local canloot,reason = canLootObject()
	
	if currentTarget == nil then
		return
	end
	
	if (currentTarget.object.objectType == tes3.objectType.npc) or (currentTarget.object.objectType == tes3.objectType.creature) then
		if (reason == "Empty") then
			mwscript.disable{reference=currentTarget}
			timer.delayOneFrame({callback = setDeleteDelay(currentTarget)})
			return
		end
	end
	
	if (not canLootObject()) then
		return
	end
	
	if currentTarget.lockNode ~= nil then
		if currentTarget.lockNode.trap ~= nil then
			tes3.cast({reference = tes3.getPlayerTarget(),
						target=tes3.player,
						spell=tes3.getPlayerTarget().lockNode.trap
						})
			tes3.getPlayerTarget().lockNode.trap = nil
			return
		end	
	end
	
	local inventory = currentTarget.object.inventory
	local crimeValue = 0
	
	tes3.playItemPickupSound({ item = inventory.iterator[1].object.id, pickup = true })
	
	for _, stack in pairs(inventory) do
        if stack.object.canCarry ~= false then
            crimeValue = crimeValue + (stack.object.value * stack.count)
            tes3.transferItem({
                from = currentTarget,
                to = tes3.player,
                item = stack.object,
                playSound = false,
                count = math.abs(stack.count),
                updateGUI = false,
            })
        end
    end
	
	crimeCheck(crimeValue)
	
	if config.showMessageBox == true then
		tes3.messageBox({ message = "Взяты все предметы" })
	end
	tes3ui.forcePlayerInventoryUpdate()

	refreshItemsList()
end

local function onUIObjectTooltip(e)
	if (tes3.menuMode()) then
		return
	end
	
	if interop.skipNextTarget == true then
		interop.skipNextTarget = false
		return
	end

	local id = e.reference.baseObject.id:lower()
	if config.blacklist[id] then return end
	
	if (config.modDisabled == false and config.hideTooltip == true) then
	   if e.reference ~= nil and e.reference.mobile ~= nil
	   and e.reference.mobile.health.current ~= nil
	   and e.reference.mobile.health.current <= 0 then
		e.tooltip.maxWidth = 0
		e.tooltip.maxHeight = 0
	   elseif e.object.objectType == tes3.objectType.container then
		e.tooltip.maxWidth = 0
		e.tooltip.maxHeight = 0
       end
	end
end

local function onInitialized()
	-- Register necessary GUI element IDs.
	GUIID_MenuContents = tes3ui.registerID("MenuContents")
	GUIID_QuickLoot_ContentBlock = tes3ui.registerID("QuickLoot:ContentBlock")
	GUIID_QuickLoot_DotBlock = tes3ui.registerID("QuickLoot:DotBlock")
	GUIID_QuickLoot_NameLabel = tes3ui.registerID("QuickLoot:NameLabel")
	GUIID_QuickLoot_DenyLabel = tes3ui.registerID(("QuickLoot:DenyLabel"))
	GUIID_QuickLoot_ContentBlock_ItemIcon = tes3ui.registerID("QuickLoot:ContentBlock:ItemIcon")
	GUIID_QuickLoot_ContentBlock_ItemLabel = tes3ui.registerID("QuickLoot:ContentBlock:ItemLabel")
	GUIID_QuickLoot_Menu = tes3ui.registerID("QuickLoot:Menu")

	-- Register the necessary events to get going.
	event.register("activationTargetChanged", onActivationTargetChanged)
	event.register("uiObjectTooltip", onUIObjectTooltip)
	event.register("keyDown", takeAllItems)
	event.register("keyDown", takeItemKey)
	event.register("keyDown", arrowKeyScroll)
	event.register("mouseWheel", onMouseWheelChanged)
	event.register("menuEnter", clearQuickLootMenu)
	event.register("keyDown", svengOnKeyDown)
	event.register("activate", takeItemActivate)
	
	mwse.log("[Morrowind Quick Loot] Initialized")
end
event.register("initialized", onInitialized)