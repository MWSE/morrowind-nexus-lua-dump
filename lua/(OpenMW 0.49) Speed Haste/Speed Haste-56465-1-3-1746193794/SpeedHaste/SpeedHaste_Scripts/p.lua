local core = require('openmw.core')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local I = require("openmw.interfaces")
local input = require('openmw.input')
local async = require('openmw.async')
local animation = require('openmw.animation')
local MOD_NAME = "SpeedHaste"
local UI = require('openmw.interfaces').UI
local Player = require('openmw.types').Player
local Actor = require('openmw.types').Actor
local ui = require('openmw.ui')
local playerSection = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local dynamic = types.Actor.stats.dynamic

local animGroups = {
	["idle2w"] = true,
	["weapontwowide"] = true,
	["idlehh"] = true,
	["handtohand"] = true,
	["idle1h"] = true,
	["weapononehand"] = true,
	["idle1h"] = true,
	["throwweapon"] = true,
	["idlecrossbow"] = true,
	["crossbow"] = true,
	["idle1h"] = true,
	["bowandarrow"] = true,
	["idlespell"] = true,
	["spellcast"] = true,
	["idle2c"] = true,
	["weapontwohand"] = true,
}

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

local function getAverageSkill(spell)
	local s = checkSpell(spell)
	local skill = 0--Player.stats.attributes["willpower"](self).modified/5 + Player.stats.attributes["luck"](self).modified/10
	for school, cost in pairs(s.schools) do
		skill = skill + Player.stats.skills[school](self).modified*(cost/math.max(1,s.calculatedCost))
	end
	return skill
end

I.AnimationController.addTextKeyHandler('', function(groupname, key) --self start/stop, touch start/stop, target start/stop
	--print(groupname)
	if animGroups[groupname] then
		local speed = Player.stats.attributes["speed"](self).modified
		local modifier1 = math.max(0, speed - playerSection:get("MinLevel"))*playerSection:get("HastePerLevel")/100
		local weapon = Actor.getEquipment(self,Actor.EQUIPMENT_SLOT.CarriedRight)
		local skill = "handtohand"
		local modifier2 = 0
		local stance = Actor.getStance(self)
		if stance == Actor.STANCE.Weapon and playerSection:get("HastePerWeaponSkill") > 0 then
			if weapon and types.Weapon.objectIsInstance(weapon) then
				local weaponType = types.Weapon.record(weapon).type
				if weaponType == types.Weapon.TYPE.AxeOneHand then
					skill = "axe"
				elseif weaponType == types.Weapon.TYPE.AxeTwoHand then
					skill = "axe"
				elseif weaponType == types.Weapon.TYPE.BluntOneHand then
					skill = "bluntweapon"
				elseif weaponType == types.Weapon.TYPE.BluntTwoClose then
					skill = "bluntweapon"
				elseif weaponType == types.Weapon.TYPE.LongBladeOneHand then
					skill = "longblade"
				elseif weaponType == types.Weapon.TYPE.LongBladeTwoHand then
					skill = "longblade"
				elseif weaponType == types.Weapon.TYPE.MarksmanBow then
					skill = "marksman"
				elseif weaponType == types.Weapon.TYPE.MarksmanCrossbow then
					skill = "marksman"
				elseif weaponType == types.Weapon.TYPE.MarksmanThrown then
					skill = "marksman"
				elseif weaponType == types.Weapon.TYPE.ShortBladeOneHand then
					skill = "shortblade"
				elseif weaponType == types.Weapon.TYPE.SpearTwoWide then
					skill = "spear"
				end
			end
			modifier2 = math.max(0, Player.stats.skills[skill](self).modified - playerSection:get("MinWeaponSkill"))*playerSection:get("HastePerWeaponSkill")/100
		elseif stance == Actor.STANCE.Spell and playerSection:get("HastePerMagicSkill") > 0 then
			local spell = Player.getSelectedSpell(self)
			if spell then
				modifier2 = math.max(0, getAverageSkill(spell) - playerSection:get("MinMagicSkill"))*playerSection:get("HastePerMagicSkill")/100
			end
		end
		--print(modifier1,modifier2)
		animation.setSpeed(self, groupname, 1 + modifier1 + modifier2) 
	end
end)

  
I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = "SpeedHaste",
	description = ""
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
			key = "MinWeaponSkill",
			name = "Minimum weapon skill level",
			description = "Level that the effect starts to kick in",
			default = 50,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "HastePerWeaponSkill",
			name = "Haste per weapon skill level (%)",
			description = "Percent speed increase per level (above the min level)",
			default = 0.4,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "MinMagicSkill",
			name = "Minimum magic skill level",
			description = "Level that the effect starts to kick in",
			default = 50,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "HastePerMagicSkill",
			name = "Haste per magic skill level (%)",
			description = "Percent speed increase per level (above the min level)",
			default = 0.4,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		
		{
			key = "MinLevel",
			name = "Minimum attribute level",
			description = "Level that the effect starts to kick in",
			default = 30,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
		{
			key = "HastePerLevel",
			name = "Haste per attribute level (%)",
			description = "Percent speed increase per level (above the min level)",
			default = 0.8,
			argument = {
				min = 0,
				max = 1000,
			},
			renderer = "number",
		},
	}
}