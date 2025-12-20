local types = require('openmw.types')
local storage = require('openmw.storage')

local BACOSSettings = storage.globalSection('BACOSGeneralSettingsG')
BACOSSettings:set("OnlyOnstrikeG", false)


local function setCharge(data)
	types.Item.itemData(data.Item).enchantmentCharge=data.Charge
end


local function SetOnlyOnstrikeG(data)
	BACOSSettings:set("OnlyOnstrikeG", data.Value)
end



return {
	eventHandlers = {	
						BACOSsetCharge=setCharge,
						SetOnlyOnstrikeG=SetOnlyOnstrikeG,
					},
	engineHandlers = {
	}

}