--[[

	inom - Inventory mouse wheel
	An MWSE-lua mod for Morrowind
	
	@version      v0.9.5
	@author       Isnan
	@last-update  July 24, 2021
	@changelog
		v0.9.5
		- Refactored quite a bit.
		- Updated how to count available items for transfer.
		- Added a check for companions before triggering pickpocket crimes.
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

local currentContainer
local currentTileData
local currentTooltipItem
local firstItem
local theHelpMenu
local theHelpMenuName
local theMenuContents
local theMultiMenu
local theSneakIcon


local function isCompanion(ref)
    local context = ref.context
    if (context) then
        return context.companion == 1
    end
    return false
end


local function moveItem()
	local menu               = tes3ui.findMenu( theMenuContents )
	local container          = menu:getPropertyObject( "MenuContents_ObjectContainer" )
	local containerRef       = menu:getPropertyObject( "MenuContents_ObjectRefr"      )
	local from               = ( currentContainer == "inventory" ) and tes3.player or containerRef
	local to                 = ( currentContainer ~= "inventory" ) and tes3.player or containerRef
	local inventory          = ( currentContainer == "inventory" ) and tes3.player.object.inventory or container.inventory
	local item               = currentTileData.item
	local itemData           = currentTileData.itemData
	local availableCount     = currentTileData.count
	local hasOwnershipAccess =  tes3.hasOwnershipAccess({ target = containerRef })
	local isPickPocketing    = (container.objectType == tes3.objectType.npc and containerRef.mobile.activeAI)
	local inputController    = tes3.worldController.inputController
	local isShiftDown        = inputController:isKeyDown( tes3.scanCode.lShift ) or inputController:isKeyDown( tes3.scanCode.rShift )
	local isControlDown      = inputController:isKeyDown( tes3.scanCode.lCtrl  ) or inputController:isKeyDown( tes3.scanCode.rCtrl  )
	local count              = isShiftDown and math.min(10, availableCount) or isControlDown and 1 or availableCount
	local weight             = item.weight * count
	local value              = item.value * count

	-- return early if there is no item
	if not inventory:contains(item, itemData) then
		return false
	end

	-- return early if item is bound or equipped
	if currentTileData.isEquipped or currentTileData.isBoundItem then
		currentTileData = nil
		return false
	end

	-- return early if gold from inventory
	if (currentContainer == "inventory" and item.id == "Gold_001") then
		currentTileData = nil
		return false
	end

	-- return early if key from inventory
	if (currentContainer == "inventory" and item.isKey) then
		currentTileData = nil
		return false
	end

	-- pickpocket check, as long as the target is an npc and alive - and not owned by the player (ie, a companion?)
	if isPickPocketing and not isCompanion( containerRef ) then

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
		
		local percentChance = ( base + playerTotal ) - ( targetTotal/multiplier + weight*multiplier + detected )
		local roll = math.random() * 100
		
		if ( roll > percentChance ) then

			-- detected! trigger the crime and close the menu
			tes3ui.leaveMenuMode()
			tes3.triggerCrime({
				type = 4, 
				victim = containerRef.mobile, 
				value = value
			})
			
			currentTileData = nil
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

	-- transfer the item
	local transfer = tes3.transferItem({
		from     = from,
		to       = to,
		item     = item,
		itemData = itemData,
		count    = count
	})

	
	-- if nothing was transferred, from the player, and new count is the same as old count
	-- inform the players their target container is probably full and end the function.
	if ( (transfer == 0) and inventory:contains(item, itemData) ) then

		if (currentContainer == "inventory" and availableCount == currentTileData.count) then
			tes3.playItemPickupSound {item = item.id, pickup = true}
			tes3.messageBox(tes3.findGMST(tes3.gmst.sContentsMessage3).value)
			currentTileData = nil
			return false
		end
	end

	-- an item has been transferred, trigger a crime if the item was taken from an owned contents container
	if (currentContainer == "contents" and not isPickPocketing and not hasOwnershipAccess ) then
		local owner = tes3.getOwner(containerRef)

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

	--isMovingItem = false
	currentTileData = nil
end

-- checks if the tooltip is currently active
local function isTooltipActive()
	-- active tooltips have names
	local root = tes3ui.findHelpLayerMenu( theHelpMenu )
	local name = root and root:findChild( theHelpMenuName )

	return name
end

-- checks if the current target is a legit target for moving
local function isLegitItemTile()
	-- allow the first item to pass through without a tooltip, as the 
	-- contents menu may have spawned under your mouse cursor, and thusly
	-- did not trigger a tooltip.
	if firstItem then
		firstItem = false
		return ( currentTileData and currentTileData.item )
	else
		local tooltipActive = isTooltipActive()
		-- tooltip is active, points to an item tile and we have tiledata ready
		return ( tooltipActive and currentTooltipItem and currentTileData and currentTileData.item )
	end
end

local function onMouseWheel(e)
	-- guard against usage outside of contents menu
	if not tes3ui.findMenu( theMenuContents) then
		return
	end

	-- if legit item, move the item
	if ( isLegitItemTile() ) then
		moveItem()
	end
end

-- store the tooltip object reference, we use this reference to invalidate stale 
-- saved currentTileItems. (ie. the mouse no longer hovers over the tile)
local function onUiObjectTooltip(e)
	-- guard against usage outside of contents menu
	if not tes3ui.findMenu( theMenuContents ) then
		return
	end
	
	-- inventory tiles should have an object and should never have a reference
	currentTooltipItem = ( e.object and not e.reference ) and e or nil

end

-- save the current inventory tile for mouse wheel action
local function onMouseOverTileInventory(e)
	e.source:forwardEvent(e)
	
	local tileData = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
	currentTileData = tileData.item and tileData or nil
	currentContainer = 'inventory'
end

-- save the current contents tile for mouse wheel action.
local function onMouseOverTileContents(e)
	e.source:forwardEvent(e)

	local tileData = e.source:getPropertyObject("MenuContents_Thing", "tes3inventoryTile")
	currentTileData = tileData.item and tileData or nil
	currentContainer = 'contents'
end

-- if the mouse ever left a tile, we can safely skip to normal uiTooltip-based currentTileData validation
local function onMouseLeaveTile()
	if (firstItem ) then
		firstItem = false
	end
end

local function onItemTileUpdatedInventory(e)
	e.element:register( "help",       onMouseOverTileInventory)
	e.element:register( "mouseOver",  onMouseOverTileInventory)
	e.element:register( "mouseLeave", onMouseLeaveTile )
end

local function onItemTileUpdatedContents(e)
	e.element:register( "help",       onMouseOverTileContents)
	e.element:register( "mouseOver",  onMouseOverTileContents)
	e.element:register( "mouseLeave", onMouseLeaveTile )
end

local function onMenuEnterContents()

	-- this flag allows the first item to be moved without a tooltip, which fixes an 
	-- issue with content menus spawning under your cursor, which does not trigger a 
	-- tooltip for the first item
	firstItem = true
end

-- clear out any tileData when we exit
local function onMenuExitContents()
	currentTileData = nil
end

local function onInitialized()

	-- assign gui application constants
	theHelpMenu     = tes3ui.registerID("HelpMenu")
	theHelpMenuName = tes3ui.registerID("HelpMenu_name")
	theMenuContents = tes3ui.registerID("MenuContents")
	theMultiMenu    = tes3ui.registerID("MenuMulti")
	theSneakIcon    = tes3ui.registerID("MenuMulti_sneak_icon")

	-- register events required for this mod
	event.register( "mouseWheel",      onMouseWheel )
	event.register( "uiObjectTooltip", onUiObjectTooltip )
	event.register( "menuEnter",     onMenuEnterContents,  { filter = "MenuContents"  })
	event.register( "menuExit", onMenuExitContents )
	event.register( "itemTileUpdated", onItemTileUpdatedContents,  { filter = "MenuContents"  })
	event.register( "itemTileUpdated", onItemTileUpdatedInventory, { filter = "MenuInventory" })
	
end

event.register( "initialized", onInitialized, { doOnce = true } )