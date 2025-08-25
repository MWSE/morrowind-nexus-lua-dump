local config = require("Place Stacks.config")
local ui = require("Place Stacks.ui")

local log = mwse.Logger.new()
local goldId = "gold_001"

local util = {}


---@param actor tes3actor
---@return fun(): tes3item, integer, tes3itemData|nil
local function inventoryIterator(actor)
	local function iterator()
		for _, stack in pairs(actor.inventory) do
			local item = stack.object
			-- Skip uncarryable lights. They are hidden from the interface. A MWSE mod
			-- could make the player glow from transferring such lights, which the player
			-- can't remove. Some creatures like atronaches have uncarryable lights
			-- in their inventory to make them glow that are not supposed to be looted.
			if item.canCarry == false then
				goto continue
			end

			-- Account for restocking items,
			-- since their count is negative
			local count = math.abs(stack.count)

			-- First yield stacks with custom data
			for _, data in pairs(stack.variables or {}) do
				coroutine.yield(item, data.count, data)
				count = count - data.count
			end

			-- Then yield all the remaining copies
			if count > 0 then
				coroutine.yield(item, count)
			end
			:: continue ::
		end
	end
	return coroutine.wrap(iterator)
end


---@class placeStacks.TransferredItemRecord
---@field name string
---@field count integer
---@field data tes3itemData|nil

---@class placeStacks.transferredTable
---@field container tes3reference
---@field list placeStacks.TransferredItemRecord[]


-- Transfers items `from` to `to` if there is at least one such item in `to`'s inventory.
---@param from tes3reference
---@param to tes3reference
function util.transferStacks(from, to)
	local inventory = to.object.inventory
	local fromActor = from.object

	-- The fromActor needs to be cloned before transfering the items since we
	-- need to get item counts including the items that come from leveled lists.
	if not fromActor.isInstance then
		from:clone()
		fromActor = from.object
	end

	local toTransfer = {}
	for item, count, data in inventoryIterator(fromActor) do
		if not inventory:contains(item) then
			goto continue
		end

		-- TODO: consider making this configurable
		if fromActor:hasItemEquipped(item, data) then
			count = count - 1
		end

		if not config.transferGold and item.id:lower() == goldId then
			goto continue
		end

		if count <= 0 then
			goto continue
		end

		table.insert(toTransfer, { item = item, count = count, data = data })
		:: continue ::
	end

	if table.empty(toTransfer) then
		return false
	end

	---@type placeStacks.TransferredItemRecord[]
	local transferred = {}
	for _, stack in ipairs(toTransfer) do
		local item = stack.item --[[@as tes3weapon]]
		local transferredCount = tes3.transferItem({
			from = from,
			to = to,
			item = item,
			count = stack.count,
			itemData = stack.data,
			reevaluateEquipment = false,
			playSound = false,
			updateGUI = false,
		})
		if transferredCount > 0 then
			table.insert(transferred, { name = item.name, id = item.id:lower(), count = transferredCount })
		end
	end

	-- It's possible we didn't transfer anything due to a container being full.
	if table.empty(transferred) then
		return false
	end

	local targetIsPlayer = (to == tes3.player)
	tes3.playItemPickupSound({
		item = toTransfer[1].item,
		pickup = targetIsPlayer
	})

	-- We deferred GUI updating earlier, so update it now.
	tes3.updateInventoryGUI({ reference = from })
	tes3.updateInventoryGUI({ reference = to })
	tes3.updateMagicGUI({ reference = from, updateSpells = false })
	tes3.updateMagicGUI({ reference = to, updateSpells = false })

	return transferred
end

function util.transferStacksFromMenu()
	local menu = tes3ui.findMenu(ui.id.menuContents)
	if not menu then
		log:error("No ContentsMenu found!")
		return
	end
	-- The access to the container isn't needed in this mod but I think that's a useful property
	-- to be aware of since these aren't readily available. I got this code from UI Expansion.
	-- local container = menu:getPropertyObject("MenuContents_ObjectContainer") --[[@as tes3container]]
	local reference = menu:getPropertyObject("MenuContents_ObjectRefr") --[[@as tes3reference]]
	util.transferStacks(tes3.player, reference)
	if not config.closeMenu then return end
	local close = menu:findChild(ui.id.closeButton) --[[@as tes3uiElement]]
	close:triggerEvent(tes3.uiEvent.mouseClick)
end

---@return tes3reference[]
function util.getNearbyContainers()
	local containers = {}
	for _, cell in ipairs(tes3.getActiveCells()) do
		for reference in cell:iterateReferences({ tes3.objectType.container, tes3.objectType.npc }) do
			local container = reference.object --[[@as tes3container|tes3npc]]
			if container.organic or container.deleted or container.disabled then
				goto continue
			end

			-- We don't want to transfer items into locked containers or alive NPCs.
			if reference.lockNode or reference.isDead == false then
				goto continue
			end

			if config.filterOwned and not tes3.hasOwnershipAccess({ reference = tes3.player, target = reference }) then
				goto continue
			end

			if reference.position:heightDifference(tes3.player.position) > config.heightMax then
				goto continue
			end

			if reference.position:distanceXY(tes3.player.position) > config.distanceMax then
				goto continue
			end

			table.insert(containers, reference)

			:: continue ::
		end
	end
	return containers
end

return util
