-- =============================================================================
-- VAIN.action_helpers
-- Pure query helpers and meleeFallback, shared by reaction_rules.lua.
-- Extracted from main.lua to avoid a circular dependency.
-- These functions only read engine state; they make no decisions.
-- =============================================================================
local config = require("VAIN.config").config
local log = mwse.Logger.new { modName = "VAIN", moduleName = "action_helpers", level = config.logLevel }

local M = {}

--- Returns true if any of the spell's effects are currently active on ref.
---@param ref tes3reference
---@param spell tes3spell
---@return boolean
function M.isSpellActive(ref, spell)
	for _, eff in ipairs(spell.effects) do
		if eff.id ~= -1 and tes3.isAffectedBy { reference = ref, effect = eff.id } then
			log:trace("isSpellActive: '%s' effect %d active on %s", spell.name, eff.id, ref.id)
			return true
		end
	end
	return false
end

--- Returns the longest effect duration in a spell (seconds). 0 if all effects are instant.
---@param spell tes3spell
---@return number
function M.getSpellDuration(spell)
	local maxDur = 0
	for _, eff in ipairs(spell.effects) do
		if eff.id ~= -1 and eff.duration > maxDur then
			maxDur = eff.duration
		end
	end
	return maxDur
end

--- Returns true if the spell contains a Dispel effect.
---@param spell tes3spell
---@return boolean
function M.isDispelSpell(spell)
	for _, eff in ipairs(spell.effects) do
		if eff.id == tes3.effect.dispel then
			log:trace("isDispelSpell: '%s' contains dispel", spell.name)
			return true
		end
	end
	return false
end

--- Returns true if the mobile currently has at least one active harmful magic effect.
---@param mobile tes3mobileActor
---@return boolean
function M.hasHarmfulEffect(mobile)
	for _, activeEff in ipairs(mobile.activeMagicEffectList) do
		if activeEff.harmful then
			log:trace("hasHarmfulEffect: %s has a harmful effect active", mobile.reference.id)
			return true
		end
	end
	return false
end

--- Returns the correct fallback action number when forcing melee.
--- Bipeds with no weapon readied use h2h (3) instead of melee-weapon (1).
---@param ctx table
---@return integer
function M.meleeFallback(ctx)
	if ctx.attackType == 1 and not ctx.readiedWeapon then
		return 3
	end
	return ctx.attackType or 1
end

return M
