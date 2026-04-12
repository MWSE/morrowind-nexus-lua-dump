local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local input = require('openmw.input')
local async = require('openmw.async')
local animation = require('openmw.animation')
local UI = require('openmw.interfaces').UI
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
local util = require('openmw.util')
local debug = require('openmw.debug')
I = require("openmw.interfaces")
MOD_NAME = "MBSP_STANDALONE"

local stats = {}
statNames = {}
for _, rec in ipairs(core.stats.Attribute.records) do
	stats[rec.id] = types.NPC.stats.attributes[rec.id](self)
	statNames[rec.id] = rec.name
end
for _, rec in ipairs(core.stats.Skill.records) do
	stats[rec.id] = types.NPC.stats.skills[rec.id](self)
	statNames[rec.id] = rec.name
end
stats.level = types.Actor.stats.level(self)
stats.health = types.Actor.stats.dynamic.health(self)
stats.magicka = types.Actor.stats.dynamic.magicka(self)

local useFlipFlop = false
local useRapidfire = false
local casting = false
local castedSpell = nil
local negativeRefundFail
local backtrack
local frame = 0
local startedCasting = 0
local stoppedCasting = 0
local backtrackFrame = 19999999999

local fEffectCostMult = core.getGMST("fEffectCostMult")

local castingSounds = {
	["restoration cast"] = true,
	["alteration cast"] = true,
	["destruction cast"] = true,
	["mysticism cast"] = true,
	["illusion cast"] = true,
	["conjuration cast"] = true,
}

require("scripts.MBSP.MBSP_settings")

local function dbg(...)
	if S_PrintDebug then
		print(...)
	end
end

-- lazy registration flags
local animationRegistered = false
local useRegistered = false
local skillUsedRegistered = false

--------------------------------------------------------------- Spell cost calculation ---------------------------------------------------------------

local spellDB = {}
local function checkSpell(spell)
	local spellId = spell.id
	if not spellDB[spellId] then
		spellDB[spellId] = {}
		local s = spellDB[spellId]
		s.schools = {}
		s.calculatedCost = 0
		s.autoCalculated = spell.autocalcFlag
		s.isSpell = spell.type == core.magic.SPELL_TYPE.Spell
		local playerSpell = spellId:sub(1,9) == "Generated"
		for _, effect in ipairs(spell.effects) do
			local school = effect.effect.school
			local hasMagnitude = effect.effect.hasMagnitude
			local hasDuration = effect.effect.hasDuration
			local appliedOnce = effect.effect.isAppliedOnce
			local minMagn = hasMagnitude and effect.magnitudeMin or 1
			local maxMagn = hasMagnitude and effect.magnitudeMax or 1
			--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
				minMagn = math.max(1, minMagn)
				maxMagn = math.max(1, maxMagn)
			-- }
			local duration = hasDuration and effect.duration or 1
			if not appliedOnce then
				duration = math.max(1, duration)
			end
			--local iAlchemyMod = core.getGMST("iAlchemyMod") 
			
			local durationOffset = 0
			local minArea = 0
			local costMult = fEffectCostMult
			if playerSpell then
				durationOffset = 1
				minArea = 1
			end -- elseif GamePotion
			--    minArea = 1;
			--    costMult = iAlchemyMod;
			-- end
			
			local x = 0.5 * (minMagn + maxMagn)
			x = x * (0.1 * effect.effect.baseCost)
			x = x * (durationOffset + duration)
			x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost)
			x = x * costMult
			if effect.range == core.magic.RANGE.Target then
				x = x * 1.5
			end
			x = math.max(0, x)
			s.schools[school] = (s.schools[school] or 0) + x
			s.calculatedCost = s.calculatedCost + x
		end
		if spell.autocalcFlag then
			s.cost = math.floor(s.calculatedCost + 0.5)
		else
			s.cost = math.floor(spell.cost + 0.5)
		end
	end
	return spellDB[spellId]
end

--------------------------------------------------------------- Refund helpers ---------------------------------------------------------------

local function getAverageSkill(spell)
	local s = checkSpell(spell)
	local skill = stats.willpower.modified/5 + stats.luck.modified/10
	for school, cost in pairs(s.schools) do
		skill = skill + stats[school].modified * (cost / math.max(1, s.calculatedCost))
	end
	return skill
end

local function calcRefund(spell)
	local s = checkSpell(spell)
	if not s.isSpell then return 0, 0 end
	local cost = s.cost
	local skill = getAverageSkill(spell) - S_refundStart
	local effectiveSpellCost = S_refundMult ^ (skill / S_levelScaling)
	if S_negativeRefunds then
		effectiveSpellCost = effectiveSpellCost * S_spellCostMultiplier
		effectiveSpellCost = effectiveSpellCost + S_spellCostOffset
	end
	effectiveSpellCost = effectiveSpellCost * cost
	local refund = cost - effectiveSpellCost
	return refund, cost, skill
end

local function getNextRefund()
	local ret = {}
	ret.refund = 0
	ret.mode = S_refundMode
	if ret.mode ~= "Disabled" then
		local spell = Player.getSelectedSpell(self)
		if spell then
			local refund = calcRefund(spell)
			if refund > 0 or S_negativeRefunds then
				ret.refund = refund
			end
		end
	end
	return ret
end

--------------------------------------------------------------- Animation handler ---------------------------------------------------------------

function registerAnimation()
	if animationRegistered then return end
	if S_magickaXPMult <= 0 and S_refundMode == "Disabled" and not S_rapidfire then return end
	animationRegistered = true
	I.AnimationController.addTextKeyHandler('', function(groupname, key)
		if groupname == "spellcast" then
			if key == "self start" or key == "touch start" or key == "target start" then
				castedSpell = Player.getSelectedSpell(self)
				casting = true
			elseif key == "self stop" or key == "touch stop" or key == "target stop" then
				castedSpell = nil
				casting = false
				stoppedCasting = frame
			end
		end
	end)
end
registerAnimation()

--------------------------------------------------------------- Helpers for experimental refund ---------------------------------------------------------------

local function hasSilenceParalysis(actor)
	for a, b in pairs(Actor.activeSpells(actor)) do
		for c, d in pairs(b.effects) do
			if d.id == "silence" then
				return true
			elseif d.id == "paralyze" then
				return true
			end
		end
	end
	return false
end

local function isCastingSoundPlaying(actor)
	for a, b in pairs(castingSounds) do
		if core.sound.isSoundPlaying(a, actor) then
			return true
		end
	end
	return false
end

--------------------------------------------------------------- Use action (experimental refund + rapidfire) ---------------------------------------------------------------

function registerUse()
	if useRegistered then return end
	if S_refundMode ~= "EXPERIMENTAL" and not S_rapidfire then return end
	useRegistered = true
	input.bindAction('Use', async:callback(function(dt, use, sneak, run)
		frame = frame + 1
		useRapidfire = not useRapidfire
		local spell = Player.getSelectedSpell(self)
		if spell and S_rapidfire and useRapidfire and Actor.getStance(self) == Actor.STANCE.Spell then
			use = false
		end
		if S_refundMode == "EXPERIMENTAL" then
			local castingSoundPlaying = isCastingSoundPlaying(self)
			if negativeRefundFail then
				stats.magicka.current = stats.magicka.current - negativeRefundFail
				negativeRefundFail = nil
			elseif backtrack and castingSoundPlaying then
				self:sendEvent("MBSP_experimentalMagickaRefund", backtrack)
				backtrack = nil
				backtrackFrame = 1999999999
			elseif backtrack and not castingSoundPlaying and backtrackFrame < frame-2 then
				stats.magicka.current = stats.magicka.current - backtrack
				dbg("backtracking "..backtrack.." magicka costs because no sound next frame")
				backtrack = nil
				backtrackFrame = 1999999999
			end
			if use
			and Actor.getStance(self) == Actor.STANCE.Spell
			and not castingSoundPlaying
			and not animation.isPlaying(self, "knockdown")
			and not animation.isPlaying(self, "knockout")
			and not animation.isPlaying(self, "hit1")
			and not animation.isPlaying(self, "hit2")
			and not animation.isPlaying(self, "hit3")
			and not animation.isPlaying(self, "hit4")
			and not animation.isPlaying(self, "hit5")
			and not hasSilenceParalysis(self)
			and not UI.getMode()
			and not useFlipFlop
			and not casting
			and not backtrack
			and not debug.isGodMode()
			then
				local refund, cost, skill = calcRefund(spell)
				if cost > 0 then
					if refund > 0 or S_negativeRefunds then
						if S_negativeRefunds and stats.magicka.current + refund < cost then
							negativeRefundFail = refund
							stats.magicka.current = stats.magicka.current + refund
							dbg(string.format("MBSP: Magic Level %i, refund: %.2f / %i", skill, refund, cost))
						elseif stats.magicka.current + refund >= cost then
							stats.magicka.current = stats.magicka.current + refund
							dbg(string.format("MBSP: Magic Level %i, refund: %.2f / %i", skill, refund, cost))
							backtrack = refund
							backtrackFrame = frame
							for _, b in ipairs(Player.getSelectedSpell(self).effects) do
								local castSound = core.magic.effects.records[b.id].castSound
								if castSound and castSound ~= "" then
									castingSounds[castSound] = true
								end
							end
						end
					end
				end
			end
		end
		useFlipFlop = useFlipFlop or use
		if not use then
			useFlipFlop = false
		end
		return use
	end), {})
end
registerUse()

--------------------------------------------------------------- Skill used handler (magicka XP + refund only) ---------------------------------------------------------------

local magickaSkills = {
	destruction = true,
	restoration = true,
	conjuration = true,
	mysticism = true,
	illusion = true,
	alteration = true,
}

function registerSkillUsed()
	if skillUsedRegistered then return end
	if S_magickaXPMult <= 0 and S_refundMode ~= "Refund" then return end
	skillUsedRegistered = true
	I.SkillProgression.addSkillUsedHandler(function(skillId, params)
		if magickaSkills[skillId] and castedSpell then
			local magickaXPMult = S_magickaXPMult
			local cost = checkSpell(castedSpell).cost
			-- magicka-based XP
			if magickaXPMult > 0 then
				local originalSkillGain = params.skillGain
				local newGain = originalSkillGain/2 + originalSkillGain * cost * magickaXPMult
				dbg(string.format("MBSP: %s XP + %.4f (= %.2f /2 + %.2f *%.2f *%i)",
					skillId, newGain, params.skillGain, params.skillGain, magickaXPMult, cost))
				params.skillGain = newGain
			end
			-- refund on successful cast
			if S_refundMode == "Refund" then
				local skill = getAverageSkill(castedSpell) - S_refundStart
				local refund = (1 - (S_refundMult ^ (skill / S_levelScaling))) * cost
				if refund > 0 then
					if not debug.isGodMode() then
						dbg(string.format("MBSP: %s# Level %i, refund: %.2f / %i",
							skillId, skill, refund, cost))
						stats.magicka.current = stats.magicka.current + refund
					else
						dbg(string.format("MBSP: %s# Level %i, refund: %.2f / %i (skipped because of god mode)",
							skillId, skill, refund, cost))
					end
				end
			end
		end
	end)
end
registerSkillUsed()

--------------------------------------------------------------- Effective spell cost (for interface + MagicWindow) ---------------------------------------------------------------

local function getSpellEffectiveCost(spellId)
	local spell = core.magic.spells.records[spellId]
	if not spell then return nil end
	local s = checkSpell(spell)
	if not s.isSpell then return s.cost, s.cost, 0 end
	local refund, cost = calcRefund(spell)
	if refund > 0 or S_negativeRefunds then
		return cost - refund, cost, refund
	end
	return cost, cost, 0
end

--------------------------------------------------------------- MagicWindow extender ---------------------------------------------------------------

local function initMagicWindow()
	if not I.MagicWindow then return end
	local MWE = I.MagicWindow
	local MWE_C = MWE.Constants

	local fFatigueBase = core.getGMST("fFatigueBase")
	local fFatigueMult = core.getGMST("fFatigueMult")
	local fatigue = types.Actor.stats.dynamic.fatigue(self)
	local configPlayer = require('scripts.MagicWindowExtender.config.player')

	MWE.overrideLineBuilder('SPELL', function(spellId, editMode)
		local spellRecord = core.magic.spells.records[spellId]
		local override = MWE.Spells.getCustomSpell(spellId)
		local pinned = MWE.getStat(MWE_C.TrackedStats.PINNED) or {}

		return {
			id = spellId,
			icon = function()
				if configPlayer.tweaks.b_SpellIcons then
					return (override and override.effects and override.effects[1].effect.icon) or spellRecord.effects[1].effect.icon
				elseif configPlayer.tweaks.b_PinnedSpellIcons and pinned['spells'] and pinned['spells'][spellId] and not editMode then
					return 'textures/MagicWindowExtender/pinned_true.dds'
				else
					return nil
				end
			end,
			label = override and override.name or spellRecord.name,
			value = function()
				local effectiveCost, baseCost, refund = getSpellEffectiveCost(spellId)
				if not effectiveCost then return { string = '' } end

				local chance = 0
				if debug.isGodMode() then
					chance = 100
				elseif spellRecord.type == core.magic.SPELL_TYPE.Spell then
					local activeEffects = self.type.activeEffects(self)
					if activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence).magnitude > 0 then
						chance = 0
					elseif spellRecord.alwaysSucceedFlag then
						chance = 100
					elseif stats.magicka.current < effectiveCost then
						chance = 0
					else
						local y = math.huge
						local lowestSkill = 0
						for _, effect in ipairs(spellRecord.effects) do
							local baseEffect = effect.effect
							local x = baseEffect.hasDuration and effect.duration or 1
							if not baseEffect.isAppliedOnce then
								x = math.max(x, 1)
							end
							x = x * 0.1 * baseEffect.baseCost
							x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
							x = x + 0.05 * baseEffect.baseCost * effect.area
							if effect.range == core.magic.RANGE.Target then
								x = x * 1.5
							end
							x = x * fEffectCostMult
							local sk = 2 * stats[baseEffect.school].modified
							if (sk - x) < y then
								y = sk - x
								lowestSkill = sk
							end
						end
						local castBonus = -activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound).magnitude
						local fatigueTerm = fFatigueBase - fFatigueMult * (1 - fatigue.current / fatigue.base)
						local castChance = (lowestSkill - util.round(baseCost) + castBonus + 0.2 * stats.willpower.modified + 0.1 * stats.luck.modified) * fatigueTerm
						chance = math.floor(util.clamp(castChance, 0, 100))
					end
				end

				local color = nil
				if S_refundMode ~= "Disabled" and refund ~= 0 then
					if effectiveCost < baseCost then
						color = MWE_C.Colors.POSITIVE
					elseif effectiveCost > baseCost then
						color = MWE_C.Colors.DAMAGED
					end
				end
				return { string = ' ' .. tostring(util.round(effectiveCost)) .. '/' .. tostring(chance), color = color }
			end,
			active = function()
				local selectedSpell = self.type.getSelectedSpell(self)
				return selectedSpell and selectedSpell.id == spellId
			end,
			onClick = function()
				if input.isShiftPressed() then
					MWE.Templates.MAGIC.tryDelete(spellId)
					return
				end
				self.type.setSelectedSpell(self, spellRecord)
				MWE.setDirtyDelayed()
			end,
			tooltip = function()
				return MWE.TooltipBuilders.SPELL(spellId)
			end,
			editInfo = {
				id = spellId,
				type = 'spells',
				editing = editMode == true,
			},
		}
	end)
end
async:newUnsavableSimulationTimer(0.1, initMagicWindow)

--------------------------------------------------------------- Return ---------------------------------------------------------------

return {
	engineHandlers = {},
	interfaceName = "MBSP",
	interface = {
		version = 3,
		getNextRefund = getNextRefund,
		getSpellEffectiveCost = getSpellEffectiveCost,
	},
}