local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local anim = require('openmw.animation')

local latestDeathAnim = nil

local function equip(data)
  -- :)
  anim.cancel(self,'death1')
  anim.cancel(self,'death2')
  anim.cancel(self,'death3')
  anim.cancel(self,'death4')
  anim.cancel(self,'death5')
  types.Actor.setEquipment(self,data.inv)
  I.AnimationController.playBlendedAnimation('death1',{startPoint=0.5})
end

--local function setLastAnim(groupname,key)
--  latestDeathAnim = groupname
--end
--
--local function cancelAnim()
----  anim.cancel(self,'death1')
----  anim.cancel(self,'death2')
----  anim.cancel(self,'death3')
----  anim.cancel(self,'death4')
----  anim.cancel(self,'death5')
--end
--
--for i=1,5 do
--  I.AnimationController.addTextKeyHandler("death"..i,setLastAnim)
--end

return {
  eventHandlers = {
    SK_Equip = equip,
    SK_CancelAnim = cancelAnim
  }
}