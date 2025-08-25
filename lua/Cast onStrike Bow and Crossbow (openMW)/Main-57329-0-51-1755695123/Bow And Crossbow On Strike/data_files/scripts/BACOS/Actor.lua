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
	if attack.successful==true then
		if attack.weapon then
			local WeaponRecord=types.Weapon.records[attack.weapon.recordId]
			if WeaponRecord.type==types.Weapon.TYPE.MarksmanCrossbow or WeaponRecord.type==types.Weapon.TYPE.MarksmanBow then
				local EnchantRecord=core.magic.enchantments.records[WeaponRecord.enchant]
--				print(EnchantRecord,EnchantRecord.type,core.magic.ENCHANTMENT_TYPE.CastOnUse)
				if EnchantRecord and (EnchantRecord.type==core.magic.ENCHANTMENT_TYPE.CastOnUse or EnchantRecord.type==core.magic.ENCHANTMENT_TYPE.CastOnStrike) then
					local effectiveCost=math.floor(EnchantRecord.cost*(1.1-types.NPC.stats.skills.enchant(attack.attacker).modified/100)+0.5)
					if effectiveCost<1 then effectiveCost=1 end
					if types.Item.itemData(attack.weapon).enchantmentCharge>effectiveCost then
						core.sendGlobalEvent("BACOSsetCharge", {Item=attack.weapon, Charge=types.Item.itemData(attack.weapon).enchantmentCharge-effectiveCost})
						anim.addVfx(self,types.Static.records[EnchantRecord.effects[1].effect.hitStatic].model)
						core.sound.playSound3d(EnchantRecord.effects[1].effect.school.." hit",self)
						local effestsnum
						for i, effect in pairs(EnchantRecord.effects) do
							effestsnum=i
						end
						types.Actor.activeSpells(self):add({id=WeaponRecord.id, effects={0,i}, caster=attack.attacker})
					else
						attack.attacker:sendEvent("BACOSShowMessage",{text="Item does not have enough charge."})
						attack.attacker:sendEvent("BACOSPlaySound",{Sound="spell failure "..EnchantRecord.effects[1].effect.school})
					end
				end
			end
		end
	end
end)

return {
	eventHandlers = {	
						BACOSApplyEffect=ApplyEffect,
						BACOSPlaySound=PlaySound,
					},
	engineHandlers = {
        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,
	}

}