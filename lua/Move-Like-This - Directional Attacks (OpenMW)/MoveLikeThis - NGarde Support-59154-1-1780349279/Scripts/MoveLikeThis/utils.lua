local I = require('openmw.interfaces')
local core  = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')

DirectionHitUtils = {}

function DirectionHitUtils.copyTable(info1)
	info2 = {}
	for key, value in pairs(info1) do
		info2[key] = value
	end
	return info2
end

return DirectionHitUtils