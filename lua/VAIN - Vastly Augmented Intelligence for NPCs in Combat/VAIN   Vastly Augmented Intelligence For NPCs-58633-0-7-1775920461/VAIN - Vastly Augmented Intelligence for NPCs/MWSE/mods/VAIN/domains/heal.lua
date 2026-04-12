-- =============================================================================
-- VAIN.domains.heal
--
-- Sub-domain mounted into the root domain's SLOT_HEAL slot.
--
-- Activates when the enemy's health drops below config.healThreshold and they
-- have a restore-health potion in inventory. The behavior is a Sequence:
--
--   1. Check health is low enough
--   2. Find a restore-health potion in inventory (cached on context)
--   3. Drink it (apply the alchemy as a magic source, remove one from inv)
--
-- Step 2's Failure cleanly aborts the sequence and lets the planner fall
-- through to the next slot (flee_override etc) - so an enemy with no potions
-- behaves exactly like before.
--
-- This slot is mounted FIRST in the root selector, giving heal top priority
-- over every other combat behavior. An enemy will always try to heal before
-- it tries to throw stones, charge melee, or re-engage.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")
local config = require("VAIN.config").config

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "Heal")

	b:Sequence("Heal up"):Condition("Low health", function(ctx)
		return ctx.healthNorm < config.healThreshold
	end):Action("Find potion"):Do(operators.findRestoreHealthPotion):End():Action("Drink potion"):Do(
	operators.drinkHealPotion):End():End()

	return b:Build()
end

return build
