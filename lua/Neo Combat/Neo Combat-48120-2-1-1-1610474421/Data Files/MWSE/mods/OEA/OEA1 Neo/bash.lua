local BashState
local hitterReference
local config = require("OEA.OEA1 Neo.config")

local function CannotBashAnymore()
	BashState = 0
	mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
end

local function KnockdownAnimationFinished()
	tes3.playAnimation({ reference = hitterReference, group = 0x0, startFlag = tes3.animationStartFlag.immediate })
end

local function OnSkill(e)
	if (e.skill == tes3.skill.block) then
		BashState = 1
		mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain" })
		local timer3 = timer.start({ duration = 1.5, callback = CannotBashAnymore })
	end
end

local function KeyDown(e)
	if e.keyCode == config.attackKey2.keyCode and not tes3.menuMode() then
		if (tes3.mobilePlayer.readiedShield ~= nil) and (tes3.mobilePlayer.weaponDrawn == true) and (BashState == 1) then
			BashState = 0
			if (config.msgkey == true) then
				tes3.messageBox "You are now shield-bashing."
			end
			if (hitterReference ~= nil) then
				local timer4 = timer.start({ duration = 3, callback = KnockdownAnimationFinished })
				tes3.modStatistic({ reference = hitterReference, name = "fatigue", current = -25 })
				tes3.playAnimation({ reference = hitterReference, group = 0x22, startFlag = tes3.animationStartFlag.immediate })
			end
		end
	end
end

local function OnAttack(e)
	if (e.targetReference == tes3.player) then
		hitterReference = e.reference
	end
end

event.register("attack", OnAttack)
event.register("keyDown", KeyDown)
event.register("exerciseSkill", OnSkill)