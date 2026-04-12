-- =============================================================================
-- VAIN.domains.stone_throw
--
-- Shared builder helper for the three-step stone-throw action sequence
-- (acquire -> charge up -> release). Both flee_override and search_reengage
-- use this sequence; entry conditions differ between them and are added by
-- each caller before invoking this helper.
--
-- Usage (inside a build function):
--   b:Sequence("...")
--     b:Condition(...)        -- caller adds gate conditions here
--     ...
--     appendStoneActions(b)  -- helper appends the three action steps
--   b:End()                  -- caller closes the sequence
-- =============================================================================
local operators = require("VAIN.operators")

--- Append acquire / chargeUp / release to an already-open :Sequence on builder b.
---@param b table  sb_htn DomainBuilder (a Sequence must be open)
local function appendStoneActions(b)
	b:Action("Acquire stone"):Do(operators.stoneAcquire):End()
	b:Action("Charge up"):ExecutingCondition("LoS good and not frozen", function(ctx)
		return ctx.hasLineOfSight and ctx.behaviourState ~= -1
	end):Do(operators.stoneChargeUp)
	b:End()
	b:Action("Release stone"):Do(operators.stoneRelease):End()
end

return appendStoneActions
