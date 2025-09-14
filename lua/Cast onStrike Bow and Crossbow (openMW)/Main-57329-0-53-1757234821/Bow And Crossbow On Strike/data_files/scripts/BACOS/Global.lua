local types = require('openmw.types')


local function setCharge(data)
	types.Item.itemData(data.Item).enchantmentCharge=data.Charge
end

return {
	eventHandlers = {	
						BACOSsetCharge=setCharge
					},
	engineHandlers = {
	}

}