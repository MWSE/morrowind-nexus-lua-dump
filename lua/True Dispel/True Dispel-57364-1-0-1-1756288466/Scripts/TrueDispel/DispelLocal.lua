local Core = require("openmw.core")
local self = require("openmw.self")
local interfaces = require("openmw.interfaces") -- oh my god I thought this was a UI thing so I never looked into it, now I can detect spells!!!

local dispelSpellData = Core.magic.effects.records.dispel
local dispelHitEffect = dispelSpellData.hitSound
if dispelHitEffect == "" then dispelHitEffect = "mysticism hit" end

local function findEffect(spellData,effectData)
	for _,sp in pairs(spellData) do
		if sp.id == effectData.id then return true end
	end
end

interfaces.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
	if cooldown or not findEffect(self.type.getSelectedSpell(self).effects,dispelSpellData) then return end
    if key == "self start" then
		dispelCheck=true
	elseif key == "self stop" and dispelCheck then
		dispelCheck=false
	end
end)
return {
engineHandlers={onFrame=function(dt)
	if not dispelCheck then
		return
	end
	if not Core.sound.isSoundPlaying(dispelHitEffect,self) then return end
	dispelCheck=false
	Core.sendGlobalEvent("onCastDispel",self)
end}}