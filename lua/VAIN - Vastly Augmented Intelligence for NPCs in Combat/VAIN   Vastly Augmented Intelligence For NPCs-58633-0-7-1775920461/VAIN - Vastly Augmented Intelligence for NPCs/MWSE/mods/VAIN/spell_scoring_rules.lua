-- =============================================================================
-- VAIN.spell_scoring_rules
-- Multiplicative scoring rules for helpers.selectOffensiveSpell.
--
-- Each rule has: name, weight, score(entry, ctx) -> [0,1]
--   score == 0  vetoes the spell (hard constraint, short-circuits)
--   score >  0  contributes (1 + weight * score) to the running product
--
-- Rules that don't apply to a given candidate must return 1 (neutral),
-- not 0, to avoid accidentally vetoing spells they're not meant to judge.
-- =============================================================================
return {
	-- Hard constraint: the NPC must be able to afford the spell.
	{
		name = "affordable",
		weight = 1.0,
		score = function(entry, ctx)
			return ctx.magickaCurrent >= entry.spell.magickaCost and 1 or 0
		end,
	},

	-- Strongly prefer target-range (action==5) over touch-range (action==4).
	-- Touch-range is not vetoed here - it stays in the running at a lower weight.
	{
		name = "target-range-preference",
		weight = 10.0,
		score = function(entry, ctx)
			return entry.action == 5 and 1 or 0.1
		end,
	},

	-- Veto touch-range spells when the player is out of melee range.
	-- Returns neutral (1) for non-touch candidates so they are unaffected.
	{
		name = "touch-range-in-melee",
		weight = 5.0,
		score = function(entry, ctx)
			if entry.action ~= 4 then
				return 1
			end
			return ctx.playerDistance <= 128 and 1 or 0
		end,
	},
}
