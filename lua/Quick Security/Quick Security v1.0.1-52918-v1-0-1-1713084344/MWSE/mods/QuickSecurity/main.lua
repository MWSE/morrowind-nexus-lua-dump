--[[
	Quick Security
	@author		
	@version	1.0.1
	@changelog	1.0.0 Initial version
	@changelog	1.0.1 Activate mod at the first addition in the journal, so after char generation (issues/1) and off center menu (issues/2)
    
	TODO check behaviour with Equip Script fix in MCP https://mwse.github.io/MWSE/references/code-patch-features/
	TODO Restore weapon when another target is activated (! nil) if previously selected tool is stil equipped, add an option to disable this behavior ?

--]]

-- mod informations
local modName = "Quick Security"
local modFolder = "QuickSecurity"	-- this way can have a different name for the mod folder
local modVersion = "V1.0.1"
local modConfig = modName	-- file name for MCM config file
local modAuthor= "Thinuviel"


-- Keep track of all the GUI IDs we care about.
local GUIID_Menu = nil
local GUIID_TestUI_TitleBlock = nil
local GUIID_TestUI_ContentBlock = nil
local GUIID_TestUI_ItemBlock = nil

-- TODO rename
local currentMenu = {
	itemsCount = 0,
	currentIndex = 0,
	window = nil,
	--
	isWeaponAStateStored=false,	-- set to true if trapped
	weapon = nil,
	-- tes3mobilePlayer properties https://mwse.github.io/MWSE/types/tes3mobilePlayer/
	weaponDrawn = false,
	weaponReady = false,
	castReady = false,
	--
	isEquipping = false,
	isProbe = false,
	currentEquippedTool = nil,	-- currently equipped tool (probe/lockpick) or nil
}

-- keep information about the target (container/door trapped or locked or both)
local currentTarget = {
	target = nil,
	isTrapped = false,
	isLocked = false,
	isClosing = false,	-- closing the menu ?
}

local playerAttribute = {
	agility = 0,
	luck = 0,
	security = 0,
	-- security ratio
	securityRatio = 0,
	-- fatigue status
	currentFatigue = 0,
	maxFatigue = 0,
	fatigueTerm = 0,
	fullFatigueTerm = 0,
	-- static GMST values 
	gmstOk=false,
	fTrapCostMult = 0,
	fFatigueBase = 0,
	fFatigueMult = 0,
	fPickLockMult = 0
}

local activatemod = false	-- to prevent mod activation before character creation

--[[

	Mod translation
	https://mwse.github.io/MWSE/guides/mod-translations/
	
]]--

-- returns a table of transation, you acces a translation by its key: i18n("HELP_ATTACKED")
local i18n = mwse.loadTranslations(modFolder)


--[[

	mod config

]]

--#region mod config


-- Define mod config default values
local modDefaultConfig = {
	modEnabled = true,
	--
	useWorstCondition = true,	-- true => use worst condition tool (already used), false best condution (maybe put a 3 states value: worst, don't care, best)
    diplayChance = true,
	selectUsableFullFatigue = false,	-- select also tools *usable* only with full fatigue (or fatigue higher than current fatigue)
	hintKeyExists = false,
	usePlayerKey = true,	-- if the player has the key to unlock, don't open lockpick menu
	selectionKey = {
	    keyCode = tes3.scanCode.space,
	    isShiftDown = false,
	    isAltDown = false,
	    isControlDown =false
	},
	--
	debugMode = false,	-- true for debugging purpose should be false for mod release, it could be a MCM option, currently you have to change its value in the config file
}


-- Load config file, and fill in default values for missing elements.
local config = mwse.loadConfig(modConfig)
if (config == nil) then
	config = modDefaultConfig
else
	for key, value in pairs(modDefaultConfig) do
		if (config[key] == nil) then
			config[key] = value
		end
	end
end

--#endregion


--[[

		Helper functions

]]--


---Log a string as Info level in MWSE.log
---@param msg string to be logged as INFO in MWSE.log
local function logInfo(msg)
	-- https://www.lua.org/pil/5.2.html
	-- TODO get ride of string.format in calling 
	--s = string.format('[' .. modName .. '] ' .. 'INFO ' .. fmt, unpack(arg))
	--mwse.log(s)
	mwse.log('[' .. modName .. '] ' .. 'INFO ' .. msg)
end


---Log a message to MWSE.log if debug mode is enabled
---@param msg string to be logged as DEBUG in MWSE.log
local function logDebug(msg)
	if (config.debugMode) then
		mwse.log('[' .. modName .. '] ' .. 'DEBUG ' .. msg)
	end
end


---Log an error message to MWSE.log
---@param msg string to be logged as ERROR in MWSE.log
-- TODO https://stackoverflow.com/questions/4021816/in-lua-how-can-you-print-the-name-of-the-current-function-like-the-c99-func
local function logError(msg)
	mwse.log('[' .. modName .. '] ' .. 'ERROR ' .. msg)
end


---Returns a table with sorted index of tbl https://stackoverflow.com/a/24565797
---@param tbl table table to order
---@param sortFunction function sorting function
---@return table table of ordered reference of tbl
local function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)

	return keys
end


---Update the currentIndex by moving to the next tool/item
local function nextTool()
	if currentMenu.itemsCount < 1 then
		logError("(nextTool) Try to get the next item but there are no items")
	end

	if currentMenu.currentIndex == currentMenu.itemsCount then
		currentMenu.currentIndex = 1
	else
		currentMenu.currentIndex = currentMenu.currentIndex + 1
	end
end


---Update currentIndex by moving to the previous tool/item
local function previousTool()
	if currentMenu.itemsCount < 1 then
		logError("(previousTool) Try to get the previous item but there are no items")
	end

	if currentMenu.currentIndex == 1 then
		currentMenu.currentIndex = currentMenu.itemsCount
	else
		currentMenu.currentIndex = currentMenu.currentIndex - 1
	end
end


--- Compute and save current player stats in playerAttribute structure
local function getPlayerStats()
	-- skill and attributes
	local player = tes3.mobilePlayer

	playerAttribute.security = player.security.current
	playerAttribute.agility = player.agility.current
	playerAttribute.luck = player.luck.current

	playerAttribute.currentFatigue = player.fatigue.current
	playerAttribute.maxFatigue = player.fatigue.base

	-- static values
	if not playerAttribute.gmstOk then
		playerAttribute.fTrapCostMult = tes3.findGMST(tes3.gmst.fTrapCostMult).value
		playerAttribute.fFatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value
		playerAttribute.fFatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value
		playerAttribute.fPickLockMult = tes3.findGMST(tes3.gmst.fPickLockMult).value
		playerAttribute.gmstOk = true
	end

	-- https://mwse.github.io/MWSE/types/tes3mobilePlayer/?h=mobile+player#getfatigueterm
	playerAttribute.fatigueTerm = playerAttribute.fFatigueBase - playerAttribute.fFatigueMult * (1 - playerAttribute.currentFatigue / playerAttribute.maxFatigue)
	playerAttribute.fullFatigueTerm = playerAttribute.fFatigueBase
	-- compute *security ratio* used in chance computation
	playerAttribute.securityRatio = (playerAttribute.agility/5 + playerAttribute.luck/10 + playerAttribute.security)
end


---Compute the chance to unlock a door/container given the toolQuality and the locklevel in parameter
---@param toolQuality number quality of the lockpick
---@param locklevel number level of the lock (0?-100)
---@return number curChance, number fullChance returns the chance to unlock the object with current and full fatigue (can be negative)
local function getUnlockChance(toolQuality, locklevel)
	-- Lockpick
	-- x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
	-- x *= pickQuality * fatigueTerm
	-- x += fPickLockMult * lockStrength

	getPlayerStats()

	local curChance = playerAttribute.securityRatio * toolQuality * playerAttribute.fatigueTerm + playerAttribute.fPickLockMult * locklevel
	local fullChance = playerAttribute.securityRatio * toolQuality * playerAttribute.fullFatigueTerm + playerAttribute.fPickLockMult * locklevel
	logDebug(string.format("Unlock chance: %.2f - %.2f", curChance, fullChance))
	-- Don't cap negative curChance to 0 because it is used to sort lockpicks later
	return curChance, fullChance
end


---Compute the chance to disarm a door/container given the probe quality and the magickaCost in parameter
---@param toolQuality number quality of the probe
---@param magickaCost number *level* of the trap
---@return number curChance, number fullChance returns the chance to disarm the trap with current and full fatigue
local function getDisarmChance(toolQuality, magickaCost)
	-- Disarm
	-- x = 0.2 * pcAgility + 0.1 * pcLuck + securitySkill
	-- x += fTrapCostMult * trapSpellPoints
	-- x *= probeQuality * fatigueTerm

	getPlayerStats()

	local curChance = (playerAttribute.securityRatio + (playerAttribute.fTrapCostMult * magickaCost)) * toolQuality * playerAttribute.fatigueTerm
	local fullChance = (playerAttribute.securityRatio + (playerAttribute.fTrapCostMult * magickaCost)) * toolQuality * playerAttribute.fullFatigueTerm
	logDebug(string.format("Disarm chance: %.2f - %.2f", curChance, fullChance))
	return curChance, fullChance
end


---Search in the inventory for lockpicks or probes with a non negative chance to unlock
---@param searchForProbes boolean true to search for probes, false to search for lockpicks
---@param level number level of the trap (magickaCost) or of the lock
---@return table unsorted table of tables with one entry par tool with quality information, can be nil if no tool found
local function searchTools(searchForProbes, level)

	---Check if the object is of the type searched (probe or lockpick)
	---@param object any object found in inventory
	---@return boolean returns true if it's a searched object type
	local function isSearchedTool(object)
		if searchForProbes then
			return (object.objectType == tes3.objectType.probe)
		else
			return (object.objectType == tes3.objectType.lockpick)
		end
	end

	---Returns the chance to unlock/disarm from the quality of the object
	---@param quality number quality of the object
	---@return number curChance, number fullChance returns chance at current and full fatigue
	local function computeChange(quality)
		if searchForProbes then
			return getDisarmChance(quality, level)
		else
			return getUnlockChance(quality, level)
		end
	end

	local inventory = tes3.player.object.inventory
	local toolsTable = {}
	for _, stack in pairs(inventory) do
		-- stack = tes3itemStack (https://mwse.github.io/MWSE/types/tes3itemStack/)
		if not isSearchedTool(stack.object) then
			goto continue
		end

		local tool = stack.object	-- tes3lockpick or tes3probe
		local toolName = tool.name

		-- compute chance current, max fatique
		local curChance, fullChance = computeChange(tool.quality)
		-- option to select object usable at full fatigue
		if config.selectUsableFullFatigue then
			if fullChance <=0 then goto continue end
		else
			if curChance <= 0 then goto continue end
		end

		if (toolsTable[toolName] == nil) then
			toolsTable[toolName]={}
			toolsTable[toolName].name = toolName
			toolsTable[toolName].tool = tool
			toolsTable[toolName].count = stack.count
			toolsTable[toolName].curChance = curChance
			toolsTable[toolName].fullChance = fullChance

			if searchForProbes then
				toolsTable[toolName].type = tes3.objectType.probe
			else
				toolsTable[toolName].type = tes3.objectType.lockpick
			end

			logDebug(string.format("searchTools: Adding %d %s - %p (%.2f - %.2f)",stack.count, toolName, tool, curChance, fullChance))
		end

		--MUST BE just before the end of the for loop: No continue in Lua :(
	    ::continue::
	end
	return toolsTable
end


---Store player weapon information and status
local function storeWeapon()
	-- Test on isWeaponAStateStored
	if  currentMenu.isWeaponAStateStored then
		logError(string.format("storeWeapon: Weapon aldeady stored %s - %p", currentMenu.weapon, currentMenu.weapon))
	end
	-- TODO better object retrieval (torch, lockpick)
	-- https://mwse.github.io/MWSE/apis/tes3/?h=get+equipped+item#tes3getequippeditem
	-- returns tes3equipmentStack https://mwse.github.io/MWSE/types/tes3equipmentStack/
	local equipStack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon })
	if (equipStack) then
		currentMenu.weapon = equipStack.object
	end

	currentMenu.weaponReady = tes3.mobilePlayer.weaponReady
	currentMenu.castReady = tes3.mobilePlayer.castReady
	currentMenu.isWeaponAStateStored = true

	logDebug(string.format("storeWeapon %s - %p", currentMenu.weapon, currentMenu.weapon))
end


---Restore the weapon and weaponDrawn state before the tool equipping
local function restoreWeapon()
	logDebug(string.format("restoreWeapon %s - %p", currentMenu.weapon, currentMenu.weapon))

	if currentMenu.isWeaponAStateStored then
		logDebug(string.format("restoreWeapon: isWeaponAStateStored"))

		currentMenu.currentEquippedTool = nil
		-- need a timer to give time to unequip the probe/lockpick
		-- TODO secure it by cancelling when there is already a timer started

		-- DEBUG test unequip first
		tes3.mobilePlayer.weaponReady = false
		tes3.mobilePlayer.castReady = false
		local objectType
		logDebug(string.format("restoreWeapon currentMenu.isProbe %s", currentMenu.isProbe))

		if currentMenu.isProbe then
			objectType = tes3.objectType.probe
		else
			objectType = tes3.objectType.lockpick
		end
		tes3.mobilePlayer:unequip({ type = objectType})

		-- https://mwse.github.io/MWSE/apis/timer/#timerstart
		timer.start({
			duration = .5,
			iterations = 1,
			callback = function()
				tes3.mobilePlayer:equip({ item = currentMenu.weapon, selectBestCondition = true })
				tes3.mobilePlayer.castReady = currentMenu.castReady
				tes3.mobilePlayer.weaponReady = currentMenu.weaponReady
				currentMenu.isWeaponAStateStored = false
				logDebug(string.format("restoreWeapon: timer callback"))
			end
		})
	end
end


--- Reset the current target to no target
local function resetCurrentTarget()
	logDebug(string.format("Reset current target"))
	currentTarget.target = nil
	currentTarget.isTrapped = false
	currentTarget.isLocked = false
end


--[[

	UI functions
	Menu structure
	+--------------------------+
	|+------------------------+|
	||        Label           || GUIID_TestUI_NameLabel
	|+------------------------+|
	|+------------------------+|
	||     Tools block        || GUIID_TestUI_ContentBlock
	||+----------------------+||
	|||     item block       |||
	|||+---++---------------+|||
	|||| i ||    label      ||||
	|||+---++---------------+|||
	||+----------------------+||
	||+----------------------+||
	|||     item block       |||
	|||+---+ +--------------+|||
	|||| i ||    label      ||||
	|||+---+ +--------------+|||
	||+----------------------+||
	|+------------------------+|
	+--------------------------+

    Menu
        titleBlock
			titleLabel
        toolsListBlock (GUIID_TestUI_ContentBlock)
            Tool block
                Tool icon block
                Tool label block

]]

-- TODO try to reorganize functions to remove forward functions declaration
local onMouseWheel, destroyWindow

-- https://mwse.github.io/MWSE/events/uiActivated/#event-data
local function uiActivatedCallback(e)
	logDebug(string.format("uiActivatedCallback %s", e.element))
end


---Equip the selected tool in the menu
local function equipSelectedTool()

    ---Retrieve the selected tool from the menu
	---@return any tool selected (highligthed) tool in the menu
	local function retrieveSelectedTool()
        -- retrieve the block containing the items
        -- TODO put and retrieve in currentMenu (same for other GUID)
        local menu = tes3ui.findMenu(GUIID_Menu)
        local contentBlock = menu:findChild (GUIID_TestUI_ContentBlock)
        local selectedBlock = contentBlock.children[currentMenu.currentIndex]

        -- https://mwse.github.io/MWSE/types/tes3uiElement/?h=create+block#getpropertyobject
        -- retrieve the tool reference
        return selectedBlock:getPropertyObject(modName .. ":Item")
    end

	---Retrieve the isProbe flag that define if the menu is about probe (true) or lockpick (false) from the title block
	---@return boolean return the kind of tool in the menuprobe (true) or lockpick (false)
	local function getIsProbe()
		local menu = tes3ui.findMenu(GUIID_Menu)
		local titleBlock = menu:findChild(GUIID_TestUI_TitleBlock)
		return titleBlock:getPropertyBool(modName .. ":isProbe")
	end

	-- already equipping
	if currentMenu.isEquipping then
		return
	end

	currentMenu.isEquipping = true

    local item = retrieveSelectedTool()
    logDebug(string.format("equipSelectedTool: selected item %s", item))

	currentMenu.currentEquippedTool = item
	currentMenu.isProbe= getIsProbe()

	-- TODO need to track the right weapon as when you pass from trapped to locked, the equipped will be the probe not the initial weapon same for weaponDrawn
	-- keep track of the already equipped weapon
    if not currentMenu.isWeaponAStateStored then
		storeWeapon()
    end

	-- equip it
	tes3.mobilePlayer.castReady = false
	-- switch to ready mode
	-- https://mwse.github.io/MWSE/types/tes3mobilePlayer/?h=weapondrawn#weaponready
	tes3.mobilePlayer.weaponReady = true

	timer.start({
		duration = .3,
		iterations = 1,
		callback = function()
			-- https://mwse.github.io/MWSE/types/tes3mobilePlayer/#equip
			logDebug(string.format("equipSelectedTool: timer callback"))

			if config.useWorstCondition then
				tes3.mobilePlayer:equip({ item = item, selectWorstCondition = true })
			else
				tes3.mobilePlayer:equip({ item = item, selectBestCondition = true })
			end
			currentMenu.isEquipping = false
		end
	})
end


--- Highlight the tool associated to the currentIndex in the menu
local function highLightTool()
	-- retrieve the block containing the items
	local menu = tes3ui.findMenu(GUIID_Menu)

	local contentBlock = menu:findChild(GUIID_TestUI_ContentBlock)
	local children = contentBlock.children

	-- iterate on blocks
	for i, block in pairs(children) do
		local label = block:findChild(GUIID_TestUI_ItemBlockLabel)
		local curChance = label:getPropertyFloat(modName .. ":curChance")

		-- https://mwse.github.io/MWSE/apis/tes3ui/?h=getpal#tes3uigetpalette
		if (i == currentMenu.currentIndex) then
			if curChance <= 0 then
				label.color = tes3ui.getPalette("answer_color")
			else
				label.color = tes3ui.getPalette("active_color")
			end
		else
			if curChance <= 0 then
				-- for the case to display usable at full fatique tool
				label.color = tes3ui.getPalette("negative_color")
			else
				label.color = tes3ui.getPalette("normal_color")
			end
		end
	end

	-- update the display
	contentBlock:updateLayout()
end


--Update the menu title depending on the type of tool in parameter
---@param isProbe boolean true if looking for probe false for lockpick
local function updateTitle(isProbe)
	local menu = tes3ui.findMenu(GUIID_Menu)

	local titleBlock = menu:findChild(GUIID_TestUI_TitleBlock)

	-- store the type of tool
	titleBlock:setPropertyBool(modName .. ":isProbe", isProbe)

	-- only one child
	local titleLabel = titleBlock.children[1]
	if isProbe then
		titleLabel.text = i18n("Menu.title_probe")
	else
		titleLabel.text = i18n("Menu.title_lockpick")
	end

	titleLabel:updateLayout()
end


---Create the menu with the tools list from the table in parameter
---@param toolsTable table of tools to display (MUST NOT BE EMPTY)
local function createWindow(toolsTable)
	if tes3.menuMode() then
		return
	end

	logDebug(string.format("createWindow"))

	if (tes3ui.findMenu(GUIID_Menu)) then
        return
    end

	local next = next
	if next(toolsTable) == nil then
        logError("createWindow: list of tools MUST NOT BE EMPTY")
        return
	end

	-- Create window and frame (off center)
	local menu = tes3ui.createMenu{ id = GUIID_Menu, fixedFrame = true }
	menu.absolutePosAlignX = 0.6 --DEJEDIT
	menu.absolutePosAlignY = 0.6 --DEJEDIT
	currentMenu.window = menu

	-- To avoid low contrast, text input windows should not use menu transparency settings
	menu.alpha = 1.0

	-- Create layout (update title later)
	local titleBlock = menu:createBlock({ id = GUIID_TestUI_TitleBlock })
	titleBlock.autoHeight = true
	titleBlock.autoWidth = true
	titleBlock.paddingAllSides = 1
	titleBlock.childAlignX = 0.5

	local titleLabel = titleBlock:createLabel({ text = '' })
	titleLabel.color = tes3ui.getPalette("header_color")
	titleBlock:updateLayout()
    titleBlock.widthProportional = 1.0
	menu.minWidth = titleLabel.width

	local toolsListBlock = menu:createBlock{ id = GUIID_TestUI_ContentBlock }
	toolsListBlock.autoWidth = true
	toolsListBlock.autoHeight = true
	toolsListBlock.flowDirection = "top_to_bottom"

	local itemsCount = 0
    local sortedKeys = getKeysSortedByValue(toolsTable, function(a, b) return a.curChance < b.curChance end)
    for _,v in pairs(sortedKeys) do
		-- Our container block for this item.
		local toolBlock = toolsListBlock:createBlock({ id = GUIID_TestUI_ItemBlock })
		toolBlock.flowDirection = "left_to_right"
		toolBlock.autoWidth = true
		toolBlock.autoHeight = true
		toolBlock.paddingAllSides = 3

		-- Store the item info on the toolBlock for later logic.
		-- https://mwse.github.io/MWSE/types/tes3uiElement/?h=set+property+object#setpropertyobject
		toolBlock:setPropertyObject(modName .. ":Item", toolsTable[v].tool)

		-- Item icon block
		local icon = toolBlock:createImage({path = "icons\\" .. toolsTable[v].tool.icon})
		icon.borderRight = 5

		-- Compute Item label text
		local labelText = toolsTable[v].name
		if toolsTable[v].count > 1 then
			labelText = labelText .. string.format(" (%d)", toolsTable[v].count)
		end
		if config.diplayChance then
			-- display only curChance when selectUsableFullFatigue = false ?
			labelText = labelText .. string.format(" %.f%% / %.f%%", math.max(0, toolsTable[v].curChance), toolsTable[v].fullChance)
		end

		-- add the GUIID for later selection job
		local label = toolBlock:createLabel({id = GUIID_TestUI_ItemBlockLabel, text = labelText})

		-- add curChance property for label color later
		label:setPropertyFloat(modName .. ":curChance", toolsTable[v].curChance)

		label.absolutePosAlignY = 0.5

		itemsCount = itemsCount + 1
    end

	currentMenu.itemsCount = itemsCount
	currentMenu.currentIndex = 1

	-- Final setup
	menu:updateLayout()
	highLightTool()

	-- events only registered during the life of the menu to ease events management and reduce mod incompatibility
	event.register(tes3.event.mouseWheel, onMouseWheel)
	event.register(tes3.event.uiActivated, uiActivatedCallback)
end


--- Destroy the menu if it exists
destroyWindow=function()
	local menu = tes3ui.findMenu(GUIID_Menu)

	logDebug("destroyWindow")

	if (menu) then
		logDebug("Destroy existing Menu")
		-- unregister events registered only for the life of the menu 
		-- https://mwse.github.io/MWSE/apis/event/#eventunregister
		event.unregister(tes3.event.mouseWheel, onMouseWheel)
		event.unregister(tes3.event.uiActivated, uiActivatedCallback)

        menu:destroy()

		currentMenu.window = nil
    end
end


--[[

	event handlers

]]

--#region events handler


-- https://mwse.github.io/MWSE/apis/event/#eventregister
local function onKeyDown(e)
	if tes3ui.findMenu(GUIID_Menu) ~= nil then
		logDebug("Event onKeyDown")
		if not currentTarget.isClosing then
			equipSelectedTool()
			currentTarget.isClosing = true
			--DEBUG test avec delai après équipement
			--TODO better test in case of multiple events
			-- timer.start({
			-- 	duration = .5,
			-- 	iterations = -1,
			-- 	callback = function()
					destroyWindow()
					currentTarget.isClosing = false
			-- 	end
			-- })
		end
	end
end


--- You NEED to destroy your menu when entering menu mode to avoid locking the UI
-- https://mwse.github.io/MWSE/events/menuEnter/
---@param e any event object for menuEnter
local function onMenuEnter(e)
	logDebug(string.format("onMenuEnter"))
	destroyWindow()
end


---DEBUG delete after tests
---https://mwse.github.io/MWSE/events/lockPick/
local function onLockPick(e)
	logDebug(string.format("Event lockPick - %s (%.2f)", e.tool, e.chance))
end

---DEBUG delete after tests
---https://mwse.github.io/MWSE/events/trapDisarm/
local function onTrapDisarm(e)
	logDebug(string.format("Event trapDisarm - %s (%.2f)", e.tool, e.chance))
end


---https://mwse.github.io/MWSE/events/journal/
---Called for the first journal event (1st addition to the journal)
---@param e any journal object event
local function onJournal(e)
	activatemod = true
	-- no need journal events anymore
	event.unregister("journal", onJournal)
end


--- https://mwse.github.io/MWSE/events/loaded/
---Disable mod on new games 
---@param e any loaded object event
local function onLoaded(e)
	if e.newGame then
		activatemod = false
		-- register journal event to detect first addition to the journal
		event.register("journal", onJournal)
	else
		activatemod = true
	end
end


---https://mwse.github.io/MWSE/events/activate/
---Prevent the activation of the trap when equipping a probe
---@param e any onActivate object
---@return any false when equipping tool to cancel the event
local function onActivate(e)
	logDebug(string.format("Event onActivate - activator  %s, target  %s", e.activator, e.target))

	-- We only care if the player is activating something
	if (e.activator ~= tes3.player) then
		return
	end

	-- and if the target is the current target
	if (e.target ~= currentTarget.target) then
		return
	end

	-- if equipping not completed => stop the event to prevent trap activation
	if (currentMenu.isEquipping) then
		return false
	end
end


---Update the selected tool in the menu depending on mousewheel direction
---@param e any mousewheel event
onMouseWheel = function(e)
	-- event registered only when menu is displayed so prerequisites checking is reduced

	-- Change the selected tool depending on mousewheel direction (delta)
	if e.delta > 0 then
		previousTool()
	else
		nextTool()
	end

	-- Update display
	highLightTool()
end


---Search for lockpicks for the given target and if any open the selection menu
---@param target any locked door/container
local function getLockpick(target)

	-- TODO returns key instead ?
	---Check if a key exists for this door/container
	---@return boolean true is there is a key to open the door/container
	local function objectHasKey()
		if (target == nil) or (target.lockNode == nil) then
			return false
		else
			return target.lockNode.key ~= nil
		end
	end

	currentTarget.target = target

	destroyWindow()

	logDebug(string.format("getLockpick: target %s (%p)", target, target))

	local items = searchTools(false, tes3.getLockLevel({ reference = target }))
	-- If no tool available just display a message
	local next = next
	if next(items) == nil then
		-- manage objectHasKey
		--TODO modify text depending on objectType
		if config.hintKeyExists and objectHasKey() then
			tes3.messageBox(i18n("MSG.NoLockpickButKey"))
		else
			tes3.messageBox(i18n("MSG.NoLockpick"))
		end
		restoreWeapon()
		return
	end

	createWindow(items)
	updateTitle(false)
	highLightTool()
end


---Search for probes for the given target and if any open the selection menu
---@param target any trapped door/container
local function getProbe(target)
	currentTarget.target = target

	destroyWindow()

	logDebug(string.format("getProbe: target %s (%p)", target, target))

	local items = searchTools(true, target.lockNode.trap.magickaCost)

	-- If no tool available just display a message
	local next = next
	if next(items) == nil then
		tes3.messageBox(i18n("MSG.NoProbe"))
		-- case exhauted probe
		restoreWeapon()
		return
	end

	createWindow(items)
	updateTitle(true)
	highLightTool()
end


--TODO rename
---manage unEquipped events by opening selection menu if needed
---@param e any event
local function onUnequipped(e)
	-- prevents activation before chargen
	if not activatemod then
		return
	end

	if not config.modEnabled then
		return
	end

	if currentTarget.target == nil then
		return
	end

	-- other item equipped
	if (currentMenu.currentEquippedTool) == nil or (e.item ~= currentMenu.currentEquippedTool) then
		logDebug(string.format("onUnequipped: Skipping - item %s (%p)", e.item.name, e.item))
		return
	end

	currentMenu.currentEquippedTool = nil

	-- prevent menu to stay displayed with manual unequip
	destroyWindow()
	if (e.itemData.condition > 0) then
		-- case disarm or unlock ?
		logDebug(string.format("onUnequipped: tool %s OK, condition %d", e.item.name, e.itemData.condition))

		--TODO Pb quand on change d'arme => unequipped lockpick => getLockpick
		if tes3.getLocked({ reference = currentTarget.target }) then
			if not currentMenu.isEquipping then
				getLockpick(currentTarget.target)
			end
		else
			restoreWeapon()
		end
	else
		-- broken tool
		-- condition = 0
		logDebug(string.format("onUnequipped: Broken tool %s", e.item.name))

	if tes3.getTrap({ reference = currentTarget.target }) then
			getProbe(currentTarget.target)
		elseif tes3.getLocked({ reference = currentTarget.target }) then
			getLockpick(currentTarget.target)
		else
			restoreWeapon()
		end
	end
	-- 2 cases
	-- object still trapped/locked
	-- dans le cas où on est obligé de reprendre un object du même type => quelque chose à faire en particulier ?
end


---manage activationTargetChanged events by opening selection menu if needed
---@param e any activationTargetChanged event object
local function onActivationTargetChanged(e)
	local target=nil

	-- TODO returns key instead ?
	---Check if a key exists for this door/container
	---@return boolean true is there is a key to open the door/container
	local function objectHasKey()
		if (target == nil) or (target.lockNode == nil) then
			return false
		else
			return target.lockNode.key ~= nil
		end
	end

	---Check if the player has the k to unlock the object
	---@return boolean true if the player has the key to unlock the object in his inventory
	local function playerHasKey()
		if objectHasKey() then
			logDebug(string.format("Target %s has key %s", target, target.lockNode.key))

			return tes3.getItemCount({
				reference = tes3.player,
				item = target.lockNode.key
			}) > 0
		else
			return false
		end
	end

	local function isProbeEquipped()
		return tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.probe })
	end

	local function isLockpickEquipped()
		return tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick })
	end

	-- prevents activation before chargen
	if not activatemod then
		return
	end

	if not config.modEnabled then
		return
	end

	logDebug(string.format("Event onActivationTargetChanged: Current = %p and Previous = %p", e.current, e.previous))

	-- currently equiping tool no need to do something
	if currentMenu.isEquipping then
		return
	end

	if e.current == nil then
		currentTarget.target = nil
		destroyWindow()
		return
	end

	target = e.current		-- e.item is tes3baseObject
	if (target.object.objectType ~= tes3.objectType.container) and (target.object.objectType ~= tes3.objectType.door) then
		destroyWindow()
		return
	end

	if tes3.getTrap({ reference = target }) then
		-- Trapped
		logDebug(string.format("onActivationTargetChanged: trapped"))
		if not isProbeEquipped() then
			--
			getProbe(target)
		end
	elseif tes3.getLocked({ reference = target }) then
		-- Locked
		logDebug(string.format("onActivationTargetChanged: locked"))
		--TODO move playerHasKey to getLockpick
		if not playerHasKey() then
			if not isLockpickEquipped() then
				--
				getLockpick(target)
			end
		else
			if not config.usePlayerKey then
				getLockpick(target)
			else
				-- restoreWeapon is case of disarmed and player has key
				tes3.messageBox(i18n("MSG.UseKey"))
				restoreWeapon()
			end
		end
	else
		-- Not trapped or locked
		logDebug(string.format("onActivationTargetChanged: %s Not trapped or locked", target))
		destroyWindow()

		if target == currentTarget.target then
			-- final state: the object is disarmed and unlocked
			-- may be can unregister unequipped event
			resetCurrentTarget()
			restoreWeapon()
		end
	end
end


--#endregion


--[[
	constructor
]]

--- Initialization register the events and the GUID for menu
local function initialize()
	-- registers needed events, better to use tes.event reference instead of the name https://mwse.github.io/MWSE/references/events/
	event.register(tes3.event.activationTargetChanged, onActivationTargetChanged)

	--event.register(tes3.event.unequipped, onUnequipped)
	event.register(tes3.event.unequipped, onUnequipped)
	event.register(tes3.event.menuEnter, onMenuEnter)

	-- TODO register only when menu is displayed (createWindow)
	event.register(tes3.event.keyDown, onKeyDown, { filter = config.selectionKey.keyCode })

	event.register(tes3.event.activate, onActivate)

	-- DEBUG to delete after tests
	if config.debugMode then
		event.register(tes3.event.lockPick, onLockPick)
		event.register(tes3.event.trapDisarm, onTrapDisarm)
	end

	GUIID_Menu = tes3ui.registerID(modName .. ":Menu")
	GUIID_TestUI_ContentBlock = tes3ui.registerID(modName .. ":ContentBlock")
	GUIID_TestUI_ItemBlock = tes3ui.registerID(modName .. ":ItemBlock")
	GUIID_TestUI_ItemBlockLabel = tes3ui.registerID(modName .. ":ItemBlockLabel")

	event.register(tes3.event.loaded, onLoaded)

	logInfo(modName .. " " .. modVersion .. " initialized")
end
event.register(tes3.event.initialized, initialize)


--[[
	Mod Config Menu

	https://easymcm.readthedocs.io/en/latest/
]]

--#region MCM


---comment
---@param id any name of the variable
---@return table a TableVariable
local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}
end


--- Create the MCM menu
local function registerModConfig()
    local template = mwse.mcm.createTemplate(modName)
	template:saveOnClose(modConfig, config)

	-- https://easymcm.readthedocs.io/en/latest/components/pages/classes/SideBarPage.html
	local page = template:createSideBarPage{
		label = "Sidebar Page",
		description = modName .. " " .. modVersion .. " (c) by " .. modAuthor
	}

	-- https://easymcm.readthedocs.io/en/latest/components/categories/classes/Category.html
	local catMain = page:createCategory(modName)
	catMain:createYesNoButton {
		label = i18n("MCM.modEnabled.label") .. modName,
		description = i18n("MCM.modEnabled.description"),
		variable = createtableVar("modEnabled"),
		defaultSetting = true,
	}

	local catSettings = page:createCategory(i18n("MCM.catGalSettings"))

	catSettings:createYesNoButton {
		label = i18n("MCM.useWorstCondition.label"),
		description = i18n("MCM.useWorstCondition.description"),
		variable = createtableVar("useWorstCondition"),
		defaultSetting = true,
	}

    catSettings:createYesNoButton {
		label = i18n("MCM.diplayChance.label"),
		description = i18n("MCM.diplayChance.description"),
		variable = createtableVar("diplayChance"),
		defaultSetting = true,
	}

	local catLock = page:createCategory(i18n("MCM.catLock"))

    catLock:createYesNoButton {
		label = i18n("MCM.hintKeyExists.label"),
		description = i18n("MCM.hintKeyExists.description"),
		variable = createtableVar("hintKeyExists"),
		defaultSetting = false,
	}

    catLock:createYesNoButton {
		label = i18n("MCM.selectUsableFullFatigue.label"),
		description = i18n("MCM.selectUsableFullFatigue.description"),
		variable = createtableVar("selectUsableFullFatigue"),
		defaultSetting = false,
	}

    catLock:createYesNoButton {
		label = i18n("MCM.usePlayerKey.label"),
		description = i18n("MCM.usePlayerKey.description"),
		variable = createtableVar("usePlayerKey"),
		defaultSetting = true,
	}

	-- https://easymcm.readthedocs.io/en/latest/components/settings/classes/KeyBinder.html
	catSettings:createKeyBinder {
		label = i18n("MCM.selectionKey.label"),
		description = i18n("MCM.selectionKey.description"),
		allowCombinations = true,
		defaultSetting = {
			keyCode = tes3.scanCode.space,
			--These default to false
			isShiftDown = false,
			isAltDown = false,
			isControlDown = false,
		},
		variable = createtableVar("selectionKey")
	}
	mwse.mcm.register(template)
end

event.register(tes3.event.modConfigReady, registerModConfig)

--#endregion