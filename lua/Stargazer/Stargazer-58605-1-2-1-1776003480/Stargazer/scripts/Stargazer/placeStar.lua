local self = require('openmw.self')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')

local function checkCollision()
  local startPos = self.position
  local distance = 1500
  local endPos = util.vector3(
        startPos.x,
        startPos.y,
        startPos.z - distance
  )
--  print(startPos,endPos)
  local hit = nearby.castRay(startPos, endPos, {ignore=self})
  if hit then
--    print(hit.hit)
--    print(hit.hitNormal)
--    print(hit.hitObject)
--    print(hit.hitPos)
  
  local pos = hit.hitPos
  local normal = hit.hitNormal
  pos = pos + util.vector3(0,0,50)
  
  local up = util.vector3(0,0,1)
  
  local rot = nil
  
  local dot = up:dot(normal)
  local axis = up:cross(normal)
  local len = axis:length()
  if len > 0 then
    axis = axis/len
    local angle = math.acos(math.max(-1,math.min(1,dot)))
    rot = util.transform.rotate(angle,axis)
  end

    core.sendGlobalEvent('SG_TeleportObj',{obj=self,pos=hit.hitPos,cell=self.cell.name,rot=rot})
  end
end

local function onActive()
--  print("SHARD ACTIVATED")
  checkCollision()
end

return {
  engineHandlers = {
    onActive = onActive,
  }
}