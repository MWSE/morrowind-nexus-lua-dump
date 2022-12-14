local containers = {}

local common = require("Virnetch.enchantmentServicesRedone.common")

containers.containerContents = {
	-- TODO Change to poor and rich containers
	blankScrolls = {
		{
			id = "AB_lvl_ScrollsBlank",	-- Chance None: 50%
			count = -common.config.itemAdditions.blankScrolls.frequency
		}
	}
}

-- Update the inventories of previously created container baseObjects to match
-- the values in `containers.containerContents`
local function updateContainerContents()
	for id in pairs(containers.containerContents) do
		local containerId = string.format("vir_esr_cont_%s", id)
		local containerObject = tes3.getObject(containerId)
		if containerObject then
			-- Remove items that shouldn't be there
			for _, stack in pairs(containerObject.inventory) do
				local isInContainerContents = false
				for _, content in pairs(containers.containerContents[id]) do
					if (
						content.id:lower() == stack.object.id:lower()
						and content.count == stack.count
					) then
						isInContainerContents = true
					end
				end
				if not isInContainerContents then
					local itemId = stack.object.id
					common.log:info("Removing invalid stack in %s: %s with count %i", containerId, itemId, stack.count)

					-- removing negative counts is hard...
					stack.count = 0
					containerObject.inventory:addItem({ item = itemId })
					containerObject.inventory:removeItem({ item = itemId })
				end
			end
			-- Add items that should be there
			for _, content in pairs(containers.containerContents[id]) do
				local isInContainerObject = false
				for _, stack in pairs(containerObject.inventory) do
					if (
						content.id:lower() == stack.object.id:lower()
						and content.count == stack.count
					) then
						isInContainerObject = true
					end
				end
				if not isInContainerObject then
					common.log:info("Adding missing content to %s: %s with count %i", containerId, content.id, content.count)
					containerObject.inventory:addItem({
						item = content.id,
						count = content.count
					})
				end
			end
		end
	end
end
event.register(tes3.event.loaded, updateContainerContents, { priority = -1 })

--- Creates a new invisible container reference, owned by `ownerRef`, containing
--- items defined in `containers.containerContents`.
--- @param id string A key in `containers.containerContents`. Will determine what the contents of the container are.
--- @param ownerRef tes3reference The npc to set ownership for
--- @return tes3reference containerRef Reference to the created container
function containers.addContainer(id, ownerRef)
	if not containers.containerContents[id] then
		common.log:error("Attempted to createContainer without contents: %s", id)
		return
	end

	local containerId = string.format("vir_esr_cont_%s", id)

	--- Get the container baseObject. If it doesn't exist, create it.
	local containerObject = tes3.getObject(containerId)
	if not containerObject then
		--- @type tes3container
		containerObject = tes3.createObject({
			objectType = tes3.objectType.container,
			id = containerId,
			mesh = "EditorMarker.nif",
			capacity = 10^6
		})
		if not containerObject then
			common.log:error("Unable to create containerObject %s for %s", id, ownerRef)
			return
		end

		-- Add the contents to the baseObject. Restocking items (i.e. items with
		-- negative count) need to be in the baseObject's inventory to be
		-- compatible with Buying Game.
		for _, content in pairs(containers.containerContents[id]) do
			containerObject.inventory:addItem({
				item = content.id,
				count = content.count
			})
		end
	end

	-- Create the reference and add its owner
	local containerRef = tes3.createReference({
		object = containerObject,
		position = ownerRef.position:copy(),
		cell = ownerRef.cell
	})
	if not containerRef then
		common.log:error("Unable to create containerReference %s for %s", id, ownerRef)
		return
	end
	tes3.setOwner({
		reference = containerRef,
		owner = ownerRef
	})

	return containerRef
end

return containers