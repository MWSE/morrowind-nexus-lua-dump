--[[

	inom - Inventory mouse wheel
	An MWSE-lua mod for Morrowind
	
	@version      v0.9.4
	@author       Isnan
	@last-update  April 25, 2020
	@changelog
		v0.9.4
		- Fixed a faulty dead-check, no more pickpocket rolls vs dead targets.
		v0.9.3
		- Added pickpocket check
		v0.9.2
		- Fixed a compatibility issue with mwse_Containers by Greatness7
		- Fixed a compatibility issue with Quick Loot by Mort
		- Initial mouse cursor targets when opening a container can now be moved without waiting for the tooltip
		v0.9.1
		- Added both auditive and visual feedback if a container is full
		- Added check for not moving keys
		- Fixed issue where mouse would seem to "fall asleep" due to mouseLeave false positive events
		v0.9.0
		- Initial release

]]

-- store

local theMultiMenu
local theSneakIcon
local currentTileData
local currentInventory
local currentMenu
local currentTooltipItem = {}
local firstItem


--[[
	main functions
]]

-- stores the item tile for later use
local function storeItemTile(tileData, inventory)
	if (tileData.item) then
		currentTileData = tileData
	else
		currentTileData = nil
	end

	currentInventory = inventory
end

-- clears the item tile for now
local function clearItemTile()
	currentTileData  = nil
	currentInventory = nil
end

-- moves items
local function moveItem(options)
	local inputController,
		  from,
		  to,
		  menu,
		  container,
		  containerRef,
		  inventory,
		  isShiftDown,
		  isControlDown,
		  availableCount,
		  count,
		  value

	menu         = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
	container    = menu:getPropertyObject("MenuContents_ObjectContainer")
	containerRef = menu:getPropertyObject("MenuContents_ObjectRefr")
	item         = currentTileData.item
	itemData     = currentTileData.itemData


	if (options.from == "inventory") then
		inventory = tes3.player.object.inventory
	else
		inventory = container.inventory
	end

	-- return early if there is no item
	if not inventory:contains(item, itemData) then
		return false
	end

	-- return early if item is bound or equipped
	if currentTileData.isEquipped or currentTileData.isBoundItem then
		return false
	end

	-- return early if gold from inventory
	if (options.from == "inventory" and item.id == "Gold_001") then
		return false
	end

	-- return early if key from inventory
	if (options.from == "inventory" and item.isKey) then
		return false
	end

	from            = (options.from == "inventory") and tes3.player or containerRef
	to              = (options.from ~= "inventory") and tes3.player or containerRef
	availableCount  = mwscript.getItemCount({reference = from, item = currentTileData.item.id})
	inputController = tes3.worldController.inputController
	isShiftDown     = inputController:isKeyDown(tes3.scanCode.lShift) or inputController:isKeyDown(tes3.scanCode.rShift)
	isControlDown   = inputController:isKeyDown(tes3.scanCode.lCtrl) or inputController:isKeyDown(tes3.scanCode.rCtrl)
	count           = isShiftDown and math.min(10, availableCount) or isControlDown and 1 or availableCount
	weight          = item.weight * count

	-- pickpocket check, as long as the target is an npc and alive
	if (container.objectType == tes3.objectType.npc and containerRef.mobile.activeAI) then
		-- base values for the math
		local playerIsHidden = tes3ui.findMenu( theMultiMenu ):findChild( theSneakIcon ).visible
		local base = 15
		local detected = playerIsHidden and 0 or 40
		local multiplier = 4

		-- player stats used
		local playerSneak = tes3.mobilePlayer.sneak.current
		local playerAgi = tes3.mobilePlayer.agility.current
		local playerLuck = tes3.mobilePlayer.luck.current
		local playerFatigue = tes3.mobilePlayer.fatigue.normalized
		local playerTotal = ( playerSneak + playerAgi/5 + playerLuck/10) * ( 0.75 + ( 0.5 * playerFatigue ) )

		-- target stats used
		local targetSneak = containerRef.mobile.sneak.current
		local targetAgi = containerRef.mobile.agility.current
		local targetLuck = containerRef.mobile.luck.current
		local targetFatigue = containerRef.mobile.fatigue.normalized
		local targetTotal = ( ( targetSneak + targetAgi/5 + targetLuck/10 ) * ( 0.75 + ( 0.5 * targetFatigue ) ) )
		
		local percentChange = ( base + playerTotal ) - ( targetTotal/multiplier + weight*multiplier + detected )
		local roll = math.random() * 100

		if ( roll > percentChange ) then
			-- detected! trigger the crime and close the menu
			tes3ui.leaveMenuMode()
			tes3.triggerCrime({
				type = 5, 
				victim = containerRef.mobile, 
				value = value
			})
			return false
		else
			-- set item as stolen
			tes3.setItemIsStolen({ 
				item = item, 
				from = container, 
				stolen = true 
			})
		end
	end

	-- now move the item
	tes3.transferItem(
		{
			from     = from,
			to       = to,
			item     = item,
			itemData = itemData,
			count    = count
		}
	)

	-- if new count is the same as old count, the inventory is probably full
	if (inventory:contains(item, itemData)) then
		local newCount = mwscript.getItemCount({reference = from, item = item.id})
		if (options.from == "inventory" and availableCount == newCount) then
			tes3.playItemPickupSound {item = item.id, pickup = true}
			tes3.messageBox(tes3.findGMST(tes3.gmst.sContentsMessage3).value)
			return false
		end
	end

	-- trigger a crime if the item was taken from an owned contents container
	if (options.from == "contents") then
		local owner = tes3.getOwner(containerRef)
		if (owner) then
			-- if the owner is a faction, and the player meets the required rank, no crime
			if (owner.playerJoined) then
				if (containerRef.attachments["variables"].requirement <= owner.playerRank) then
					return false
				end
			end
			-- item is now stolen
			tes3.setItemIsStolen({ 
				item = item, 
				from = owner, 
				stolen = true 
			})
			-- trigger a crime
			tes3.triggerCrime({
				type = 5, 
				victim = owner, 
				value = value
			})
		end
	end
	clearItemTile()
end


--[[
	helper functions
]]

-- check if the tooltip has a name
local function hasTooltipName()
	local root = tes3ui.findHelpLayerMenu(tes3ui.registerID("HelpMenu"))
	local name = root and root:findChild(tes3ui.registerID("HelpMenu_name"))

	return ( name )
end

--[[
	event handlers 
]]

-- store tile data for later use
local function onTargetItemTileContents(e)
	local tileData = e.source:getPropertyObject("MenuContents_Thing", "tes3inventoryTile")
	pcall( function() storeItemTile(tileData, "contents") end )

	e.source:forwardEvent(e)
end

-- store tile data for later use
local function onTargetItemTileInventory(e)
	local tileData = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
	pcall( function() storeItemTile(tileData, "inventory") end )

	e.source:forwardEvent(e)
end

-- remove the firstItem privilege if the mouse ever left an item tile
local function onMouseLeaveItemTile()
	firstItem = false
end

-- claim mouse wheel events
local function onMouseWheelChange(e)
	-- if not in a container interface, return false.
	if not tes3ui.findMenu(tes3ui.registerID("MenuContents")) then
		return
	end

	local allowTarget

	if (firstItem) then
		allowTarget = true
		firstItem   = false
	else
		allowTarget = (hasTooltipName() and currentTileData and currentTileData.item and (currentTooltipItem.objectType == currentTileData.item.objectType))
	end

	if (allowTarget and currentInventory and currentMenu) then
		local options = {}

		if (e.delta > 0) then
			options.move = "push"
			options.from = (currentInventory == "inventory") and "inventory" or currentMenu
		else
			options.move = "pull"
			options.from = (currentInventory == "inventory") and currentMenu or "inventory"
		end
		moveItem(options)
	end
end

-- store the tooltip object reference
local function onUiObjectTooltip(e)
	if (e.object) then
		currentTooltipItem = e.object
	end
end

-- claim mouse events on item tiles in contents window
local function onTileUpdateContents(e)
	e.element:register("help", onTargetItemTileContents)
	e.element:register("mouseOver", onTargetItemTileContents)
	e.element:register("mouseLeave", onMouseLeaveItemTile)
end

-- claim mouse events on item tiles in inventory window
local function onTileUpdateInventory(e)
	e.element:register("help", onTargetItemTileInventory)
	e.element:register("mouseOver", onTargetItemTileContents)
	e.element:register("mouseLeave", onMouseLeaveItemTile)
end

-- store which menu we're in, will be important when I get to add similar functionality to the barter menus
local function onMenuContents(e)
	firstItem = true
	currentMenu = "contents"
end

--[[
	constructor
]]
local function onInit(e)

	theMultiMenu = tes3ui.registerID("MenuMulti")
	theSneakIcon = tes3ui.registerID("MenuMulti_sneak_icon")

	event.register("itemTileUpdated", onTileUpdateContents,  {filter = "MenuContents"})
	event.register("itemTileUpdated", onTileUpdateInventory, {filter = "MenuInventory"})
	event.register("uiObjectTooltip", onUiObjectTooltip)
	event.register("mouseWheel",      onMouseWheelChange)
	event.register("uiActivated",     onMenuContents,        {filter = "MenuContents"})
end

event.register("initialized", onInit)
