--Window To Aetherius, coded by Greatness7 with artwork and implementation by Markel


-- disable vanilla sky rotating (only for testing!)
--a necessary evil, if anything causes problems it'll end up being this
 mwse.memory.writeNoOperation({ address = 0x440D0F, length = 13 })

local function getCurrentTimeOfYearNormalized()
	local month = tes3.worldController.month.value
	local day = tes3.worldController.day.value
	local hour = tes3.worldController.hour.value
	local daysPassed = tes3.getCumulativeDaysForMonth(month) + day
	local hoursPassed = daysPassed * 24 + hour
	local minutesPassed = hoursPassed * 60
	local secondsPassed = minutesPassed * 60
	return math.remap(secondsPassed, 0, 365*24*60*60, 0, 1)
end

event.register("simulate", function(e)
	local skyRoot = tes3.worldController.weatherController.sceneSkyRoot
	local nightSky = skyRoot:getObjectByName("sky_night_02_anim")
    if nightSky == nil then
        tes3.messageBox("Could not find NiTriShape('sky_night_02_anim')")
        return
    end

	local phase = getCurrentTimeOfYearNormalized()

	local controller = nightSky.controller
	while controller do
		controller.active = true
		controller.frequency = 0
		controller.phase = phase - controller.lastScaledTime
		controller = controller.nextController
	end

	nightSky:updateEffects()
	nightSky:updateProperties()
	nightSky:update({controllers=true})

--	tes3.messageBox("UV Phase: %.6f", phase)
--	tes3.messageBox("Current Day: %s", tes3.worldController.day.value)
--	tes3.messageBox("Current Month: %s", tes3.worldController.month.value)
end)