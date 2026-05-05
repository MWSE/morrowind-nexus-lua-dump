local core = require('openmw.core')

local FATIGUE_BASE = core.getGMST('fFatigueBase')
local FATIGUE_MULT = core.getGMST('fFatigueMult')

local Util = {}

-- engine fatigue formula
function Util.getFatigueTerm(actor)
	local fat = actor.type.stats.dynamic.fatigue(actor)
	local norm = fat.base == 0 and 1 or math.max(0, fat.current / fat.base)
	return FATIGUE_BASE - FATIGUE_MULT * (1 - norm)
end

return Util