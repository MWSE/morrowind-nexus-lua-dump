local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local animation = require('openmw.animation')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')

local targets = {}

function onActivated(actor)
	print("ACTIVATING NPC!")
	local inventory = types.Actor.inventory(self)
	actor:sendEvent('SentNPCInventory', {npc=self})
end

local function getFollowingPlayer()
	if I.AI.getActivePackage().type == "Follow" then
		for _, target in pairs(I.AI.getTargets("Follow")) do
			if target.recordId == "player" then
				return self
			end
		end
	end
end

local function emitActorFollowingChange()
	for _, player in ipairs(nearby.players) do
        player:sendEvent("SentFollowerActor", {actor = self, targets = targets})
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

local function onUpdate(dt)

	local currentFollowTargets = I.AI.getTargets("Follow")
	
	if #currentFollowTargets ~= #targets then
		targets = currentFollowTargets
		emitActorFollowingChange()
	end
	
	if I.AI.getActivePackage().type == "Follow" then
		for _, target in pairs(I.AI.getTargets("Follow")) do
			if target.recordId == "player" then
				
			end
		end
	end
end

return {
	eventHandlers = { 
		PlayTransferedContainerAnimation = playTransferedContainerAnimation,
		GetFollowingPlayer = getFollowingPlayer
	},
    engineHandlers = {
        onActivated = onActivated,
		onUpdate = onUpdate
    }
}