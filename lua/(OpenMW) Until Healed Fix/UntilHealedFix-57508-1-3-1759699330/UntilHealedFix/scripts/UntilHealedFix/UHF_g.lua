local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')

local function activateBed(object, actor)
	local scrName = types.Activator.record(object.recordId).mwscript
	if scrName == "bed_standard" or scrName == "chargenbed" or scrName == "A_UsingBedRoll" then
		actor:sendEvent("UHF_ActivatedBed", object)
	end
end

I.Activation.addHandlerForType(types.Activator, activateBed)

local function cancelSleep()
	local script = world.mwscript.getGlobalScript("UntilHealedFix_wakeUp")
	script.variables.wakeUp = 1
end



return{
	eventHandlers = {
		UHF_cancelSleep = cancelSleep,
    }
}