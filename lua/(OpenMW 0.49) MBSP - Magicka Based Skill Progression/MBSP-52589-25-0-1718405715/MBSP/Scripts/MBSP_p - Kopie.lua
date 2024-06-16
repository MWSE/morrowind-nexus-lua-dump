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

--local L = core.l10n(MOD_NAME)
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local dynamic = types.Actor.stats.dynamic
local debug = require('openmw.debug')
local useFlipFlop = false
local useRapidfire = false
local casting = false
local frame = 0
local startedCasting = 0
local stoppedCasting = 0
I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if startedCasting < frame-2 and groupname == "spellcast" and key == "self stop" then
		casting = false -- still doesnt fully prevent backtracking, but reduces it to once per cast with rapidfire
		stoppedCasting = frame
	print(groupname,key)
	end
end)

local castingSounds = {
"restoration cast",
"alteration cast",
"destruction cast",
"mysticism cast",
"illusion cast",
"conjuration cast"
}

local function dbg(...)
	if playerSection:get("PrintDebug") then
		print(...)
	end
end

local function hasSilence(actor)
	for a,b in pairs(Actor.activeSpells(actor)) do
		for c,d in pairs(b.effects) do
			if d.id == "silence" then
				return true
			end
		end
	end
	return false
end

local function isCastingSoundPlaying(actor)
	for a,b in pairs(castingSounds) do
		if core.sound.isSoundPlaying(b, actor) then
			return true
		end
	end
	return false
end
local function getAverageSkill(spell)
	local schools = {}
	local totalCost = 0.000001
	local skill = Player.stats.attributes["willpower"](self).base/5 + Player.stats.attributes["luck"](self).base/10 
	for a,effect in pairs(spell.effects) do
		--print(effect.effect.id, effect.effect.baseCost, ((effect.magnitudeMax+effect.magnitudeMin) * (effect.duration + 1 ) + effect.area ) * effect.effect.baseCost / 40)
		local tempCost =  ((effect.magnitudeMax+effect.magnitudeMin) * (effect.duration + 1 ) + effect.area ) * effect.effect.baseCost / 40
		totalCost = totalCost + tempCost
		schools[effect.effect.school] = (schools[effect.effect.school] or 0) + tempCost
	end
	for school,cost in pairs(schools) do
		schools[school] = cost/totalCost
	end
	for school, contribution in pairs(schools) do
		skill = skill + Player.stats.skills[school](self).base*contribution
	end
	return skill
end

input.bindAction('Use', async:callback(function(dt, use, sneak, run)
	frame = frame + 1
	if not casting and frame > stoppedCasting + 1 then use = true end
	useRapidfire = not useRapidfire
	if not playerSection:get("rapidfire") or useRapidfire or Actor.getStance(self) ~= Actor.STANCE.Spell then
	else
		use = false
	end
	if playerSection:get("refundEnabled") and playerSection:get("refundBeforeCasting") then
		local castingSoundPlaying = isCastingSoundPlaying(self)
		if backtrack and not castingSoundPlaying and frame > startedCasting+2 then
			dynamic.magicka(self).current = dynamic.magicka(self).current - backtrack
			dbg("backtracking "..backtrack.." magicka costs because no sound next frame")
			backtrack = nil
		elseif frame > startedCasting + 1 then
			backtrack = nil
		end
		if use 
		and Player.getControlSwitch(self, Player.CONTROL_SWITCH.Magic)
		and not castingSoundPlaying
		and not animation.isPlaying(self, "knockdown")
		and not animation.isPlaying(self, "knockout") 
		and not animation.isPlaying(self, "hit1") 
		and not animation.isPlaying(self, "hit2") 
		and not animation.isPlaying(self, "hit3") 
		and not animation.isPlaying(self, "hit4") 
		and not animation.isPlaying(self, "hit5")
		and not hasSilence(self)
		and not UI.getMode()
		--and not useFlipFlop
		and not casting
		and frame > stoppedCasting + 1
		and frame > startedCasting + 2
		then 
			local cost = Player.getSelectedSpell(self).cost
			local skill = getAverageSkill(Player.getSelectedSpell(self))
			local refund = (1-(playerSection:get("refundMult")^(math.max(0,skill-playerSection:get("refundStart"))/100)))*cost
			if dynamic.magicka(self).current > cost-refund then
				dynamic.magicka(self).current = dynamic.magicka(self).current + refund
				dbg(string.format("MBSP: Skill Level %i, refund: %.2f",skill, refund))
				dbg(stoppedCasting, frame)
				backtrack = refund
				casting = true
				startedCasting = frame
			end
		end
	end
	--useFlipFlop = useFlipFlop or use
	--if not use then
	--	useFlipFlop = false
	--end
	return use
end), {  })
  
I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "MBSP",
	description = "Your Effective Skill level for Magicka refunding is:\nSkill Level + Willpower/5 + Luck/10\n\nThe Formula for Refunds is 1-Scaling^(Skill/100)\n\nThe Experience per Spellcast will never be lower than vanilla, even if the spell costs only 1 magicka."
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
			default = 15,
			argument = {
				min = 1,
				max = 1000,
			},
			renderer = "number",
			description = "magicka per experience point",
		},
		{
			key = "refundEnabled",
			name = "Enable Refund",
			default = true,
			renderer = "checkbox",
			description = "",
		},
		{
			key = "refundMult",
			name = "Magicka Refund Scaling",
			default = 0.5,
			argument = {
				min = 0.1,
				max = 0.9,
			},
			renderer = "number",
			description = "The effective magicka costs get multiplied by this value every 100 levels"
		},
		{
			key = "refundStart",
			default = 35,
			renderer = 'number',
			name = "Refund Skill Start",
			description = "Before this skill level, you won't get and Magicka Refunds.\nThis Value is also subtracted from your effective Level for the refund formula",
			argument = {
				integer = true,
				min = 1,
				max = 1000,
			},
		},
		{
			key = "refundBeforeCasting",
			name = "Refund Before Casting",
			description = "Turns the refund mechanic into real spell cost reduction by applying the refund upfront and ignoring if a cast failed",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "PrintDebug",
			name = "Print Debug Messages",
			default = true,
			renderer = "checkbox",
			description = "into the console",
		},
		{
			key = "rapidfire",
			name = "Bonus: Rapidfire Casting",
			default = false,
			renderer = "checkbox",
			description = "Allows you to spam spells by holding the button",
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
	if not magickaSkills[skillId] then return end
	local magickaXPRate = playerSection:get("magickaXPRate")
	local cost = Player.getSelectedSpell(self).cost
	--dbg(string.format("MBSP: Magic skill \"%s\" increase, base gain = %.5f, cost = %d, XP rate = %d, final gain = %.5f", skillId, params.skillGain, cost, magickaXPRate, math.max(params.skillGain,params.skillGain * cost / magickaXPRate)))
	params.skillGain = math.max(params.skillGain,params.skillGain * cost / magickaXPRate)
	if playerSection:get("refundEnabled") and not playerSection:get("refundBeforeCasting") then
		--local attribute = core.stats.Skill.record(skillId).attribute
		local skill = Player.stats.skills[skillId](self).base + Player.stats.attributes["willpower"](self).base/5 + Player.stats.attributes["luck"](self).base/10 
		local refund = (1-(playerSection:get("refundMult")^(math.max(0,skill-playerSection:get("refundStart"))/100)))*cost
		if refund > 0 then
			if not debug.isGodMode() then
				dbg(string.format("MBSP: Magic school %s# Level %i, refund: %.2f", skillId,skill, refund))
				dynamic.magicka(self).current = dynamic.magicka(self).current + refund
			else
				dbg(string.format("MBSP: Magic school %s# Level %i, refund: %.2f (skipped because of god mode)", skillId,skill, refund))
			end
		end
	end
	 
end)

