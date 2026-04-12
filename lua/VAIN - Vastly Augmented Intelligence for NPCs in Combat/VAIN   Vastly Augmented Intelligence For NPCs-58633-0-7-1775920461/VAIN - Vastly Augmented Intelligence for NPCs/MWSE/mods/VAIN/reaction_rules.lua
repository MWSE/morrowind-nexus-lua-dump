-- =============================================================================
-- VAIN.reaction_rules
-- =============================================================================
--
-- PURPOSE
-- -------
-- The Morrowind engine calls `determinedAction` every time it picks a combat
-- action for an NPC. This module intercepts those decisions and overrides them
-- when the engine's choice would produce bad behaviour - freezing at range,
-- spamming bound weapons, fleeing unnecessarily, casting while silenced, etc.
--
-- This is purely reactive: one engine decision in, one override out (or none).
-- There is no planning, no carried state between decisions beyond the counters
-- already on ctx, and no lookahead. Each call to onDeterminedAction is
-- independent.
--
-- HOW THE RULE SYSTEM WORKS
-- -------------------------
-- Rules are grouped into branches keyed by the engine's selected action number:
--
--   rules[7]  flee
--   rules[6]  summon
--   rules[4]  touch-range offensive spell
--   rules[5]  target-range offensive spell
--   rules[8]  empower (bound weapons, self-buffs, Dispel)
--
-- Actions without a branch (melee, h2h, marksman, alchemy, enchanted item) are
-- not intercepted. The handler resets loop counters and returns.
--
-- Within a branch, rules are evaluated in order. The FIRST rule whose match()
-- returns true wins: its apply() runs and the handler returns immediately. Rules
-- below it in the list are never evaluated for that tick.
--
-- Each rule has three fields:
--   name  (string)    - kebab-case identifier, used for logging and next-chaining
--   match (function)  - (e, ctx) -> boolean; pure read, no side effects
--   apply (function)  - (e, ctx) -> nil; does the work, logs what happened
--
-- An optional `next` field (string rule name) lets a rule nominate one follow-up
-- rule to evaluate after itself. This is intended for edge cases where a rule
-- needs to "and also check X" - it is not the primary control flow mechanism.
-- Sequential logic (tick counters, pin state) lives in a single apply() rather
-- than being split across chained rules.
--
-- AVAILABLE CONTEXT (ctx fields used here)
-- -----------------------------------------
--   ctx.healthNorm          normalised health [0,1]
--   ctx.fleeValue           current flee stat
--   ctx.fleeLimit           flee threshold set at combat start
--   ctx.hasLineOfSight      true if the NPC can see the player this tick
--   ctx.isKnockedDown       true if the NPC is currently knocked down
--   ctx.magickaCurrent      current magicka (snapshot from last HTN tick)
--   ctx.playerDistance      distance to player in units
--   ctx.offensiveSpells     list of {spell, action} built at combat start; nil if none
--   ctx.mobile              tes3mobileActor for this NPC
--   ctx.ref                 tes3reference for this NPC
--   ctx.actorObj            tes3actor (for name, spells, etc.)
--   ctx.actionData          aiBehaviorState lives here; set to 3 to force attack
--   ctx.summonTicks         consecutive ticks the engine picked summon (6)
--   ctx.summonBrokeTime     os.clock() when the last summon loop was broken
--   ctx.empowerTicks        consecutive ticks the engine picked empower (8)
--   ctx.empowerSpell        spell pinned on the first empower tick; nil between cycles
--   ctx.empowerBrokeTime    os.clock() when the last empower loop was broken
--   ctx.empowerBreakDuration seconds to stay in empower cooldown after a break-out
--
-- ADDING A NEW RULE
-- -----------------
-- 1. Write a local rule table with name / match / apply (and next if needed).
-- 2. Add a comment above it explaining why the situation exists and what the
--    rule does. Include what happens when the rule does NOT match.
-- 3. Insert it into the correct branch list at the right priority position.
--    Remember: earlier = higher priority.
-- 4. If the rule is only reachable via `next`, add it to the index manually
--    at the bottom of the file.
-- =============================================================================
local config = require("VAIN.config").config
local helpers = require("VAIN.helpers")
local ah = require("VAIN.action_helpers")

local log = mwse.Logger.new { modName = "VAIN", moduleName = "reaction_rules", level = config.logLevel }

-- ============================================================
-- Shared helpers
-- ============================================================

local function forceMelee(e, ctx)
	e.session.selectedAction = ah.meleeFallback(ctx)
	ctx.actionData.aiBehaviorState = 3
end

-- ============================================================
-- Action 7: flee
-- ============================================================

-- The engine picks flee (7) when the NPC is scared. We suppress it as long as
-- the NPC is not critically wounded and hasn't exceeded their personal flee
-- threshold - forcing them back into melee so they don't turn and run mid-fight.
-- If neither condition holds (they're badly hurt or genuinely terrified), the
-- rule doesn't match and the flee action is allowed through untouched.
local fleeSuppressRule = {
	name = "flee-suppress",
	match = function(e, ctx)
		return ctx.healthNorm > 0.1 and ctx.fleeValue < ctx.fleeLimit
	end,
	apply = function(e, ctx)
		forceMelee(e, ctx)
		if config.m4 then
			tes3.messageBox("VAIN: flee suppressed -> melee  %s", ctx.actorObj.name)
		end
		log:debug("[determinedAction] %s: flee-suppress -> melee", ctx.actorObj.name)
	end,
}

-- ============================================================
-- Action 6: summon
-- summon-cooldown bails out without touching the tick counter.
-- summon-process handles the rest: increment -> stuck check -> allow.
-- ============================================================

-- After a summon loop is broken (summon-process detected a stuck NPC), we
-- suppress further summon attempts for 60 seconds. Without this, the NPC would
-- immediately try to summon again on the very next tick and get stuck again.
-- Redirects to melee for the duration; does not touch the tick counter so the
-- counter stays at zero until the cooldown expires.
local summonCooldownRule = {
	name = "summon-cooldown",
	match = function(e, ctx)
		return os.clock() - ctx.summonBrokeTime < 60
	end,
	apply = function(e, ctx)
		forceMelee(e, ctx)
		log:debug("[determinedAction] %s: summon-cooldown (broke %.0fs ago) -> melee", ctx.actorObj.name,
		          os.clock() - ctx.summonBrokeTime)
	end,
}

-- Handles the normal summon path: counts consecutive summon ticks and breaks
-- the loop when the NPC appears stuck (e.g. no player detection, can't cast).
-- Each tick the engine picks summon (6) advances the counter. If it exceeds
-- empowerStuckMax, we force melee and start the 60-second cooldown so the NPC
-- fights instead of standing still trying to summon indefinitely.
local summonProcessRule = {
	name = "summon-process",
	match = function()
		return true
	end,
	apply = function(e, ctx)
		ctx.summonTicks = ctx.summonTicks + 1
		log:debug("[determinedAction] %s: summon tick %d/%d", ctx.actorObj.name, ctx.summonTicks, config.empowerStuckMax)
		if ctx.summonTicks > config.empowerStuckMax then
			ctx.summonTicks = 0
			ctx.summonBrokeTime = os.clock()
			forceMelee(e, ctx)
			log:debug("[determinedAction] %s: summon-stuck -> melee (cooldown 60s)", ctx.actorObj.name)
		end
	end,
}

-- ============================================================
-- Actions 4 and 5: touch / target spell
-- ============================================================

-- The engine can pick an offensive spell even when the NPC can't actually cast
-- it: no magicka, silenced, or (for target-range) no line of sight. Rather than
-- letting the NPC stand frozen at range, we redirect to melee so they stay
-- active. Touch-range spells (4) don't need LoS - the engine chases the player
-- into range - so LoS is only checked for target-range (5).
-- Only active when smartMages is enabled; otherwise the rule never matches.
local cantCastSpellRule = {
	name = "cant-cast-spell",
	match = function(e, ctx)
		if not config.smartMages then
			return false
		end
		local spell = e.session.selectedSpell
		local isSilenced = tes3.isAffectedBy { reference = ctx.ref, effect = tes3.effect.silence }
		local noLoS = (e.session.selectedAction == 5) and not ctx.hasLineOfSight
		return isSilenced or noLoS or (spell and ctx.mobile.magicka.current < spell.magickaCost)
	end,
	apply = function(e, ctx)
		local spell = e.session.selectedSpell
		local isSilenced = tes3.isAffectedBy { reference = ctx.ref, effect = tes3.effect.silence }
		local noLoS = (e.session.selectedAction == 5) and not ctx.hasLineOfSight
		local reason
		if isSilenced then
			reason = "silenced"
		elseif noLoS then
			reason = "no LoS"
		else
			reason = string.format("%.0f/%.0f magicka", ctx.mobile.magicka.current, spell and spell.magickaCost or 0)
		end
		forceMelee(e, ctx)
		log:debug("[determinedAction] %s: cant-cast-spell '%s' (%s) -> melee", ctx.actorObj.name, spell and spell.name or "?",
		          reason)
	end,
}

-- ============================================================
-- Action 8: empower
-- Early-exit rules bail out before any state is mutated.
-- empower-process handles the rest as a sequential pipeline:
--   increment tick -> pin spell -> check if already active -> break out if stuck.
-- ============================================================

-- Two early exits that allow the empower action through without any processing:
-- • smartMages disabled - the whole empower subsystem is off, do nothing.
-- • NPC is knocked down - can't cast anyway, no point in touching state.
-- Both result in the action being allowed; we just skip all the pin/stuck logic.
local empowerKnockedDownRule = {
	name = "empower-knocked-down",
	match = function(e, ctx)
		return not config.smartMages or ctx.isKnockedDown
	end,
	apply = function(e, ctx)
		if ctx.isKnockedDown then
			log:debug("[determinedAction] %s: empower-knocked-down -> allow", ctx.actorObj.name)
		end
	end,
}

-- After empower-process breaks out of a stuck loop, empower is suppressed for
-- a cooldown period (duration of the pinned spell, or empowerBreakCooldown as
-- fallback). During this window we redirect to an affordable offensive spell so
-- the NPC keeps fighting instead of immediately trying to empower again.
-- Falls back to melee if no offensive spell is available.
local empowerCooldownRule = {
	name = "empower-cooldown",
	match = function(e, ctx)
		return os.clock() - ctx.empowerBrokeTime < ctx.empowerBreakDuration
	end,
	apply = function(e, ctx)
		local left = ctx.empowerBreakDuration - (os.clock() - ctx.empowerBrokeTime)
		local picked = helpers.selectOffensiveSpell(ctx.offensiveSpells, ctx)
		if picked then
			ctx.mobile:equipMagic{ source = picked.spell }
			e.session.selectedAction = picked.action
			log:debug("[determinedAction] %s: empower-cooldown (%.1fs left) -> %s '%s'", ctx.actorObj.name, left,
			          picked.action == 5 and "target-spell" or "touch-spell", picked.spell.name)
		else
			forceMelee(e, ctx)
			log:debug("[determinedAction] %s: empower-cooldown (%.1fs left) -> melee", ctx.actorObj.name, left)
		end
	end,
}

-- NPCs with a Dispel spell will sometimes cast it on themselves as an empower
-- action. This is wasted if they have no active harmful effects to remove.
-- We detect that case and redirect to melee, also clearing empower state so
-- the NPC doesn't get stuck in a dispel loop on subsequent ticks.
local empowerDispelNoEffectRule = {
	name = "empower-dispel-no-effect",
	match = function(e, ctx)
		local spell = e.session.selectedSpell
		return spell and ah.isDispelSpell(spell) and not ah.hasHarmfulEffect(ctx.mobile)
	end,
	apply = function(e, ctx)
		ctx.empowerTicks = 0
		ctx.empowerSpell = nil
		forceMelee(e, ctx)
		log:debug("[determinedAction] %s: empower-dispel-no-effect -> melee", ctx.actorObj.name)
	end,
}

-- Core empower handler. Runs when all early-exit rules above have passed.
-- Manages the full lifecycle of an empower cycle in order:
--   1. Increment the tick counter (only reaches here if not knocked down / in cooldown).
--   2. Pin the chosen spell on the first tick so the engine can't cycle through
--      different bound weapons each tick.
--   3. If the engine switched to a different spell, force it back to the pinned one.
--   4. If the pinned spell is already active on the NPC, it doesn't need casting -
--      skip ahead to stuck handling immediately.
--   5. If the tick counter reaches empowerStuckMax, break out: redirect to an
--      affordable offensive spell (or melee), reset all empower state, and start
--      the cooldown so the NPC doesn't loop straight back into empower next tick.
local empowerProcessRule = {
	name = "empower-process",
	match = function()
		return true
	end,
	apply = function(e, ctx)
		ctx.empowerTicks = ctx.empowerTicks + 1
		log:debug("[determinedAction] %s: empower tick %d/%d", ctx.actorObj.name, ctx.empowerTicks, config.empowerStuckMax)

		local spell = e.session.selectedSpell
		if not spell then
			return
		end

		-- Pin the spell on the first tick; force back if the engine switched.
		if not ctx.empowerSpell then
			ctx.empowerSpell = spell
			log:debug("[determinedAction] %s: empower-pin -> '%s'", ctx.actorObj.name, spell.name)
		elseif spell ~= ctx.empowerSpell then
			log:debug("[determinedAction] %s: empower-pin -> engine switched '%s'->'%s', forcing back (tick %d)",
			          ctx.actorObj.name, spell.name, ctx.empowerSpell.name, ctx.empowerTicks)
			ctx.mobile:equipMagic{ source = ctx.empowerSpell }
		end

		-- If the pinned spell is already active, skip straight to stuck handling.
		if ah.isSpellActive(ctx.ref, ctx.empowerSpell) then
			log:debug("[determinedAction] %s: '%s' already active -> triggering stuck", ctx.actorObj.name, ctx.empowerSpell.name)
			ctx.empowerTicks = config.empowerStuckMax
		end

		-- Break out after too many consecutive ticks.
		if ctx.empowerTicks >= config.empowerStuckMax then
			local pinnedName = ctx.empowerSpell.name
			local spellDur = ah.getSpellDuration(ctx.empowerSpell)

			ctx.empowerTicks = 0
			ctx.empowerSpell = nil
			ctx.empowerBrokeTime = os.clock()
			ctx.empowerBreakDuration = spellDur > 0 and spellDur or config.empowerBreakCooldown

			local picked = helpers.selectOffensiveSpell(ctx.offensiveSpells, ctx)
			if picked then
				ctx.mobile:equipMagic{ source = picked.spell }
				e.session.selectedAction = picked.action
				log:debug("[determinedAction] %s: empower-stuck (pinned: '%s', cooldown=%.0fs) -> %s '%s' (pdist=%.0f)",
				          ctx.actorObj.name, pinnedName, ctx.empowerBreakDuration,
				          picked.action == 5 and "target-spell" or "touch-spell", picked.spell.name, ctx.playerDistance)
			else
				forceMelee(e, ctx)
				log:debug("[determinedAction] %s: empower-stuck (pinned: '%s', cooldown=%.0fs) -> melee (pdist=%.0f)",
				          ctx.actorObj.name, pinnedName, ctx.empowerBreakDuration, ctx.playerDistance)
			end
		end
	end,
}

-- ============================================================
-- Assemble branches
-- ============================================================

local rules = {
	[7] = { fleeSuppressRule },
	[6] = { summonCooldownRule, summonProcessRule },
	[4] = { cantCastSpellRule },
	[5] = { cantCastSpellRule },
	[8] = { empowerKnockedDownRule, empowerCooldownRule, empowerDispelNoEffectRule, empowerProcessRule },
}

-- Build name -> rule index (for `next` chaining if used in future rules).
local index = {}
for _, branch in pairs(rules) do
	for _, rule in ipairs(branch) do
		index[rule.name] = rule
	end
end
rules._index = index

return rules
