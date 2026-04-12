-- =============================================================================
-- VAIN.domains.ranged_stance
--
-- Sub-domain mounted into SLOT_RANGED_STANCE.
--
-- For NPCs that have at least one offensive target-range spell, this domain
-- manages combatSession.distance each tick:
--   * Enough magicka to cast -> widen to rangedEngagementDistance so the engine
--     positions the NPC at spell-casting range instead of charging into melee.
--   * Not enough magicka     -> collapse back to 128 so the NPC closes in and
--     melees rather than standing uselessly at range.
--
-- Fails immediately for NPCs with no offensive target-range spell (ctx.rangedOffensiveSpell == nil),
-- so the root selector falls through to idle tidy for melee-only fighters.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")
local helpers = require("VAIN.helpers")

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "RangedStance")

	b:Select("Ranged stance"):Condition("Has target-range spell", function(ctx)
		if not ctx.offensiveSpells then
			return false
		end
		for _, e in ipairs(ctx.offensiveSpells) do
			if e.action == 5 then
				return true
			end
		end
		return false
	end) -- Has an affordable target-range spell AND line of sight: keep the NPC at casting range
	:Sequence("Set ranged distance"):Condition("Has affordable target spell", function(ctx)
		return helpers.hasAffordableTargetSpell(ctx.offensiveSpells, ctx.magickaCurrent)
	end):Condition("Has LoS", function(ctx)
		return ctx.hasLineOfSight
	end):Action("Set ranged distance"):Do(operators.setRangedDistance):End():End() -- No affordable target-range spell: collapse to melee so the NPC doesn't stand idle
	:Action("Set melee distance"):Do(operators.setMeleeDistance):End():End()

	return b:Build()
end

return build
