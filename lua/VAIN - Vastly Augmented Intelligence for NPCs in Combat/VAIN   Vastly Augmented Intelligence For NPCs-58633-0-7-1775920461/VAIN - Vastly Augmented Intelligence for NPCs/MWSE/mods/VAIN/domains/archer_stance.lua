-- =============================================================================
-- VAIN.domains.archer_stance
--
-- Sub-domain mounted into SLOT_ARCHER_STANCE.
--
-- For NPCs with a ranged weapon readied, this domain manages
-- combatSession.distance each tick:
--   * Has line of sight -> widen to archerEngagementDistance so the engine
--     positions the NPC at bow range instead of closing into melee.
--   * No line of sight  -> collapse back to 128 so the NPC chases the player
--     to re-establish LoS rather than standing idle at range.
--
-- Fails immediately when no ranged weapon is readied, so the root selector
-- falls through to idle tidy for melee-only fighters.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "ArcherStance")

	b:Select("Archer stance"):Condition("Has ranged weapon", function(ctx)
		return ctx.hasRangedWeapon
	end) -- Has LoS -> maintain bow engagement distance
	:Sequence("Set archer distance"):Condition("Has LoS", function(ctx)
		return ctx.hasLineOfSight
	end):Action("Set archer distance"):Do(operators.setArcherDistance):End():End() -- No LoS -> collapse to melee so the engine chases the player
	:Action("Set melee distance"):Do(operators.setMeleeDistance):End():End()

	return b:Build()
end

return build
