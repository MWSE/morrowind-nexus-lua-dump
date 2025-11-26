local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local time=require('openmw_aux.time')
local Combat=require('openmw.interfaces').Combat


I.Combat.addOnHitHandler(function(attack)
	if attack.weapon and attack.weapon~=types.Actor.getEquipment(attack.attacker)[types.Actor.EQUIPMENT_SLOT.CarriedRight] then
		local DamageCondition=1
		if attack.successful==true then
			if core.getGMST("fWeaponDamageMult")*attack.damage.health>DamageCondition then
				DamageCondition=core.getGMST("fWeaponDamageMult")*attack.damage.health
			end

			local WeaponRecord=types.Weapon.records[attack.weapon.recordId]
			local EnchantRecord
			if WeaponRecord.enchant and core.magic.enchantments.records[WeaponRecord.enchant] then
				EnchantRecord=core.magic.enchantments.records[WeaponRecord.enchant]
			end
--				print(EnchantRecord,EnchantRecord.type,core.magic.ENCHANTMENT_TYPE.CastOnUse)
			if EnchantRecord and EnchantRecord.type==core.magic.ENCHANTMENT_TYPE.CastOnStrike then
				local effectiveCost=math.floor(EnchantRecord.cost*(1.1-types.NPC.stats.skills.enchant(attack.attacker).modified/100)+0.5)
				if effectiveCost<1 then effectiveCost=1 end
				if types.Item.itemData(attack.weapon).enchantmentCharge>effectiveCost then
					core.sendGlobalEvent("OnStrikesetCharge", {Item=attack.weapon, Charge=types.Item.itemData(attack.weapon).enchantmentCharge-effectiveCost})
					
					local effestsnum={}
					for i, effect in pairs(EnchantRecord.effects) do
						anim.addVfx(self,types.Static.records[effect.effect.hitStatic].model)
						core.sound.playSound3d(effect.effect.school.." hit",self)
						effestsnum[i]=i-1
					end
					types.Actor.activeSpells(self):add({id=WeaponRecord.id, effects=effestsnum, caster=attack.attacker})
				else
					attack.attacker:sendEvent('ShowMessage', {message = "Item does not have enough charge."})
					attack.attacker:sendEvent("BACOSPlaySound",{Sound="spell failure "..EnchantRecord.effects[1].effect.school})
				end
			end
		end

		core.sendGlobalEvent('ModifyItemCondition', {actor = attack.attacker, item = attack.weapon, amount= -DamageCondition})
	end
end)

return {
	eventHandlers = {	
					},
	engineHandlers = {
	}

}