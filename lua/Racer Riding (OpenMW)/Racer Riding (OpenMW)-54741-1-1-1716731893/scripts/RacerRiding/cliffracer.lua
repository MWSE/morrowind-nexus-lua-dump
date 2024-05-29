local self = require("openmw.self")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local trans = require("openmw.util").transform
local AI = require("openmw.interfaces").AI

return {
  eventHandlers = {
    RacerRidingStart = function()
      self:enableAI(false)
      AI.removePackages("Combat")
    end,
    RacerRidingStop = function()
      self:enableAI(true)
    end,
    RacerRidingControl = function(data)
      -- Racer has to be in control when attacking target
      if data.inCombat then
        if not AI.getActiveTarget("Combat") then
          self.controls.yawChange = 0
          self.controls.pitchChange = 0
          data.player:sendEvent("RacerRidingTargetDead")
        end
        return
      end

      self.controls.yawChange = data.yawChange
      self.controls.pitchChange = data.pitchChange

      -- Check if the are moving downwards. Note that side movement moves cliff racers forward in some cases, so that is checked for here as well.
      if (data.movement ~= 0 or data.sideMovement ~= 0) and self.rotation:getPitch() + data.pitchChange > 0 then
        local res = nearby.castRay(self.position, trans.move(0, 0, -50) * self.position, { collisionType = nearby.COLLISION_TYPE.Water + nearby.COLLISION_TYPE.World })
        if res.hit then
          -- If no hit object, we are trying to move into water
          if not res.hitObject then
            return
          end
          local script = types.Activator.objectIsInstance(res.hitObject) and types.Activator.record(res.hitObject).mwscript
          if script == "lava" then
            return
          end
        end
      end

      self.controls.sideMovement = data.sideMovement
      self.controls.movement = data.movement
    end,
    RemoveAIPackages = function()
      self:enableAI(false)
    end,
    StartAIPackage = function()
      self:enableAI(true)
    end,
  },
  engineHandlers = {
    onActivated = function(actor)
      if actor.recordId == "player" then
        actor:sendEvent("RacerRidingActivated", { racer = self })
      end
    end
  },
}
