local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
I = require("openmw.interfaces")
local input = require('openmw.input')
local async = require('openmw.async')
local animation = require('openmw.animation')
local UI = require('openmw.interfaces').UI
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
MOD_NAME = "MBSP_STANDALONE"
playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)



local dynamic = types.Actor.stats.dynamic
local debug = require('openmw.debug')
local useFlipFlop = false
local useRapidfire = false
local casting = false
local castedSpell = nil
local backtrackFrame = 19999999999
local castingSounds = {
["restoration cast"] = true,
["alteration cast"] = true,
["destruction cast"] = true,
["mysticism cast"] = true,
["illusion cast"] = true,
["conjuration cast"] = true,
}
local addSkillNextFrame = {}

require("scripts.MBSP_settings")


local function dbg(...)
	if playerSection:get("PrintDebug") then
		print(...)
	end
end




local casting = false
local frame = 0
local startedCasting = 0
local stoppedCasting = 0

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
		for _,effect in pairs(spell.effects) do
			local school = effect.effect.school
			local hasMagnitude = effect.effect.hasMagnitude
			local hasDuration = effect.effect.hasDuration
			local appliedOnce = effect.effect.isAppliedOnce
			local minMagn = hasMagnitude and effect.magnitudeMin or 1;
			local maxMagn = hasMagnitude and effect.magnitudeMax or 1;
			--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
				minMagn = math.max(1, minMagn);
				maxMagn = math.max(1, maxMagn);
			-- }
			local duration = hasDuration and effect.duration or 1;
			if (not appliedOnce) then
				duration = math.max(1, duration);
			end
			local fEffectCostMult =  core.getGMST("fEffectCostMult")
			--local iAlchemyMod = core.getGMST("iAlchemyMod") 
	
			local durationOffset = 0;
			local minArea = 0;
			local costMult = fEffectCostMult;
			if playerSpell then
				durationOffset = 1;
				minArea = 1;
			end -- elseif GamePotion
			--    minArea = 1;
			--    costMult = iAlchemyMod;
			-- end
	
			local x = 0.5 * (minMagn + maxMagn);
			x = x * (0.1 * effect.effect.baseCost);
			x = x * (durationOffset + duration);
			x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost);
	
			x = x * costMult;
			if effect.range == core.magic.RANGE.Target then--  if (effect.mData.mRange == ESM::RT_Target)
				x = x * 1.5
			end
			x= math.max(0,x)
			s.schools[school] = (s.schools[school] or 0) + x
			s.calculatedCost = s.calculatedCost + x
		end
		if spell.autocalcFlag then
			s.cost = math.floor(s.calculatedCost+0.5)
		else
			s.cost = math.floor(spell.cost+0.5)
		end
	end
	return spellDB[spellId]
end
I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
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
	--print(groupname,key)
end)

local function hasSilenceParalysis(actor)
	for a,b in pairs(Actor.activeSpells(actor)) do
		for c,d in pairs(b.effects) do
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
	for a,b in pairs(castingSounds) do
		if core.sound.isSoundPlaying(a, actor) then
			return true
		end
	end
	return false
end
local function getAverageSkill(spell)
	local s = checkSpell(spell)
	local skill = Player.stats.attributes["willpower"](self).modified/5 + Player.stats.attributes["luck"](self).modified/10
	for school, cost in pairs(s.schools) do
		skill = skill + Player.stats.skills[school](self).modified*(cost/math.max(1,s.calculatedCost))
	end
	return skill
end

local function getNextRefund()
	local ret = {}
	ret.refund = 0
	ret.mode = playerSection:get("refundMode")
	if ret.mode ~= "Disabled" then
		local spell = Player.getSelectedSpell(self)
		if spell then
			local s = spell and checkSpell(spell)
			if s.isSpell then	
				local cost = s.cost
				local skill = getAverageSkill(spell)-playerSection:get("refundStart")
				local effectiveSpellCost = playerSection:get("refundMult")^(skill/playerSection:get("levelScaling"))-- ex: 0.5^(-25/100) = 1,19
				if playerSection:get("negativeRefunds") then
					effectiveSpellCost = effectiveSpellCost*playerSection:get("spellCostMultiplier")
					effectiveSpellCost = effectiveSpellCost + playerSection:get("spellCostOffset")
					--effectiveSpellCost = effectiveSpellCost*(1+(math.random()-0.5)*playerSection:get("randomSpellCostVariance"))
				end
				--print(effectiveSpellCost)
				effectiveSpellCost = effectiveSpellCost * cost
				local refund = cost-effectiveSpellCost
				if refund > 0 or playerSection:get("negativeRefunds") then
					ret.refund = refund
				end
			end
		end
	end
	return ret
end

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	frame = frame + 1
	--if not casting and frame > stoppedCasting + 1 then use = true end
	useRapidfire = not useRapidfire
	local spell = Player.getSelectedSpell(self)
	if spell and playerSection:get("rapidfire") and useRapidfire and Actor.getStance(self) == Actor.STANCE.Spell then
		use = false
	end
	if playerSection:get("refundMode") == "EXPERIMENTAL" then
		local castingSoundPlaying = isCastingSoundPlaying(self)
		if negativeRefundFail then
			dynamic.magicka(self).current = dynamic.magicka(self).current - negativeRefundFail
			negativeRefundFail = nil
		elseif backtrack and castingSoundPlaying then
			self:sendEvent("MBSP_experimentalMagickaRefund", backtrack)
			backtrack = nil
			backtrackFrame = 1999999999
			--dbg("success")
		elseif backtrack and not castingSoundPlaying and backtrackFrame < frame-2 then
			dynamic.magicka(self).current = dynamic.magicka(self).current - backtrack
			dbg("backtracking "..backtrack.." magicka costs because no sound next frame")
			backtrack = nil
			backtrackFrame = 1999999999
		end
		if use
		and Actor.getStance(self)==Actor.STANCE.Spell
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
			
			local s = spell and checkSpell(spell)
			if spell and s.isSpell then	
				local cost = s.cost
				local skill = getAverageSkill(spell)-playerSection:get("refundStart")
				local effectiveSpellCost = playerSection:get("refundMult")^(skill/playerSection:get("levelScaling"))-- ex: 0.5^(-25/100) = 1,19
				if playerSection:get("negativeRefunds") then
					effectiveSpellCost = effectiveSpellCost*playerSection:get("spellCostMultiplier")
					effectiveSpellCost = effectiveSpellCost + playerSection:get("spellCostOffset")
					--effectiveSpellCost = effectiveSpellCost*(1+(math.random()-0.5)*playerSection:get("randomSpellCostVariance"))
				end
				--print(effectiveSpellCost)
				effectiveSpellCost = effectiveSpellCost * cost
				local refund = cost-effectiveSpellCost
				if refund > 0 or playerSection:get("negativeRefunds") then
					if playerSection:get("negativeRefunds") and dynamic.magicka(self).current+refund < cost then
						negativeRefundFail = refund
						dynamic.magicka(self).current = dynamic.magicka(self).current + refund
						dbg(string.format("MBSP: Magic Level %i, refund: %.2f / %i",skill, refund, cost))
					elseif dynamic.magicka(self).current+refund >= cost then
						dynamic.magicka(self).current = dynamic.magicka(self).current + refund
						dbg(string.format("MBSP: Magic Level %i, refund: %.2f / %i",skill, refund, cost))
						backtrack = refund
						backtrackFrame = frame
						for a,b in pairs( Player.getSelectedSpell(self).effects) do
							--print(core.magic.effects.records[b.id])
							--print(core.magic.effects.records[b.id].castSound)
							local castSound = core.magic.effects.records[b.id].castSound
							if castSound and castSound ~= "" then
								castingSounds[castSound] = true
							end
							--castingSounds[core.magic.effects.records[b.id].castSound] = true
						end	--castingSounds[] = true
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
end), {  })





local magickaSkills = {
    destruction = true,
    restoration = true,
    conjuration = true,
    mysticism = true,
    illusion = true,
    alteration = true,
}



I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if magickaSkills[skillId] and castedSpell then
		--local magickaXPRate = playerSection:get("magickaXPRate")
		local magickaXPMult = playerSection:get("magickaXPMult")
		local cost = checkSpell(castedSpell).cost
		if magickaXPMult > 0 then
			local newGain = params.skillGain/2 + params.skillGain * cost * magickaXPMult
			dbg(string.format("MBSP: %s XP + %.4f (= %.2f /2 + %.2f *%.2f *%i)",skillId, newGain, params.skillGain, params.skillGain, magickaXPMult, cost ))
			params.skillGain = newGain
		end
		if playerSection:get("refundMode") == "Refund" then
			--local attribute = core.stats.Skill.record(skillId).attribute
			local skill = getAverageSkill(castedSpell)-playerSection:get("refundStart") --Player.stats.skills[skillId](self).base + Player.stats.attributes["willpower"](self).base/5 + Player.stats.attributes["luck"](self).base/10 
			local refund = (1-(playerSection:get("refundMult")^(skill/playerSection:get("levelScaling"))))*cost
			if refund > 0 then
				if not debug.isGodMode() then
					dbg(string.format("MBSP: %s# Level %i, refund: %.2f / %i", skillId, skill, refund, cost))
					dynamic.magicka(self).current = dynamic.magicka(self).current + refund
				else
					dbg(string.format("MBSP: %s# Level %i, refund: %.2f / %i (skipped because of god mode)", skillId, skill, refund, cost))
				end
			end
		end
		
	end
	--dbg(skillId.." "..(math.floor(params.skillGain*100)/100).." XP * "..(math.floor((playerSection:get("SKILL_MULT_"..skillId) or 1)*100)/100))
	params.skillGain = params.skillGain * (playerSection:get("SKILL_MULT_"..skillId) or 1)
	if playerSection:get("CATCH_UP_SPEED") > 1 then
		local speedMult = math.max(1,playerSection:get("CATCH_UP_SPEED")*(1-Player.stats.skills[skillId](self).base/(types.Actor.stats.level(self).current*2)) + 1*(Player.stats.skills[skillId](self).base/(types.Actor.stats.level(self).current*2)))
		if speedMult > 1 then
			params.skillGain = params.skillGain * speedMult
			--dbg("MBSP: Catch Up mult: "..(math.floor(speedMult*100)/100))
		end
	end
	
end)

I.SkillProgression.addSkillLevelUpHandler(function(skillId, source)
	if playerSection:get("enableUncapper") then
		if source ~= I.SkillProgression.SKILL_INCREASE_SOURCES.Jail then
			if Player.stats.skills[skillId](self).base >= 100 then
				--if Player.stats.skills[skillId](self).progress >= 1 then
					Player.stats.skills[skillId](self).progress = Player.stats.skills[skillId](self).progress%1
					ambient.playSound("skillraise")
					if core.stats.Skill.records[skillId] then
						local attribute = core.stats.Skill.records[skillId].attribute
						types.Actor.stats.level(self).skillIncreasesForAttribute[attribute] = types.Actor.stats.level(self).skillIncreasesForAttribute[attribute] + 1
					end
					Player.stats.skills[skillId](self).base = Player.stats.skills[skillId](self).base + 1
					dbg("MBSP Uncapper: +1 "..skillId)
					--I.SkillProgression.skillLevelUp(skillId, I.SkillProgression.SKILL_INCREASE_SOURCES.Usage)
				--end
			end
		end
	end
end)

return {
	engineHandlers ={ 
		--onFrame = onFrame,
		--onUpdate = onUpdate,
	},
	interfaceName = "MBSP",
	interface = {
		version = 1,
		getNextRefund = getNextRefund,
	}
}
