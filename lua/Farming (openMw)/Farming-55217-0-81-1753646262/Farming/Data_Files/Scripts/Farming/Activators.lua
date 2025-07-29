 local self=require('openmw.self')
local core=require('openmw.core')
local types = require('openmw.types')


local function Activate(data)
	if string.find(self.type.records[self.recordId].name,"Young") then
		core.sendGlobalEvent("CarePlant",{Plant=self, Player=data})
	end

	if types.Activator.records[self.recordId].name=="Clod" and string.find(types.Weapon.records[types.Actor.getEquipment(data,types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].name,"seed") then
		core.sound.playSoundFile3d("sound/farming/createclod.mp3",self)
		core.sendGlobalEvent('CreateYoungFlora',{ Name = string.gsub(types.Weapon.records[types.Actor.getEquipment(data,types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].name," seed",""), CellName=self.cell.name, Position=self.position})
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