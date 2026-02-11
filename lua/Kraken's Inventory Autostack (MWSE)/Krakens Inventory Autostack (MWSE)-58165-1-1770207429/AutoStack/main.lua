-- Kraken's Autostack
-- Adds Stack and Share buttons to the container menu for quick inventory management.
-- Stack: Pull matching items from your inventory into the container.
-- Share: Pull matching items from the container into your inventory.
-- Equipped items are never transferred.

local GUI_ID_MenuContents = tes3ui.registerID("MenuContents")
local GUI_ID_MenuContents_takeallbutton = tes3ui.registerID("MenuContents_takeallbutton")
local GUI_ID_AutoStack_toPlayer = tes3ui.registerID("AutoStack_button_toPlayer")
local GUI_ID_AutoStack_toContainer = tes3ui.registerID("AutoStack_button_toContainer")

--- Check if we're in pickpocket mode (don't allow stacking in that case)
local function isPickpocketing(menu)
	return menu:getPropertyInt("MenuContents_PickPocket") == 1
end

--- Check if a specific item (by object) is equipped on the actor.
--- tes3.getEquippedItem does NOT support an object parameter - it only filters by objectType/slot.
--- We iterate actor.equipment and match by object.id (same approach as ashfall backpack).
local function getEquippedStackForItem(actorRef, itemObject)
	if not actorRef or not itemObject or not itemObject.id then return nil end
	local actor = actorRef.object or actorRef
	if not actor or not actor.equipment then return nil end
	local wantId = itemObject.id:lower()
	for _, equipStack in pairs(actor.equipment) do
		if equipStack and equipStack.object and equipStack.object.id and equipStack.object.id:lower() == wantId then
			return equipStack
		end
	end
	return nil
end

--- Get the set of item IDs that exist in the given inventory.
local function getItemIdsInInventory(inventory)
	local ids = {}
	for _, stack in pairs(inventory) do
		if stack and stack.object and stack.object.id then
			ids[stack.object.id:lower()] = true
		end
	end
	return ids
end

--- Stack items from source into target.
--- For each item type in target, pull all matching stacks from source.
--- @param fromRef tes3reference|tes3mobileActor The source
--- @param toRef tes3reference|tes3mobileActor The destination
--- @param skipEquipped boolean If true, skip equipped items when fromRef is player
--- @param sourceInventoryOverride tes3inventory|nil Use for containers (UI Expansion)
local function doStack(fromRef, toRef, skipEquipped, sourceInventoryOverride)
	local targetInventory = toRef.object.inventory
	local sourceInventory = sourceInventoryOverride or fromRef.object.inventory
	if not sourceInventory then return 0, 0 end

	local wantedIds = getItemIdsInInventory(targetInventory)
	local totalTransferred = 0
	local totalValue = 0
	local stacksToTransfer = {}

	for _, stack in pairs(sourceInventory) do
		if stack and stack.object and stack.object.id and wantedIds[stack.object.id:lower()] then
			local equippedTile = nil
			if skipEquipped and fromRef == tes3.player then
				equippedTile = getEquippedStackForItem(tes3.player, stack.object)
			end

			if stack.variables and #stack.variables > 0 then
				local varCount = #stack.variables
				local plainCount = stack.count - varCount
				if not equippedTile then
					for _, itemData in ipairs(stack.variables) do
						table.insert(stacksToTransfer, {
							item = stack.object,
							itemData = itemData,
							count = 1,
							value = stack.object.value or 0
						})
					end
				end
				local adjPlain = plainCount
				if equippedTile and not equippedTile.itemData then
					adjPlain = math.max(0, plainCount - 1)
				end
				if adjPlain > 0 then
					table.insert(stacksToTransfer, {
						item = stack.object,
						itemData = nil,
						count = adjPlain,
						value = (stack.object.value or 0) * adjPlain
					})
				end
			else
				local transferCount = stack.count
				if equippedTile then
					transferCount = math.max(0, stack.count - 1)
				end
				if transferCount > 0 then
					table.insert(stacksToTransfer, {
						item = stack.object,
						itemData = nil,
						count = transferCount,
						value = (stack.object.value or 0) * transferCount
					})
				end
			end
		end
	end

	for _, data in ipairs(stacksToTransfer) do
		local transferred = tes3.transferItem({
			from = fromRef,
			to = toRef,
			item = data.item,
			itemData = data.itemData,
			count = data.count,
			playSound = false,
			updateGUI = false
		})
		totalTransferred = totalTransferred + transferred
		if transferred > 0 and data.value > 0 then
			totalValue = totalValue + (data.value * transferred / data.count)
		end
	end

	if totalTransferred > 0 then
		tes3ui.forcePlayerInventoryUpdate()
		tes3ui.updateContentsMenuTiles()
	end

	return totalTransferred, totalValue
end

--- Share: container -> player
local function stackToPlayer(menu)
	local containerRef = menu:getPropertyObject("MenuContents_ObjectRefr")
	local container = menu:getPropertyObject("MenuContents_ObjectContainer")
	if not containerRef then return end

	local containerInv = (container and container.inventory) or containerRef.object.inventory
	local total, stolenValue = doStack(containerRef, tes3.player, false, containerInv)

	if total > 0 and not tes3.hasOwnershipAccess({ target = containerRef }) then
		local owner = tes3.getOwner(containerRef)
		if owner and stolenValue > 0 then
			tes3.triggerCrime({ type = tes3.crimeType.theft, victim = owner, value = stolenValue })
		end
	end
end

--- Stack: player -> container
local function stackToContainer(menu)
	local containerRef = menu:getPropertyObject("MenuContents_ObjectRefr")
	if not containerRef then return end
	doStack(tes3.player, containerRef, true)
end

--- Add Stack and Share buttons to the container menu.
local function onMenuContentsActivated(e)
	if not e.newlyCreated then return end

	local menu = e.element
	if isPickpocketing(menu) then return end

	local takeAllButton = menu:findChild(GUI_ID_MenuContents_takeallbutton)
	if not takeAllButton then return end

	local buttonBlock = takeAllButton.parent
	if not buttonBlock then return end

	local existingToPlayer = buttonBlock:findChild(GUI_ID_AutoStack_toPlayer)
	local existingToContainer = buttonBlock:findChild(GUI_ID_AutoStack_toContainer)
	if existingToPlayer then existingToPlayer:destroy() end
	if existingToContainer then existingToContainer:destroy() end

	local stackBtn = buttonBlock:createButton{
		id = GUI_ID_AutoStack_toContainer,
		text = "Stack"
	}
	stackBtn.borderAllSides = 4
	stackBtn.paddingLeft = 8
	stackBtn.paddingRight = 8
	stackBtn.paddingBottom = 3
	stackBtn:register("mouseClick", function()
		stackToContainer(menu)
	end)
	stackBtn:register("help", function()
		tes3ui.createTooltipMenu{ contents = "Pull matching items from your inventory into the container" }
	end)
	buttonBlock:reorderChildren(takeAllButton, stackBtn, 1)

	local shareBtn = buttonBlock:createButton{
		id = GUI_ID_AutoStack_toPlayer,
		text = "Share"
	}
	shareBtn.borderAllSides = 4
	shareBtn.paddingLeft = 8
	shareBtn.paddingRight = 8
	shareBtn.paddingBottom = 3
	shareBtn:register("mouseClick", function()
		stackToPlayer(menu)
	end)
	shareBtn:register("help", function()
		tes3ui.createTooltipMenu{ contents = "Pull matching items from container into your inventory" }
	end)
	buttonBlock:reorderChildren(stackBtn, shareBtn, 1)

	menu:updateLayout()
end

event.register("uiActivated", onMenuContentsActivated, { filter = "MenuContents" })

event.register("initialized", function()
	mwse.log("[AutoStack] Initialized")
end)
