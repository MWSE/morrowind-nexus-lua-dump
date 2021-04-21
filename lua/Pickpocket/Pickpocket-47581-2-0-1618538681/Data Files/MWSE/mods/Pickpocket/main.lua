--[[
	Pickpocket
	Author: mort
	v2.0
]] --

--local interopQL = require("QuickLoot.interop")

-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20210412) then
	mwse.log("[Pickpocket] Build date of %s does not meet minimum build date of 2021-04-12.", mwse.buildDate)
	event.register(
		"initialized",
		function()
			tes3.messageBox("Pickpocket requires a newer version of MWSE. Please run MWSE-Update.exe.")
		end
	)
	return
end

-- The default configuration values.
local defaultConfig = {
	modEnabled = true,
	maxItemDisplaySize = 10,
	hideTooltip = true,
	merchantBonus = 40,
	allowArmorTheft = false,
	invisFix = true,
	pickpocketExpValue = 2,
	equippedArmorBonus = 50,
	useItemValueCrime = false,
	equippedItemHiddenCount = false,
	allowWeaponTheft = false,
	weaponTheftCrime = true,
	allowShieldTheft = false,
	allowEquippedJewelryTheft = true,
	pickpocketCrimeValue = 25,
	equipBonus = 40,
	menuX = 6,
	menuY = 4,
}

-- Load our config file, and fill in default values for missing elements.
local config = mwse.loadConfig("mortPickpocket")
if (config == nil) then
	config = defaultConfig
else
	for k, v in pairs(defaultConfig) do
		if (config[k] == nil) then
			config[k] = v
		end
	end
end

-- State for the currently targetted reference and item.
local currentTarget = nil
local currentIndex = nil

-- Keep track of the current inventory size.
local currentInventorySize = nil

-- Keep easy access to the menu.
local pickpocketGUI = nil

-- Keep track of all the GUI IDs we care about.
local GUI_Pickpocket_multi = nil
local GUI_Pickpocket_sneak = nil
local GUIID_Pickpocket_NameLabel = nil
local GUIID_Pickpocket_DenyLabel = nil
local GUIID_Pickpocket_ContentBlock = nil
local GUIID_Pickpocket_ContentBlock_ItemIcon = nil
local GUIID_Pickpocket_ContentBlock_ItemLabel = nil
local GUIID_Pickpocket_Menu = nil

-- Changes the selection to a new index. Enforces bounds to [1, currentInventorySize].
local function setSelectionIndex(index)
	if (index == currentIndex or index < 1 or index > currentInventorySize) then
		return
	end

	local contentBlock = pickpocketGUI:findChild(GUIID_Pickpocket_ContentBlock)
	local dotBlock = pickpocketGUI:findChild(GUIID_Pickpocket_DotBlock)
	local children = contentBlock.children
	
	--fixes inventory display on menu open/close
	local container = currentTarget.object
	--currentInventorySize = #container.inventory
	
	local range = config.maxItemDisplaySize
	local firstIndex = math.clamp(index - range, 0, index)
	local lastIndex = math.clamp(index + range, index, currentInventorySize)
	
	for i, block in pairs(children) do
		if (i == index) then
			-- If this is the new index, set it to the active color.
			local label = block:findChild(GUIID_Pickpocket_ContentBlock_ItemLabel)
			label.color = tes3ui.getPalette("active_color")
		elseif (i == currentIndex) then
			-- If this is the old index, change the color back to normal.
			local label = block:findChild(GUIID_Pickpocket_ContentBlock_ItemLabel)
			label.color = tes3ui.getPalette("normal_color")
		end
		
		--show or hide items
		--tes3.messageBox("%d %d", index, currentInventorySize)
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
		dotBlock.visible = true
	else
		dotBlock.visible = false
	end

	currentIndex = index

	contentBlock:updateLayout()
end

local function canLootObject()
	if (currentTarget == nil) then
		return false
	end

	-- Tell if the container is empty.
	local container = currentTarget.object
	currentInventorySize = #container.inventory
	if (currentInventorySize == 0) then
		return false, "Empty"
	end

	return true
end

local function iterItems(obj)
    local function iterator()
        for _, stack in pairs(obj.inventory) do
            local item = stack.object
            local count = math.abs(stack.count)
            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
					if data then
						coroutine.yield(item, data.count, data)
						count = count - data.count
					end
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

local function checkBarter(npc)
	local npcClass = npc.object.class
	if npcClass.bartersAlchemy or
	npcClass.bartersApparatus or
	npcClass.bartersArmor or
	npcClass.bartersBooks or
	npcClass.bartersClothing or
	npcClass.bartersEnchantedItems or
	npcClass.bartersIngredients or
	npcClass.bartersLights or
	npcClass.bartersLockpicks or
	npcClass.bartersMiscItems or
	npcClass.bartersProbes or
	npcClass.bartersRepairTools or
	npcClass.bartersWeapons then
		return(true)
	else
		return(false)
	end
end

-- nice try you cheeky bastard, not without a challenge
local function checkSpecial(npc)
	if npc.baseObject.id == "King Hlaalu Helseth" then 
		return true 
	else
		return false
	end	
end

-- Refresh the GUI with the currently available items.
local function refreshItemsList()
	-- Kill all our children.
	local contentBlock = pickpocketGUI:findChild(GUIID_Pickpocket_ContentBlock)
	contentBlock:destroyChildren()
	
	local nameLabel = pickpocketGUI:findChild(GUIID_Pickpocket_NameLabel)
	nameLabel.text = currentTarget.object.name
	
	local denyLabel = pickpocketGUI:findChild(GUIID_Pickpocket_DenyLabel)

	-- Check to see if we can loot the inventory.
	local canLoot, cantLootReason = canLootObject()
	if (not canLoot) then
		denyLabel.visible = true
		denyLabel.text = cantLootReason
		--contentBlock:createLabel({text = cantLootReason})
		pickpocketGUI:updateLayout()
		return
	else
		denyLabel.visible = false
	end
	
	pickpocketGUI.visible = false

	-- Clone the object if necessary.
	currentTarget:clone()
	
	-- Start going over the items in the object's inventory and making elements for them.
	currentIndex = nil
	local container = currentTarget.object
	
	--backup print for loaded inventories
	if (#container.inventory == 0) then
		contentBlock:createLabel({text = "Empty"})
		pickpocketGUI:updateLayout()
		return
	end
	
	local securitySkill = tes3.mobilePlayer.security.current
	local opponentSecuritySkill = currentTarget.mobile.security.current
	
	--local isGuard = currentTarget.object.isGuard
	local equipmentTable = {}
	local itemcount = 0
	local hiddenitems = 0
		
	for _,equipstack in pairs(container.equipment) do
		table.insert(equipmentTable, equipstack.itemData)
	end
	
	for item, count, data in iterItems(container) do
		local canPickpocket = false
		local isEquipped = false
		
		if table.find(equipmentTable, data) then
			--#mwse.log('%s %s',item.id,item.slot)
			--mwse.log(item.objectType)
			--slot nil = weapon, slot 8 = rings or shield, slot 9 = amulets
			if (item.slot == nil and config.allowWeaponTheft) or 
			(item.slot == 8 and tes3.objectType.armor == item.objectType and config.allowShieldTheft) or 
			((item.slot == 8 or item.slot == 9) and tes3.objectType.clothing == item.objectType and config.allowEquippedJewelryTheft) then
				isEquipped = true
				local valueMod = math.clamp((math.log(item.value)-2),1,2)
				local difficultyRating = (opponentSecuritySkill + item.weight + config.equipBonus) --* (valueMod) 
				--set merchant check
				if checkBarter(currentTarget) then
					difficultyRating = difficultyRating + config.merchantBonus
				end
				if checkSpecial(currentTarget) then
					difficultyRating = difficultyRating + 50
				end
				if difficultyRating <= securitySkill then
					canPickpocket = true
				else
					if (item.slot == 8) then
						--rings are always shown as hidden
						hiddenitems = hiddenitems + 1
					else 
						if (config.equippedItemHiddenCount == true) then
							hiddenitems = hiddenitems + 1
						end
					end
				end
			elseif (config.allowArmorTheft) == true then
				local difficultyRating = (opponentSecuritySkill + item.weight + config.equippedArmorBonus)
				isEquipped = true
				if checkBarter(currentTarget) then
					difficultyRating = difficultyRating + config.merchantBonus
				end
				if difficultyRating <= securitySkill then
					canPickpocket = true
				end
			end
			--mwse.log("%s is equipped!", item)
		else
			local difficultyRating = opponentSecuritySkill + item.weight
			if checkBarter(currentTarget) then
				difficultyRating = difficultyRating + config.merchantBonus
			end
			if difficultyRating <= securitySkill then
				canPickpocket = true
			else
				hiddenitems = hiddenitems + 1
			end
			
			--if sneakSitem.isKey == true then
			--	canPickpocket = true
			--end
		end
				
		if canPickpocket == true then
			itemcount = itemcount + 1
		
			-- Our container block for this item.
			local block = contentBlock:createBlock({})
			block.flowDirection = "left_to_right"
			block.autoWidth = true
			block.autoHeight = true
			block.paddingAllSides = 3
			if isEquipped == true then
				block:setPropertyBool("Pickpocket:Equipped", true)
			else
				block:setPropertyBool("Pickpocket:Equipped", false)
			end
				-- local newRect = block:createRect({color = tes3ui.getPalette("health_color")})
				-- newRect.width = 2
				-- newRect.height = 30
			-- else
				-- block:setPropertyBool("Pickpocket:Equipped", false)
			-- end
			

			-- Store the item/count on the block for later logic.
			block:setPropertyObject("Pickpocket:Item", item)
			block:setPropertyInt("Pickpocket:Count", math.abs(count))
			block:setPropertyInt("Pickpocket:Value", item.value)
			
			-- Item icon.
			local icon = block:createImage({id = GUIID_Pickpocket_ContentBlock_ItemIcon, path = "icons\\" .. item.icon})
			icon.borderRight = 5

			-- Label text
			local labelText = item.name
			if (math.abs(count) > 1) then
				labelText = labelText .. " (" .. math.abs(count) .. ")"
			end
			
			local label = block:createLabel({id = GUIID_Pickpocket_ContentBlock_ItemLabel, text = labelText})
			--label.color = tes3ui.getPalette("health_color")
			label.absolutePosAlignY = 0.5
		end
	end
	
	currentInventorySize = itemcount
	
	if ((itemcount == 0) and (hiddenitems == 0)) then
		contentBlock:createLabel({text = "Nothing to steal"})
		pickpocketGUI:updateLayout()
		return
	end
	
	if (hiddenitems ~= 0) then
		denyLabel.visible = true
		if (hiddenitems == 1) then
			hiddenText = hiddenitems .. " item beyond your skill"
		else
			hiddenText = hiddenitems .. " items beyond your skill"
		end
		denyLabel.text = hiddenText
		pickpocketGUI:updateLayout()
	end

	setSelectionIndex(1)
	
	pickpocketGUI:updateLayout()
end

-- Creates the GUI and populates it.
local function createpickpocketGUI()
	if (tes3ui.findMenu(GUIID_Pickpocket_Menu)) then
		refreshItemsList()
		return
	end

	--
	pickpocketGUI = tes3ui.createMenu({id = GUIID_Pickpocket_Menu, fixedFrame = true})
	pickpocketGUI.absolutePosAlignX = 0.1 * config.menuX
	pickpocketGUI.absolutePosAlignY = 0.1 * config.menuY
	
	--if tes3.mobilePlayer.isSneaking == false then
	--	pickpocketGUI.visible = false
	--else
	--	pickpocketGUI.visible = true
	--end
	--pickpocketGUI.visible = false	
	--
	
	local nameBlock = pickpocketGUI:createBlock({})
	nameBlock.autoHeight = true
	nameBlock.autoWidth = true
	nameBlock.paddingAllSides = 1
	nameBlock.childAlignX = 0.5
	local nameLabel = nameBlock:createLabel({id = GUIID_Pickpocket_NameLabel, text = ''})
	nameLabel.color = tes3ui.getPalette("header_color")
	nameBlock:updateLayout()
    nameBlock.widthProportional = 1.0
	pickpocketGUI.minWidth = nameLabel.width
	
	local denyBlock = pickpocketGUI:createBlock({})
	denyBlock.autoHeight = true
	denyBlock.autoWidth = true
	denyBlock.paddingAllSides = 1
	denyBlock.childAlignX = 0.5
	denyBlock:createLabel({id = GUIID_Pickpocket_DenyLabel, text = ''})
	denyBlock:updateLayout()
	denyBlock.widthProportional = 1.0
	
	local dotBlock = pickpocketGUI:createBlock({id = GUIID_Pickpocket_DotBlock})
	dotBlock.flowDirection = "top_to_bottom"
	dotBlock.widthProportional = 1.0
	dotBlock.autoHeight = true
	dotBlock.paddingAllSides = 3
	local dotLabel = dotBlock:createLabel({text = "..."})
	dotLabel.absolutePosAlignX = 0.5
	dotBlock.visible = false

	--
	local contentBlock = pickpocketGUI:createBlock({id = GUIID_Pickpocket_ContentBlock})
	contentBlock.flowDirection = "top_to_bottom"
	contentBlock.autoHeight = true
	contentBlock.autoWidth = true

	-- This is needed or things get weird.
	pickpocketGUI:updateLayout()

	refreshItemsList()
end

-- Clears the current menu.
local function clearPickpocketMenu()
	local destroyMenu = nil
	if (destroyMenu == nil) then
		destroyMenu = true
	end

	-- Clear the current target.
	currentTarget = nil
	currentInventorySize = nil

	if (destroyMenu and pickpocketGUI) then
		pickpocketGUI:destroy()
		pickpocketGUI = nil
	end
end

local function onUIObjectTooltip(e)
	if (config.modEnabled == true and config.hideTooltip == true and tes3.mobilePlayer.isSneaking) then
	   if e.reference ~= nil and e.reference.mobile ~= nil and e.reference.mobile.health.current > 0 then
			e.tooltip.maxWidth = 0
			e.tooltip.maxHeight = 0
		end
	end
end

-- Called when the player looks at a new object that would show a tooltip, or transfers off of such an object.
local function onActivationTargetChanged(e)
	-- Bail if we don't have a target or the mod is disabled.
	if config.modEnabled == false then
		return
	end
	
	-- Declone the inventory if they aren't opening the inventory
	if ( currentTarget ~= nil ) then
		currentTarget.object:onInventoryClose(currentTarget)
	end
	
	local newTarget = e.current

	local targetNil = (newTarget == nil)
	clearPickpocketMenu()
	
	if (targetNil) then
		return
	end
	
	--if tes3.mobilePlayer.isSneaking == false then
	--	return
	--end

	-- We only care about npcs.
	if (newTarget.object.objectType ~= tes3.objectType.npc) then
		return
	end
	
	-- You can't pickpocket the dead
	if (newTarget.mobile.health.current <= 0 ) then
		return
	end

	-- Don't loot containers if your hands are disabled
	if (tes3.mobilePlayer.attackDisabled) then
		return
	end
	
	currentTarget = newTarget
	createpickpocketGUI(newTarget)
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

-- unused at the moment
local function resetAlarm(pre)
	tes3.getPlayerTarget().mobile.alarm = pre
end

--makes NPCs react to Pickpocketing
local function crimeCheck(itemValue,currentTarget)

	
	--so many npcs have alarms of 0, its ridiculous
	if tes3.getPlayerTarget().mobile.alarm < 50 then
		tes3.getPlayerTarget().mobile.alarm = 50
	end
	
	crimeValue = config.pickpocketCrimeValue
	
	-- pickpocketCrimeValue sets a minimum
	if config.useItemValueCrime and (itemValue > config.pickpocketCrimeValue) then 
		crimeValue = itemValue 
	end
	
	tes3.triggerCrime({
		type = 5,
		value = crimeValue,
		victim=(tes3.getPlayerTarget())
		})
	--timer.delayOneFrame({callback = resetAlarm(pre)})
end

local function takeItem()
	local crimeValue = 0
	local invisFlag = false
	local block = pickpocketGUI:findChild(GUIID_Pickpocket_ContentBlock).children[currentIndex]
	
	if block ~= nil then
	
		-- remove player invisibility effect
		if tes3.mobilePlayer.invisibility == 1 then
			invisFlag = true
			tes3.removeEffects{reference=tes3.player, effect=tes3.effect.invisibility}
			if config.invisFix then tes3.mobilePlayer.invisibility = 0 end
		end
		
		tes3.worldController.mobController.processManager:detectPresence(tes3.mobilePlayer, true)

		crimeValue = crimeValue + (block:getPropertyInt("Pickpocket:Value") * block:getPropertyInt("Pickpocket:Count"))
		
		-- if (block:getPropertyBool("Pickpocket:Equipped") and block:getPropertyObject("Pickpocket:Item").objectType == tes3.objectType.weapon and config.weaponTheftCrime) then
			-- tes3.triggerCrime({
				-- forceDetection = true,
				-- type = 5,
				-- value = crimeValue,
				-- victim=(tes3.getPlayerTarget())
			-- })
			-- return
		-- else
		crimeCheck(crimeValue,currentTarget)
		--end
		
		-- reset the invisibility flag, as this will get decremented naturally on the next frame
		if invisFlag and config.invisFix then tes3.mobilePlayer.invisibility = 1 end
		
		if ( tes3ui.findMenu(GUI_Pickpocket_multi):findChild(GUI_Pickpocket_sneak).visible == false ) then
			return
		end
		
		tes3.setItemIsStolen({ item = block:getPropertyObject("Pickpocket:Item"), from = currentTarget.baseObject, stolen = true })
		tes3.transferItem({
			from = currentTarget,
			to = tes3.player,
			item = block:getPropertyObject("Pickpocket:Item"),
			count = block:getPropertyInt("Pickpocket:Count"),
		})

		tes3.mobilePlayer:exerciseSkill(tes3.skill.security, config.pickpocketExpValue)
		
		if config.showMessageBox == true then
			tes3.messageBox({ message = "Looted " .. block:getPropertyInt("Pickpocket:Count") .. " " .. block:getPropertyObject("Pickpocket:Item").name })
		end

		local preservedIndex = currentIndex
		refreshItemsList()
		setSelectionIndex(math.clamp(preservedIndex, 1, currentInventorySize))
		
	end
end

local function stealItem()
	if (not canLootObject()) then
		return
	end
	
	if config.modEnabled == false then
		return
	end
	
	if currentTarget == nil then
		return
	end
	
	if tes3.mobilePlayer.isSneaking == true then
		takeItem()
		return false
	end
end

local function sneakChecker()
	if tes3.mobilePlayer.isSneaking == false then
		--clearPickpocketMenu()
		if pickpocketGUI ~= nil then
			pickpocketGUI.visible = false
		end
	else
		if pickpocketGUI ~= nil then
			pickpocketGUI.visible = true
		end
	end
end


-- welcome to my underground lair
-- this is a wip of a stealth overhaul I'm leaving in here as a bonus to any intrepid coders
-- the structure is entirely from nullcascade with a few changes from me
-- mess with it if you want!

-- local function vanillaDetectSneak(e)
	-- local macp = tes3.mobilePlayer
	-- if (e.target ~= macp) then
		-- return
	-- end

	-- local detector = e.detector

	-- -- Get view multiplier.
	-- local viewMultiplier = tes3.findGMST(tes3.gmst.fSneakNoViewMult).value
	-- local facingDifference = math.abs(detector:getViewToActor(macp))
	-- if (facingDifference > 270 or facingDifference < 90) then
		-- viewMultiplier = tes3.findGMST(tes3.gmst.fSneakViewMult).value
	-- end

	-- -- Add bonuses for sneaking.
	-- local playerScore = 0
	-- if (macp.isSneaking) then
		-- local fSneakSkillMult = tes3.findGMST(tes3.gmst.fSneakSkillMult).value
		-- local sneakTerm = macp.sneak.current * fSneakSkillMult
		-- local agilityTerm = macp.agility.current * 0.2
		-- local luckTerm = macp.luck.current * 0.1
		-- playerScore = playerScore + sneakTerm + agilityTerm + luckTerm
	-- end

	-- -- Adjust for player's boot weight.
	-- playerScore = playerScore + macp:getBootsWeight() * tes3.findGMST(tes3.gmst.fSneakBootMult).value

	-- -- Get distance term.
	-- local fSneakDistanceBase = tes3.findGMST(tes3.gmst.fSneakDistanceBase).value
	-- local fSneakDistanceMultiplier = tes3.findGMST(tes3.gmst.fSneakDistanceMultiplier).value
	-- local distanceTerm = fSneakDistanceBase + detector.reference.position:distance(macp.reference.position) * fSneakDistanceMultiplier

	-- -- Multiply main terms together.
	-- local fatigueTerm = macp:getFatigueTerm()
	-- playerScore = playerScore * fatigueTerm * distanceTerm

	-- -- Add on chameleon and invisibility modifiers.
	-- playerScore = playerScore + macp.chameleon
	-- if (macp.invisibility > 0) then
		-- playerScore = playerScore + 100
	-- end

	-- -- Get detector score.
	-- local detectorScore = (detector.sneak.current
			-- + detector.agility.current * 0.2
			-- + detector.luck.current * 0.1
			-- - detector.blind)
		-- * viewMultiplier * detector:getFatigueTerm()

	-- -- Set detection flags.
	-- local finalScore = playerScore - detectorScore
	-- local randNum = math.random(10,50)
	-- local detected = randNum >= finalScore
	-- detector.isPlayerDetected = detected
	-- detector.isPlayerHidden = not detected

	-- tes3.messageBox("%s %s %d %.1f", detector.reference, detected, randNum, finalScore )
	-- -- Let the event know to return the right value.
	-- e.isDetected = detected
	-- playerSpotted = e.isDetected
-- end


local function onInitialized()

	-- Register necessary GUI element IDs.
	GUI_Pickpocket_multi = tes3ui.registerID("MenuMulti")
	GUI_Pickpocket_sneak = tes3ui.registerID("MenuMulti_sneak_icon")
	GUIID_Pickpocket_ContentBlock = tes3ui.registerID("Pickpocket:ContentBlock")
	GUIID_Pickpocket_NameLabel = tes3ui.registerID("Pickpocket:NameLabel")
	GUIID_Pickpocket_DenyLabel = tes3ui.registerID(("Pickpocket:DenyLabel"))
	GUIID_Pickpocket_DotBlock = tes3ui.registerID("Pickpocket:DotBlock")
	GUIID_Pickpocket_ContentBlock_ItemIcon = tes3ui.registerID("Pickpocket:ContentBlock:ItemIcon")
	GUIID_Pickpocket_ContentBlock_ItemLabel = tes3ui.registerID("Pickpocket:ContentBlock:ItemLabel")
	GUIID_Pickpocket_Menu = tes3ui.registerID("Pickpocket:Menu")

	-- Register the necessary events to get going.
	event.register("activationTargetChanged", onActivationTargetChanged)
	event.register("uiObjectTooltip", onUIObjectTooltip)
	event.register("activate", stealItem)
	event.register("simulate", sneakChecker)
	event.register("mouseWheel", onMouseWheelChanged)
	event.register("menuEnter", clearPickpocketMenu)
	--event.register("detectSneak", vanillaDetectSneak)

	mwse.log("[Pickpocket] Initialized.")
end
event.register("initialized", onInitialized)

---
--- Mod Config
---

local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Pickpocket")
	template:saveOnClose("mortPickpocket", config)
	
    local page = template:createPage()
    local categoryMain = page:createCategory("Settings")
	categoryMain:createYesNoButton{ label = "Enable Pickpocket",
								variable = createtableVar("modEnabled"),
								defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Hide NPC tooltips while pickpocketing (only if you are already sneaking)",
								variable = createtableVar("hideTooltip"),
								defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Count equipped weapons/shields in the 'hidden' count",
								variable = createtableVar("equippedItemHiddenCount"),
								defaultSetting = false}
								
	categoryMain:createYesNoButton{ label = "Force stealth check immediately after breaking stealth. Mandatory for game balance.",
								variable = createtableVar("invisFix"),
								defaultSetting = true}


	categoryMain:createSlider{ label = "Added difficulty of stealing equipped jewelry/weapons/shields",
						variable = createtableVar("equipBonus"),
						max = 100,
						jump = 1,
						defaultSetting = 50}
						
	categoryMain:createSlider{ label = "Merchant bonus to detect pickpockets",
						variable = createtableVar("merchantBonus"),
						max = 100,
						jump = 1,
						defaultSetting = 40}
						
	categoryMain:createYesNoButton{ label = "Allow stealing of equipped weapons (more realistic than armor, semi-unbalanced)",
								variable = createtableVar("allowWeaponTheft"),
								defaultSetting = false}

	-- categoryMain:createYesNoButton{ label = "Taking a weapon is always noticed (does nothing without above setting)",
								-- variable = createtableVar("weaponTheftCrime"),
								-- defaultSetting = true}
								
	categoryMain:createYesNoButton{ label = "Allow stealing of equipped shields (enable this to get Auriel's Shield)",
								variable = createtableVar("allowShieldTheft"),
								defaultSetting = false}
								
	categoryMain:createYesNoButton{ label = "Allow stealing of equipped jewelry",
								variable = createtableVar("allowEquippedJewelryTheft"),
								defaultSetting = true}								
						
	categoryMain:createYesNoButton{ label = "Allow stealing of equipped armor (warning: probably unrealistic but very funny)",
								variable = createtableVar("allowArmorTheft"),
								defaultSetting = false}				

	categoryMain:createSlider{ label = "Added difficulty of stealing equipped armor (does nothing without the above setting)",
						variable = createtableVar("equippedArmorBonus"),
						max = 300,
						jump = 10,
						defaultSetting = 50}
								
	categoryMain:createSlider{ label = "Number of items displayed by default",
						variable = createtableVar("maxItemDisplaySize"),
						max = 20,
						jump = 1,
						defaultSetting = 10}
						
	categoryMain:createSlider{ label = "Pickpocket crime value",
						variable = createtableVar("pickpocketCrimeValue"),
						max = 500,
						jump = 5,
						defaultSetting = 25}
						
	categoryMain:createYesNoButton{ label = "Use Item Value as bounty amount on failed stealth check (uses pickpocket crime value above as minimum)",
								variable = createtableVar("useItemValueCrime"),
								defaultSetting = false}		

	categoryMain:createSlider{ label = "Pickpocket experience value",
						variable = createtableVar("pickpocketExpValue"),
						max = 10,
						jump = 1,
						defaultSetting = 2}
	
	categoryMain:createSlider{ label = "Menu X position (higher = right)",
						variable = createtableVar("menuX"),
						max = 10,
						jump = 1,
						defaultSetting = 6}
						
	categoryMain:createSlider{ label = "Menu Y position (higher = down)",
						variable = createtableVar("menuY"),
						max = 10,
						jump = 1,
						defaultSetting = 4}

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)