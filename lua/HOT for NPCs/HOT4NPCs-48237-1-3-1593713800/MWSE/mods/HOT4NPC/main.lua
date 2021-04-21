local config = require("HOT4NPC.config")

local function healneut()
	--tes3.messageBox("NPC heal")
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
		if (ref == tes3.mobilePlayer) then
			return
		end
		if ref.mobile then
			local hostile = (ref.mobile.fight)
			if (hostile >= 80) then
				return
			end
			local animState = ref.mobile.actionData.animationAttackState
			if (animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
				return
			end
			local noHealth = (ref.mobile.health.current <= 0)
			if (noHealth) then
				return
			end
			if tes3.getCurrentAIPackageId(ref.mobile) ~= tes3.aiPackage.follow then
				local lowHealth = (ref.mobile.health.current < ref.mobile.health.base)
				if (lowHealth) then
					tes3.modStatistic{ reference = ref.mobile, name = "health", current = config.hotNeutralHeal }
				end
				local greaterHealth = (ref.mobile.health.current > ref.mobile.health.base)
				if (greaterHealth) then
					tes3.setStatistic{ reference = ref.mobile, name = "health", current = ref.mobile.health.base }
				end
			end
		end
	end
end

local function healcomp()
	--tes3.messageBox("Companion heal")
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
		if (ref == tes3.mobilePlayer) then
			return
		end
		if ref.mobile then
			local animState = ref.mobile.actionData.animationAttackState
			if (animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
				return
			end
			local noHealth = (ref.mobile.health.current <= 0)
			if (noHealth) then
				return
			end
			if tes3.getCurrentAIPackageId(ref.mobile) == tes3.aiPackage.follow then
				local lowHealth = (ref.mobile.health.current < ref.mobile.health.base)
				if (lowHealth) then
					tes3.modStatistic{ reference = ref.mobile, name = "health", current = config.hotNeutralHeal }
				end
				local greaterHealth = (ref.mobile.health.current > ref.mobile.health.base)
				if (greaterHealth) then
					tes3.setStatistic{ reference = ref.mobile, name = "health", current = ref.mobile.health.base }
				end
			end
		end
	end
end

local function healhost()
	--tes3.messageBox("Hostile heal")
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.actor) do
		if (ref == tes3.mobilePlayer) then
			return
		end
		if (ref.mobile) then
			local nonhostile = (ref.mobile.fight < 80)
			if (nonhostile) then
				return
			end
			local animState = ref.mobile.actionData.animationAttackState
			if (animState == tes3.animationState.dying or animState == tes3.animationState.dead) then
				return
			end
			local noHealth = (ref.mobile.health.current <= 0)
			if (noHealth) then
				return
			end
			local lowHealth = (ref.mobile.health.current < ref.mobile.health.base)
			if (lowHealth) then
				tes3.modStatistic{ reference = ref.mobile, name = "health", current = config.hotHostileHeal }
			end
			local greaterHealth = (ref.mobile.health.current > ref.mobile.health.base)
			if (greaterHealth) then
				tes3.setStatistic{ reference = ref.mobile, name = "health", current = ref.mobile.health.base }
			end
		end
	end
end

local function onLoaded()
	timer.start({iterations = -1, duration = config.hotNeutralRate, callback = healneut, type = timer.simulate })
	timer.start({iterations = -1, duration = config.hotCompanionRate, callback = healcomp, type = timer.simulate })
	timer.start({iterations = -1, duration = config.hotHostileRate, callback = healhost, type = timer.simulate })
end

event.register("loaded", onLoaded)

local function registerModConfig()
	require("HOT4NPC.mcm")
end
event.register("modConfigReady", registerModConfig)