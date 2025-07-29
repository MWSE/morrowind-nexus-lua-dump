local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require("openmw.interfaces")
local input = require('openmw.input')
local async = require('openmw.async')
local animation = require('openmw.animation')
local MOD_NAME = "MBSP_STANDALONE"
local UI = require('openmw.interfaces').UI
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
--local L = core.l10n(MOD_NAME)
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
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

local catchupSpeed = 1 -- 1=default = no catchup boost. only gradually activates if the skill is below character level * 2
local skillMultipliers= { -- suggested multipliers (frequently used skills = 0.9, rare skills up to 1.5)
["acrobatics"  ] = 0.8,
["alchemy"     ] = 1  ,
["alteration"  ] = 1.4,
["armorer"     ] = 1  ,
["athletics"   ] = 0.9,
["axe"         ] = 0.9,
["block"       ] = 1  ,
["bluntweapon" ] = 0.9,
["conjuration" ] = 1.5,
["destruction" ] = 0.9, --
["enchant"     ] = 1.1,
["handtohand"  ] = 0.9,
["heavyarmor"  ] = 1.2,
["illusion"    ] = 1.5,
["lightarmor"  ] = 1.1,
["longblade"   ] = 0.9,
["marksman"    ] = 0.9,
["mediumarmor" ] = 1.1,
["mercantile"  ] = 1  ,
["mysticism"   ] = 1.5,
["restoration" ] = 1  ,
["security"    ] = 1.1,
["shortblade"  ] = 0.9,
["sneak"       ] = 1.6,
["spear"       ] = 0.9,
["speechcraft" ] = 1.1,
["unarmored"   ] = 1.3,
}

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
  
I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "MBSP",
	description = "Your effective skill level for magicka refunding is:\nSkill Level + Willpower/5 + Luck/10 - RefundStart\n\nThe formula for the effective mana costs after refund is Scaling^(Skill/LevelScaling) (for example 0.5^(50/100) = 0.7071)\n\nThe experience per successful spell cast is halfed but you get experience equal to 1 spellcast every X magicka spent (->'Magicka XP Rate' setting)"
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "magickaXPRate",
			name = "Magicka XP Rate",
			description = "spent magicka per experience point\nIgnores Refunds\n0 = disabled for compatibility with ncgd or other leveling/uncapper mods",
			default = 15,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "enableUncapper",
			name = "Enable Uncapper",
			description = "Allows any skill to reach a higher level than 100.\nIf you want, there's also multipliers for every skill's xp in the lua file that i don't wanna list here.",
			default = false,
			renderer = 'checkbox',
		},
		{
			key = "refundMode",
			name = "Enable Refund",
			description = "Refund magicka on successful casts or before spending the magicka (EXPERIMENTAL)",
			default = "Refund", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "LocalizationContext", 
				items = {"Disabled", "Refund", "EXPERIMENTAL"},
			},
		},
		{
			key = "refundStart",
			name = "Refund: Skill Start",
			description = "Before this skill level, you won't get any Magicka Refunds.\nThis Value is also subtracted from your effective Level for the refund formula",
			default = 35,
			renderer = 'number',
			argument = {
				integer = true,
				min = 1,
				max = 1000,
			},
		},
		{
			key = "refundMult",
			name = "Refund: Magicka Cost Scaling",
			description = "The effective magicka costs get multiplied by this value every 100 levels (by default, setting below)",
			default = 0.5,
			argument = {
				min = 0.01,
				max = 10,
			},
			renderer = "number",
		},
		{
			key = "levelScaling",
			name = "Refund: Level Scaling",
			description = "Every 100 levels (by default, or whatever this setting's value is) your effective spell costs get multiplied by 0.5 (by default, setting above), so your effective spell costs would be 25% at level 200 with default settings for example.",
			default = 100,
			renderer = 'number',
			argument = {
				integer = true,
				min = 1,
				max = 10000,
			},
		},
		{
			key = "negativeRefunds",
			name = "Refunds Can Be Negative",
			description = "For example when your skill is lower than the 'Refund Skill Start'\nRequires the 'EXPERIMENTAL' refund mode\nfor example: 0.5^(-25/100) = 1.19x",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "spellCostMultiplier",
			name = "Spell Cost Multiplier",
			description = "Requires the 'Negative Refunds' setting and the 'EXPERIMENTAL' refund mode!\nThis is a multiplier on the spell costs after the exponential refund formula was applied",
			default = 1,
			renderer = 'number',
			argument = {
				min = 0,
				max = 10000,
			},
		},
		{
			key = "spellCostOffset",
			name = "Spell Cost Offset",
			description = "Requires the 'Negative Refunds' setting and the 'EXPERIMENTAL' refund mode!\nThis setting adds or subtracts a portion of the spell's base(vanilla) cost to the final result after the multiplier above has been applied",
			default = 0,
			renderer = 'number',
			argument = {
				min = -1,
				max = 1,
			},
		},
		{
			key = "PrintDebug",
			name = "Print Debug Messages",
			description = "into the console",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "rapidfire",
			name = "Experimental: Rapidfire Casting",
			description = "Allows you to spam spells by holding the button",
			default = false,
			renderer = "checkbox",
		},
	}
}

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
		local magickaXPRate = playerSection:get("magickaXPRate")
		local cost = checkSpell(castedSpell).cost
		if magickaXPRate > 0 then
			local newGain = params.skillGain/2 + params.skillGain * cost / magickaXPRate
			dbg(string.format("MBSP: %s XP + %.4f (= %.2f /2 + %.2f /%i *%i)",skillId, newGain, params.skillGain, params.skillGain, magickaXPRate, cost ))
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
	params.skillGain = params.skillGain * (skillMultipliers[skillId] or 1)
	if catchupSpeed > 1 then
		local speedMult = math.max(1,catchupSpeed*(1-Player.stats.skills[skillId](self).base/(types.Actor.stats.level(self).current*2)) + 1*(Player.stats.skills[skillId](self).base/(types.Actor.stats.level(self).current*2)))
		--print(speedMult)
		params.skillGain = params.skillGain * speedMult
	end
	if playerSection:get("enableUncapper") then
		if Player.stats.skills[skillId](self).base >= 100 then
			if Player.stats.skills[skillId](self).progress >= 1 then
				Player.stats.skills[skillId](self).progress = Player.stats.skills[skillId](self).progress%1
				ambient.playSound("skillraise")
				if core.stats.Skill.records[skillId] then
					local attribute = core.stats.Skill.records[skillId].attribute
					types.Actor.stats.level(self).skillIncreasesForAttribute[attribute] = types.Actor.stats.level(self).skillIncreasesForAttribute[attribute] + 1
				end
				Player.stats.skills[skillId](self).base = Player.stats.skills[skillId](self).base + 1
			end
		end
	end
end)


return {
	engineHandlers ={ 
		--onFrame = onFrame,
		--onUpdate = onUpdate,
	}
}
