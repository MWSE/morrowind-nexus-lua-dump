local blankScrolls = {}

local common = require("Virnetch.enchantmentServicesRedone.common")
local containers = require("Virnetch.enchantmentServicesRedone.items.containers")

blankScrolls.enabled = (
	common.config.itemAdditions.blankScrolls.enabled
	and (tes3.getObject("AB_lvl_ScrollsBlank") ~= nil)
)

--- Checks if blank scrolls should be added to the npc
--- @param referenceOrObject tes3reference|tes3npc
--- @return boolean
function blankScrolls.requirements(referenceOrObject)
	local npcObject = referenceOrObject.object or referenceOrObject
	if common.bartersBlankScrolls(npcObject) then
		-- Check that scrolls haven't already been added
		if not (
			referenceOrObject.data
			and referenceOrObject.data.esr
			and referenceOrObject.data.esr.blankScrollsReceived
		) then
			return true
		end
	end
	return false
end

--- Adds blank scrolls to `reference`
--- @param reference tes3reference
function blankScrolls.addTo(reference)
	reference.data.esr = reference.data.esr or {}

	if reference.data.esr.blankScrollsAdded then
		-- Clean up old references from versions prior to 0.9.6
		reference.data.esr.blankScrollsAdded = nil
		for cont in reference.cell:iterateReferences(tes3.objectType.container) do
			if cont.baseObject.id == "vir_esr_cont_blankScrolls" then
				common.log:debug("Deleting %s in %s", cont.id, reference.cell.id)
				cont:delete()
			end
		end
	end

	-- Add the scrolls, enchanters get double
	local gold = reference.baseObject.barterGold
	local countToAdd = math.remap(math.clamp(gold, 0, 1500), 0, 1500, 1, 4)
	if reference.object.aiConfig.bartersEnchantedItems then
		countToAdd = countToAdd * 2
	end

	common.log:debug("Adding %i conts of blank scrolls to %s", countToAdd, reference)
	for _=1, countToAdd do
		containers.addContainer("blankScrolls", reference)
	end

	reference.data.esr.blankScrollsReceived = true
end

return blankScrolls