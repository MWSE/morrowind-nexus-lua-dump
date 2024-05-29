local util = require("openmw.util")
local world = require("openmw.world")

local teleporting = false

local function teleport(player, racer, force)
  local position = racer.position + util.vector3(0, 0, 500)
  local script = world.mwscript.getGlobalScript("racerridingteleportscript", player)
  if script and not force then
    -- If moving the player through mwscript, we can just set the position directly
    script.variables.doMove = 1
    script.variables.x = position.x
    script.variables.y = position.y
    script.variables.z = position.z
  else
    -- If moving the player through lua, we can't move every frame because the
    -- the cliff racer will not move when the player is teleporting, so only
    -- teleport once the cliff racer gets too far away from the player.
    local distance = (player.position - racer.position):length()
    if force or (not teleporting and distance > 2000 or distance < 50) then
      teleporting = true
      player:teleport(player.cell, position, racer.rotation)
    else
      teleporting = false
    end
  end
end

return {
  eventHandlers = {
    RacerRidingTeleport = function(data)
      teleport(data.player, data.racer)
    end,
    RacerRidingStart = function(data)
      data.player:setScale(0.001)
      teleport(data.player, data.racer, true)
    end,
    RacerRidingStop = function(data)
      data.player:setScale(data.scale)
      data.player:teleport(data.player.cell, data.position, data.rotation)
      teleporting = false
    end,
  },
}
