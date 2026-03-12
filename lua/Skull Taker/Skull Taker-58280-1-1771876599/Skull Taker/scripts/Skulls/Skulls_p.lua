local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local anim = require('openmw.animation')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local util = require('openmw.util')

local function raycastSwing(groupname,key)
  if string.find(key,'hit$') and not string.find(key,'min hit$') then
    local startPos = camera.getPosition()
    local lookVec = camera.viewportToWorldVector(util.vector2(0.5,0.5)):normalize()
    startPos = startPos - lookVec * 30
    local endPos = startPos + lookVec * 100
    local result = nearby.castRay(startPos,endPos,{collisionType=nearby.COLLISION_TYPE.Actor,ignore=self})
--    print("RAYCAST:")
--    print("Hit:",result.hit)
--    print("object:",result.hitObject)
    if result.hitObject ~= nil then
      core.sendGlobalEvent('SK_RaycastSuccess',{actor=self,object=result.hitObject})
    end
  end
end

I.AnimationController.addTextKeyHandler('handtohand',raycastSwing)
I.AnimationController.addTextKeyHandler('weapononehand',raycastSwing)
I.AnimationController.addTextKeyHandler('weapontwohand',raycastSwing)