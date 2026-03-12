local function combatStartCallback(e)
	if e.actor ~= tes3.mobilePlayer then
		return
	end
	if tes3.mobilePlayer.fatigue.current <= tes3.mobilePlayer.fatigue.base * 0.5 then
		tes3.messageBox("У ВАС МАЛО СТАМИНЫ!!!")
		tes3.playSound({ sound = "heartdead", reference = tes3.player })
	end
end
event.register(tes3.event.combatStart, combatStartCallback)

local function initializedCallback(e)
	mwse.log("StaminaRemainder is initialized")
end
event.register(tes3.event.initialized, initializedCallback)