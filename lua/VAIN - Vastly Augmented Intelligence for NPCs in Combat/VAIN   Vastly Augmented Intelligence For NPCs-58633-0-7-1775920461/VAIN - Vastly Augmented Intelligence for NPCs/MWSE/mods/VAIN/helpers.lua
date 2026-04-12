-- =============================================================================
-- VAIN.helpers
-- Low-level engine touchpoints used by operators. Pure side-effect functions -
-- no decision logic. If a function reads or writes the engine without making
-- a choice about *whether* to do so, it lives here.
-- =============================================================================
local data = require("VAIN.data")
local config = require("VAIN.config").config

local M = {}

--- Ensure the actor has at least `count` stones in inventory and equips one.
---@param ref tes3reference
---@param mobile tes3mobileActor
---@param actorObj tes3actor
---@param count integer
function M.equipStone(ref, mobile, actorObj, count)
	local stone = data.stone
	if not stone then
		return
	end
	if not actorObj.inventory:contains(stone) then
		tes3.addItem { reference = ref, item = stone, count = count }
	end
	mobile:equip{ item = stone }
	ref:updateEquipment()
end

--- Apply a randomly chosen ranged "spell" (actually an alchemy projectile) to
--- the reference. No-ops if the actor has no ranged spells.
---@param ref tes3reference
---@param rangedSpells string[]?
function M.fireRangedSpell(ref, rangedSpells)
	if not rangedSpells then
		return
	end
	local source = data.spells[table.choice(rangedSpells)]
	if not source then
		return
	end
	tes3.applyMagicSource { reference = ref, source = source }
end

--- Combat debug message box, gated by config.m4.
function M.dbg(fmt, ...)
	if config.m4 then
		tes3.messageBox(fmt, ...)
	end
end

-- =============================================================================
-- Offensive spell utilities
-- =============================================================================

--- Returns true if every harmful effect in the spell is in the forbidden set.
--- A spell with at least one non-forbidden harmful effect is still valid.
--- Used to exclude spells like Soul Trap or Demoralize that are useless against
--- the player character.
---@param spell tes3spell
---@return boolean
function M.hasOnlyForbiddenEffects(spell)
	for _, eff in ipairs(spell.effects) do
		if eff.id ~= -1 and not data.forbiddenOffensiveEffects[eff.id] then
			return false -- at least one non-forbidden effect: spell is valid
		end
	end
	return true -- all effects are forbidden
end

--- Scan the actor's spell list and return a flat list of all qualifying offensive
--- spells. A spell qualifies if it is castable (isActiveCast), has at least one
--- harmful effect with target or touch range, and is not composed entirely of
--- forbidden effects (see data.forbiddenOffensiveEffects).
--- Each entry: { spell = tes3spell, action = 5|4 } (5 = target-range, 4 = touch-range).
---@param actorObj tes3actor
---@return table  list of {spell, action} entries (may be empty)
function M.buildOffensiveSpellList(actorObj)
	local list = {}
	for _, sp in pairs(actorObj.spells) do ---@diagnostic disable-line: undefined-field
		if sp.isActiveCast and not M.hasOnlyForbiddenEffects(sp) then
			-- Scan all effects and prefer target-range (5) over touch-range (4).
			-- A spell can have both; classifying by the first match could wrongly
			-- mark a target-range spell as touch-range, vetoing it at distance.
			local bestAction = nil
			for _, eff in ipairs(sp.effects) do
				if eff.id ~= -1 then
					local magicEff = tes3.getMagicEffect(eff.id)
					if magicEff and magicEff.isHarmful then
						local rt = eff.rangeType
						if rt == tes3.effectRange.target then
							bestAction = 5 -- target-range: can't do better, stop scanning
							break
						elseif rt == tes3.effectRange.touch and bestAction == nil then
							bestAction = 4 -- touch-range: keep scanning in case target comes later
						end
					end
				end
			end
			if bestAction then
				list[#list + 1] = { spell = sp, action = bestAction }
			end
		end
	end
	return list
end

--- Returns true if the list contains at least one target-range spell affordable
--- at the given magicka level.
---@param spells table?
---@param magicka number
---@return boolean
function M.hasAffordableTargetSpell(spells, magicka)
	if not spells then
		return false
	end
	for _, e in ipairs(spells) do
		if e.action == 5 and magicka >= e.spell.magickaCost then
			return true
		end
	end
	return false
end

--- Registered scoring rules. Set from main.lua via setScoringRules().
local scoringRules = nil ---@type table?

--- Register the spell scoring rules. Called once during initialized.
---@param rules table  list of { name, weight, score } rules
function M.setScoringRules(rules)
	scoringRules = rules
end

--- Score a single spell entry against all scoring rules.
--- Returns 0 on any veto, otherwise the product of (1 + weight * score) factors.
---@param entry table
---@param ctx table
---@param rules table
local function scoreEntry(entry, ctx, rules)
	local total = 1
	for _, rule in ipairs(rules) do
		local s = rule.score(entry, ctx)
		if s == 0 then
			return 0
		end
		total = total * (1 + rule.weight * s)
	end
	return total
end

--- Pick the highest-scoring affordable offensive spell for ctx.
--- Returns nil if no spell passes all hard constraints.
---@param spells table?
---@param ctx table  CairnContext (needs magickaCurrent, playerDistance)
---@return table?  {spell: tes3spell, action: integer}
function M.selectOffensiveSpell(spells, ctx)
	if not spells or #spells == 0 then
		return nil
	end
	if not scoringRules then
		return nil
	end
	local best, bestScore = nil, 0
	for _, entry in ipairs(spells) do
		local s = scoreEntry(entry, ctx, scoringRules)
		if s > bestScore then
			best, bestScore = entry, s
		end
	end
	return best
end

return M
