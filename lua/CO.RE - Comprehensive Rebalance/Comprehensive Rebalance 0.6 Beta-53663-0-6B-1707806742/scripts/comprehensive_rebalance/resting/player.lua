local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local calendar = require('openmw_aux.calendar')
local self = require('openmw.self')
local core = require("openmw.core")
local storage = require('openmw.storage')

local MOD_NAME = "comprehensive_rebalance"
local settings = storage.globalSection("SettingsGlobal" .. MOD_NAME .. "rest")
local strings = core.l10n(MOD_NAME)

local startedRestMenuTime = 0
local lastRestTime = 0

--log whenever we last slept
local function setLastSleep(data)

	if data.newMode == 'Rest' then
		startedRestMenuTime = core.getGameTime()
	elseif data.oldMode == 'Rest' and core.getGameTime() >= startedRestMenuTime + 3600 then
			--ui.showMessage("Update last rest time...")
			lastRestTime = core.getSimulationTime()
			core.sendGlobalEvent('playerRested', {origin = self.object, restTime = lastRestTime})
	end
end

--handle pressing T and trying to rest
local function processRest(id)
	
	if id == input.ACTION.Rest and I.UI.getMode() == 'Rest' then
        
        local restMode = settings:get("disableRestMode")
        local waitMode = settings:get("disableWaitMode")

		local myCell = self.object.cell
		local noSleep = myCell:hasTag("NoSleep")

		local gameTime = calendar.formatGameTime("%d %B\n%I %p")
		local restString = "";
		
		if restMode ~= "disabled" and not noSleep then
			I.UI.removeMode('Rest')
			restString = strings("no_rest")
			if restMode == "show_time" then
				--restString = restString .. '\n\n' .. gameTime
				restString = gameTime
			end
		elseif waitMode ~= "disabled" and noSleep then
			I.UI.removeMode('Rest')
			restString = strings("no_wait")
			if waitMode == "show_time" then
				--restString = restString .. '\n\n' .. gameTime
				restString = gameTime
			end
		elseif not noSleep and settings:get('noRepeatedSleeping') and lastRestTime + (settings:get('noRepeatedSleepingTimer') * 60) > core.getSimulationTime() then
			I.UI.removeMode('Rest')
			restString = strings("not_tired")
		end
		ui.showMessage(restString)
	end
end

local function onSave()
    return {
        lastRest = lastRestTime
    }
end

local function onLoad(data)
    if data then
		lastRestTime = data.lastRest
	end
end

return {
    engineHandlers = {
		onInputAction = processRest,
		onSave = onSave,
        onLoad = onLoad,
    },
	eventHandlers = {
		UiModeChanged = setLastSleep,
		handleBed = handleBedEvent
	},
}
