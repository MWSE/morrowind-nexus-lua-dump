local function onKeyDown(e)
	local target = tes3.getPlayerTarget()
	if not target then
		return
	end
	local objectType = target.object.objectType
	if not (objectType == tes3.objectType.creature or objectType == tes3.objectType.npc) then
		return
	end
	if e.isAltDown and target and tes3.getCurrentAIPackageId({ reference = target }) == tes3.aiPackage.follow then
		local targetActor = target.mobile.aiPlanner:getActivePackage().targetActor
		tes3.setAITravel({
			reference = target,
			destination = tes3.mobilePlayer.position + (tes3.mobilePlayer.position - target.mobile.position) * 0.25,
		})
		timer.start {
			duration = 4,
			type = timer.simulate,
			callback = function()
				tes3.setAIFollow({ reference = target, target = targetActor })
			end,
		}
	end
end
event.register("keyDown", onKeyDown)
