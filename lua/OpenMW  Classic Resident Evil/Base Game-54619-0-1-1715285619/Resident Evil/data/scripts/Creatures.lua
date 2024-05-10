local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')

DamageLocTimer=0
DamageLocPlayer=nil


local function DamageEffects(data)
    print(self)
    print("life1"..types.Actor.stats.dynamic.health(self).current)
    --print(data.enchant)
    --print(data.damages)
    types.Actor.stats.dynamic.health(self).current=types.Actor.stats.dynamic.health(self).current-data.damages
    
    print("life2"..types.Actor.stats.dynamic.health(self).current)
    --if core.magic.enchantments[data.enchant].type==1 then  --onStrike enchantment
    --    for i, effect in ipairs(data.enchant.effects) do 
    --        print(effect)
    --        types.Actor.activeEffects(self):modify(effect.magnitudeMax,effect.effect)
    --    end
    --end
end


local function Damagelocalisation(data)
    DamageLocTimer=core.getRealTime()
    DamageLocPlayer=data.Player
    --print(data.Hitpos.z/(self:getBoundingBox().halfSize.z*2-self.position.z)*100)
    core.sendGlobalEvent("ReturnLocalScriptVariable",{Player=data.Player, GameObject=self,Variable="DamageLoc",value=data.Hitpos.z/(self:getBoundingBox().halfSize.z*2-self.position.z)*100})
end

return {
	eventHandlers = {Damagelocalisation=Damagelocalisation,DamageEffects=DamageEffects },
	engineHandlers = {
        onUpdate = function()
            if DamageLocPlayer and (core.getRealTime()-DamageLocTimer)>0.1 then
                --print("Stop localisation")
                core.sendGlobalEvent("ReturnLocalScriptVariable",{Player=DamageLocPlayer, GameObject=self,Variable="DamageLoc",value=-5})
                DamageLocPlayer=nil
            elseif DamageLocPlayer then
                --print("localisation")
            end
            
	end
    ,
	}
}