-- =============================================================================
-- VAIN.domains.sessionless
--
-- Sub-domain mounted into the root domain's SLOT_SESSIONLESS slot.
--
-- Activates when the enemy has no active combat session. Two cases:
--   * Fight value still high (> 50): force re-engage by calling startCombat
--   * Fight value low: drop the enemy from the active registry
--
-- applyMagicSource was previously called here too, but flagged
-- it as unsafe ("ball spell cannot be used safely without a combat session"),
-- so we don't fire spells in this branch.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "Sessionless")

	b:Select("No combat session"):Condition("No session", function(ctx)
		return ctx.combatSession == nil
	end) -- Fight value high -> force re-engage
	:Sequence("Force re-engage"):Condition("Wants to fight", function(ctx)
		return ctx.fightValue > 50
	end):Action("Restart combat"):Do(operators.forceReengage):End():End() -- Calmed down -> drop from registry
	:Sequence("Give up"):Condition("Calm", function(ctx)
		return ctx.fightValue <= 50
	end):Action("Forget enemy"):Do(operators.giveUp):End():End():End()

	return b:Build()
end

return build
