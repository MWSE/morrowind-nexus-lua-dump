-- =============================================================================
-- VAIN.operators
-- Primitive task operators. Each is a function (ctx) -> ETaskStatus.
--
-- Operators are the only place that mutates the engine. They contain no
-- branching logic about *whether* to act - that's the planner's job. They
-- just do their one thing and report Success / Failure / Continue.
--
-- Continue is the interesting one: returning Continue tells the planner
-- "I'm not done yet, tick me again next frame on the same task." This is
-- how multi-tick actions like the stone wind-up work.
-- =============================================================================
local htn = require("sb_htn.interop")
local ETaskStatus = htn.Tasks.ETaskStatus

local helpers = require("VAIN.helpers")
local config = require("VAIN.config").config
local runtime = require("VAIN.runtime")

local M = {}

-- -----------------------------------------------------------------------------
-- Single-step combat operators
-- -----------------------------------------------------------------------------

function M.castOffensiveSpell(ctx)
	if not ctx.combatSession then
		return ETaskStatus.Failure
	end
	local entry = helpers.selectOffensiveSpell(ctx.offensiveSpells, ctx)
	if not entry then
		return ETaskStatus.Failure
	end
	ctx.combatSession.selectedAction = entry.action
	ctx.combatSession.selectedSpell = entry.spell
	ctx.actionData.aiBehaviorState = 3
	ctx.lastStatus = "CAST: " .. (entry.spell.name or "?")
	return ETaskStatus.Success
end

function M.keepShootingRanged(ctx)
	if not ctx.combatSession then
		return ETaskStatus.Failure
	end
	ctx.combatSession.selectedAction = 2
	ctx.actionData.aiBehaviorState = 3
	helpers.fireRangedSpell(ctx.ref, ctx.rangedSpells)
	ctx.lastStatus = "RANGE"
	return ETaskStatus.Success
end

function M.chargeMelee(ctx)
	if not ctx.combatSession then
		return ETaskStatus.Failure
	end
	ctx.combatSession.selectedAction = ctx.attackType or 1
	ctx.actionData.aiBehaviorState = 3
	helpers.fireRangedSpell(ctx.ref, ctx.rangedSpells)
	ctx.lastStatus = "CHARGE"
	return ETaskStatus.Success
end

function M.creatureChase(ctx)
	if not ctx.combatSession then
		return ETaskStatus.Failure
	end
	ctx.combatSession.selectedAction = 5
	ctx.actionData.aiBehaviorState = 3
	ctx.lastStatus = "NO RUN MONSTR"
	return ETaskStatus.Success
end

-- -----------------------------------------------------------------------------
-- Multi-step stone-throw sequence
-- These three chain inside a Sequence: acquire -> chargeUp -> release.
-- chargeUp returns Continue for stoneChargeMax ticks; if its executing
-- condition (LoS) fails mid-charge, the planner aborts and replans.
-- -----------------------------------------------------------------------------

function M.stoneAcquire(ctx)
	helpers.equipStone(ctx.ref, ctx.mobile, ctx.actorObj, math.random(2, 3))
	ctx.stoneCharge = 0
	ctx.lastStatus = "STONE: ACQUIRE"
	return ETaskStatus.Success
end

function M.stoneChargeUp(ctx)
	if not ctx.hasLineOfSight then
		ctx.lastStatus = "STONE: LOST LOS"
		return ETaskStatus.Failure
	end
	ctx.stoneCharge = ctx.stoneCharge + 1
	ctx.lastStatus = string.format("STONE: CHARGE %d/%d", ctx.stoneCharge, ctx.stoneChargeMax)
	if ctx.stoneCharge >= ctx.stoneChargeMax then
		return ETaskStatus.Success
	end
	return ETaskStatus.Continue
end

function M.stoneRelease(ctx)
	if not ctx.combatSession then
		return ETaskStatus.Failure
	end
	ctx.counter = 0
	ctx.combatSession.selectedAction = 2
	ctx.actionData.aiBehaviorState = 3
	helpers.fireRangedSpell(ctx.ref, ctx.rangedSpells)
	ctx.lastStatus = "STONE: RELEASE!"
	return ETaskStatus.Success
end

-- -----------------------------------------------------------------------------
-- Sessionless / frozen / housekeeping operators
-- -----------------------------------------------------------------------------

function M.forceReengage(ctx)
	if not runtime.mobilePlayer then
		return ETaskStatus.Failure
	end
	ctx.mobile:startCombat(runtime.mobilePlayer)
	ctx.actionData.aiBehaviorState = 3
	ctx.lastStatus = "FORCE REENGAGE"
	return ETaskStatus.Success
end

function M.checkControlSpell(ctx)
	if tes3.getCurrentAIPackageId(ctx.mobile) == 3 then
		runtime.activeEnemies[ctx.ref] = nil
		ctx.lastStatus = "CONTROL!"
		return ETaskStatus.Success
	end
	if not runtime.mobilePlayer then
		return ETaskStatus.Failure
	end
	ctx.mobile:startCombat(runtime.mobilePlayer)
	ctx.actionData.aiBehaviorState = 3
	ctx.lastStatus = "EXTRA COMBAT"
	return ETaskStatus.Success
end

function M.giveUp(ctx)
	runtime.activeEnemies[ctx.ref] = nil
	ctx.lastStatus = "CALM!"
	return ETaskStatus.Success
end

function M.idleTidy(ctx)
	if ctx.counter > 0 and not ctx.hasRangedWeapon then
		ctx.counter = 0
	end
	ctx.lastStatus = "tidy"
	return ETaskStatus.Success
end

function M.incrementCounter(ctx)
	ctx.counter = ctx.counter + 1
	ctx.lastStatus = "wait stone"
	return ETaskStatus.Success
end

-- -----------------------------------------------------------------------------
-- Ranged stance operators
-- -----------------------------------------------------------------------------

--- Widen combat distance so the engine keeps the NPC at spell-casting range.
function M.setRangedDistance(ctx)
	local session = ctx.mobile.combatSession
	if not session then
		return ETaskStatus.Failure
	end
	session.distance = config.rangedEngagementDistance
	ctx.lastStatus = "RANGED STANCE"
	return ETaskStatus.Success
end

--- Widen combat distance so the engine keeps an archer at bow range.
function M.setArcherDistance(ctx)
	local session = ctx.mobile.combatSession
	if not session then
		return ETaskStatus.Failure
	end
	session.distance = config.archerEngagementDistance
	ctx.lastStatus = "ARCHER STANCE"
	return ETaskStatus.Success
end

--- Collapse combat distance back to melee range.
function M.setMeleeDistance(ctx)
	local session = ctx.mobile.combatSession
	if not session then
		return ETaskStatus.Failure
	end
	session.distance = 128
	ctx.lastStatus = "ARCHER: no LoS"
	return ETaskStatus.Success
end

-- -----------------------------------------------------------------------------
-- Heal-potion operators
-- -----------------------------------------------------------------------------

--- Scan the actor's inventory for a tes3alchemy item that contains a
--- restoreHealth effect. Caches the result on the context to avoid scanning
--- every tick. Re-scans only when ctx.healPotionDirty is set (initially true,
--- and re-set to true after a potion is consumed in case the next-best one
--- has different magnitude).
---
--- Returns Success if a potion is found and cached, Failure otherwise.
function M.findRestoreHealthPotion(ctx)
	if ctx.cachedHealPotion and not ctx.healPotionDirty then
		-- Verify the cached potion is still in inventory; the actor may have
		-- consumed or dropped it via some other code path since last tick.
		if ctx.actorObj.inventory:contains(ctx.cachedHealPotion) then
			return ETaskStatus.Success
		end
		ctx.cachedHealPotion = nil
	end

	local restoreHealthId = tes3.effect.restoreHealth
	for _, stack in pairs(ctx.actorObj.inventory) do
		local item = stack.object
		if item.objectType == tes3.objectType.alchemy and item.effects then
			for _, eff in ipairs(item.effects) do
				if eff.id == restoreHealthId then
					ctx.cachedHealPotion = item
					ctx.healPotionDirty = false
					ctx.lastStatus = "POTION FOUND"
					return ETaskStatus.Success
				end
			end
		end
	end

	ctx.cachedHealPotion = nil
	ctx.lastStatus = "NO POTION"
	return ETaskStatus.Failure
end

--- Drink the cached restore-health potion. Applies the alchemy magic source
--- to the actor and removes one from inventory. Marks the potion cache dirty
--- so the next tick re-scans (in case this was the last one).
function M.drinkHealPotion(ctx)
	local potion = ctx.cachedHealPotion
	if not potion then
		return ETaskStatus.Failure
	end

	tes3.applyMagicSource { reference = ctx.ref, source = potion, name = potion.name or "Restore Health" }
	tes3.removeItem { reference = ctx.ref, item = potion, count = 1 }

	ctx.healPotionDirty = true
	ctx.lastStatus = "DRINK!"
	return ETaskStatus.Success
end

return M
