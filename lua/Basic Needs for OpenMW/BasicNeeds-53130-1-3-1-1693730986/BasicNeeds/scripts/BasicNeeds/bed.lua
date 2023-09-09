-- SPDX-License-Identifier: GPL-3.0-or-later
-- -----------------------------------------------------------------------------
-- scripts/BasicNeeds/bed.lua
-- 2023 -- Antti Joutsi <antti.joutsi@gmail.com>
-- -----------------------------------------------------------------------------
local camera = require("openmw.camera")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local Activator = require("openmw.types").Activator
local transform = util.transform

local function getRayTarget(origin, yaw, pitch, rayLength)
   local rotation = transform.rotateZ(yaw) * transform.rotateX(pitch)
   return origin + rotation * util.vector3(0, rayLength, 0)
end

return {
   tryFindBed = function(player)
      local origin = camera.getPosition()
      local target = getRayTarget(origin, camera.getYaw(), camera.getPitch(), 250)
      local hitObject = nearby.castRay(origin, target, { ignore = player }).hitObject
      if (not hitObject) then
         return false
      end

      local record = Activator.objectIsInstance(hitObject) and Activator.record(hitObject)
      return (record and record.mwscript == "bed_standard")
   end,
}
