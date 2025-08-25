local Core = require("openmw.core")
local self = require("openmw.self")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require('openmw.types')
local ambient = require("openmw.ambient")

local life = 0
local markSoundEffect = Core.magic.effects.records.mark.hitSound
if markSoundEffect=="" then markSoundEffect = "mysticism hit" end
return {engineHandlers={
	onUpdate=function(dt)
		local marking = Core.sound.isSoundPlaying(markSoundEffect, self)
		if marking then
			Core.sendGlobalEvent("onCastMark",self)
		end
	end
	}
}