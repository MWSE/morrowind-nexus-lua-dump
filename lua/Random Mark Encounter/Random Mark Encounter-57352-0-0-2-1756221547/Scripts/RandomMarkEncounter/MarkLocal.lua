local Core = require("openmw.core")
local self = require("openmw.self")
local util = require("openmw.util")
local nearby = require("openmw.nearby")
local types = require('openmw.types')
local ambient = require("openmw.ambient")

local life = 0
local markSpellData = Core.magic.effects.records.mark
local markSoundEffect = markSpellData.hitSound
if markSoundEffect=="" then markSoundEffect = "mysticism hit" end
return {engineHandlers={
	onUpdate=function(dt)
		local marking = false
		if Core.sound.isSoundPlaying(markSoundEffect, self) then
			for _,effect in pairs((self.type.getSelectedSpell(self) or {}).effects or {}) do
				if effect.id == markSpellData.id then
					marking=true
					break
				end
			end
		end
		if marking then
			Core.sendGlobalEvent("onCastMark",self)
		end
	end
	}
}