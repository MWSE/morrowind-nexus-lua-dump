local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local timer=core.getRealTime()
local Collision

Move=false
Ammo=nil
Vector=nil

print("activated")

local function start(data)
    Move=true
    Vector=data.Vector
    print(data.Ammo)
    Ammo=types.Weapon.record(data.Ammo)
end


return {
	eventHandlers = {start=start},
	engineHandlers = {
        onUpdate = function()
            if Move==true then


                core.sendGlobalEvent('Teleport', {object=self,position=self.position+Vector})

                local Collision=nearby.castRay(self.position,self.position+Vector,{ignore=self})

               -- if Collision.hitObject then
                 --   print(Collision.hitObject)
                   -- print(Collision.hitObject.type)
                --end
                if Collision.hitObject then
                    if Collision.hitObject.type==types.Creature and types.Actor.stats.dynamic.health(Collision.hitObject).current>0  then
                        print(Collision.hitObject)
                        print(types.Actor.stats.dynamic.health(Collision.hitObject).current)
                        Collision.hitObject:sendEvent('DamageEffects',{damages=Ammo.thrustMinDamage})
                    end
                end

                if (core.getRealTime()-timer)>=1 or Collision.hit then
                    core.sendGlobalEvent('Disable',{Object=self})
                    --core.sendGlobalEvent('RemoveItem', {Item=self, number=1})
                end

            end
	end
    ,
	}
}