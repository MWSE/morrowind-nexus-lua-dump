local I = require("openmw.interfaces")
local core  = require("openmw.core")
local self = require("openmw.self")
local types = require("openmw.types")
local util = require("openmw.util")

Compatibility = {}

----NGARDE----

function Compatibility.NGardeHitCheck(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	toReturn = true
	if attackInfo.ngarde_glancing then --A glancing hit is not clean enough to trigger an effect
		toReturn = false
	end
	if attackInfo.ngarde_perfectParry then -- A perfect parry should suffer no effects
		toReturn = false
	end
	if attackInfo.ngarde_parry then -- A parry blocks
		toReturn = false
	end
	return toReturn
end

function Compatibility.NGardePiercingHitCheck(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	toReturn = true
	if attackInfo.ngarde_glancing then --A glancing hit is not clean enough to trigger an effect
		toReturn = false
	end
	if attackInfo.ngarde_perfectParry then -- A perfect parry should suffer no effects
		toReturn = false
	end
	if attackInfo.ngarde_parry then -- A parry can"t block armor piercing
		toReturn = true
	end
	return toReturn
end


function Compatibility.NGardeIsWeakParry(attackInfo) -- Support for ngarde, returns true if Ngarde is not enabled or if the attack was not parried/a glance
	if attackInfo.ngarde_parry ~= nil and attackInfo.ngarde_parry then
		if attackInfo.ngarde_perfectParry ~= nil and attackInfo.ngarde_perfectParry then
			return false --No damage on perfect parries
		else
			return true
		end
	end
	return false
end

return Compatibility