---@type conversationValidationRule
return {
	isMet = function(configuration)
		local conditions = configuration.conditions
		if not conditions then
			return true
		end

		if conditions.whitelistNpcs and conditions.blacklistNpcs then
			return false, "cannot both whitelist and blacklist NPCs in the same conversation"
		end
		if conditions.whitelistFactions and conditions.blacklistFactions then
			return false, "cannot both whitelist and blacklist factions in the same conversation"
		end
		if conditions.whitelistClass and conditions.blacklistClass then
			return false, "cannot both whitelist and blacklist classes in the same conversation"
		end
		if conditions.whitelistCells and conditions.blacklistCells then
			return false, "cannot both whitelist and blacklist cells in the same conversation"
		end
		if conditions.whitelistWeathers and conditions.blacklistWeathers then
			return false, "cannot both whitelist and blacklist weathers in the same conversation"
		end
		if conditions.whitelistProvinces and conditions.blacklistProvinces then
			return false, "cannot both whitelist and blacklist provinces in the same conversation"
		end
		if conditions.whitelistRegions and conditions.blacklistRegions then
			return false, "cannot both whitelist and blacklist regions in the same conversation"
		end
		return true, nil
	end,
}
