-- =============================================================================
-- VAIN.domains.flee_override
--
-- Sub-domain mounted into the root domain's SLOT_FLEE_OVERRIDE slot.
--
-- Activates when the engine has decided the enemy should flee
-- (selectedAction == 7) but the enemy still has fight in them. Tries, in
-- priority order:
--
--   1a.  Has ranged weapon + LoS -> keep shooting
--   1a.5 Monster ranged spells + LoS -> fire projectile attack
--   1a.7 Offensive spells + LoS -> cast best scoring spell
--   1b.  Biped + no ranged + LoS + stone delay elapsed -> multi-step stone throw
--   1c.  Creature + no ranged + LoS -> chase instead of fleeing
--   1d.  Biped + no ranged + LoS + counter not ready -> wait and increment
--   1e.  LoS -> charge melee
--   1f.  Creature + no LoS -> force re-engage (predator instinct: hunt them down)
--   1g.  Biped + no LoS -> resume flee (scared: take the opening to run)
--
-- heightAdvantage is intentionally NOT a condition for 1b or 1c. On flat
-- terrain it caused 1d to become an accidental charge delay (counter incremented
-- but 1b never fired because height was absent, so the NPC waited then charged).
-- Removing it lets 1b fire correctly on flat ground after the delay elapses.
--
-- The delay before stone-throwing (1d/1b) lives here as a domain condition
-- rather than inside the operator - operators decide *how* to act, not *when*.
-- The shared three-step stone sequence is in domains/stone_throw.lua.
-- =============================================================================
local htn = require("sb_htn.interop")
local operators = require("VAIN.operators")
local config = require("VAIN.config").config
local appendStoneActions = require("VAIN.domains.stone_throw")

---@param ContextClass table The VainContext class
---@return table  -- sb_htn Domain (untyped external library)
local function build(ContextClass)
	local b = htn.DomainBuilder:new(ContextClass, "FleeOverride")

	b:Select("Override flee")
	b:Condition("Wants to flee", function(ctx)
		return ctx.combatSession ~= nil and ctx.selectedAction == 7
	end)
	b:Condition("Health and flee under limit", function(ctx)
		return ctx.healthNorm > 0.1 and ctx.fleeValue < ctx.fleeLimit
	end)

	-- 1a: ranged weapon equipped -> keep shooting
	b:Sequence("Already has ranged")
	b:Condition("Has ranged weapon", function(ctx)
		return ctx.hasRangedWeapon
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Keep shooting"):Do(operators.keepShootingRanged):End()
	b:End()

	-- 1a.5: biped with monster ranged spells but no bow -> fire projectile attack.
	-- Without this, dremoras / golden saints / etc. would fall into the "wait for
	-- stone" delay loop whose counter never increments for enemies with rangedSpells,
	-- leaving them stuck in a "wait stone" state instead of closing to melee.
	b:Sequence("Biped monster ranged")
	b:Condition("Has ranged spells", function(ctx)
		return ctx.rangedSpells ~= nil
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Fire monster ranged"):Do(operators.keepShootingRanged):End()
	b:End()

	-- 1a.7: offensive spells available and affordable -> cast best scoring spell.
	-- selectOffensiveSpell handles affordability and vetoes touch-range spells when
	-- the player is out of melee range, so the operator returns Failure gracefully.
	b:Sequence("Cast offensive spell")
	b:Condition("Has offensive spells", function(ctx)
		return ctx.offensiveSpells ~= nil
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Cast spell"):Do(operators.castOffensiveSpell):End()
	b:End()

	-- 1b: biped, stone delay elapsed -> MULTI-STEP stone throw (acquire/charge/release)
	b:Sequence("Biped throws stones")
	b:Condition("Stone throwing on", function(ctx)
		return config.stoneThrowing
	end)
	b:Condition("Stone delay elapsed", function(ctx)
		return ctx.counter > config.AIsec
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Condition("No ranged weapon", function(ctx)
		return not ctx.hasRangedWeapon
	end)
	b:Condition("Is biped", function(ctx)
		return ctx.attackType == 1
	end)
	appendStoneActions(b)
	b:End()

	-- 1c: creature, no ranged weapon, LoS -> chase instead of flee
	b:Sequence("Creature chase")
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Condition("No ranged weapon", function(ctx)
		return not ctx.hasRangedWeapon
	end)
	b:Condition("Is creature", function(ctx)
		return ctx.attackType ~= 1
	end)
	b:Action("Chase"):Do(operators.creatureChase):End()
	b:End()

	-- 1d: biped, not ready to throw yet -> wait
	b:Sequence("Biped wait for stones")
	b:Condition("Stone throwing on", function(ctx)
		return config.stoneThrowing
	end)
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Condition("No ranged weapon", function(ctx)
		return not ctx.hasRangedWeapon
	end)
	b:Condition("Is biped", function(ctx)
		return ctx.attackType == 1
	end)
	b:Condition("Counter not ready", function(ctx)
		return ctx.counter <= config.AIsec
	end)
	b:Action("Increment counter and hold"):Do(operators.incrementCounter):End()
	b:End()

	-- 1e: LoS -> charge melee
	b:Sequence("Charge melee")
	b:Condition("Detected & LoS", function(ctx)
		return ctx.hasLineOfSight
	end)
	b:Action("Charge melee"):Do(operators.chargeMelee):End()
	b:End()

	-- 1f: creature, no LoS -> hunt the player
	b:Sequence("Creature hunt")
	b:Condition("Is creature", function(ctx)
		return ctx.attackType ~= 1
	end)
	b:Action("Force re-engage"):Do(operators.forceReengage):End()
	b:End()

	-- 1g: biped, no LoS -> resume flee (take the opening to run)
	b:Action("Resume flee"):Do(operators.idleTidy):End()
	b:End()

	return b:Build()
end

return build
