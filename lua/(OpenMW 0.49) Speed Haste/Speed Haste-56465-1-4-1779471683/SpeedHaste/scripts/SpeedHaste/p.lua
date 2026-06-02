core = require('openmw.core')
self = require('openmw.self')
storage = require('openmw.storage')
types = require('openmw.types')
I = require('openmw.interfaces')
async = require('openmw.async')
animation = require('openmw.animation')

------------------------- CONSTANTS -------------------------
MODNAME = "SpeedHaste"
local Player = types.Player
local Actor = types.Actor

------------------------- SETTINGS -------------------------
require('scripts.SpeedHaste.settings')

------------------------- LOOKUPS -------------------------
local animGroups = {
	["idle1h"]        = true,
	["idle2c"]        = true,
	["idle2w"]        = true,
	["idlecrossbow"]  = true,
	["idlehh"]        = true,
	["idlespell"]     = true,
	["weapononehand"] = true,
	["weapontwohand"] = true,
	["weapontwowide"] = true,
	["handtohand"]    = true,
	["throwweapon"]   = true,
	["crossbow"]      = true,
	["bowandarrow"]   = true,
	["spellcast"]     = true,
}

local weaponSkillMap = {
	[types.Weapon.TYPE.ShortBladeOneHand] = "shortblade",
	[types.Weapon.TYPE.LongBladeOneHand]  = "longblade",
	[types.Weapon.TYPE.LongBladeTwoHand]  = "longblade",
	[types.Weapon.TYPE.BluntOneHand]      = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoClose]     = "bluntweapon",
	[types.Weapon.TYPE.BluntTwoWide]      = "bluntweapon",
	[types.Weapon.TYPE.SpearTwoWide]      = "spear",
	[types.Weapon.TYPE.AxeOneHand]        = "axe",
	[types.Weapon.TYPE.AxeTwoHand]        = "axe",
	[types.Weapon.TYPE.MarksmanBow]       = "marksman",
	[types.Weapon.TYPE.MarksmanCrossbow]  = "marksman",
	[types.Weapon.TYPE.MarksmanThrown]    = "marksman",
}

------------------------- STAT CACHE -------------------------
local speedStat = Player.stats.attributes["speed"](self)
local skillStats = {}
for _, skillRecord in ipairs(core.stats.Skill.records) do
	skillStats[skillRecord.id] = Player.stats.skills[skillRecord.id](self)
end

------------------------- SPELL COST CACHE -------------------------
local spellDB = {}
local function checkSpell(spell)
	local spellId = spell.id
	if not spellDB[spellId] then
		spellDB[spellId] = {}
		local s = spellDB[spellId]
		s.schools = {}
		s.calculatedCost = 0
		s.autoCalculated = spell.isAutocalc
		s.isSpell = spell.type == core.magic.SPELL_TYPE.Spell
		local playerSpell = spellId:sub(1,9) == "Generated"
		for _,effect in pairs(spell.effects) do
			local school = effect.effect.school
			local hasMagnitude = effect.effect.hasMagnitude
			local hasDuration = effect.effect.hasDuration
			local appliedOnce = effect.effect.isAppliedOnce
			local minMagn = hasMagnitude and effect.magnitudeMin or 1
			local maxMagn = hasMagnitude and effect.magnitudeMax or 1
			minMagn = math.max(1, minMagn)
			maxMagn = math.max(1, maxMagn)
			local duration = hasDuration and effect.duration or 1
			if not appliedOnce then
				duration = math.max(1, duration)
			end
			local fEffectCostMult = core.getGMST("fEffectCostMult")
			local durationOffset = 0
			local minArea = 0
			local costMult = fEffectCostMult
			if playerSpell then
				durationOffset = 1
				minArea = 1
			end
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
		if spell.isAutocalc then
			s.cost = math.floor(s.calculatedCost + 0.5)
		else
			s.cost = math.floor(spell.cost + 0.5)
		end
	end
	return spellDB[spellId]
end

local function getAverageSkill(spell)
	local s = checkSpell(spell)
	local skill = 0
	for school, cost in pairs(s.schools) do
		skill = skill + skillStats[school].modified * (cost / math.max(1, s.calculatedCost))
	end
	return skill
end

------------------------- MAIN -------------------------

local function getHaste(skipCost)
	local speed = speedStat.modified
	local speedMod = math.max(0, speed - S_MinLevel) ^ S_LevelExponent * S_HastePerLevel / 100
	
	local stanceMod = 0
	local recordSpeed = 1
	local base = 1
	local costMod = 0
	local stance = Actor.getStance(self)

	if stance == Actor.STANCE.Spell then
		base = S_BaseMagicSpeed
		local spell = Player.getSelectedSpell(self)
		-- no spell = enchanted item
		local magicSkill = spell and getAverageSkill(spell) or skillStats["enchant"].modified
		stanceMod = math.max(0, magicSkill - S_MinMagicSkill) ^ S_MagicSkillExponent * S_HastePerMagicSkill / 100
		-- expensive spells slow the wind-up
		if not skipCost then
			local cost = spell and checkSpell(spell).cost or 0
			costMod = math.max(0, cost - S_MinSpellCost) ^ S_SpellCostExponent * S_SlowPerSpellCost / 100
		end
	else
		base = S_BaseWeaponSpeed
		local skill = "handtohand"
		local weapon = Actor.getEquipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
		if weapon and types.Weapon.objectIsInstance(weapon) then
			local record = types.Weapon.record(weapon)
			recordSpeed = record.speed
			skill = weaponSkillMap[record.type] or skill
		end
		stanceMod = math.max(0, skillStats[skill].modified - S_MinWeaponSkill) ^ S_WeaponSkillExponent * S_HastePerWeaponSkill / 100
	end

	return math.max(0.1, base + speedMod + stanceMod - costMod) * recordSpeed
end

------------------------- HANDLERS -------------------------

local castReleased = false

I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if not S_Enabled then return end
	if not animGroups[groupname] then return end
	-- spellcast: cost slowdown applies only before the release key
	if groupname == "spellcast" then
		if key:sub(-5) == "start" then
			castReleased = false
		elseif key:sub(-7) == "release" then
			castReleased = true
		end
		animation.setSpeed(self, groupname, getHaste(castReleased))
	else
		animation.setSpeed(self, groupname, getHaste(false))
	end
end)
