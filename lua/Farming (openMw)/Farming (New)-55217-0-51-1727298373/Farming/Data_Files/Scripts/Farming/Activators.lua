 local self=require('openmw.self')
local core=require('openmw.core')
local types = require('openmw.types')


local function Activate(data)
	if string.find(self.type.record(self).name,"Young") then
		core.sendGlobalEvent("CarePlant",{Plant=self, Player=data})
	end

	if self.recordId=="clod" and string.find(types.Weapon.record(types.Actor.getEquipment(data,types.Actor.EQUIPMENT_SLOT.CarriedRight)).name,"seed") then
		core.sound.playSound3d("animalLARGEleft",self)
		core.sendGlobalEvent('CreateYoungFlora',{ Name = string.gsub(types.Weapon.record(types.Actor.getEquipment(data,types.Actor.EQUIPMENT_SLOT.CarriedRight)).name," seed",""), CellName=self.cell.name, Position=self.position})
		core.sendGlobalEvent('RemoveItem',{ Object = self, number=1})
		core.sendGlobalEvent('RemoveItem',{ Object = types.Actor.getEquipment(data,types.Actor.EQUIPMENT_SLOT.CarriedRight), number=1})
	end
end

return {
	eventHandlers = {},
	engineHandlers = {
		onActivated=Activate
	}

}