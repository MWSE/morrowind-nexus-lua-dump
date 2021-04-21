local CounterState
local hitterReference
local config = require("OEA.OEA1 Neo.config")

local function CannotCounterAnymore()
	if (CounterState ~= nil) then
		if (CounterState == 1) then
			CounterState = 0
		end
	end
end

local function FailedCounterEndlag()
	mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain_2" })
end

local function CounterWindowComplete()
	mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Counter_1" })
	if (CounterState ~= nil) then
		if (CounterState == 2) then
			CounterState = 0
			mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain_2" })
			local timer7 = timer.start({ duration = 10, callback = FailedCounterEndlag })
		end
	end
end

local function CounterAnimationFinished()
	tes3.playAnimation({ reference = tes3.player, group = 0x0, startFlag = tes3.animationStartFlag.immediate })
	mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Speed_Drain_2" })
end

local function KeyDown(e)
    if (e.keyCode == config.attackKey.keyCode) and not tes3.menuMode() then
		if (CounterState ~= nil) then
			if (CounterState == 1) then
				CounterState = 2
                		mwscript.addSpell({ reference = tes3.player, spell = "OEA1_Counter_1" })
                		local timer6 = timer.start({ duration = 0.5, callback = CounterWindowComplete })
				if (config.msgkey == true) then
					tes3.messageBox "You are now ready to counter."
				end
			end
		end
	end
end

local function OnAttack(e)
	if (e.targetReference == tes3.player) then
		hitterReference = e.reference
		if (CounterState == 2) then
			CounterState = 0
			mwscript.removeSpell({ reference = tes3.player, spell = "OEA1_Counter_1" })
			tes3.playAnimation({ reference = tes3.player, group = 0x89, startFlag = tes3.animationStartFlag.immediate })
			local timer8 = timer.start({ duration = 1.5, callback = CounterAnimationFinished })
			if (config.msgkey == true) then
				tes3.messageBox "You are now countering. It was probably a lousy attack in the first place."
			end
			tes3.modStatistic({ reference = hitterReference, name = "fatigue", current = -50 })
			tes3.modStatistic({ reference = hitterReference, name = "health", current = -20 })
		end
	end
	if (e.reference == tes3.player) then
		if (tes3.mobilePlayer.readiedWeapon == nil) then
			if (tes3.mobilePlayer.handToHand.current > 30) then
				CounterState = 1
				local timer5 = timer.start({ duration = 5, callback = CannotCounterAnymore })
			end
		end
	end
end

event.register("attack", OnAttack)
event.register("keyDown", KeyDown)