local config = require("StormAtronach.SO.config")
local interop = require("StormAtronach.SO.interop")

local log = mwse.Logger.new({
	name = "Stealth Overhaul",
	level = mwse.logLevel.debug,
})

--- Set hit chance to 100 if sneak strike (From Mort's Stealth improved)
--- @param e calcHitChanceEventData
local function sneakAttack(e)
	if e.attacker == tes3.player and e.targetMobile then
		if tes3.mobilePlayer.isSneaking and (not e.targetMobile.isPlayerDetected) then
			e.hitChance = 100
		end
	end
end
event.register("calcHitChance",sneakAttack)

--- Non-lethal and sneak strike stream
--- @param e attackHitEventData
local function attackHitCallback(e)
	-- If the attacker is not the player, do nothing
	if e.reference ~= tes3.player then return end
	-- If the player is not sneaking, do nothing
	if not tes3.mobilePlayer.isSneaking then return end
	-- If there is not target, then do nothing
	if not e.targetMobile then return end
	-- If the player has been already detected, do nothing
	if e.targetMobile.isPlayerDetected then return end
	-- If the target is not an NPC, then do nothing
	if e.targetMobile.actorType ~= tes3.actorType.npc then return end

	-- Let's find what weapon is the player holding
	local relevantSkill = -1
	local skillLevel = -1
	local weapon = e.mobile.readiedWeapon
	if not weapon then
		relevantSkill 	= tes3.skill.handToHand
		skillLevel 		= e.mobile.handToHand.current
	elseif weapon.object and weapon.object.type == tes3.weaponType.shortBladeOneHand then
		relevantSkill 	= tes3.skill.shortBlade
		skillLevel 		= e.mobile.shortBlade.current
	elseif 	(weapon.object and weapon.object.type == tes3.weaponType.bluntOneHand) or
			(weapon.object and weapon.object.type == tes3.weaponType.bluntTwoWide) then
		relevantSkill 	= tes3.skill.bluntWeapon
		skillLevel 		= e.mobile.bluntWeapon.current
	end
	-- If not one of these, do nothing
	if relevantSkill == -1 then return end



	-- Now, for the non-lethal stream
	if relevantSkill == tes3.skill.handToHand or relevantSkill == tes3.skill.bluntWeapon then
		-- 1: Find the helmet that the target is wearing
		local helmetScore = 0
		-- 0 = No helmet 	1 = light
		-- 2 = medium		3 = heavy
		local helmet = tes3.getEquippedItem({
			actor = e.targetMobile,
			slot = tes3.armorSlot.helmet,
			objectType = tes3.objectType.armor
		})
		if helmet and helmet.object and helmet.object.weightClass then
			helmetScore = 1 + helmet.object.weightClass
		end
		-- 2: Calculate the player score
		local playerScore = math.floor(e.mobile.sneak.current/25)

		local skillCheck = helmetScore < playerScore

		if skillCheck then
			e.targetMobile:applyFatigueDamage(3000)
			local victim = tes3.makeSafeObjectHandle(e.targetReference)
			timer.delayOneFrame(
				function() if victim:valid() then
					local victimSH = victim:getObject()
					victimSH.mobile:stopCombat(true)
				else
					log:debug("Reference got invalidated in the non-lethal stream delayOneFrame")
				end

			 end)
			else
				if helmet then
				tes3.messageBox("This helmet was too tough!")
				else
				tes3.messageBox("I need to improve my skill")
				end
		end
	-- Now for the lethal stream
	elseif relevantSkill == tes3.skill.shortBlade then
		local sneakStrikeFactor = (2 + math.clamp(e.mobile.sneak.current/25,0,6)) or 1
		e.mobile.actionData.physicalDamage = e.mobile.actionData.physicalDamage*sneakStrikeFactor
		tes3.messageBox(string.format("Sneak attack! %s x damage",sneakStrikeFactor))
	end


end
event.register(tes3.event.attackHit, attackHitCallback)
