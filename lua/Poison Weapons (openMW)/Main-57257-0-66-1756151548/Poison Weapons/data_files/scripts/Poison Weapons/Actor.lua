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
	local effestsnum={}
	for i, effect in pairs(PoisonRecord.effects) do
		anim.addVfx(self,types.Static.records[effect.effect.hitStatic].model)
		core.sound.playSound3d(effect.effect.school.." hit",self)
		effestsnum[i]=i-1
	end
	types.Actor.activeSpells(self):add({id=PoisonRecord.id, effects=effestsnum, caster=data.Attacker})
end




return {
	eventHandlers = {	
						APtWApplyEffect=ApplyEffect
					},
	engineHandlers = {
	}

}