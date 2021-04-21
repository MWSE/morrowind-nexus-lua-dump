local config = require("OEA.OEA1 Neo.config")

local function OnCombat(e)
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if (e.actor == tes3.mobilePlayer) or (e.target == tes3.mobilePlayer) then
		if (tes3.player.data.OEA1.CombatState == nil) then
			mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
			tes3.player.data.OEA1.CombatState = 1
		end
	end
end

local function OffCombat(e)
	--mwse.log("%s should have ended combat.", e.actor.object.name)
	if (e.actor == tes3.mobilePlayer) or (tes3.mobilePlayer.inCombat == false) then
		mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
		mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
		tes3.player.data.OEA1.BlockState = 0
		tes3.player.data.OEA1.CombatState = nil
		if (config.msgkey == true) and (tes3.mobilePlayer.health.current > 0) then
			tes3.messageBox "You have left combat. Thus, you are automatically no longer ready to block."
		end
	end
end

local function KeyDown(e)
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if e.keyCode == config.attackKey2.keyCode and not tes3.menuMode() then
		if (tes3.mobilePlayer.readiedShield ~= nil) and (tes3.mobilePlayer.weaponDrawn == true) and (tes3.mobilePlayer.inCombat == true) then
			if (tes3.player.data.OEA1.BlockState == nil) or (tes3.player.data.OEA1.BlockState == 0) then
				tes3.player.data.OEA1.BlockState = 1
				if (config.msgkey == true) then
					tes3.messageBox "You are now ready to block."
				end
				mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
				mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
				tes3.mobilePlayer.magicDisabled = true
			elseif (tes3.player.data.OEA1.BlockState == 1) and (mwscript.getSpellEffects({ reference = tes3.player, spell = "OEA1_Speed_Drain" }) == true) then
				tes3.player.data.OEA1.BlockState = 0
				if (config.msgkey == true) then
					tes3.messageBox "You are no longer ready to block."
				end
				tes3.mobilePlayer.magicDisabled = false
				mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
				mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
			end
		elseif (tes3.mobilePlayer.inCombat == false) then
			mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
			mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
		end
	end
end

local function WeaponReadied(e)
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if (tes3.mobilePlayer.inCombat == false) then
		return
	end

	if (tes3.player.data.OEA1.BlockState ~= nil) and (tes3.player.data.OEA1.BlockState == 1) then
		if (tes3.mobilePlayer.readiedShield == nil) then
			mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
			mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
			tes3.player.data.OEA1.BlockState = 0
			if (config.msgkey == true) and (tes3.mobilePlayer.health.current > 0) then
				tes3.messageBox "You have removed your shield. Thus, you are automatically no longer ready to block."
			end
		end
	end
end

local function WeaponUnreadied(e)
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if (tes3.menuMode() == true) then
		return
	end

	if (tes3.mobilePlayer.inCombat == false) then
		return
	end

	if (tes3.player.data.OEA1.BlockState ~= nil) and (tes3.player.data.OEA1.BlockState == 1) then
		mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Blocking_Penalty" })
		mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
		tes3.player.data.OEA1.BlockState = 0
		if (config.msgkey == true) and (tes3.mobilePlayer.health.current > 0) then
			tes3.messageBox "You have lowered your weapons. Thus, you are automatically no longer ready to block."
		end
	end
end

local function OnDamage(e)
	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if (e.attackerReference ~= nil) and (e.attackerReference == tes3.player) then
		if (tes3.player.data.OEA1.BlockState ~= nil) and (tes3.player.data.OEA1.BlockState == 1) then
			e.damage = 0
		end
	end
end

local function OnAttack(e)
	if (e.reference == nil) or (e.reference ~= tes3.player) then
		return
	end

	if (tes3.player.data.OEA1 == nil) then
		tes3.player.data.OEA1 = {}
	end

	if (tes3.player.data.OEA1.BlockState ~= nil) and (tes3.player.data.OEA1.BlockState == 1) then
		tes3.messageBox("You cannot attack while ready to block.")
		tes3.mobilePlayer.actionData.animationAttackState = 0
		return false
	end
end

event.register("weaponReadied", WeaponReadied)
event.register("weaponUnreadied", WeaponUnreadied)
event.register("attack", OnAttack, { priority = 1000000 })
event.register("damage", OnDamage, { priority = -1000000 })
event.register("combatStarted", OnCombat)
event.register("combatStopped", OffCombat)
event.register("keyDown", KeyDown)