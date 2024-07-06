local core   = require('openmw.core')
local self   = require('openmw.self')
local types  = require('openmw.types')
local async  = require('openmw.async')
local time   = require('openmw_aux.time')
local ui     = require('openmw.ui')
local i_UI   = require('openmw.interfaces').UI
local input  = require('openmw.input')
local camera = require('openmw.camera')
local util   = require('openmw.util')
local nearby = require('openmw.nearby')
local skp    = require('openmw.interfaces').SkillProgression
local anim   = require('openmw.animation')

local Dt     = require('scripts.Skill_Uses_Scaled.data')
local Mui    = require('scripts.Skill_Uses_Scaled.modui')
-- TOOLS
local eps    = 0.001
local function equal(a, b) return (math.abs(b - a) < eps) end

local function percentify(num) return string.format('%.1f', num * 100) .. '%' end

local function get(var) -- var must be serializable, recursions WILL stack overflow :D
	if type(var) ~= 'table' then
		return var
	else
		local deepcopy = {}
		for _key, _value in pairs(var) do deepcopy[_key] = get(_value) end
		return deepcopy
	end
end

-- local function makecounter(val)
-- 	local count = val
-- 	local simseconds = function() return core.getSimulationTime() - (core.getSimulationTime() % 0.01 * time.second) end
-- 	local start = simseconds() -- for debugging
-- 	return function(mod)
-- 		count = count + mod
-- 		return count
-- 	end
-- end

local function DEBUG(string)
	if Mui.getSetting("SUS_DEBUG") then
		if Mui.getSetting("SUS_VERBOSE") then
			ui.showMessage(string)
		else
			print(string)
		end
	end
end

-- Credit to zackhasacat for this one
-- I shortened it by removing checks I don't need (due to where it's used)
-- Also made it use and return SUS Dt values
local function getArmorType(armor_obj)
	local lightMultiplier = Dt.GMST.fLightMaxMod + 0.0005
	local medMultiplier   = Dt.GMST.fMedMaxMod + 0.0005
	local armorType       = types.Armor.record(armor_obj).type
	local weight          = types.Armor.record(armor_obj).weight
	local armorTypeWeight = math.floor(Dt.ARMOR_TYPES[armorType])
	if weight <= armorTypeWeight * lightMultiplier then  -- print('SKILL: lightarmor')
		return 'lightarmor'
	elseif weight <= armorTypeWeight * medMultiplier then -- print('SKILL: mediumarmor')
		return 'mediumarmor'
	else                                                 -- print('SKILL: heavyarmor')
		return 'heavyarmor'
	end
end

-- Credit to Pharis for this one. I couldn't have made it, no chance in hell.
local function getFacedObject()
	local origin = camera.getPosition();
	local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5));

	local activationDistance = Dt.GMST.iMaxActivateDist + camera.getThirdPersonDistance();
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
	if (telekinesis) then
		activationDistance = activationDistance + (telekinesis.magnitude * 22);
	end;

	local result = nearby.castRenderingRay(
		origin,
		origin + direction * activationDistance,
		{ ignore = self }
	);

	if (result ~= nil and result.hit) then return result.hitObject; end;
end;

-- DEFINITIONS --
-----------------------------------------------------------------------------------------------------------

local Fn = {}

-----------------------------------------------------------------------------------------------------------

Fn.get_attack_damage = function(min, max, str_mod, health_mod, draw)
	local base = min + (max - min) * draw
	local damage = base * str_mod * health_mod
	return damage
end
Fn.get_H2H_damage = function(draw)
	local str_mod = types.Player.stats.attributes.strength(self).base / Mui.getSetting('HandToHand_Strength')
	local damage_per_skillpoint = Fn.get_attack_damage(Dt.GMST.fMinHandToHandMult, Dt.GMST.fMaxHandToHandMult, str_mod, 1,
		draw)
	local skill = types.Player.stats.skills.handtohand(self)
			.base -- Note we don't count fortifies. This prevents sujama from murdering your XP rates.
	local damage = (damage_per_skillpoint * skill)
	return damage
end
Fn.get_weapon_damage = function(weapon, draw, atktype)
	local wp_record = types.Weapon.record(weapon)
	local min = wp_record[atktype .. 'MinDamage']
	local max = wp_record[atktype .. 'MaxDamage']
	local str_mod = types.Player.stats.attributes.strength(self).base * Dt.GMST.fDamageStrengthMult / 10 +
			Dt.GMST.fDamageStrengthBase
	local dur_current = weapon.condition
	local health_mod = 1
	if dur_current then
		health_mod = weapon.condition / types.Weapon.record(weapon).health
	elseif Dt.WEAPON_TYPES.BOW[wp_record.type] then
		local ammo = types.Actor.getEquipment(self, Dt.SLOTS.AMMO)
		local ammo_record = types.Weapon.record(ammo)
		min = min + ammo_record[atktype .. 'MinDamage']
		max = max + ammo_record[atktype .. 'MaxDamage']
	elseif Dt.WEAPON_TYPES.THROWN[wp_record.type] then
		health_mod = 2 --Thrown weapons count twice as they are both weapon and projectile.
	end
	local damage = Fn.get_attack_damage(min, max, str_mod, health_mod, draw)
	return damage
end

local function get_attack_draw()
	if not (Dt.pc.attack.step == 1) then return Dt.pc.attack.draw end
	local atktype = Dt.ATTACK_ANIMATION_KEYS.MIN[Dt.pc.attack.minkey]
	local group   = Dt.pc.attack.group
	local min     = anim.getTextKeyTime(self, group .. ': ' .. atktype .. ' min attack')
	local current = anim.getCurrentTime(self, group)
	local max     = anim.getTextKeyTime(self, group .. ': ' .. atktype .. ' max attack')
	if current < min then
		print('SUS: Can\'t get weapon draw if current < min')
		return
	end
	Dt.pc.attack.step = 2 -- Make sure we don't check again till the next hit is reached.
	local draw = 0
	if current < max then -- Getting draw mid-windup. Calculate how far we've gotten.
		max = math.max(0, max - min)
		current = math.max(0, current - min)
		draw = math.min(current / max, 1)
	end -- If we skipped this block, then we've not drawn our weapon at all, and draw = 0
	return draw
end
function Fn.get_attack(groupname, key)
	if Dt.pc.attack.step == 0 then
		if Dt.ATTACK_ANIMATION_KEYS.MIN[key] then
			Dt.pc.attack.step   = 1
			Dt.pc.attack.minkey = key
			Dt.pc.attack.group  = groupname
		end
	elseif Dt.pc.attack.step == 1 or Dt.pc.attack.step == 2 then
		if Dt.pc.attack.step == 1 and Dt.ATTACK_ANIMATION_KEYS.MAX[key] then
			Dt.pc.attack.draw = 1 -- No need to calculate. We reached max. It's a full draw.
			Dt.pc.attack.step = 2
		elseif Dt.ATTACK_ANIMATION_KEYS.HIT_RELEASE[key] then
			Dt.pc.attack.draw = get_attack_draw()
			Dt.pc.attack.step = 0
			-- Get attack min and max damages
			local weapon = types.Actor.getEquipment(self, Dt.SLOTS.WEAPON)
			if weapon then
				Dt.pc.attack.damage = math.max(1,
					Fn.get_weapon_damage(weapon, Dt.pc.attack.draw, Dt.ATTACK_ANIMATION_KEYS.HIT_RELEASE[key]))
			else
				Dt.pc.attack.damage = math.max(1, Fn.get_H2H_damage(Dt.pc.attack.draw))
			end
		end
	end
end

local draw
Fn.set_hit_release = function()
	if Dt.pc.attack.step == 1 then
		draw = get_attack_draw()
		if draw then
			Dt.pc.attack.draw = draw
			Dt.pc.attack.step = 2
		end
	end
end
Fn.set_hit_release_callback = async:registerTimerCallback('set_hit_release_callback',
	function() if not input.getBooleanActionValue("Use") then Fn.set_hit_release() end end)

function Fn.get_spell(groupname, key)
	if Dt.SPELL_ANIMATION_KEYS[key] then
		local spell = types.Actor.getSelectedSpell(self)
		if spell then Dt.pc.spell = types.Actor.getSelectedSpell(self) end
	end
end

Fn.register_Use_Action_Handler = function()
	local useCallback = async:callback(
		function()
			if input.getBooleanActionValue("Use") then
				if i_UI.getMode() then
					return -- We're in a menu
				elseif Dt.STANCE.WEAPON[types.Actor.getStance(self)] then
					local weapon = types.Actor.getEquipment(self, Dt.SLOTS.WEAPON)
					if not weapon then
						return -- H2H
					elseif (weapon.type == types.Lockpick) or (weapon.type == types.Probe) then
						Dt.pc.security_target = Fn.get_security_target()
						Dt.securiting = true -- We make onFrame scan continuously in case the player starts without a valid target and moves their cursor to one while holding click down.
					end
				end
			else
				if not Dt.STANCE.WEAPON[types.Actor.getStance(self)] then return end
				local weapon = types.Actor.getEquipment(self, Dt.SLOTS.WEAPON)
				if not weapon or (weapon.type == types.Weapon) then                     -- H2H
					if not i_UI.getMode() then Fn.set_hit_release() end
				elseif (weapon.type == types.Lockpick) or (weapon.type == types.Probe) then -- Security
					Dt.securiting = false
					Dt.pc.security_target = nil                                           -- This will turn the scaler off in case another mod triggers security uses outside of this loop.
				end
			end
		end
	)
	input.registerActionHandler("Use", useCallback)
end

Fn.get_active_effect_mag       = function(effectid) return types.Actor.activeEffects(self):getEffect(effectid).magnitude end

Fn.has_effect                  = function(effectid) return not (types.Actor.activeEffects(self):getEffect(effectid).magnitude == 0) end

Fn.get_security_target         = function()
	local target = getFacedObject()
	local lockable = nil -- scopeset
	if target and (target.type == types.Door or target.type == types.Container) then
		lockable          = {}
		lockable.islocked = types.Lockable.isLocked(target)
		lockable.level    = types.Lockable.getLockLevel(target)
		lockable.trap     = types.Lockable.getTrapSpell(target)
	end
	return lockable
end

Fn.get_equipped_armor          = function()
	local armor_list = {}
	for _, _object in pairs(types.Actor.getEquipment(self)) do
		if _object.type == types.Armor then table.insert(armor_list, _object) end
	end
	return armor_list
end

Fn.get_hit_armorpiece          = function()
	for _, _obj in ipairs(Fn.get_equipped_armor()) do
		local slot = types.Armor.record(_obj).type
		if not equal(Dt.pc.armor_condition.prevframe[slot], types.Item.itemData(_obj).condition) then return _obj end
	end
end

Fn.clean_slots                 = function(_slot, _armor_types) -- This is to guarantee we don't get ghost unarmored slots for gauntlets and bracers
	if _slot == types.Armor.TYPE.LBracer or _slot == types.Armor.TYPE.LGauntlet then
		_armor_types[types.Armor.TYPE.LBracer] = nil
		_armor_types[types.Armor.TYPE.LGauntlet] = nil
	elseif _slot == types.Armor.TYPE.RBracer or _slot == types.Armor.TYPE.RGauntlet then
		_armor_types[types.Armor.TYPE.RBracer] = nil
		_armor_types[types.Armor.TYPE.RGauntlet] = nil
	else
		_armor_types[_slot] = nil
	end
	return _armor_types
end

Fn.get_unarmored_slots         = function()
	local armor_types = get(Dt.ARMOR_TYPES)
	local armor = Fn.get_equipped_armor()
	for _, _obj in ipairs(armor) do Fn.clean_slots(types.Armor.record(_obj).type, armor_types) end
	local unarmored_slots = {}
	for _slot, _ in pairs(armor_types) do table.insert(unarmored_slots, _slot) end
	return unarmored_slots --Note this is iterable and #ble. That's important.
end

Fn.get_AR                      = function()
	local skill  = 0
	local rating = 0
	local armor  = Fn.get_equipped_armor()
	for _, _obj in ipairs(armor) do
		skill        = types.Player.stats.skills[getArmorType(_obj)](self).modified
		local slot   = types.Armor.record(_obj).type
		local hp_mod = types.Item.itemData(_obj).condition / types.Armor.record(_obj).health
		rating       = rating +
				types.Armor.record(_obj).baseArmor * hp_mod * Dt.ARMOR_RATING_WEIGHTS[slot] * skill / Dt.GMST.iBaseArmorSkill
	end
	local unarmored_slots = Fn.get_unarmored_slots()
	for _, _slot in ipairs(unarmored_slots) do
		skill = types.Player.stats.skills.unarmored(self).modified
		rating = rating +
				skill * Dt.GMST.fUnarmoredBase1 * skill * Dt.GMST.fUnarmoredBase2 *
				Dt.ARMOR_RATING_WEIGHTS
				[_slot] -- Why have 2 GMSTs for 1 number? Precision? Yeah precision I guess.
	end
	rating = rating + Fn.get_active_effect_mag('shield')
	return rating
end

local unarmored_hit_decay      = time.runRepeatedly(function()
	if Dt.counters.unarmored(0) > 0.01 then
		Dt.counters.unarmored(-math.max(Dt.counters.unarmored(0) / Mui.getSetting('Unarmored_Decay_Time'),
			2 / (Mui.getSetting('Unarmored_Decay_Time'))))
	else
		Dt.counters.unarmored(-Dt.counters.unarmored(0))
	end
end, time.second)
local acrobatics_jump_decay    = time.runRepeatedly(function()
	if Dt.counters.acrobatics(0) > 0.01 then
		Dt.counters.acrobatics(-math.max(Dt.counters.acrobatics(0) / Mui.getSetting('Acrobatics_Decay_Time'),
			2 / (Mui.getSetting('Acrobatics_Decay_Time'))))
	else
		Dt.counters.acrobatics(-Dt.counters.acrobatics(0))
	end
end, time.second)
local athletics_run_decay      = time.runRepeatedly(function()
	if Dt.counters.athletics(0) > 0.01 then
		Dt.counters.athletics(-math.max(Dt.counters.athletics(0) - Mui.getSetting('Athletics_Decay_Time'), 1))
	else
		Dt.counters.athletics(-Dt.counters.athletics(0))
	end
	if Dt.counters.athletics_debug(0) > 9.01 then
		DEBUG('SUS [Athletics] Decay Timer: ' .. string.format('%.0f', Dt.counters.athletics(0)))
	end
end, time.second)

--  =============
--  || SCALERS ||
--  =============

Fn.make_scalers                = function()
	-- ARMOR
	-----------------------------------------------------------------------------------------------------------
	for _, _skillid in ipairs(Dt.scaler_groups.ARMOR) do
		Dt.scalers:new {
			name = _skillid,
			func = function(_, xp)
				if not Mui.getSetting('toggle_armor') then return xp end
				if not Mui.getSetting(_skillid) then return xp end

				-- Disable scaling while under the effect of Disintegrate Armor, for you may get ridiculous amounts of XP if the stars line up wrong.
				-- For the sake of robustness and simplicity, it's a tradeoff I'm willing to accept. I will NOT attempt to fix it.
				if Fn.has_effect('disintegratearmor') then
					DEBUG('SUS - Disintegrate Armor in effect, returning vanilla XP')
					return xp
				end
				local armor_obj = Fn.get_hit_armorpiece()
				if not armor_obj then return xp end -- If we didn't find a hit piece, we skip scaling and leave XP vanilla. It's an edge case not worth pursuing.

				-- Estimate incoming damage from AR and condition lost instead of directly using condition lost.
				-- This helps avoid low ARs becoming a pit of neverleveling.
				local condition_lost = Dt.pc.armor_condition.prevframe[types.Armor.record(armor_obj).type] -
						types.Item.itemData(armor_obj).condition
				local rating = Fn.get_AR()
				local damage = (condition_lost * rating) / (rating - condition_lost)
				-- Armor skill and AR GMSTs are combined to make leveling below base AR faster, and above slower.
				local skill = types.Player.stats.skills[_skillid](self).base
				local multiplier = damage / Mui.getSetting('Armor_Damage_To_XP') * 60 / (30 + skill)
				xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
						Mui.getSetting('Global_Multiplier')

				-- Add a hit for Unarmored's timer, so that having a couple empty pieces doesn't result in massive unarmored bonuses.
				Dt.counters.unarmored(1)
				DEBUG('SUS [Armor] Skill Uses: ' ..
					string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier') ..
					' | XP ' .. string.format('%.2f', xp) .. ' | Damage Received: ' .. string.format('%.2f', damage))

				return xp
			end
		}
	end

	-- BLOCK
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'block',
		func = function(_, xp)
			if not Mui.getSetting('toggle_armor') then return xp end
			if not Mui.getSetting('block') then return xp end

			-- Disable scaling while under the effect of Disintegrate Armor, for you may get ridiculous amounts of XP if the stars line up wrong.
			-- For the sake of robustness and simplicity, it's a tradeoff I'm willing to accept. I will NOT attempt to fix it.
			if Fn.has_effect('disintegratearmor') then
				DEBUG('SUS - Disintegrate Armor in effect, returning vanilla XP')
				return xp
			end
			local armor_obj = types.Actor.getEquipment(self, Dt.SLOTS.SHIELD)
			local current_shield_condition = 0 -- if armor_obj is nill, because the shield was broken and unequipped, then we count condition as 0.
			local condition_lost = 0
			-- With armor the likelyhood of breaking is low, so we're better off just returning xp, but here we should air on the side of scaling the edge case rather than ignoring it.
			if armor_obj then
				current_shield_condition = types.Item.itemData(armor_obj).condition
				condition_lost = Dt.pc.armor_condition.prevframe[types.Armor.record(armor_obj).type] - current_shield_condition
			else
				DEBUG('Armor pice broken! Returning vanilla XP')
				return xp
			end
			local damage = condition_lost
			-- Armor skill and AR GMSTs are combined to make leveling below base AR faster, and above slower.
			local skill = types.Player.stats.skills.block(self).base

			local multiplier = damage / Mui.getSetting('Block_Damage_To_XP') * 60 / (30 + skill)
			xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')

			DEBUG('SUS [Block] Skill Uses: ' ..
				string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
				Mui.getSetting('Global_Multiplier') ..
				' | XP ' .. string.format('%.2f', xp) .. ' | Damage Received: ' .. string.format('%.2f', damage))

			-- Note we DON'T add an unarmored hit down here. You fully blocked, took no damage and gained no armor skill xp, so it doesn't count as a hit in my books.

			return xp
		end
	}

	-- UNARMORED
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'unarmored',
		func = function(_, xp)
			if not Mui.getSetting('unarmored') then return xp end

			local armor_weight = 0
			local armor = Fn.get_equipped_armor()
			for _, _obj in ipairs(armor) do armor_weight = armor_weight + types.Armor.record(_obj).weight end
			--       local race     = get_val(types.Player.record(self).race)
			local beast_factor = 1 -- If you have more than 3 empty slots, this will stay a 1 and not affect your XP rates, even if you are Argonian/Khajiit
			--       if #Fn.get_unarmored_slots() <= 3 and (race == 'argonian' or race == 'khajiit') then beast_factor = Mui.getSetting('Unarmored_Beast_Races')/ #Fn.get_unarmored_slots() end
			local gank_factor  = (Mui.getSetting('Unarmored_Start') - Mui.getSetting('Unarmored_Min')) /
					(2 * Dt.counters.unarmored(1) - 1) + Mui.getSetting('Unarmored_Min')
			local skill        = types.Player.stats.skills['unarmored'](self).base
			local rating       = skill * Dt.GMST.fUnarmoredBase1 * skill * Dt.GMST.fUnarmoredBase2
			local skill_factor = 100 /
					(35 + rating + skill + armor_weight * Mui.getSetting('Unarmored_Armor_Mult')) -- Rating is added here alongside skill, because unarmored has exponential scaling baked in.

			local multiplier   = skill_factor * beast_factor * gank_factor
			xp                 = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')

			DEBUG('SUS [Unarmored] Skill Uses: ' ..
				string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
				Mui.getSetting('Global_Multiplier') ..
				' | XP ' .. string.format('%.2f', xp) .. ' | Hit Counter: ' .. string.format('%.2f', Dt.counters.unarmored(0)))

			return xp
		end
	}

	-- SPELL
	-----------------------------------------------------------------------------------------------------------
	for _, _skillid in ipairs(Dt.scaler_groups.SPELL) do
		Dt.scalers:new { name = _skillid,
			func = function(_, xp)
				if not Mui.getSetting('toggle_magic') then return xp end
				if not Mui.getSetting(_skillid) then return xp end

				local spell = Dt.pc.spell
				if not spell then
					DEBUG('SUS - Held Spell not found, returning vanilla XP')
					return xp
				elseif (not spell.cost) or (spell.cost == 0) then
					DEBUG('SUS - Held Spell\'s cost (' .. tostring(spell.cost) .. ') is not valid, returning vanilla XP')
					return xp
				end
				local max_mp = types.Player.stats.dynamic.magicka(self).base
				local mp_factor = 0.01 * max_mp
				local multiplier = spell.cost / Mui.getSetting('Magicka_to_XP') * 4.8 / (4 + math.max(0, mp_factor - 1))
				xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
						Mui.getSetting('Global_Multiplier')

				DEBUG('SUS [Magic] Skill Uses: ' ..
					string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier') ..
					' | XP ' .. string.format('%.2f', xp) .. ' | Spell Cost: ' .. string.format('%.2f', spell.cost))

				if not Mui.getSetting('toggle_refund') then return xp end

				local armor_weight = 0
				local armor = Fn.get_equipped_armor()
				for _, _obj in ipairs(armor) do armor_weight = armor_weight + types.Armor.record(_obj).weight end
				local armor_offset                               = armor_weight * Mui.getSetting('MP_Refund_Armor_mult')
				local cost_factor                                = max_mp / (max_mp + spell.cost)
				local skill                                      = types.Player.stats.skills[_skillid](self).base
				local skill_factor                               = (skill - Mui.getSetting('MP_Refund_Skill_Offset') - armor_offset) /
						(40 + skill)

				local refund                                     = spell.cost * cost_factor * skill_factor * 0.01 *
						Mui.getSetting('MP_Refund_Max_Percent')

				--Yes, this will apply even if current > max.
				--To keep vanilla compatibility, we have to consider current>max as a valid gameplay state, since Fortify Magicka doesn't increase Max MP.
				types.Player.stats.dynamic.magicka(self).current = types.Player.stats.dynamic.magicka(self).current + refund
				if refund > 0 then
					DEBUG('SUS [Dynamic Spell Cost] Refund: ' ..
						string.format('%.2f', refund / spell.cost * 100) .. '% | ' .. string.format('%.2f', refund) .. ' MP')
				else
					DEBUG('SUS [Dynamic Spell Cost] Penalty: ' ..
						string.format('%.2f', refund / spell.cost * 100) .. '% | ' .. string.format('%.2f', refund) .. ' MP')
				end

				return xp
			end
		}
	end

	-- MELEE
	-----------------------------------------------------------------------------------------------------------
	for _, _skillid in ipairs(Dt.scaler_groups.WEAPON) do
		Dt.scalers:new { name = _skillid,
			func = function(_, xp)
				if not Mui.getSetting('toggle_physical') then return xp end
				if not Mui.getSetting(_skillid) then return xp end

				local skill = types.Player.stats.skills[_skillid](self).base
				local multiplier = Dt.pc.attack.damage / Mui.getSetting('Physical_Damage_to_XP') * 80 / (40 + skill)
				xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
						Mui.getSetting('Global_Multiplier')
				DEBUG('SUS [Weapon] Skill Uses: ' ..
					string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier') ..
					' | XP ' ..
					string.format('%.2f', xp) ..
					' | Damage Dealt: ' ..
					string.format('%.2f', Dt.pc.attack.damage) .. ' | Weapon Draw // Attack Charge: ' ..
					percentify(Dt.pc.attack.draw))
				return xp
			end
		}
	end

	-- HAND TO HAND
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'handtohand',
		func = function(_, xp)
			if not Mui.getSetting('toggle_physical') then return xp end
			if not Mui.getSetting('handtohand') then return xp end

			-- Now we average your fatigue damage and your health damage.
			-- It's the best method I could think of to balance the fact that H2H goes through 2 different healthbars at 2 different rates
			-- ..while also keeping compatibility with mods that change H2H GMSTs.
			local skill = types.Player.stats.skills.handtohand(self).base
			local damage = Dt.pc.attack.damage
			local damage = (damage + damage * Dt.GMST.fHandtoHandHealthPer) / 2
			local multiplier = damage / Mui.getSetting('Physical_Damage_to_XP') * 80 / (40 + skill)
			xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')
			DEBUG('SUS [Hand-To-Hand] Skill Uses: ' ..
				string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
				Mui.getSetting('Global_Multiplier') ..
				' | XP ' ..
				string.format('%.2f', xp) ..
				' | Damage Dealt: ' ..
				string.format('%.2f', damage) .. ' | Weapon Draw // Attack Charge: ' .. percentify(Dt.pc.attack.draw))
			return xp
		end
	}
	-- ACROBATICS
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'acrobatics',
		func = function(useType, xp)
			if not Mui.getSetting('acrobatics') then return xp end

			local encumbered_mult = Mui.getSetting('Acrobatics_Encumbrance_Min') +
					(Mui.getSetting('Acrobatics_Encumbrance_Max') - Mui.getSetting('Acrobatics_Encumbrance_Min'))
					* types.Actor.getEncumbrance(self) /
					(Dt.GMST.fEncumbranceStrMult * types.Player.stats.attributes.strength(self).base)
			local recursive_mult = 1
			if useType == skp.SKILL_USE_TYPES.Acrobatics_Jump then
				recursive_mult = (Mui.getSetting('Acrobatics_Start')) / (1 + (Dt.counters.acrobatics(1) - 1) / 2)
				Dt.pc.grounded = false                         -- We skip the next athletics use, bunny hopping isn't running.
			end
			local multiplier = encumbered_mult * recursive_mult -- No fatigue% => no XP, and more weight% == less XP
			xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')
			DEBUG('SUS [Acrobatics] Skill Uses: ' ..
				string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
				Mui.getSetting('Global_Multiplier') ..
				' | XP ' .. string.format('%.2f', xp) .. ' | Jump Mult: ' .. string.format('%.2f', recursive_mult))
			return xp
		end
	}
	-- ATHLETICS
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'athletics',
		func = function(_, xp)
			if not Mui.getSetting('athletics') then return xp end
			if not Dt.pc.grounded then
				Dt.pc.grounded = true
				return 0
			end -- We just jumped, setup for next cycle and give no xp.
			local position = self.object.position
			Dt.pc.grounded = nearby.castRay(position, position - util.vector3(0, 0, 25),
				{ collisionType = nearby.COLLISION_TYPE.AnyPhysical }).hitPos
			local swimming = position.z < -100
			if not swimming and not Dt.pc.grounded and not Fn.has_effect('levitate') then
				Dt.pc.grounded = true
				return 0
			end -- We were in the air or in a particularly slopey slope, and we weren't levitating. Setup. Skip. | Fun fact: you DO run while levitating!
			local movement = Dt.pc.position - position
			movement = math.abs(movement.x) + math.abs(movement.y)
			local move_factor = 1
			if movement < 150 then move_factor = Mui.getSetting('Athletics_No_Move_Penalty') end
			Dt.pc.position        = position
			local encumbered_mult = Mui.getSetting('Athletics_Encumbrance_Min') +
					(Mui.getSetting('Athletics_Encumbrance_Max') - Mui.getSetting('Athletics_Encumbrance_Min'))
					* types.Actor.getEncumbrance(self) / (Dt.GMST.fEncumbranceStrMult
						* types.Player.stats.attributes.strength(self).base)
			local recursive_mult  = (Mui.getSetting('Athletics_Start')) +
					(Mui.getSetting('Athletics_Marathon') - (Mui.getSetting('Athletics_Start')))
					* (Dt.counters.athletics(2) - 2) / Mui.getSetting('Athletics_Decay_Time')
			if swimming then Dt.counters.athletics(2) end
			local multiplier = encumbered_mult * recursive_mult * move_factor
			xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')
			local printcounter = Dt.counters.athletics_debug(1)
			if printcounter > 5.01 then
				DEBUG('SUS [Athletics] Skill Uses: ' ..
					string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier')
						+ Mui.getSetting('Base_Action_Value')) * Mui.getSetting('Global_Multiplier') .. ' | XP '
					.. string.format('%.2f', xp * printcounter) .. ' | Marathon Mult: ' .. string.format('%.2f', recursive_mult))
				Dt.counters.athletics_debug(-printcounter)
			end
			return xp
		end
	}

	-- SECURITy
	-----------------------------------------------------------------------------------------------------------
	Dt.scalers:new { name = 'security',
		func = function(useType, xp)
			if not Mui.getSetting('security') then return xp end

			local target = Dt.pc.security_target
			if not target then
				print('SUS - Targeted Door/Container not found, returning vanilla xp')
				return xp
			end
			local security_print = ''
			local multiplier = 1
			if (useType == skp.SKILL_USE_TYPES.Security_PickLock) and Dt.pc.security_target.islocked then
				multiplier = target.level / Mui.getSetting('Security_Lock_Points_To_XP')
				security_print = 'Lock Level: ' .. target.level
			elseif (useType == skp.SKILL_USE_TYPES.Security_DisarmTrap) and Dt.pc.security_target.trap then
				multiplier = target.trap.cost / Mui.getSetting('Security_Trap_Points_To_XP')
				security_print = 'Trap Level: ' .. target.trap.cost
			end

			xp = xp * (multiplier * Mui.getSetting('Scaling_Multiplier') + Mui.getSetting('Base_Action_Value')) *
					Mui.getSetting('Global_Multiplier')
			DEBUG('SUS [Security] Skill Uses: ' .. string.format('%.2f', multiplier * Mui.getSetting('Scaling_Multiplier')
					+ Mui.getSetting('Base_Action_Value')) * Mui.getSetting('Global_Multiplier')
				.. ' | XP ' .. string.format('%.2f', xp) .. ' | ' .. security_print)
			return xp
		end
	}

	DEBUG('SUS: Scalering Commenced')
end

-----------------------------------------------------------------------------------------------------------

-- RETURN || NEED THIS SO FILE DO THING
return Fn
