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
	if attack.successful==true and attack.weapon then
--		print(attack.weapon,attack.ammo)
		core.sendGlobalEvent("APtWApplyPoison",{Weapon=attack.weapon,Actor=self,Attacker=attack.attacker})
	end
end)


local function ApplyEffect(data)
	local PoisonRecord
    if types.Potion.records[data.PoisonId] then
        PoisonRecord=types.Potion.records[data.PoisonId]
	else
        PoisonRecord=types.Ingredient.records[data.PoisonId]
    end
	anim.addVfx(self,types.Static.records[PoisonRecord.effects[1].effect.hitStatic].model)
	core.sound.playSound3d(PoisonRecord.effects[1].effect.school.." hit",self)
	local effestsnum
	for i, effect in pairs(PoisonRecord.effects) do
		effestsnum=i
	end
	types.Actor.activeSpells(self):add({id=PoisonRecord.id, effects={0,i}, caster=data.Attacker})
end




return {
	eventHandlers = {	
						APtWApplyEffect=ApplyEffect
					},
	engineHandlers = {
	}

}