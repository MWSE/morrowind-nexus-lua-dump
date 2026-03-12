local self = require("openmw.self")

local currentEquipment

local function startEquipProcess()
    currentEquipment = self.type.equipment(self)
end

local function finishEquipProcess()
    self.type.setEquipment(self, currentEquipment)
end

local function equipNewItem(params)
    if params.itemObject ~= nil then
        currentEquipment[params.slot] = params.itemObject.recordId
    else
        currentEquipment[params.slot] = nil -- Effectively unequips the item
    end
end

return {eventHandlers = {
    dynamicMoragTongArmor_equipItem = equipNewItem,
    dynamicMoragTongArmor_startEquipProcess = startEquipProcess,
    dynamicMoragTongArmor_finishEquipProcess = finishEquipProcess
}}
