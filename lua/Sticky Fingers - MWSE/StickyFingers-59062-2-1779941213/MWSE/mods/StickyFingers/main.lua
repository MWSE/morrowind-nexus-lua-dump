-- ============================================================
-- Mod Info
-- ============================================================

local mod = require("StickyFingers.config")
local config = mod.config

require("StickyFingers.mcm")

-- ============================================================
-- Logging
-- ============================================================

local logPrefix = "[Sticky Fingers]"

local function log(message)
	if config.debugLog then
		mwse.log("%s %s", logPrefix, message)
	end
end

-- ============================================================
-- Name Helpers
-- ============================================================

local function getObjectName(object)
	if not object then
		return "Unknown object"
	end

	return object.name or object.id or "Unknown object"
end

local function getOwnerName(owner)
	if not owner then
		return nil
	end

	return owner.name or owner.id or "Unknown owner"
end

local function getStolenFromName(stolenFrom)
	if not stolenFrom then
		return nil
	end

	if type(stolenFrom) == "string" then
		return stolenFrom
	end

	if type(stolenFrom) ~= "table" then
		return stolenFrom.name or stolenFrom.id or nil
	end

	local names = {}

	for _, owner in ipairs(stolenFrom) do
		local name = getOwnerName(owner)

		if name then
			table.insert(names, name)
		end
	end

	if #names == 0 then
		return nil
	end

	return table.concat(names, ", ")
end

-- ============================================================
-- Object Type Helpers
-- ============================================================

local function isCarryableItem(object)
	if not object then
		return false
	end

	local allowedItemTypes = {
		[tes3.objectType.alchemy] = true,
		[tes3.objectType.ammunition] = true,
		[tes3.objectType.apparatus] = true,
		[tes3.objectType.armor] = true,
		[tes3.objectType.book] = true,
		[tes3.objectType.clothing] = true,
		[tes3.objectType.ingredient] = true,
		[tes3.objectType.light] = true,
		[tes3.objectType.lockpick] = true,
		[tes3.objectType.miscItem] = true,
		[tes3.objectType.probe] = true,
		[tes3.objectType.repairItem] = true,
		[tes3.objectType.weapon] = true,
	}

	return allowedItemTypes[object.objectType] == true
end

local function isContainer(object)
	if not object then
		return false
	end

	return object.objectType == tes3.objectType.container
end

local function isBedLikeActivator(object)
	if not object then
		return false
	end

	if object.objectType ~= tes3.objectType.activator then
		return false
	end

	local name = string.lower(object.name or "")
	local id = string.lower(object.id or "")

	return name:find("bed", 1, true)
		or name:find("bedroll", 1, true)
		or name:find("hammock", 1, true)
		or id:find("bed", 1, true)
		or id:find("bedroll", 1, true)
		or id:find("hammock", 1, true)
end

local function isSupportedObject(object)
	if isCarryableItem(object) then
		return true
	end

	if isContainer(object) then
		return true
	end

	if isBedLikeActivator(object) then
		return true
	end

	return false
end

-- ============================================================
-- Ownership Data Helpers
-- ============================================================

local function shouldShowAnyOwnershipForObject(object)
	if isCarryableItem(object) then
		return config.showItemOwnerName or config.showItemStatus
	end

	if isContainer(object) then
		return config.showContainerOwnerName or config.showContainerStatus
	end

	if isBedLikeActivator(object) then
		return config.showBedOwnerName or config.showBedStatus
	end

	return false
end

local function getItemDataFromTooltipEvent(e)
	if e.itemData then
		return e.itemData
	end

	if e.reference and e.reference.itemData then
		return e.reference.itemData
	end

	return nil
end

local function getOwnershipData(e)
	local itemData = getItemDataFromTooltipEvent(e)

	if itemData and itemData.owner then
		return itemData.owner, itemData.requirement
	end

	if e.reference and e.reference.itemData and e.reference.itemData.owner then
		return e.reference.itemData.owner, e.reference.itemData.requirement
	end

	return nil, nil
end

local function tooltipAlreadyHasStickyFingersInfo(tooltip)
	if not tooltip then
		return false
	end

	return tooltip:findChild("StickyFingers_OwnerLabel") ~= nil
end

local function getOwnerType(owner)
	if not owner then
		return "none"
	end

	if owner.objectType == tes3.objectType.npc then
		return "npc"
	end

	if owner.objectType == tes3.objectType.faction then
		return "faction"
	end

	return string.format("unknown:%s", tostring(owner.objectType))
end

local function playerHasOwnershipAccess(e)
	if not e.reference then
		return false
	end

	local success, result = pcall(tes3.hasOwnershipAccess, {
		reference = tes3.player,
		target = e.reference,
	})

	if not success then
		log(string.format("hasOwnershipAccess failed: %s", tostring(result)))
		return false
	end

	return result == true
end

local function getOwnershipWarningText(e, owner, requirement)
	local ownerName = getOwnerName(owner)
	if not ownerName then
		return nil
	end

	local hasAccess = playerHasOwnershipAccess(e)
	local isBed = isBedLikeActivator(e.object)
	local isContainerObject = isContainer(e.object)

	if hasAccess then
		if isBed then
			return string.format("Owned by %s. You may sleep here.", ownerName)
		end

		if isContainerObject then
			return string.format("Owned by %s. You have access.", ownerName)
		end

		return string.format("Owned by %s. Taking this is allowed.", ownerName)
	end

	if isBed then
		return string.format("Owned by %s. Sleeping here is trespassing.", ownerName)
	end

	if isContainerObject then
		return string.format("Owned by %s. Taking items from this is theft.", ownerName)
	end

	return string.format("Owned by %s. Taking this is theft.", ownerName)
end

-- ============================================================
-- Stolen Item Tooltip
-- ============================================================

local function createTooltipTextRow(tooltip, id)
	local row = tooltip:createBlock({
		id = id,
	})

	row.flowDirection = tes3.flowDirection.leftToRight
	row.autoHeight = true
	row.autoWidth = true

	return row
end

local function addTooltipTextPart(row, text, color)
	local label = row:createLabel({
		text = text,
	})

	if color then
		label.color = color
	end

	return label
end

local function addStolenTooltip(e)
	if not e.tooltip then
		return
	end

	if not e.object then
		return
	end

	if not isCarryableItem(e.object) then
		return
	end

	if e.tooltip:findChild("StickyFingers_StolenLabel") then
		return
	end

	-- If this is a loose world item that is currently owned, do NOT show
	-- "Stolen from". It has not been stolen yet. The ownership tooltip will
	-- handle "Taking this is theft."
	if e.reference then
		local owner = select(1, getOwnershipData(e))

		if owner then
			return
		end
	end

	local stolen = false
	local stolenFromName = nil

	local success, result, stolenFrom = pcall(function()
		return tes3.getItemIsStolen({
			item = e.object,
		})
	end)

	if success and result then
		stolen = true
		stolenFromName = getStolenFromName(stolenFrom)
	end

	if not stolen then
		return
	end

	local red = nil

	if config.showColors then
		red = tes3ui.getPalette("negative_color")
	end

	local row = createTooltipTextRow(e.tooltip, "StickyFingers_StolenLabel")

	if stolenFromName and config.showStolenFromName then
		addTooltipTextPart(row, "Stolen from:")
		addTooltipTextPart(row, " " .. stolenFromName, red)
	else
		addTooltipTextPart(row, "Stolen", red)
	end

	e.tooltip:updateLayout()

	log(string.format(
		"Stolen tooltip: %s | stolenFrom=%s",
		getObjectName(e.object),
		tostring(stolenFromName)
	))
end

-- ============================================================
-- Ownership Tooltip
-- ============================================================

local function addOwnershipTooltip(e, owner, requirement)
	if not e.tooltip then
		return
	end

	if tooltipAlreadyHasStickyFingersInfo(e.tooltip) then
		return
	end

	local ownerName = getOwnerName(owner)
	if not ownerName then
		return
	end

	local objectName = getObjectName(e.object)
	local ownerType = getOwnerType(owner)
	local hasAccess = playerHasOwnershipAccess(e)
	local isBed = isBedLikeActivator(e.object)
	local isContainerObject = isContainer(e.object)
	local isItemObject = isCarryableItem(e.object)

	local showOwnerName = false
	local showStatus = false

	if isBed then
		showOwnerName = config.showBedOwnerName
		showStatus = config.showBedStatus
	elseif isContainerObject then
		showOwnerName = config.showContainerOwnerName
		showStatus = config.showContainerStatus
	elseif isItemObject then
		showOwnerName = config.showItemOwnerName
		showStatus = config.showItemStatus
	end

	if not showOwnerName and not showStatus then
		return
	end

	local red = nil
	local green = nil

	if config.showColors then
		red = tes3ui.getPalette("negative_color")
		green = { 0.45, 0.75, 0.35 }
	end

	local row = createTooltipTextRow(e.tooltip, "StickyFingers_OwnerLabel")

	if showOwnerName then
		addTooltipTextPart(row, "Owned by")
		addTooltipTextPart(row, " " .. ownerName)
	end

	if showStatus then
		if showOwnerName then
			addTooltipTextPart(row, ".")
		end

		if hasAccess then
			if isBed then
				addTooltipTextPart(row, " You may sleep here", green)
				addTooltipTextPart(row, ".")
			elseif isContainerObject then
				addTooltipTextPart(row, " You have")
				addTooltipTextPart(row, " access", green)
				addTooltipTextPart(row, ".")
			else
				addTooltipTextPart(row, " Taking this is")
				addTooltipTextPart(row, " allowed", green)
				addTooltipTextPart(row, ".")
			end
		else
			if isBed then
				addTooltipTextPart(row, " Sleeping here is")
				addTooltipTextPart(row, " trespassing", red)
				addTooltipTextPart(row, ".")
			elseif isContainerObject then
				addTooltipTextPart(row, " Taking items from this is")
				addTooltipTextPart(row, " theft", red)
				addTooltipTextPart(row, ".")
			else
				addTooltipTextPart(row, " Taking this is")
				addTooltipTextPart(row, " theft", red)
				addTooltipTextPart(row, ".")
			end
		end
	end

	e.tooltip:updateLayout()

	log(string.format(
		"Ownership: %s | Owner=%s | ownerType=%s | requirement=%s | hasAccess=%s",
		objectName,
		ownerName,
		ownerType,
		tostring(requirement),
		tostring(hasAccess)
	))
end

-- ============================================================
-- Tooltip Event Handler
-- ============================================================

local function onObjectTooltip(e)
	if not config.enabled then
		return
	end

	if not e.object then
		return
	end

	if not isSupportedObject(e.object) then
		return
	end

	if config.showStolenStatus then
		addStolenTooltip(e)
	end

	local owner, requirement = getOwnershipData(e)

	if not owner then
		return
	end

	if shouldShowAnyOwnershipForObject(e.object) then
		addOwnershipTooltip(e, owner, requirement)
	end
end

-- ============================================================
-- Initialization
-- ============================================================

local function initialized()
	log("Initialized.")
end

-- ============================================================
-- Event Registration
-- ============================================================

event.register(tes3.event.initialized, initialized)

event.register(tes3.event.uiObjectTooltip, onObjectTooltip, {
	priority = -100,
})