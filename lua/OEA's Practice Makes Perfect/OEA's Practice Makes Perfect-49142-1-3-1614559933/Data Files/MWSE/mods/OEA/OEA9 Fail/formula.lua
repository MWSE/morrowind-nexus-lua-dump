local config = require("OEA.OEA9 Fail.config")
local H = {}

function H.PickFormula()
	local X = (0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) + tes3.mobilePlayer.security.current
	local quality = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick }).object.quality
	local fatigueTerm = tes3.findGMST("fFatigueBase").value - (tes3.findGMST("fFatigueMult").value * (1 - tes3.mobilePlayer.fatigue.normalized))
	X = (X * quality * fatigueTerm)

	local hitResult = tes3.rayTest({ position = tes3.getCameraPosition(), direction = tes3.getCameraVector() })
	local target = hitResult and hitResult.reference
	if (target == nil) then
		--mwse.log("[Practice Makes Perfect] lock target is nil")
		return
	end

	local lockLevel = tes3.getLockLevel({ reference = target })
	if (lockLevel == nil) then
		--mwse.log("[Practice Makes Perfect] lock level is nil")
		return
	end

	X = X + (tes3.findGMST("fPickLockMult").value * lockLevel)
	--mwse.log(("[Practice Makes Perfect] Lock X is the following: %s"):format(X))
	if (X > 0) then
		local skills = tes3.dataHandler.nonDynamicData.skills
		tes3.mobilePlayer:exerciseSkill(tes3.skill.security, skills[tes3.skill.security + 1].actions[2] * config.SecMult)
	end
end

function H.ProbeFormula()
	local X = (0.2 * tes3.mobilePlayer.agility.current) + (0.1 * tes3.mobilePlayer.luck.current) + tes3.mobilePlayer.security.current

	local hitResult = tes3.rayTest({ position = tes3.getCameraPosition(), direction = tes3.getCameraVector() })
	local target = hitResult and hitResult.reference
	if (target == nil) then
		--mwse.log("[Practice Makes Perfect] trap target is nil")
		return
	end

	local trap = tes3.getTrap({ reference = target })
	if (trap == nil) then
		--mwse.log("[Practice Makes Perfect] trap spell is nil")
		return
	end

	X = X + (tes3.findGMST("fTrapCostMult").value * trap.magickaCost)

	local quality = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.probe }).object.quality
	local fatigueTerm = tes3.findGMST("fFatigueBase").value - (tes3.findGMST("fFatigueMult").value * (1 - tes3.mobilePlayer.fatigue.normalized))
	X = (X * quality * fatigueTerm)
	--mwse.log(("[Practice Makes Perfect] Trap X is the following: %s"):format(X))

	if (X > 0) then
		local skills = tes3.dataHandler.nonDynamicData.skills
		tes3.mobilePlayer:exerciseSkill(tes3.skill.security, skills[tes3.skill.security + 1].actions[1] * config.SecMult)
	end
end

return H