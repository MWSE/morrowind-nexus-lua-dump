local config = mwse.loadConfig("Tired Spell Casting")

if (config == nil or config.levUncapped == nil) then
	config = {
		levUncapped = false,		-- Caster mastery tiers for level uncapped games
		penChanceHiTier = false,	-- Casting chance penalty for higher tier spells
		penCostHiTier = true,		-- Spell cost penalty for higher tier spells
		redCostLoTier = true,		-- Spell cost reduction for lower tier spells
		redCostHiMastery = false,	-- Spell cost reduction for high caster mastery
		expFailure = true,			-- Gain experience on spell failure
	}
end

return config