MODNAME = "Banishing"
I = require('openmw.interfaces')
types = require('openmw.types')
core = require('openmw.core')
storage = require('openmw.storage')
async = require('openmw.async')
vfs = require('openmw.vfs')
self = require('openmw.self')
camera = require('openmw.camera')
nearby = require('openmw.nearby')

util = require('openmw.util')
v2 = util.vector2
--onFrameFunctions = {}
--local function onFrame(dt)
--	for _, f in pairs(onFrameFunctions) do
--		f(dt)
--	end
--end

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if skillId == "mysticism" then
		local spell = types.Player.getSelectedSpell(self)
		if spell then
			for _,effect in pairs(spell.effects) do
				if effect.id == "dispel" then
					viewportBugfixDelay = core.getRealTime() + 0.05
					--onFrameFunctions["banish"] = 
					async:newUnsavableSimulationTimer(0.05, function()
						if core.getRealTime() > viewportBugfixDelay then
							local cameraPos = camera.getPosition()
							local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
							local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance();
							local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis);
							if (telekinesis) then
								activationDistance = activationDistance + (telekinesis.magnitude * 22);
							end
							activationDistance = activationDistance+0.1
							local targetPos = cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance
							--local res = nearby.castRenderingRay(
							--	cameraPos,
							--	targetPos,
							--	{ ignore = self }
							--)
							nearby.asyncCastRenderingRay(async:callback(function(res)
								if res.hitObject and types.Actor.objectIsInstance(res.hitObject) then
									res.hitObject:sendEvent("Banishing_banish", {self, (effect.magnitudeMin + effect.magnitudeMax)/2})
									if effect.area > 0 then
										local pos = res.hitPos
										for _, act in pairs(nearby.actors) do
											local distance = (act.position - pos):length()
											if act ~= res.hitObject and distance < effect.area*22 then
												act:sendEvent("Banishing_banish", {self, (effect.magnitudeMin + effect.magnitudeMax)/2})
											end
										end
									end
								elseif effect.area > 0 then
									local pos = targetPos
									--local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Dispel]
									--local model = types.Static.records[effect.castStatic].model
									local model = types.Static.records[effect.effect.areaStatic].model
									core.sendGlobalEvent('SpawnVfx', {model = model, position = pos, options = {scale  = effect.area*1.1}})
									for _, act in pairs(nearby.actors) do
										local distance = (act.position - pos):length()
										if distance < effect.area*22 then
											act:sendEvent("Banishing_banish", {self, (effect.magnitudeMin + effect.magnitudeMax)/2, true})
										end
									end
								end
							end),
							cameraPos,
							targetPos,
							{ ignore = self }
							)
							--onFrameFunctions["banish"] = nil
						end
					end)
				end
			end
		end
	end
end)
return {
	engineHandlers = {
		onObjectActive = onObjectActive,
		onFrame = onFrame
	},
	eventHandlers = {
		Banishing_Unhook = unhookObject,
	},
}
