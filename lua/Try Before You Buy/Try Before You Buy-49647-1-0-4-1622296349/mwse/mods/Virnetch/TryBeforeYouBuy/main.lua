
local config = require("Virnetch.tryBeforeYouBuy.config")

local itemTypes = {
	[tes3.objectType.armor] = true,
	[tes3.objectType.clothing] = true
}

local itemsBuying = {}
local itemsTrying
local tryingFrom

local currentMenu

local distCheckTimer
local crimeTimer

local function stopCrimeTimer()
	if crimeTimer and crimeTimer.state == timer.active then
		crimeTimer:cancel()
		crimeTimer = nil
	end
end

local function triggerCrime()
	-- Triggers crime if player gets too far or changes cells
	if not itemsTrying then return end

	local totalValue = 0
	local owner
	for _, item in ipairs(itemsTrying) do
		local value = item.item.value * item.count
		owner = owner or item.owner
		totalValue = totalValue + value
		tes3.setItemIsStolen({
			item = item.item,
			from = item.owner.object.baseObject,
			stolen = true
		})
	end
	if not owner then return end

	local oldBounty = tes3.mobilePlayer.bounty

	tes3.triggerCrime({
		type = tes3.crimeType.theft,
		value = totalValue,
		victim = owner.object
	})
	itemsTrying = nil

	timer.delayOneFrame(function()
		timer.delayOneFrame(function()
			if oldBounty == tes3.mobilePlayer.bounty then
				crimeTimer = timer.start({
					type = timer.simulate,
					duration = 0.5,
					iterations = 20,
					callback = function()
						if oldBounty == tes3.mobilePlayer.bounty then
							if crimeTimer.iterations == 1 then
								-- After 10 seconds if crime isn't triggered add to bounty manually
								tes3.mobilePlayer.bounty = oldBounty + totalValue
								stopCrimeTimer()
							else
								-- If crime wasn't triggered, start combat with player
								-- and try to trigger it again.
								if not owner.mobile.inCombat then
									owner.mobile:startCombat(tes3.mobilePlayer)
								end
								tes3.triggerCrime({
									type = tes3.crimeType.theft,
									value = totalValue,
									victim = owner.object
								})
								timer.delayOneFrame(function()
									timer.delayOneFrame(function()
										if oldBounty ~= tes3.mobilePlayer.bounty then
											stopCrimeTimer()
										end
									end)
								end)
							end
						else
							stopCrimeTimer()
						end
					end
				})
			end
		end)
	end)
end

local function blockCompanionShare()
	-- Blocks companion share while trying items
	if not itemsTrying then return end

	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if not menu then return end

	local companionShareButton = menu:findChild("MenuDialog_service_companion")
	if not companionShareButton then return end

	companionShareButton:register("mouseClick", function()
		tes3.messageBox("You can't use companion share while trying equipment")
		return false
	end)
end

local function onItemDropped(e)
	-- Prevents dropping of items that player is trying
	if not itemsTrying then
		event.unregister("itemDropped", onItemDropped)
		return
	end
	for _, item in ipairs(itemsTrying) do
		if item.item.id == e.reference.id then
			tes3.messageBox("You can't drop items that you are currently trying")
			timer.start({
				type = timer.real,
				duration = 0.01,
				callback = function()
					tes3.player:activate(e.reference)
				end
			})
		end
	end
end

local function onActivate(e)
	-- Trigger crime if activating load doors
	-- Also prevent opening of containers while trying items
	if e.activator ~= tes3.player then return end
	if not e.target then return end

	local obj = e.target.object
	local destination = e.target.destination
	if (
			obj
		and obj.objectType == tes3.objectType.door
		and destination
		and destination.cell
		and destination.marker
	) then
		event.unregister("activate", onActivate)
		event.unregister("itemDropped", onItemDropped)
		triggerCrime()
		timer.start({
			type = timer.simulate,
			duration = 0.2,
			callback = function()
				tes3.player:activate(e.target)
			end
		})
		return false
	elseif obj.objectType == tes3.objectType.container then
		tes3.messageBox("You can't open containers while trying equipment")
		return false
	end
end

local function stopDistCheck()
	event.unregister("activate", onActivate)
	event.unregister("itemDropped", onItemDropped)
	if distCheckTimer and distCheckTimer.state == timer.active then
		distCheckTimer:cancel()
		distCheckTimer = nil
	end
	itemsTrying = nil
end

local function startDistCheck()
	-- trigger crime if player moves too far
	event.register("activate", onActivate)
	event.register("itemDropped", onItemDropped)

	if config.distanceCheck then
		local startPos = tes3.player.position:copy()
		distCheckTimer = timer.start({
			type = timer.simulate,
			duration = 0.5,
			iterations = -1,
			callback = function()
				local currentPos = tes3.player.position
				local dist = currentPos:distance(startPos)
				if dist > config.maxDistance then
					triggerCrime()
					stopDistCheck()
				end
			end
		})
	end
end

local function getPlacesToTakeFrom(item)
	local totalItemCount = 0
	local refsToTakeFrom = {}
	if item.owner.object.inventory:contains(item.item, item.itemData) then
		local itemCount = mwscript.getItemCount({
			reference = item.owner,
			item = item.item
		})
		if itemCount >= item.count then
			return {{ ref = item.owner, count = item.count, isItem = false }}
		else
			totalItemCount = itemCount
			table.insert(refsToTakeFrom, { ref = item.owner, count = itemCount, isItem = false })
		end
	end

	for ref in item.owner.cell:iterateReferences() do
		if ref.object.objectType == tes3.objectType.container then
			local container = ref
			local owner = tes3.getOwner(container)
			if owner and owner.id == item.owner.object.baseObject.id then
				if container.object.inventory:contains(item.item, item.itemData) then
					local itemCount = mwscript.getItemCount({
						reference = container,
						item = item.item
					})
					if itemCount >= item.count then
						return {{ ref = container, count = item.count, isItem = false }}
					else
						totalItemCount = totalItemCount + itemCount
						table.insert(refsToTakeFrom, { ref = container, count = itemCount, isItem = false })
						if totalItemCount >= item.count then
							return refsToTakeFrom
						end
					end
				end
			end
		elseif ref.id == item.item.id then
			local owner = tes3.getOwner(ref)
			if owner.id == item.owner.object.baseObject.id then
				local count = ref.count or 1
				if count >= item.count then
					return {{
						ref = ref,
						count = item.count,
						isItem = true,
						cell = ref.cell,
						pos = ref.position,
						orientation = ref.orientation,
						owner = item.owner
					}}
				else
					totalItemCount = totalItemCount + count
					table.insert(refsToTakeFrom, {
						ref = ref,
						count = count,
						isItem = true,
						cell = ref.cell,
						pos = ref.position,
						orientation = ref.orientation,
						owner = item.owner
					})
					if totalItemCount >= item.count then
						return refsToTakeFrom
					end
				end
			end
		end
	end
	return false
end

local function returnItems()
	tes3.messageBox("You return the items to "..tryingFrom.object.name)
	for _, item in ipairs(itemsTrying) do
		if item.places then
			for _, place in pairs(item.places) do
				if place.isItem == true then
					local placedItem = tes3.createReference({
						object = item.item.id,
						position = place.pos,
						orientation = place.orientation,
						cell = place.cell
					})
					tes3.setOwner({
						reference = placedItem,
						owner = place.owner.object
					})
				else
					tes3.addItem({
						reference = place.ref,
						item = item.item.id,
						count = place.count,
						playSound = false
					})
				end
				mwscript.removeItem({
					reference = tes3.player,
					item = item.item.id,
					count = place.count
				})
			end
		else
			mwscript.removeItem({
				reference = tes3.player,
				item = item.item.id,
				count = item.count
			})
		end
	end
	tes3ui.forcePlayerInventoryUpdate()
	itemsTrying = nil
	stopDistCheck()
end

local function returnMaybe(e)
	if itemsTrying then
		if e.target == tryingFrom then
			-- Return the items to owner
			returnItems()
		end
	end
end

local function calcBarterPrice(e)
	if not itemTypes[e.item.objectType] then return end
	if e.buying then
		local ownerMobile = tes3ui.getServiceActor()
		if not ownerMobile then return end
		local owner = ownerMobile.reference
		-- Check if player has already selected this item and clicked on it in inventory
		-- e.buying is true also when returning an item that was about to be bought
		if currentMenu == "inventory" then
			-- player is moving an item back
			for k, item in ipairs(itemsBuying) do
				if item.item == e.item
					and item.itemData == e.itemData
				--	and item.count == e.count
					and item.owner == owner
				then
					if e.count < item.count then
						item.count = item.count - e.count
					else
						table.remove(itemsBuying, k)
					end
					break
				end
			end
		else
			local done = false
			for _, item in ipairs(itemsBuying) do
				if item.item == e.item
					and item.itemData == e.itemData
				--	and item.count == e.count
					and item.owner == owner
				then
					item.count = item.count + e.count
					done = true
					break
				end
			end
			if not done then
				table.insert(itemsBuying, {
					item = e.item,
					itemData = e.itemData,
					count = e.count,
					owner = owner
				})
			end
		end
	end
end

local function canTry()
	if not config.enableLimits then
		return true
	end
	local totalValue = 0
	local disposition = tes3ui.getServiceActor().object.disposition

	if disposition <= 20 then
		-- disposition <= 20 can't try any item
		return false
	end
	disposition = ( disposition / 10 - 2 ) / 3
	disposition = disposition ^2
	-- Disp. 50 = 1.0, 100 = 7.11, 30 = 0.11
	local maxTotalValue = config.maxTotalValue * disposition
	local maxSingleValue = config.maxSingleValue * disposition
	-- mwse.log(" maxTotalValue: "..config.maxTotalValue.." * "..disposition.." = "..maxTotalValue)
	-- mwse.log(" maxSingleValue: "..config.maxSingleValue.." * "..disposition.." = "..maxSingleValue)

	for _, item in ipairs(itemsBuying) do
		if item.item.value > maxSingleValue then
			return false
		end
		totalValue = totalValue + item.item.value * item.count
		if totalValue > maxTotalValue then
			return false
		end
	end
	return true
end

local function tryButtonDown()
	local barterMenu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
	if not barterMenu then return end
	if not tes3ui.getServiceActor() then return end

	if not canTry() then
		tes3.messageBox(tes3ui.getServiceActor().object.name..": Why don't you pay for those first")
		return
	end

	for _, item in ipairs(itemsBuying) do
		local placesToTakeFrom = getPlacesToTakeFrom(item)
		if placesToTakeFrom then
			item.places = placesToTakeFrom
			-- Add the item to player
			tes3.addItem({
				reference = tes3.player,
				item = item.item,
				itemData = item.itemData,
				count = item.count,
				playSound = false
			})

			-- Remove the item from NPC or containers owned by him
			for _, place in pairs(placesToTakeFrom) do
				if place.isItem == true then
					local count = place.ref.count or 1
					if count == place.count then
						place.ref:disable()
						mwscript.setDelete({ reference = place.ref })
					elseif place.ref.count then
						place.ref.count = count - place.count
					end
				else
				--	tes3.removeItem({
				--		reference = place.ref,
				--		item = item.item,
				--		count = place.count,
				--		playSound = false
				--	})
					mwscript.removeItem({
						reference = place.ref,
						item = item.item,
						count = place.count
					})
				end
			end
		end
	end
	if #itemsBuying > 0 then
		itemsTrying = table.deepcopy(itemsBuying)
		tryingFrom = tes3ui.getServiceActor().reference
		startDistCheck()
	end
	itemsBuying = {}
	local cancelButton = barterMenu:findChild("MenuBarter_Cancelbutton")
	cancelButton:triggerEvent("mouseClick")

end

local function onCellChanged(e)
	if e.previousCell and ( e.cell.isInterior == true or e.previousCell.isInterior == true ) then
		-- Triggers the crime if player teleports or something
		if itemsTrying then
			triggerCrime()
		--	returnItems(e.previousCell)
		end
	end
end

local function onSave(e)
	if itemsTrying then
		local file = e.filename
		local name = e.name
		returnItems()
		timer.start({
			type = timer.simulate,
			duration = 1,
			callback = function()
				tes3.saveGame({
					file = file,
					name = name
				})
			end
		})
		return false
	end
end

local function leaveBarterMenu()
	itemsBuying = {}
end

local function onMenuBarter(e)
	local quantityMenuId = tes3ui.registerID("MenuQuantity")
	e.element:register("mouseOver", function()
		if not tes3ui.findMenu(quantityMenuId) then
			currentMenu = "barter"
		end
	end)

	local inventoryMenu = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
	inventoryMenu:register("mouseOver", function()
		if not tes3ui.findMenu(quantityMenuId) then
			currentMenu = "inventory"
		end
	end)

	local buttonBlock = e.element:findChild("MenuBarter_Cancelbutton").parent
	buttonBlock:register("destroy", leaveBarterMenu)

	local tryButton = buttonBlock:createButton{ text = "Try Equipment" }
	tryButton:register("mouseClick", tryButtonDown)
	e.element:updateLayout()

	if itemsTrying then
		returnItems()
	end
end

local function onItemTileUpdated(e)
	if not itemsTrying then return end

	for _, v in pairs(itemsTrying) do
		if e.item == v.item then
			local icon = e.element:createImage({ path = "icons/tbyb/icon_frame.dds" })
			icon.consumeMouseEvents = false
			icon.width = 16
			icon.height = 16
			icon.absolutePosAlignY = 0
			icon.absolutePosAlignX = 0
			icon.borderAllSides = -2
			break
		end
	end
end

local function onLoad()
	stopDistCheck()
end
local function onInitialized()
	event.register("uiActivated", blockCompanionShare, { filter = "MenuDialog" })
	event.register("uiActivated", onMenuBarter, { filter = "MenuBarter" })

	event.register("activate", returnMaybe)
	event.register("calcBarterPrice", calcBarterPrice)
	event.register("itemTileUpdated", onItemTileUpdated, { filter = "MenuInventory" })

	event.register("cellChanged", onCellChanged)
	event.register("save", onSave)
	event.register("load", onLoad)

	mwse.log("[Try Before You Buy] Initialized")
end
event.register("initialized", onInitialized)

event.register("modConfigReady", function()
	require("Virnetch.tryBeforeYouBuy.mcm")
end)
