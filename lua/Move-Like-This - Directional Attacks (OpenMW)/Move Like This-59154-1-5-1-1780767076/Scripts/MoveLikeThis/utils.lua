local I = require('openmw.interfaces')
local core  = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local util = require('openmw.util')
local anim = require("openmw.animation")

DirectionHitUtils = {}

function DirectionHitUtils.copyTable(info1)
	info2 = {}
	for key, value in pairs(info1) do
		info2[key] = value
	end
	return info2
end

function DirectionHitUtils.isPlayingStaggerAnim(actor)
	return anim.isPlaying(actor, "hit1") or anim.isPlaying(actor, "hit2") or anim.isPlaying(actor, "hit3") or anim.isPlaying(actor, "hit4") or anim.isPlaying(actor, "hit5")
end

function DirectionHitUtils.isPlayingKnockBackOrOutAnim(actor)
	return anim.isPlaying(actor, "knockdown") or anim.isPlaying(actor, "knockout")
end

function DirectionHitUtils.isPlayingKnockdownAnim(actor)
	return anim.isPlaying(actor, "knockdown") or anim.isPlaying(actor, "knockout")
end

function DirectionHitUtils.isPlayingKnockoutAnim(actor)
	return anim.isPlaying(actor, "knockdown") or anim.isPlaying(actor, "knockout")
end

return DirectionHitUtils