local A = require('openmw.types').Actor
local self = require('openmw.self')
local ui = require('openmw.ui')

return {
    engineHandlers = {
     onFrame = function(dt)
     
local helmet = A.equipment(self, A.EQUIPMENT_SLOT.Helmet)
   if helmet and helmet.recordId:find('rw_sinek_space_ship') then 
     -- ui.showMessage('You have pressed "X"')          
     -- вот сюда вставить нажатие следующее заклинание однократно
	-- или как-то выбрать заклинание по ID
     local st = A.stance(self)
     if st == 0 or 1 then
     A.setStance(self, 2)
     end
   end
   end,
    }
}