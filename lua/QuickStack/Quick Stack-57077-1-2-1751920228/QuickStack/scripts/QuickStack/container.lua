local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local animation = require('openmw.animation')
local async = require('openmw.async')

inventory = nil

function onActivated(actor)
	if tostring(self.type) == 'Container' then
		local inventory = types.Container.inventory(self)
		actor:sendEvent('SentInventory', {container=self})
	end
end

local clearVFXCallback = async:registerTimerCallback('quickStackClearVFXCallback', function(data)
    animation.removeVfx(self, data.vfxID)
end)

local function playTransferedContainerAnimation(data)
	local effectDuration = data.duration
	local spell = core.magic.spells.records['sanctuary']
	local effectWithParams
	for _, effect in ipairs(spell.effects) do
		effectWithParams = effect
    end
	--local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Sanctuary]
	local vfxID = "QuickStack" .. tostring(effectWithParams.effect.id) .. math.random(1, 1000)
	animation.addVfx(self, types.Static.record(effectWithParams.effect.hitStatic).model, {
		vfxId = vfxID,
		particuleTextureOverride = effectWithParams.effect.particle,
		loop = true
    })
	async:newSimulationTimer(effectDuration, clearVFXCallback, {
            vfxID = vfxID
        })
end


return {
	eventHandlers = { PlayTransferedContainerAnimation = playTransferedContainerAnimation },
    engineHandlers = {
        onActivated = onActivated
    }
}