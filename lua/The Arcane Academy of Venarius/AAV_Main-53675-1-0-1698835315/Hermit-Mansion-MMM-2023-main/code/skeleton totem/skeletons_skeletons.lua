local ais = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local time = require('openmw_aux.time')

local function onTeleported()
  local near = nearby.actors
  for i,_ in pairs(near) do
  
      if near[i].type == types.Player then  -- nearby player
       
        ais.startPackage({type='Follow', target=near[i], sideWithTarget = true }) -- follow and help
        --local targ = ais.getActivePackage()
        --print(targ.target)
        --print(targ.type)
      end
  end
  
  time.runRepeatedly(function()
    if types.Actor.stats.dynamic.health(self).current <= 0 then -- if die
      core.sendGlobalEvent("madgodmissingmarbles_removeskel", { skel = self } )      -- remove event
    end
  end, 1*time.second)
  
end


return { engineHandlers = { onTeleported = onTeleported }}
