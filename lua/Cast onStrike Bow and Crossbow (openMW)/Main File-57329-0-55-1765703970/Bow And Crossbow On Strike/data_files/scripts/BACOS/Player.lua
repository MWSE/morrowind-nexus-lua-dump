local ui=require('openmw.ui')
local core=require('openmw.core')
local self=require('openmw.self')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local async = require('openmw.async')
local BACOSSettingsG = storage.globalSection('BACOSGeneralSettingsG')

core.sendGlobalEvent("SetOnlyOnstrikeG",{Value=storage.playerSection('BACOSGeneralSettings'):get('OnlyOnstrike')})

local function ShowMessage(data)
    ui.showMessage(data.text)
end

local function PlaySound(data)
	core.sound.playSound3d(data.Sound,self)
end

storage.playerSection('BACOSGeneralSettings'):subscribe(async:callback(function (section, key)
  if section=="BACOSGeneralSettings" and key=="OnlyOnstrike" then
	core.sendGlobalEvent("SetOnlyOnstrikeG",{Value=storage.playerSection('BACOSGeneralSettings'):get('OnlyOnstrike')})
  end
end))




return {
	eventHandlers = {	
						BACOSPlaySound=PlaySound,
					},
	engineHandlers = {

	}

}