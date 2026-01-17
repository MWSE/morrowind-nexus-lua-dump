-- ============================================================================
-- SPEECHCRAFT UNLOCKS SYSTEM
-- Progressive features unlocked as player's speechcraft skill increases
-- ============================================================================

local config = require("SmoothTalker.config")
local unlocks = {}

-- Unlock feature types (values match config key names)
unlocks.FEATURE = {
	-- Actions
	ACTION_ADMIRE = "unlockActionAdmire",
	ACTION_INTIMIDATE = "unlockActionIntimidate",
	ACTION_TAUNT = "unlockActionTaunt",
	ACTION_PLACATE = "unlockActionPlacate",
	ACTION_BOND = "unlockActionBond",

	-- Status bars visibility
	STATUS_DISPOSITION = "unlockStatusDisposition",
	STATUS_PATIENCE = "unlockStatusPatience",
	STATUS_FIGHT = "unlockStatusFight",
	STATUS_ALARM = "unlockStatusAlarm",
	STATUS_FLEE = "unlockStatusFlee",

	-- Success chance display
	SUCCESS_CHANCE_APPROXIMATE = "unlockSuccessChanceApproximate",
	SUCCESS_CHANCE_EXACT = "unlockSuccessChanceExact",

	-- Special abilities
	COMBAT_PERSUASION = "unlockCombatPersuasion",
	BRIBE_REDUCES_ALARM = "unlockBribeReducesAlarm",
	REDUCED_PATIENCE_COST = "unlockReducedPatienceCost",
	PERMANENT_EFFECTS = "unlockPermanentEffects"
}

--- Check if a feature is unlocked based on player's current speechcraft
--- @param feature string|nil The feature to check (config key), or nil if always available
--- @return boolean True if feature is unlocked
function unlocks.isUnlocked(feature)
	if feature == nil then
		return true  -- No unlock requirement, always available
	end

	local threshold = config[feature]
	if not threshold then
		return false
	end

	local speechcraft = tes3.mobilePlayer.speechcraft.current
	local isUnlocked = speechcraft >= threshold

	return isUnlocked
end

--- Check if any items in a list have unlocked features based on player's speechcraft
--- @param items table List of items with unlockFeature field
--- @return boolean True if at least one item is unlocked
function unlocks.hasAnyUnlocked(items)
	for _, item in ipairs(items) do
		local isUnlocked = unlocks.isUnlocked(item.unlockFeature)

		if isUnlocked then
			return true
		end
	end
	return false
end

return unlocks
