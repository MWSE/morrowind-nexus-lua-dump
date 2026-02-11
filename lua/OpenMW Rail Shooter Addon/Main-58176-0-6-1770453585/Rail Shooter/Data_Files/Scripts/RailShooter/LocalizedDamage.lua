--You can add here new functions for damage localization.

local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local async = require('openmw.async')

local LocalizedDamage={}

LocalizedDamage["corprus_stalker"]=function(attack)
	if attack.hitPos.z<(self:getBoundingBox().halfSize.z+self.position.z) then
		return(attack.damage.health/2)
	elseif attack.hitPos.z>(self:getBoundingBox().halfSize.z*3/2+self.position.z) then
		return(attack.damage.health*2)
	else
		return(attack.damage.health)
	end
end

LocalizedDamage["corprus_lame"]=function(attack)
	if attack.hitPos.z<(self:getBoundingBox().halfSize.z+self.position.z) then
		return(attack.damage.health/2)
	elseif attack.hitPos.z>(self:getBoundingBox().halfSize.z*3/2+self.position.z) then
		return(attack.damage.health*2)
	else
		return(attack.damage.health)
	end
end

LocalizedDamage["ash_zombie"]=function(attack)
	if attack.hitPos.z<(self:getBoundingBox().halfSize.z+self.position.z) then
		return(attack.damage.health/2)
	elseif attack.hitPos.z>(self:getBoundingBox().halfSize.z*3/2+self.position.z) then
		return(attack.damage.health*2)
	else
		return(attack.damage.health)
	end
end

LocalizedDamage["dremora"]=function(attack)
	if attack.hitPos.z>(self:getBoundingBox().halfSize.z*5/3+self.position.z) then
		return(attack.damage.health)
	else
		core.sound.playSound3d("heavy armor hit",self)
		core.sendGlobalEvent("SpawnVfx",{model=types.Static.records[core.magic.effects.records["firedamage"].areaStatic].model, position=attack.hitPos, options={scale=0.05,useAmbientLight=false}})
		return(0)
	end
end

LocalizedDamage["vavran reni"]=function(attack)
	print("okoki")
	if attack.hitPos.z>(self:getBoundingBox().halfSize.z*5/3+self.position.z) then
		return(attack.damage.health)
	else
		core.sound.playSound3d("heavy armor hit",self)
		core.sendGlobalEvent("SpawnVfx",{model=types.Static.records[core.magic.effects.records["firedamage"].areaStatic].model, position=attack.hitPos, options={scale=0.05,useAmbientLight=false}})
		return(0)
	end
end


return (LocalizedDamage)
