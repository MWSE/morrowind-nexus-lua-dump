-- =============================================================================
-- VAIN.domains.search_reengage
--
-- Sub-domain mounted into the root domain's SLOT_SEARCH_REENGAGE slot.
--
-- Handles three related situations:
--   * beh=2 (idle) WITH an active session: the engine dropped the NPC out of
--     pursuit without removing the session (e.g. after a summon completes).
--     Force re-engage immediately via startCombat.
--   * beh=5 (search) or beh=6 (flee) WITH detection + LoS: attack the player
--     using a ranged weapon, monster ranged spells, or the multi-step stone throw.
--   * beh=5/6 WITHOUT LoS: hold (idleTidy).
--
-- Note: beh=2 WITHOUT a session is handled by the sessionless domain (slot 3).
-- The outer condition here excludes that case so sessionless can still fire.
--
-- Stone throws in search mode have no counter delay - the delay gate belongs
-- to flee_override, where the biped is being pressured and needs a moment to
-- react. In search mode the player has already been spotted and stones fly
-- immediately.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")
local config = require("VAIN.config").config
local appendStoneActions = require("VAIN.domains.stone_throw")

---@param ContextClass table
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "SearchReengage")

	b:Select("Re-engage from search/idle")
	b:Condition("Needs attention", function(ctx)
		-- beh=2 only when session is alive; no-session case belongs to sessionless
		return (ctx.behaviourState == 2 and ctx.combatSession ~= nil) or ctx.behaviourState == 5 or ctx.behaviourState == 6
	end)

	-- Idle with active session: engine dropped pursuit. Force restart.
	b:Sequence("Idle -> restart pursuit")
	b:Condition("Idle with session", function(ctx)
		return ctx.behaviourState == 2 and ctx.combatSession ~= nil
	end)
	b:Action("Restart combat"):Do(operators.forceReengage):End()
	b:End()

	-- Search/flee with ranged weapon and LoS -> keep firing
	b:Sequence("Search -> ranged")
	b:Condition("Has ranged weapon", function(ctx)
		return ctx.hasRangedWeapon
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Search ranged"):Do(operators.keepShootingRanged):End()
	b:End()

	-- Search/flee, biped with monster ranged spells, no bow, LoS -> fire projectile
	b:Sequence("Search -> monster ranged")
	b:Condition("Has ranged spells", function(ctx)
		return ctx.rangedSpells ~= nil
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Fire monster ranged"):Do(operators.keepShootingRanged):End()
	b:End()

	-- Search/flee, offensive spells available and affordable -> cast best scoring spell
	b:Sequence("Search -> cast spell")
	b:Condition("Has offensive spells", function(ctx)
		return ctx.offensiveSpells ~= nil
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Cast spell"):Do(operators.castOffensiveSpell):End()
	b:End()

	-- Search/flee, biped, no ranged weapon, LoS -> stone throw (no delay)
	b:Sequence("Search -> stones (multi-step)")
	b:Condition("Stone throwing on", function(ctx)
		return config.stoneThrowing
	end)
	b:Condition("No ranged weapon", function(ctx)
		return not ctx.hasRangedWeapon
	end)
	b:Condition("Is biped", function(ctx)
		return ctx.attackType == 1
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	appendStoneActions(b)
	b:End()

	-- No LoS: hold position
	b:Action("Idle search"):Do(operators.idleTidy):End()
	b:End()

	return b:Build()
end

return build
