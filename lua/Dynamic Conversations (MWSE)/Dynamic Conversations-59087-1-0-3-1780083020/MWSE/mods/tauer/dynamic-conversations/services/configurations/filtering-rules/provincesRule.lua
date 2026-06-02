local arrays = require("tauer.dynamic-conversations.services.arrays.arrays")

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------

-- Province detection is a naive approximation.
-- Provinces don't exist as a concept in the game files, so this rule infers province
-- ownership from the cell/region source plugin. This should work well for most cases,
-- but patched cells or custom worldspaces may occasionally resolve incorrectly.

---@class provincesRule : conversationFilteringRule
local this = {}

---@type { [string]: string }
this.modsToProvincesMap = {
	["sky_main.esm"] = "skyrim",
	["bloodmoon.esm"] = "skyrim",
	["cyr_main.esm"] = "cyrodiil"
}

---@public
---@param _ tes3npcInstance
---@param configuration conversationConfiguration
---@return boolean
function this.isMet(_, configuration)
	local conditions = configuration.conditions
	if not conditions then
		return true
	end

	local whitelistedProvinces = conditions.whitelistProvinces
	local blacklistedProvinces = conditions.blacklistProvinces
	if not whitelistedProvinces and not blacklistedProvinces then
		return true
	end

	local currentCell = tes3.getPlayerCell()
	local sourceMod = currentCell.region and currentCell.region.sourceMod or currentCell.sourceMod
	if not sourceMod then
		return true
	end

	local currentProvince = this.modsToProvincesMap[sourceMod:lower()] or "morrowind"

	if whitelistedProvinces then
		return arrays.contains(whitelistedProvinces, currentProvince)
	end

	if blacklistedProvinces then
		return not arrays.contains(blacklistedProvinces, currentProvince)
	end

	return true
end

return this
